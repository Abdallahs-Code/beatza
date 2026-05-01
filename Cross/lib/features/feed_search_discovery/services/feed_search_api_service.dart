// Service: FeedSearchApiService
// Handles all API calls for Module 8: Feed, Search & Discovery.
//
// Endpoints covered:
//   GET  /api/feed/v1/feed                         → getUserFeed
//   GET  /api/feed/v1/trending-tracks/{userId}     → getTrendingTracks
//   GET  /api/public/feed/v1/search                       → globalSearch
//   GET  /api/public/feed/v1/search/suggestions           → getSearchSuggestions
//   GET  /api/feed/v1/search/history                      → getSearchHistory
//   POST /api/feed/v1/search/add-to-history               → addToSearchHistory
//   DELETE /api/feed/v1/search/history/{historyId}        → deleteSearchHistoryItem
//   GET  /api/public/tracks/v1/permalink/{profileLink}/{permalink}
//                                                  → getTrackByPermalink
//   GET  /api/public/tracks/v1/{id}               → getTrackById (for details)
//
// Service pattern: constructor injection, returns Future<(int, dynamic)>.
// Token read from FlutterSecureStorage key 'access_token'.
// User ID read from FlutterSecureStorage key 'user_id'.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';

class FeedSearchApiService {
  final ApiServices _apiServices;
  final FlutterSecureStorage _storage;
  final http.Client _client;

