import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/library/models/notification_settings_model.dart';

class NotificationSettingsApiService {
  final ApiServices _apiServices;
  final http.Client _client;

  NotificationSettingsApiService({ApiServices? apiServices, http.Client? client})
      : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client();

  Future<NotificationSettings> getSettings(String accessToken) async {
    final response = await _client.get(
      Uri.parse('${_apiServices.baseUrl}/api/profile/v1/settings/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch notification settings. Status: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : decoded;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected notification settings response format.');
    }
    return NotificationSettings.fromJson(data);
  }

  Future<NotificationSettings> updateSettings(
    String accessToken,
    NotificationSettings settings,
  ) async {
    final response = await _client.patch(
      Uri.parse('${_apiServices.baseUrl}/api/profile/v1/settings/notifications'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
      body: jsonEncode(settings.toJson()),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update notification settings. Status: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : decoded;
    if (data is! Map<String, dynamic>) {
      return settings;
    }
    return NotificationSettings.fromJson(data);
  }

  void dispose() => _client.close();
}
