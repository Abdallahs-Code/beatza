import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/follower.dart';
import '../../../core/services/api_services.dart';


class SocialApiService 
{
  final ApiServices _apiServices = ApiServices();
  String? _servicePath;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SocialApiService() 
  {
    _servicePath = "${_apiServices.baseUrl}/api/social";
  }

  // ─────────────────────────────────────────────
  // HELPER: reads the stored access token
  // ─────────────────────────────────────────────
  Future<String?> _getAccessToken() async 
  {
    return await _storage.read(key: 'access_token');
  }

  // ─────────────────────────────────────────────
  // HELPER: builds auth headers using stored token
  // ─────────────────────────────────────────────
  Future<Map<String, String>> _buildHeaders() async 
  {
    final accessToken = await _getAccessToken();
    return 
    {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'User-Agent': 'Android',
    };
  }

  // ─────────────────────────────────────────────
  // HELPER: parses Shape A response
  // Used by: getFollowers, getFollowing, getSuggestedUsers, getBlockedUsers
  //
  // Shape A:
  // {
  //   "total": 0, "offset": 0, "limit": 0,
  //   "data": [
  //     { "user_id": "string", "display_name": "string",
  //       "profile_img_link": "string", "track_count": 0 }
  //   ]
  // }
  // ─────────────────────────────────────────────
  List<Follower> _parseUserList(String responseBody) 
  {
    final decoded = jsonDecode(responseBody);
    final List<dynamic> list = decoded['data'] ?? [];

    return list.map((item) 
    {
      return Follower(
        item['user_id']?.toString()        ?? '',
        item['display_name']?.toString()   ?? '',
        item['profile_img_link']?.toString(),
        item['track_count'] as int?        ?? 0,
        false, // isFollowing is a local UI state, not returned by the API
      );
    }).toList();
  }

  // ─────────────────────────────────────────────
  // HELPER: parses Shape B response
  // Used by: followUser, unfollowUser, blockUser, unblockUser
  //
  // Shape B:
  // {
  //   "success": true,
  //   "user": {
  //     "user_id": "string", "display_name": "string",
  //     "profile_img_link": "string", "track_count": 0
  //   }
  // }
  // ─────────────────────────────────────────────
  Follower _parseSingleUser(String responseBody) 
  {
    final decoded = jsonDecode(responseBody);
    final item    = decoded['user'];

    return Follower(
      item['user_id']?.toString()        ?? '',
      item['display_name']?.toString()   ?? '',
      item['profile_img_link']?.toString(),
      item['track_count'] as int?        ?? 0,
      false,
    );
  }

  // ─────────────────────────────────────────────
  // GET /api/social/followers/{userId}
  // Returns list of users who follow the given user
  // Params: userId (path), offset (query, default 0), limit (query, default 20)
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getFollowers({
    required String userId,
    int offset = 0,
    int limit  = 20,
  }) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final uri = Uri.parse('$_servicePath/followers/$userId')
          .replace(queryParameters: 
          {
            'offset': offset.toString(),
            'limit' : limit.toString(),
          });

      final response = await http.get(uri, headers: await _buildHeaders());
      final data     = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseUserList(response.body));
      }
      return (response.statusCode, data['message'] ?? "Failed to load followers");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // GET /api/social/following/{userId}
  // Returns list of users that the given user is following
  // Params: userId (path), offset (query, default 0), limit (query, default 20)
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getFollowing({
    required String userId,
    int offset = 0,
    int limit  = 20,
  }) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final uri = Uri.parse('$_servicePath/following/$userId')
          .replace(queryParameters: 
          {
            'offset': offset.toString(),
            'limit' : limit.toString(),
          });

      final response = await http.get(uri, headers: await _buildHeaders());
      final data     = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseUserList(response.body));
      }
      return (response.statusCode, data['message'] ?? "Failed to load following");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // GET /api/social/suggested
  // Returns suggested users for the authenticated user to follow
  // Backend identifies current user from auth token
  // Params: offset (query, default 0), limit (query, default 20)
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getSuggestedUsers({
    int offset = 0,
    int limit  = 20,
  }) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final uri = Uri.parse('$_servicePath/suggested')
          .replace(queryParameters: 
          {
            'offset': offset.toString(),
            'limit' : limit.toString(),
          });

      final response = await http.get(uri, headers: await _buildHeaders());
      final data     = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseUserList(response.body));
      }
      return (response.statusCode, data['message'] ?? "Failed to load suggestions");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // GET /api/social/blocked
  // Returns list of users blocked by the authenticated user
  // Backend identifies current user from auth token
  // Params: offset (query, default 0), limit (query, default 20)
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getBlockedUsers({
    int offset = 0,
    int limit  = 20,
  }) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final uri = Uri.parse('$_servicePath/blocked')
          .replace(queryParameters: 
          {
            'offset': offset.toString(),
            'limit' : limit.toString(),
          });

      final response = await http.get(uri, headers: await _buildHeaders());
      final data     = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseUserList(response.body));
      }
      return (response.statusCode, data['message'] ?? "Failed to load blocked users");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // POST /api/social/follow/{userId}
  // Authenticated user follows another user
  // Returns the followed user's data on success
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> followUser({required String targetUserId}) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final response = await http.post(
        Uri.parse('$_servicePath/follow/$targetUserId'),
        headers: await _buildHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseSingleUser(response.body));
      }
      return (response.statusCode, data['message'] ?? "Follow request failed");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // POST /api/social/unfollow/{userId}
  // Authenticated user unfollows another user
  // Returns the unfollowed user's data on success
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> unfollowUser({required String targetUserId}) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final response = await http.post(
        Uri.parse('$_servicePath/unfollow/$targetUserId'),
        headers: await _buildHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseSingleUser(response.body));
      }
      return (response.statusCode, data['message'] ?? "Unfollow request failed");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // POST /api/social/block/{userId}
  // Authenticated user blocks another user
  // Returns the blocked user's data on success
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> blockUser({required String targetUserId}) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final response = await http.post(
        Uri.parse('$_servicePath/block/$targetUserId'),
        headers: await _buildHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseSingleUser(response.body));
      }
      return (response.statusCode, data['message'] ?? "Block request failed");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // POST /api/social/unblock/{userId}
  // Authenticated user unblocks another user
  // Returns the unblocked user's data on success
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> unblockUser({required String targetUserId}) async 
  {
    final accessToken = await _getAccessToken();
    if (accessToken == null) 
    {
      return (401, "User is not authenticated");
    }

    try 
    {
      final response = await http.post(
        Uri.parse('$_servicePath/unblock/$targetUserId'),
        headers: await _buildHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        return (200, _parseSingleUser(response.body));
      }
      return (response.statusCode, data['message'] ?? "Unblock request failed");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }
}




