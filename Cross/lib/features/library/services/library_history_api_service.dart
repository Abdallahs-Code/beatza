// Dart imports
import 'dart:convert';

// Package imports
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';

class LibraryHistoryApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  late final String _servicePath;

  LibraryHistoryApiService({ApiServices? apiServices, http.Client? client})
    : _apiServices = apiServices ?? ApiServices(),
      _client = client ?? http.Client() {
    _servicePath = '${_apiServices.baseUrl}/api/playback/v1';
  }

  Future<List<PlaybackTrackModel>> getUserHistoryTracks(
    String accessToken,
  ) async {
    final response = await _client.get(
      Uri.parse('$_servicePath/history/tracks'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
    );

    if (response.statusCode == 404) {
      final dynamic decoded404 = jsonDecode(response.body);
      if (decoded404 is Map<String, dynamic>) {
        final String message = (decoded404['message'] ?? '').toString();
        if (message.toLowerCase().contains('no history')) {
          return [];
        }
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch listening history. '
        'Status code: ${response.statusCode}. '
        'Body: ${response.body}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected listening history response format.');
    }

    final dynamic data = decoded['data'];

    if (data is! List) {
      throw Exception(
        'Listening history response does not contain a valid data list.',
      );
    }

    final List<PlaybackTrackModel> parsedTracks = data
        .whereType<Map<String, dynamic>>()
        .map(PlaybackTrackModel.fromApiJson)
        .toList();

    return _deduplicateKeepingLatestAtTop(parsedTracks);
  }

  List<PlaybackTrackModel> _deduplicateKeepingLatestAtTop(
    List<PlaybackTrackModel> tracks,
  ) {
    final Set<String> seenTrackIds = <String>{};
    final List<PlaybackTrackModel> uniqueTracks = <PlaybackTrackModel>[];

    for (final PlaybackTrackModel track in tracks) {
      final String normalizedId = track.id.trim();

      if (normalizedId.isEmpty) {
        uniqueTracks.add(track);
        continue;
      }

      if (seenTrackIds.contains(normalizedId)) {
        continue;
      }

      seenTrackIds.add(normalizedId);
      uniqueTracks.add(track);
    }

    return uniqueTracks;
  }

  Future<List<PlaybackTrackModel>> getUserLikedTracks(
    String userId,
    String accessToken,
  ) async {
    final response = await _client.get(
      Uri.parse('${_apiServices.baseUrl}/api/public/tracks/v1/liked/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch liked tracks. '
        'Status code: ${response.statusCode}.',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected liked tracks response format.');
    }

    final dynamic data = decoded['data'];

    if (data is! List) {
      return [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(PlaybackTrackModel.fromApiJson)
        .toList();
  }

  void dispose() {
    _client.close();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ROUNDABOUT — no direct "tracks reposted by user" endpoint exists yet.
  //
  // Strategy:
  //   1. Fetch every track ID via GET /api/public/tracks/v1/ (all pages).
  //   2. For each track, call GET /api/engagement/tracks/v1/{trackId}/repost
  //      (authenticated) to check whether the current user reposted it.
  //   3. Return tracks whose repost status is { "reposted": true }.
  //
  //       once the backend endpoint is available.
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<PlaybackTrackModel>> getUserRepostedTracks(
    String userId,
    String accessToken,
  ) async {
    try {
      // Step 1 — collect every track in the database (paginated).
      final List<PlaybackTrackModel> allTracks = await _fetchAllPublicTracks();
      if (allTracks.isEmpty) return [];

      // Step 2 — check repost status for each track in parallel.
      final List<PlaybackTrackModel?> results = await Future.wait(
        allTracks.map((t) => _checkRepostStatus(t, accessToken)),
      );

      // Step 3 — keep only tracks the user has reposted.
      return results.whereType<PlaybackTrackModel>().toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PlaybackTrackModel>> _fetchAllPublicTracks() async {
    final List<PlaybackTrackModel> all = [];
    int page = 1;
    bool hasNext = true;

    while (hasNext) {
      try {
        final uri = Uri.parse(
          '${_apiServices.baseUrl}/api/public/tracks/v1/',
        ).replace(queryParameters: {'page': page.toString(), 'limit': '50'});

        final response = await _client.get(
          uri,
          headers: const {
            'Content-Type': 'application/json',
            'User-Agent': 'Android',
          },
        );

        if (response.statusCode < 200 || response.statusCode >= 300) break;

        final dynamic decoded = jsonDecode(response.body);
        final dynamic data = decoded is Map<String, dynamic>
            ? decoded['data']
            : null;
        if (data == null) break;

        final List<dynamic> tracks = (data['tracks'] as List<dynamic>?) ?? [];
        all.addAll(
          tracks.whereType<Map<String, dynamic>>().map(
            PlaybackTrackModel.fromApiJson,
          ),
        );

        hasNext = data['paginationInfo']?['hasNext'] == true;
        page++;
      } catch (_) {
        break;
      }
    }

    return all;
  }

  Future<PlaybackTrackModel?> _checkRepostStatus(
    PlaybackTrackModel track,
    String accessToken,
  ) async {
    if (track.id.trim().isEmpty) return null;
    try {
      final response = await _client.get(
        Uri.parse(
          '${_apiServices.baseUrl}/api/engagement/tracks/v1/${track.id}/repost',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'Android',
        },
      );
      if (response.statusCode != 200) return null;
      final dynamic data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['reposted'] == true) {
        return track;
      }
    } catch (_) {}
    return null;
  }
}
