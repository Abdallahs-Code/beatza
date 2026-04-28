import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/library/models/account_settings_model.dart';

class AccountSettingsApiService {
  final ApiServices _apiServices;
  final http.Client _client;

  AccountSettingsApiService({ApiServices? apiServices, http.Client? client})
      : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client();

  Future<AccountSettings> getSettings(String accessToken) async {
    final response = await _client.get(
      Uri.parse('${_apiServices.baseUrl}/api/profile/v1/settings/account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to fetch account settings. Status: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : decoded;
    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected account settings response format.');
    }
    return AccountSettings.fromJson(data);
  }

  Future<AccountSettings> updateSettings(
    String accessToken,
    AccountSettings settings,
  ) async {
    final response = await _client.patch(
      Uri.parse('${_apiServices.baseUrl}/api/profile/v1/settings/account'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'User-Agent': 'Android',
      },
      body: jsonEncode(settings.toJson()),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update account settings. Status: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    final dynamic data = decoded is Map<String, dynamic> ? (decoded['data'] ?? decoded) : decoded;
    if (data is! Map<String, dynamic>) {
      return settings;
    }
    return AccountSettings.fromJson(data);
  }

  void dispose() => _client.close();
}
