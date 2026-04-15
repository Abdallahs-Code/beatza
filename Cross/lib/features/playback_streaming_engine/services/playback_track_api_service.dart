import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:cross_team5/core/services/api_services.dart';

import '../models/playback_track_model.dart';

class PlaybackTrackApiService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  PlaybackTrackApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => ApiServices().baseUrl;

  Future<List<PlaybackTrackModel>> getTracksById(String trackId) async {
    final String? accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null || accessToken.trim().isEmpty) {
      throw Exception('No access token found. Please log in first.');
    }

    final String url = '$_baseUrl/api/public/tracks/v1/$trackId';
    print('Playback track URL: $url');

    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
        'Authorization': 'Bearer $accessToken',
      },
    );

    print('Playback track response: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch tracks. '
        'Status code: ${response.statusCode}. '
        'Body: ${response.body}',
      );
    }

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

  void dispose() {
    _client.close();
  }
}