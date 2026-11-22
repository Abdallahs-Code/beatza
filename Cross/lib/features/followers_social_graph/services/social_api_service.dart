
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;


import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';

class SocialApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  late final String _servicePath;

  SocialApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _apiServices = apiServices ?? ApiServices(),
       _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage() {
    _servicePath = "${_apiServices.baseUrl}/api/social/v1";
  }

  int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  dynamic _tryDecodeJson(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return null;

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return null;
    }
  }

  String _extractMessage(
    http.Response response, {
    required String fallbackMessage,
  }) {
    final decoded = _tryDecodeJson(response.body);

    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    final raw = response.body.trim();
    if (raw.isNotEmpty) {
      return raw;
    }

    return fallbackMessage;
  }

  List<Follower> _parseUserList(String responseBody) {
    final decoded = _tryDecodeJson(responseBody);

    final List<dynamic> list;
    if (decoded is List) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      list = data is List ? data : <dynamic>[];
    } else {
      list = <dynamic>[];
    }

    return list.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);

      return Follower(
        map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
        map['displayName']?.toString() ??
            map['display_name']?.toString() ??
            'Unknown User',
        map['profileImgLink']?.toString() ??
            map['profile_img_link']?.toString(),
        _parseInt(map['trackCount'] ?? map['track_count']),
        _parseInt(map['followersCount'] ?? map['followers_count']),
        _parseIsFollowing(map),
      );
    }).toList();
  }

  bool _parseIsFollowing(Map<String, dynamic> map) {
    
    
    final value =
        map['isFollowed'] ??
        map['is_followed'] ??
        map['isFollowing'] ??
        map['is_following'];

    if (value is bool) return value;

    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1';
    }

    if (value is num) {
      return value != 0;
    }

    return false;
  }

  Future<String?> _getAccessToken() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null || accessToken.trim().isEmpty) {
      return null;
    }
    return accessToken;
  }

  Map<String, String> _headers(String accessToken) {
    return {
      "Content-Type": "application/json",
      "User-Agent": "Android",
      "Authorization": "Bearer $accessToken",
    };
  }

  Future<(int, dynamic)> getFollowers({required String userId}) async {
    if (userId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.get(
        Uri.parse("$_servicePath/followers/$userId"),
        headers: _headers(accessToken),
      );

      if (response.statusCode == 200) {
        final followers = _parseUserList(response.body);
        return (200, followers);
      }

      return (
        response.statusCode,
        _extractMessage(response, fallbackMessage: "Failed to fetch followers"),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }

  Future<(int, dynamic)> getFollowing({required String userId}) async {
    if (userId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.get(
        Uri.parse("$_servicePath/following/$userId"),
        headers: _headers(accessToken),
      );

      if (response.statusCode == 200) {
        final following = _parseUserList(response.body);
        return (200, following);
      }

      return (
        response.statusCode,
        _extractMessage(response, fallbackMessage: "Failed to fetch following"),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }

  Future<(int, dynamic)> getSuggestedUsers() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.get(
        Uri.parse("$_servicePath/suggested"),
        headers: _headers(accessToken),
      );

      if (response.statusCode == 200) {
        final suggestedUsers = _parseUserList(response.body);
        return (200, suggestedUsers);
      }

      return (
        response.statusCode,
        _extractMessage(
          response,
          fallbackMessage: "Failed to fetch suggested users",
        ),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }

  Future<(int, dynamic)> getBlockedUsers() async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.get(
        Uri.parse("$_servicePath/blocked"),
        headers: _headers(accessToken),
      );

      if (response.statusCode == 200) {
        final blockedUsers = _parseUserList(response.body);
        return (200, blockedUsers);
      }

      return (
        response.statusCode,
        _extractMessage(
          response,
          fallbackMessage: "Failed to fetch blocked users",
        ),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }

  Future<(int, dynamic)> followUser({required String targetUserId}) async {
    if (targetUserId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.post(
        Uri.parse("$_servicePath/follow/$targetUserId"),
        headers: _headers(accessToken),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _tryDecodeJson(response.body);
        return (
          response.statusCode,
          decoded ?? _extractMessage(response, fallbackMessage: "Followed"),
        );
      }

      return (
        response.statusCode,
        _extractMessage(response, fallbackMessage: "Follow request failed"),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }

  Future<(int, dynamic)> unfollowUser({required String targetUserId}) async {
    if (targetUserId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.post(
        Uri.parse("$_servicePath/unfollow/$targetUserId"),
        headers: _headers(accessToken),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _tryDecodeJson(response.body);
        return (
          response.statusCode,
          decoded ?? _extractMessage(response, fallbackMessage: "Unfollowed"),
        );
      }

      return (
        response.statusCode,
        _extractMessage(response, fallbackMessage: "Unfollow request failed"),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }

  Future<(int, dynamic)> blockUser({required String targetUserId}) async {
    if (targetUserId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.post(
        Uri.parse("$_servicePath/block/$targetUserId"),
        headers: _headers(accessToken),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _tryDecodeJson(response.body);
        return (
          response.statusCode,
          decoded ?? _extractMessage(response, fallbackMessage: "Blocked"),
        );
      }

      return (
        response.statusCode,
        _extractMessage(response, fallbackMessage: "Block request failed"),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }

  Future<(int, dynamic)> unblockUser({required String targetUserId}) async {
    if (targetUserId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return (401, "Unauthorized");
      }

      final response = await _client.post(
        Uri.parse("$_servicePath/unblock/$targetUserId"),
        headers: _headers(accessToken),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _tryDecodeJson(response.body);
        return (
          response.statusCode,
          decoded ?? _extractMessage(response, fallbackMessage: "Unblocked"),
        );
      }

      return (
        response.statusCode,
        _extractMessage(response, fallbackMessage: "Unblock request failed"),
      );
    } catch (err) {
      return (500, "Request failed: $err");
    }
  }
}
