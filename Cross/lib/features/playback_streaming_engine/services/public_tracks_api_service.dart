// Dart imports
import 'dart:convert';

// Package imports
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';

class PublicTracksApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  late final String _servicePath;

  PublicTracksApiService({
    ApiServices? apiServices,
    http.Client? client,
  })  : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client() {
    _servicePath = '${_apiServices.baseUrl}/api/public/tracks/v1';
  }

  Future<List<PlaybackTrackModel>> getPublicTracks({
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(_servicePath).replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch public tracks. '
        'Status code: ${response.statusCode}. '
        'Body: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected public tracks response format.');
    }

    final dynamic data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception(
        'Public tracks response does not contain a valid data object.',
      );
    }

    final dynamic tracks = data['tracks'];
    if (tracks is! List) {
      throw Exception(
        'Public tracks response does not contain a valid tracks list.',
      );
    }

    return tracks
        .whereType<Map<String, dynamic>>()
        .map(PlaybackTrackModel.fromApiJson)
        .toList();
  }



  Future<List<PlaybackTrackModel>> getAllPublicTracks({
    int limit = 10,
  }) async {
    int page = 1;
    bool hasNext = true;

    final List<PlaybackTrackModel> allTracks = [];

    while (hasNext) {
      final uri = Uri.parse(_servicePath).replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _client.get(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'Failed to fetch tracks page $page. '
          'Status code: ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);

      final tracks = decoded['data']['tracks'] as List;
      final pagination = decoded['data']['paginationInfo'];

      final parsedTracks = tracks
          .whereType<Map<String, dynamic>>()
          .map(PlaybackTrackModel.fromApiJson)
          .toList();

      allTracks.addAll(parsedTracks);

      hasNext = pagination['hasNext'] == true;
      page++;
    }

    print('TOTAL TRACKS FETCHED: ${allTracks.length}');

    return allTracks;
  }

  /// Fetches the single-track detail endpoint and extracts the uploader's
  /// userId. Returns null if the endpoint doesn't include it.
  /// Used as a fallback when PlaybackTrackModel.artistId is null.
  Future<String?> getTrackArtistId(String trackId) async {
    if (trackId.trim().isEmpty) return null;
    try {
      final response = await _client.get(
        Uri.parse('$_servicePath/$trackId'),
        headers: const {
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final dynamic decoded = jsonDecode(response.body);
      // Response may be wrapped in { "data": {...} } or be the track directly.
      final Map<String, dynamic> raw =
          decoded is Map<String, dynamic>
              ? ((decoded['data'] as Map<String, dynamic>?) ?? decoded)
              : {};
      final Map<String, dynamic> basic =
          (raw['basicInfo'] as Map<String, dynamic>?) ?? {};

      // Try every known path the backend might use for the uploader userId.
      // Also handle nested objects: raw['user'] or raw['uploader'] may be a Map.
      final Map<String, dynamic> userObj =
          (raw['user'] as Map<String, dynamic>?) ??
          (raw['uploader'] as Map<String, dynamic>?) ??
          {};
      for (final dynamic candidate in [
        raw['userId'],
        raw['user_id'],
        raw['creator'],
        raw['uploadedBy'],
        raw['uploaded_by'],
        raw['createdBy'],
        raw['created_by'],
        raw['uploaderId'],
        raw['uploader'],  // might be a plain string
        userObj['userId'],
        userObj['_id'],
        userObj['id'],
        userObj['user_id'],
        basic['userId'],
        basic['user_id'],
        basic['uploadedBy'],
        basic['uploaded_by'],
        basic['createdBy'],
        basic['uploaderId'],
      ]) {
        if (candidate is Map) continue; // skip nested objects
        final String val = (candidate ?? '').toString().trim();
        if (val.isNotEmpty) return val;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}