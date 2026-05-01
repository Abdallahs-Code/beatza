// Dart imports
import 'dart:convert';

// Package imports
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';

class PublicTracksPageResult {
  final List<PlaybackTrackModel> tracks;
  final int page;
  final int totalPages;
  final bool hasNext;
  final int totalNumTracks;

  const PublicTracksPageResult({
    required this.tracks,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.totalNumTracks,
  });
}

class PublicTracksApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  late final String _paginatedPath;
  late final String _singleTrackPublicPath;

  PublicTracksApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage() {
    _paginatedPath = '${_apiServices.baseUrl}/api/tracks/v2';
    _singleTrackPublicPath = '${_apiServices.baseUrl}/api/public/tracks/v1';
  }

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'User-Agent': 'Android',
  };

  Future<PublicTracksPageResult> fetchPublicTracksPage({
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse(_paginatedPath).replace(
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );

    final String? token = await _getToken();
    final Map<String, String> headers = token != null
        ? _authHeaders(token)
        : const {'Content-Type': 'application/json', 'User-Agent': 'Android'};

    final response = await _client.get(uri, headers: headers);

    debugPrint('[PublicTracksApiService] GET $uri → ${response.statusCode}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[PublicTracksApiService] ❌ body: ${response.body}');
      throw Exception(
        'Failed to fetch public tracks. '
        'Status code: ${response.statusCode}. '
        'Body: ${response.body}',
      );
    }
    debugPrint(
      '[PublicTracksApiService] raw body (first 400): ${response.body.substring(0, response.body.length.clamp(0, 400))}',
    );

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

    final Map<String, dynamic> paginationInfo =
        (data['paginationInfo'] as Map<String, dynamic>?) ??
        <String, dynamic>{};

    return PublicTracksPageResult(
      tracks: tracks
          .whereType<Map<String, dynamic>>()
          .map(PlaybackTrackModel.fromApiJson)
          .toList(),
      page: paginationInfo['page'] as int? ?? page,
      totalPages: paginationInfo['totalPages'] as int? ?? 1,
      hasNext: paginationInfo['hasNext'] == true,
      totalNumTracks: paginationInfo['totalNumTracks'] as int? ?? 0,
    );
  }

  Future<List<PlaybackTrackModel>> getPublicTracks({
    int page = 1,
    int limit = 10,
  }) async {
    final PublicTracksPageResult result = await fetchPublicTracksPage(
      page: page,
      limit: limit,
    );
    return result.tracks;
  }

  Future<List<PlaybackTrackModel>> getAllPublicTracks({int limit = 10}) async {
    int page = 1;
    bool hasNext = true;

    final List<PlaybackTrackModel> allTracks = <PlaybackTrackModel>[];

    while (hasNext) {
      final PublicTracksPageResult result = await fetchPublicTracksPage(
        page: page,
        limit: limit,
      );

      allTracks.addAll(result.tracks);
      hasNext = result.hasNext;
      page = result.page + 1;
    }

    return allTracks;
  }

  Future<String?> getTrackArtistId(String trackId) async {
    if (trackId.trim().isEmpty) return null;
    try {
      final response = await _client.get(
        Uri.parse('$_singleTrackPublicPath/$trackId'),
        headers: const {
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final dynamic decoded = jsonDecode(response.body);
      final Map<String, dynamic> raw = decoded is Map<String, dynamic>
          ? ((decoded['data'] as Map<String, dynamic>?) ?? decoded)
          : {};
      final Map<String, dynamic> basic =
          (raw['basicInfo'] as Map<String, dynamic>?) ?? {};

      final Map<String, dynamic> userObj =
          (raw['user'] as Map<String, dynamic>?) ??
          (raw['uploader'] as Map<String, dynamic>?) ??
          {};
      for (final dynamic candidate in [
        raw['posterId'], // new API field
        raw['userId'],
        raw['user_id'],
        raw['creator'],
        raw['uploadedBy'],
        raw['uploaded_by'],
        raw['createdBy'],
        raw['created_by'],
        raw['uploaderId'],
        raw['uploader'],
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
        if (candidate is Map) continue;
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
