import 'dart:convert';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:http/http.dart' as http;

class ActivityNotificationsApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final AuthApiService _authApiService;
  late final String _servicePath;

  ActivityNotificationsApiService({
    ApiServices? apiServices,
    http.Client? client,
    AuthApiService? authApiService,
  }) : _apiServices = apiServices ?? ApiServices(),
       _client = client ?? http.Client(),
       _authApiService = authApiService ?? AuthApiService() {
    _servicePath = '${_apiServices.baseUrl}/api/notifications/v1';
  }

  Future<String> _requireAccessToken() async {
    final accessToken = await _authApiService.getStoredAccessToken();
    if (accessToken == null || accessToken.trim().isEmpty) {
      throw Exception('Unauthorized Access');
    }
    return accessToken;
  }

  Map<String, String> _headers(String accessToken) {
    return <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'User-Agent': 'Android',
    };
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  Exception _buildError(
    http.Response response,
    dynamic data,
    String fallbackMessage,
  ) {
    if (data is Map && data['message'] != null) {
      return Exception(data['message'].toString());
    }

    if (response.statusCode == 401) {
      return Exception('Unauthorized Access');
    }

    return Exception(fallbackMessage);
  }

  Future<ActivityNotificationsPage> getNotifications({
    int offset = 1,
    int limit = 20,
    bool? read,
  }) async {
    final accessToken = await _requireAccessToken();

    final query = <String, String>{
      'offset': '$offset',
      'limit': '$limit',
      if (read != null) 'read': '$read',
    };

    final uri = Uri.parse(_servicePath).replace(queryParameters: query);

    final response = await _client.get(uri, headers: _headers(accessToken));
    final data = _decodeBody(response);

    if (response.statusCode == 200 && data is Map) {
      return ActivityNotificationsPage.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    throw _buildError(response, data, 'Failed to fetch notifications');
  }

  Future<int> getUnreadCount() async {
    final accessToken = await _requireAccessToken();

    final uri = Uri.parse('$_servicePath/unread-count');
    final response = await _client.get(uri, headers: _headers(accessToken));
    final data = _decodeBody(response);

    if (response.statusCode == 200 && data is Map) {
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    }

    throw _buildError(response, data, 'Failed to fetch unread count');
  }

  Future<int> markAllAsRead() async {
    final accessToken = await _requireAccessToken();

    final uri = Uri.parse('$_servicePath/read-all');
    final response = await _client.patch(uri, headers: _headers(accessToken));
    final data = _decodeBody(response);

    if (response.statusCode == 200 && data is Map) {
      return (data['unreadCount'] as num?)?.toInt() ?? 0;
    }

    throw _buildError(
      response,
      data,
      'Failed to mark all notifications as read',
    );
  }

  Future<void> markSingleAsRead(String notificationId) async {
    final accessToken = await _requireAccessToken();

    final uri = Uri.parse('$_servicePath/$notificationId/read');
    final response = await _client.patch(uri, headers: _headers(accessToken));
    final data = _decodeBody(response);

    if (response.statusCode == 200) {
      return;
    }

    throw _buildError(response, data, 'Failed to mark notification as read');
  }
}
