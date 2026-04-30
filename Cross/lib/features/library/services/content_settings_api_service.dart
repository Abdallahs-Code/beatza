import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/library/models/content_settings_model.dart';

class ContentSettingsApiService {
  final ApiServices _apiServices;
  final http.Client _client;

  ContentSettingsApiService({ApiServices? apiServices, http.Client? client})
      : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client();

  Future<ContentSettings> getSettings(String accessToken) async {
    final url = '${_apiServices.baseUrl}/api/profile/v1/settings/content';
    debugPrint('[ContentSettingsApi] GET $url');

    final response = await _client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
    ).timeout(const Duration(seconds: 10));

    debugPrint('[ContentSettingsApi] GET ${response.statusCode}: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Failed to fetch content settings. Status: ${response.statusCode}. Body: ${response.body}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic>
        ? (decoded['data'] ?? decoded)
        : decoded;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected content settings response format.');
    }
    return ContentSettings.fromJson(data);
  }

  Future<ContentSettings> updateSettings(
    String accessToken,
    ContentSettings settings,
  ) async {
    final url = '${_apiServices.baseUrl}/api/profile/v1/settings/content';
    final body = jsonEncode(settings.toJson());
    debugPrint('[ContentSettingsApi] PATCH $url');
    debugPrint('[ContentSettingsApi] PATCH body: $body');

    final response = await _client.patch(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
      body: body,
    ).timeout(const Duration(seconds: 10));

    debugPrint('[ContentSettingsApi] PATCH ${response.statusCode}: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Failed to update content settings. Status: ${response.statusCode}. Body: ${response.body}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic>
        ? (decoded['data'] ?? decoded)
        : decoded;
    if (data is! Map<String, dynamic>) return settings;
    return ContentSettings.fromJson(data);
  }

  void dispose() => _client.close();
}
