




















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
        
        final data = body['data'] as Map<String, dynamic>?;
        return (200, data ?? body);
      }
      return (response.statusCode, body['message'] ?? 'Error');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  
  
  
  Future<(int, dynamic)> getTrackByPermalink({
    required String profileLink,
    required String permalink,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/public/tracks/v2/permalink/$profileLink/$permalink',
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

  
  
  
  Future<(int, dynamic)> getTrackByPermalinkV2({
    required String profileLink,
    required String permalink,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'No access token');

      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/tracks/v2/permalink/$profileLink/$permalink',
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
