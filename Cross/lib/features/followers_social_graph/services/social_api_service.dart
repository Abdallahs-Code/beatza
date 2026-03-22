import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

//import '../models/follower.dart';
import '../../../core/services/api_services.dart';


class SocialApiService 
{

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
    _servicePath = "${_apiServices.baseUrl}/api/social";
  }


  

  // List<Follower> _parseUserList(String responseBody) 
  // {
  //   final decoded = jsonDecode(responseBody);
  //   final List<dynamic> list = decoded['data'] ?? [];

  //   return list.map((item) 
  //   {
  //     return Follower(
  //       item['user_id']?.toString()        ?? '',
  //       item['display_name']?.toString()   ?? '',
  //       item['profile_img_link']?.toString(),
  //       item['track_count'] as int?        ?? 0,
  //       false,
  //     );
  //   }).toList();
  // }

 

  Future<(int, dynamic)> getFollowers({required String userId}) async {
    if (userId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _storage.read(key: 'access_token');

      if (accessToken == null || accessToken.trim().isEmpty) {
        return (401, "Unauthorized");
      }

      final response = await _client.get(
        Uri.parse("$_servicePath/followers/$userId"),
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "Android",
          "Authorization": "Bearer $accessToken",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final followers = data['data'] ?? [];

        print("Followers fetched successfully:");
        print("Followers count: ${followers.length}");

        return (200, followers);
      }

      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch followers",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> getFollowing({required String userId,}) async {
    if (userId.trim().isEmpty) {
      return (400, "Invalid user ID");
    }

    try {
      final accessToken = await _storage.read(key: 'access_token');

      if (accessToken == null || accessToken.trim().isEmpty) {
        return (401, "Unauthorized");
      }

      final response = await _client.get(
        Uri.parse("$_servicePath/following/$userId"),
        headers: {
          "Content-Type": "application/json",
          "User-Agent": "Android",
          "Authorization": "Bearer $accessToken",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final following = data['data'] ?? [];

        print("Following fetched successfully:");
        print("Offset: ${data['offset']}");
        print("Limit: ${data['limit']}");
        print("Following count: ${following.length}");

        for (var user in following) {
          print("User:");
          print("User ID: ${user['user_id']}");
          print("Display Name: ${user['display_name']}");
          print("Profile Image: ${user['profile_img_link']}");
          print("Track Count: ${user['track_count']}");
        }

        return (200, following);
      }
print("MANGA");
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch following",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

Future<(int, dynamic)> getSuggestedUsers() async {
  try {
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null || accessToken.trim().isEmpty) {
      return (401, "Unauthorized");
    }

    final response = await _client.get(
      Uri.parse("$_servicePath/suggested"),
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
        "Authorization": "Bearer $accessToken",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final suggestedUsers = data['data'] ?? [];

      print("Suggested users fetched successfully:");
      print("Suggested users count: ${suggestedUsers.length}");

      return (200, suggestedUsers);
    }
print("MANGA");
    return (
      response.statusCode,
      data["message"] ?? "Failed to fetch suggested users",
    );
  } catch (err) {
    return (500, "Network error: $err");
  }
}

Future<(int, dynamic)> getBlockedUsers() async {
  try {
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null || accessToken.trim().isEmpty) {
      return (401, "Unauthorized");
    }

    final response = await _client.get(
      Uri.parse("$_servicePath/blocked"),
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
        "Authorization": "Bearer $accessToken",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final blockedUsers = data['data'] ?? [];

      print("Blocked users fetched successfully:");
      print("Blocked users count: ${blockedUsers.length}");

      return (200, blockedUsers);
    }
print("MANGA");
    return (
      
      response.statusCode,
      data["message"] ?? "Failed to fetch blocked users",
    );
  } catch (err) {
    return (500, "Network error: $err");
  }
}

  Future<(int, dynamic)> followUser({required String targetUserId}) async {
  if (targetUserId.trim().isEmpty) {
    return (400, "Invalid user ID");
  }

  try {
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null || accessToken.trim().isEmpty) {
      return (401, "Unauthorized");
    }

    final response = await _client.post(
      Uri.parse("$_servicePath/follow/$targetUserId"),
      headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
        "Authorization": "Bearer $accessToken",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      print("Follow successful:");
      print("Target User ID: $targetUserId");

      return (200, data);
    }

    return (
      response.statusCode,
      data["message"] ?? "Follow request failed",
    );
  } catch (err) {
    return (500, "Network error: $err");
  }
}

Future<(int, dynamic)> unfollowUser({required String targetUserId}) async 
{
  if (targetUserId.trim().isEmpty) 
  {
    return (400, "Invalid user ID");
  }
  try 
  {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null || accessToken.trim().isEmpty) 
    {
      return (401, "Unauthorized");
    }
    final response = await _client.post(
      Uri.parse("$_servicePath/unfollow/$targetUserId"),
      headers: 
      {
        "Content-Type" : "application/json",
        "User-Agent"   : "Android",
        "Authorization": "Bearer $accessToken",
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) 
    {
      print("Unfollow successful:");
      print("Target User ID: $targetUserId");
      return (200, data);
    }
    return (
      response.statusCode,
      data["message"] ?? "Unfollow request failed",
    );
  } 
  catch (err) 
  {
    return (500, "Network error: $err");
  }
}

Future<(int, dynamic)> blockUser({required String targetUserId}) async 
{
  if (targetUserId.trim().isEmpty) 
  {
    return (400, "Invalid user ID");
  }
  try 
  {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null || accessToken.trim().isEmpty) 
    {
      return (401, "Unauthorized");
    }
    final response = await _client.post(
      Uri.parse("$_servicePath/block/$targetUserId"),
      headers: 
      {
        "Content-Type" : "application/json",
        "User-Agent"   : "Android",
        "Authorization": "Bearer $accessToken",
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) 
    {
      print("Block successful:");
      print("Target User ID: $targetUserId");
      return (200, data);
    }
    return (
      response.statusCode,
      data["message"] ?? "Block request failed",
    );
  } 
  catch (err) 
  {
    return (500, "Network error: $err");
  }
}

Future<(int, dynamic)> unblockUser({required String targetUserId}) async 
{
  if (targetUserId.trim().isEmpty) 
  {
    return (400, "Invalid user ID");
  }
  try 
  {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null || accessToken.trim().isEmpty) 
    {
      return (401, "Unauthorized");
    }
    final response = await _client.post(
      Uri.parse("$_servicePath/unblock/$targetUserId"),
      headers: 
      {
        "Content-Type" : "application/json",
        "User-Agent"   : "Android",
        "Authorization": "Bearer $accessToken",
      },
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) 
    {
      print("Unblock successful:");
      print("Target User ID: $targetUserId");
      return (200, data);
    }
    return (
      response.statusCode,
      data["message"] ?? "Unblock request failed",
    );
  } 
  catch (err) 
  {
    return (500, "Network error: $err");
  }
}
}