  FeedSearchApiService({
    ApiServices? apiServices,
    FlutterSecureStorage? storage,
    http.Client? client,
  }) : _apiServices = apiServices ?? ApiServices(),
       _storage = storage ?? const FlutterSecureStorage(),
       _client = client ?? http.Client();

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    return _storage.read(key: 'access_token');
  }

  Future<String?> _getUserId() async {
    return _storage.read(key: 'user_id');
  }

  Map<String, String> _authHeaders(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
    'User-Agent': 'Android',
  };

  // ── GET /api/feed/v1/feed ────────────────────────────────────────────────
  // Returns: (200, List<dynamic>) | (401, message) | (500, message)
  // Query params: includeReposts (bool, default true), offset (int), limit (int)
  Future<(int, dynamic)> getUserFeed({
    bool includeReposts = true,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse('${_apiServices.baseUrl}/api/feed/v1/feed').replace(
        queryParameters: {
          'includeReposts': includeReposts.toString(),
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, body is List ? body : []);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/feed/v1/trending-tracks/{userId} ────────────────────────────
  // Returns: (200, List<dynamic>) | (401, message) | (500, message)
  // Query params: offset (int), limit (int)
  Future<(int, dynamic)> getTrendingTracks({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final userId = await _getUserId();
      if (userId == null) return (401, 'No user ID found');

      final uri =
          Uri.parse(
            '${_apiServices.baseUrl}/api/public/feed/v1/trending-tracks/$userId',
          ).replace(
            queryParameters: {
              'offset': offset.toString(),
              'limit': limit.toString(),
            },
          );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, body is List ? body : []);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/public/profile/v1/{userId} ──────────────────────────────────
  // Fetches public profile details by user ID (display name, avatar, etc.)
  // Returns: (200, Map<String, dynamic>) | (404, message) | (500, message)
  Future<(int, dynamic)> getUserById(String userId) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/public/profile/v1/$userId',
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body is Map<String, dynamic>) {
          // Try unwrapping common envelope shapes
          if (body['data'] is Map<String, dynamic>) {
            return (200, body['data'] as Map<String, dynamic>);
          }
          return (200, body);
        }
      }
      return (
        response.statusCode,
        body is Map ? (body['message'] ?? 'Error') : 'Error',
      );
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/public/tracks/v2/{id} ───────────────────────────────────────
  // Fetches full track details by ID (used to hydrate feed/trending items
  // before navigating to player or displaying in the feed card).
  // Returns: (200, Map<String, dynamic>) | (404, message) | (500, message)
  Future<(int, dynamic)> getTrackById(String trackId) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/public/tracks/v2/$trackId',
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Response shape: { "data": { ... track fields ... } }
        final data = body['data'] as Map<String, dynamic>?;
        return (200, data ?? body);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/public/tracks/v1/permalink/{profileLink}/{permalink} ─────────
  // Returns: (200, Map<String, dynamic> data) | (404, message) | (500, message)
  // Response data shape documented in module_8_apis_ (permalink endpoint).
  Future<(int, dynamic)> getTrackByPermalink({
    required String profileLink,
    required String permalink,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/public/tracks/v1/permalink/$profileLink/$permalink',
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Response: { "message": "...", "data": { trackId, basicInfo, image, audio, ... } }
        final data = body['data'] as Map<String, dynamic>?;
        return (200, data ?? body);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/public/feed/v1/search ──────────────────────────────────────────────
  // Required: q (keyword)
  // Optional: type (everything|tracks|users|playlists|albums),
  //           dateRange (hour|day|week|month|year|all),
  //           duration (lt2|2to10|10to30|gt30|all),
  //           usage (commercial|modify|share|listen),
  //           tag, location, offset, limit
  // Returns: (200, Map<String, dynamic>) | (401, message) | (500, message)
  Future<(int, dynamic)> globalSearch({
    required String query,
    String? type,
    String? dateRange,
    String? duration,
    String? usage,
    String? tag,
    String? location,
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final params = <String, String>{
        'q': query,
        'offset': offset.toString(),
        'limit': limit.toString(),
        'type': type ?? 'everything',
        'dateRange': dateRange ?? 'all',
        'duration': duration ?? 'all',
        'usage': usage ?? 'listen',
      };
      if (tag != null) params['tag'] = tag;
      if (location != null) params['location'] = location;

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/public/feed/v1/search',
      ).replace(queryParameters: params);

      final response = await _client.get(uri, headers: _authHeaders(token));
      debugPrint(
        '[FeedSearch] globalSearch ${response.statusCode} — ${response.body}',
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body is Map<String, dynamic>) {
          // Unwrap {data: {results:[...], counts:{...}}} if present
          if (body['data'] is Map<String, dynamic>) {
            return (200, body['data'] as Map<String, dynamic>);
          }
          return (200, body);
        }
        return (200, <String, dynamic>{});
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      debugPrint('[FeedSearch] globalSearch error: $err');
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/public/feed/v1/search/suggestions ──────────────────────────────────
  // Required: q (partial keyword)
  // Returns: (200, List<dynamic>) | (400, message) | (401, message) | (500, message)
  Future<(int, dynamic)> getSearchSuggestions(String query) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/public/feed/v1/search/suggestions',
      ).replace(queryParameters: {'q': query});

      final response = await _client.get(uri, headers: _authHeaders(token));
      debugPrint(
        '[FeedSearch] suggestions ${response.statusCode} — ${response.body}',
      );
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (body is List) return (200, body);
        // Unwrap common envelope shapes: {data:[...]}, {suggestions:[...]}, {results:[...]}
        for (final key in ['data', 'suggestions', 'results', 'items']) {
          if (body[key] is List) return (200, body[key] as List);
        }
        return (200, <dynamic>[]);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      debugPrint('[FeedSearch] suggestions error: $err');
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/feed/v1/search/history ──────────────────────────────────────────
  // Returns: (200, List<dynamic>) | (401, message) | (500, message)
  Future<(int, dynamic)> getSearchHistory() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/feed/v1/search/history',
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, body is List ? body : []);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── POST /api/feed/v1/search/add-to-history ──────────────────────────────────
  // Body: { "id": "string", "type": "track" }
  // Returns: (201, null) | (400, message) | (401, message) | (500, message)
  Future<(int, dynamic)> addToSearchHistory({
    required String id,
    required String type,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/feed/v1/search/add-to-history',
      );

      final response = await _client.post(
        uri,
        headers: _authHeaders(token),
        body: jsonEncode({'id': id, 'type': type}),
      );

      if (response.statusCode == 201) return (201, null);

      final body = jsonDecode(response.body);
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── GET /api/tracks/v2/ ──────────────────────────────────────────────────
  // Returns: (200, Map<String,dynamic> data) with {tracks:[...], paginationInfo:{...}}
  // Query params: page (int, default 1), limit (int, default 30)
  Future<(int, dynamic)> getPublicTracks({int page = 1, int limit = 30}) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse('${_apiServices.baseUrl}/api/tracks/v2/').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        return (200, data ?? body);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ── DELETE /api/feed/v1/search/history/{historyId} ───────────────────────────
  // Returns: (204, null) | (401, message) | (404, message) | (500, message)
  Future<(int, dynamic)> deleteSearchHistoryItem(String historyId) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/feed/v1/search/history/$historyId',
      );

      final response = await _client.delete(uri, headers: _authHeaders(token));

      if (response.statusCode == 204) return (204, null);

      final body = jsonDecode(response.body);
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }
}
