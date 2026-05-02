import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/activity/models/track_stats_model.dart';

class PlaybackTrackApiService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  PlaybackTrackApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => ApiServices().baseUrl;

  Future<List<PlaybackTrackModel>> getTracksById(String trackId) async {
    final String? accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw Exception('No access token found. Please log in first.');
    }

    final String url = '$_baseUrl/api/public/tracks/v2/$trackId';

    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
        'Authorization': 'Bearer $accessToken',
      },
    );

    debugPrint('[PlaybackTrackApiService] GET $url → ${response.statusCode}');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[PlaybackTrackApiService] ❌ body: ${response.body}');
      throw Exception(
        'Failed to fetch tracks. '
        'Status code: ${response.statusCode}. '
        'Body: ${response.body}',
      );
    }
    debugPrint(
      '[PlaybackTrackApiService] raw body: ${response.body.substring(0, response.body.length.clamp(0, 400))}',
    );

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected response format: expected top-level object.');
    }

    final dynamic data = decoded['data'];

    if (data == null) {
      throw Exception('Response does not contain a data field.');
    }

    if (data is Map<String, dynamic>) {
      return [PlaybackTrackModel.fromApiJson(data)];
    }

    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PlaybackTrackModel.fromApiJson)
          .toList();
    }

    throw Exception('Unexpected data format inside track response.');
  }

  Future<PlaybackTrackModel> getSingleTrackById(String trackId) async {
    final List<PlaybackTrackModel> tracks = await getTracksById(trackId);

    if (tracks.isEmpty) {
      throw Exception('No track found for id: $trackId');
    }

    return tracks.first;
  }

  Future<TrackStatsModel> getTrackStats(String trackId) async {
    debugPrint('━━━ [getTrackStats] START ━━━');
    debugPrint('[getTrackStats] Fetching stats for trackId: $trackId');
    
    final String? accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null || accessToken.trim().isEmpty) {
      debugPrint('[getTrackStats] ❌ ERROR: No access token found');
      throw Exception('No access token found. Please log in first.');
    }

    final String url = '$_baseUrl/api/public/tracks/v2/stats/$trackId';
    debugPrint('[getTrackStats] Request URL: $url');

    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
        'Authorization': 'Bearer $accessToken',
      },
    );

    debugPrint('[getTrackStats] Response Status: ${response.statusCode}');
    debugPrint('[getTrackStats] Response Headers: ${response.headers}');
    debugPrint('[getTrackStats] Response Body Length: ${response.body.length}');
    
    if (response.statusCode == 403) {
      debugPrint('[getTrackStats] ⚠️ Track stats are private — returning empty private model');
      return TrackStatsModel.private();
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('[getTrackStats] ❌ ERROR: Failed to fetch stats');
      debugPrint('[getTrackStats] Error Body: ${response.body}');
      throw Exception(
        'Failed to fetch track stats. '
        'Status code: ${response.statusCode}. '
        'Body: ${response.body}',
      );
    }
    
    debugPrint('[getTrackStats] Response Body (first 500 chars): ${response.body.substring(0, response.body.length.clamp(0, 500))}');

    final dynamic decoded = jsonDecode(response.body);
    debugPrint('[getTrackStats] Decoded Response Type: ${decoded.runtimeType}');

    if (decoded is! Map<String, dynamic>) {
      debugPrint('[getTrackStats] ❌ ERROR: Unexpected response format - not a Map');
      throw Exception('Unexpected response format: expected top-level object.');
    }

    final dynamic data = decoded['data'];
    debugPrint('[getTrackStats] Data field exists: ${data != null}');
    debugPrint('[getTrackStats] Data Type: ${data?.runtimeType}');

    if (data == null || data is! Map<String, dynamic>) {
      debugPrint('[getTrackStats] ❌ ERROR: No valid data field in response');
      throw Exception('Response does not contain valid stats data.');
    }
    
    // Debug topFans
    final topFansJson = data['topFans'] as List<dynamic>? ?? [];
    debugPrint('[getTrackStats] topFans field exists: ${data.containsKey('topFans')}');
    debugPrint('[getTrackStats] topFans Count: ${topFansJson.length}');
    debugPrint('[getTrackStats] topFans Data: $topFansJson');
    
    // Debug firstFans
    final firstFansJson = data['firstFans'] as List<dynamic>? ?? [];
    debugPrint('[getTrackStats] firstFans field exists: ${data.containsKey('firstFans')}');
    debugPrint('[getTrackStats] firstFans Count: ${firstFansJson.length}');
    debugPrint('[getTrackStats] firstFans Data: $firstFansJson');

    debugPrint('[getTrackStats] ✅ SUCCESS: Parsing TrackStatsModel');
    final stats = TrackStatsModel.fromJson(data);
    debugPrint('[getTrackStats] ✅ Parsed - topFans: ${stats.topFans.length}, firstFans: ${stats.firstFans.length}');

    // Help diagnose privacy-vs-empty: server returned 200 but lists are empty.
    // This commonly means every fan in this track has `showFirstTopFan = false`.
    if (stats.topFans.isEmpty && stats.firstFans.isEmpty) {
      debugPrint(
        '[getTrackStats] ⚠️ Lists are empty (server returned 200, NOT private). '
        'Most likely every fan has showFirstTopFan=false, OR no listens have '
        'been registered yet. Track owner has NOT disabled stats.',
      );
    }
    debugPrint('━━━ [getTrackStats] END ━━━');

    return stats;
  }

  void dispose() {
    _client.close();
  }
}