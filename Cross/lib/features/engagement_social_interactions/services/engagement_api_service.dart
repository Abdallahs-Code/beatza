
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';


import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/engagement_user.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/repost_status.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';

class EngagementApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  late final String _basePath;
  late final String _publicBasePath;

  EngagementApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _apiServices = apiServices ?? ApiServices(),
       _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage() {
    _basePath = "${_apiServices.baseUrl}/api/engagement";
    _publicBasePath = "${_apiServices.baseUrl}/api/public/engagement";
  }

  
  
  

  
  Future<Map<String, String>?> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.trim().isEmpty) return null;
    return {
      "Content-Type": "application/json",
      "User-Agent": "Android",
      "Authorization": "Bearer $token",
    };
  }

  
  Map<String, String> get _publicHeaders => {
    "Content-Type": "application/json",
    "User-Agent": "Android",
  };

  
  
  Future<Map<String, String>> _optionalAuthHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null && token.trim().isNotEmpty) {
      return {
        "Content-Type": "application/json",
        "User-Agent": "Android",
        "Authorization": "Bearer $token",
      };
    }
    return _publicHeaders;
  }

  
  
  
  
  
  
  
  

  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> toggleTrackLike({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final response = await _client.post(
        Uri.parse("$_basePath/tracks/v1/$trackId/like"),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) return (200, data);
      return (
        response.statusCode,
        data["message"] ?? "Failed to toggle track like",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  Future<(int, dynamic)> checkTrackLikeStatus({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");
    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");
      final response = await _client.get(
        Uri.parse("$_basePath/tracks/v1/$trackId/like"),
        headers: headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) return (200, data);
      return (response.statusCode, data["message"] ?? "Failed to check like");
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> togglePlaylistLike({
    required String playlistId,
  }) async {
    if (playlistId.trim().isEmpty) return (400, "Invalid playlist ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final response = await _client.post(
        Uri.parse("$_basePath/playlists/v1/$playlistId/like"),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) return (200, data);
      return (
        response.statusCode,
        data["message"] ?? "Failed to toggle playlist like",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> getTrackLikers({
    required String trackId,
    int offset = 1,
    int limit = 20,
  }) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");

    try {
      final uri = Uri.parse("$_publicBasePath/tracks/v1/$trackId/likes")
          .replace(
            queryParameters: {
              "offset": offset.toString(),
              "limit": limit.toString(),
            },
          );

      final response = await _client.get(uri, headers: _publicHeaders);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, EngagementUser.listFromResponse(data));
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch track likers",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  Future<(int, dynamic)> getPlaylistLikers({
    required String playlistId,
    int offset = 1,
    int limit = 20,
  }) async {
    if (playlistId.trim().isEmpty) return (400, "Invalid playlist ID");

    try {
      final uri = Uri.parse("$_publicBasePath/playlists/v1/$playlistId/likes")
          .replace(
            queryParameters: {
              "offset": offset.toString(),
              "limit": limit.toString(),
            },
          );

      final response = await _client.get(uri, headers: _publicHeaders);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, EngagementUser.listFromResponse(data));
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch playlist likers",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> toggleTrackRepost({
    required String trackId,
    String? caption,
  }) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      
      final Map<String, dynamic> body = {};
      if (caption != null && caption.trim().isNotEmpty) {
        body['caption'] = caption.trim();
      }

      final response = await _client.post(
        Uri.parse("$_basePath/tracks/v1/$trackId/repost"),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) return (200, data);
      return (
        response.statusCode,
        data["message"] ?? "Failed to toggle track repost",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> togglePlaylistRepost({
    required String playlistId,
  }) async {
    if (playlistId.trim().isEmpty) return (400, "Invalid playlist ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final response = await _client.post(
        Uri.parse("$_basePath/playlists/v1/$playlistId/repost"),
        headers: headers,
        body: jsonEncode({}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) return (200, data);
      return (
        response.statusCode,
        data["message"] ?? "Failed to toggle playlist repost",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> getTrackRepostStatus({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final response = await _client.get(
        Uri.parse("$_basePath/tracks/v1/$trackId/repost"),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, RepostStatus.fromJson(data));
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch repost status",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> updateTrackRepostCaption({
    required String trackId,
    required String caption,
  }) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");
    if (caption.trim().isEmpty) return (400, "Caption cannot be empty");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final response = await _client.patch(
        Uri.parse("$_basePath/tracks/v1/$trackId/repost"),
        headers: headers,
        body: jsonEncode({"caption": caption.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) return (200, data);

      
      if (response.statusCode == 400) {
        return (400, data["error"] ?? "You have not reposted this track");
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to update repost caption",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> getTrackReposters({
    required String trackId,
    int offset = 1,
    int limit = 20,
  }) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");

    try {
      final uri = Uri.parse("$_publicBasePath/tracks/v1/$trackId/reposts")
          .replace(
            queryParameters: {
              "offset": offset.toString(),
              "limit": limit.toString(),
            },
          );

      final response = await _client.get(uri, headers: _publicHeaders);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, EngagementUser.listFromResponse(data));
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch track reposters",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  Future<(int, dynamic)> getPlaylistReposters({
    required String playlistId,
    int offset = 1,
    int limit = 20,
  }) async {
    if (playlistId.trim().isEmpty) return (400, "Invalid playlist ID");

    try {
      final uri = Uri.parse("$_publicBasePath/playlists/v1/$playlistId/reposts")
          .replace(
            queryParameters: {
              "offset": offset.toString(),
              "limit": limit.toString(),
            },
          );

      final response = await _client.get(uri, headers: _publicHeaders);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, EngagementUser.listFromResponse(data));
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch playlist reposters",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> getTracksRepostedByUser({
    required String userId,
    int offset = 1,
    int limit = 50,
  }) async {
    if (userId.trim().isEmpty) return (400, "Invalid user ID");

    final int safeLimit = limit.clamp(1, 50);

    try {
      final uri =
          Uri.parse("$_publicBasePath/tracks/v1/users/$userId/reposted")
              .replace(
                queryParameters: {
                  "offset": offset.toString(),
                  "limit": safeLimit.toString(),
                },
              );

      final response = await _client.get(uri, headers: _publicHeaders);
      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (decoded is Map<String, dynamic>) {
          return (200, _tracksFromRepostedTracksResponse(decoded));
        }
        return (200, <Track>[]);
      }

      final String message = decoded is Map
          ? (decoded["message"]?.toString() ?? "Failed to fetch reposted tracks")
          : "Failed to fetch reposted tracks";
      return (response.statusCode, message);
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  static Map<String, dynamic> _normalizeRepostedTrackItem(
    Map<String, dynamic> json,
  ) {
    final out = Map<String, dynamic>.from(json);
    if (out["audio"] is Map<String, dynamic>) {
      final a = Map<String, dynamic>.from(out["audio"]! as Map);
      final link = a["audioLink"] ?? a["url"];
      if (link != null) a["audioLink"] = link.toString();
      out["audio"] = a;
    }
    if (out["image"] is Map<String, dynamic>) {
      final i = Map<String, dynamic>.from(out["image"]! as Map);
      final img = i["imgLink"] ?? i["url"];
      if (img != null) i["imgLink"] = img.toString();
      out["image"] = i;
    }
    final id = out["_id"] ?? out["id"];
    if ((id == null || id.toString().trim().isEmpty) &&
        out["trackId"] != null) {
      out["_id"] = out["trackId"].toString();
    }
    return out;
  }

  static List<Track> _tracksFromRepostedTracksResponse(
    Map<String, dynamic> json,
  ) {
    final raw = json["tracks"];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => Track.fromNestedJson(_normalizeRepostedTrackItem(m)),
        )
        .toList();
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<int> getTrackCommentCount(String trackId) async {
    if (trackId.trim().isEmpty) return 0;
    try {
      final uri = Uri.parse("$_publicBasePath/tracks/v1/$trackId/comments")
          .replace(
            queryParameters: {"offset": "1", "limit": "1", "sortBy": "newest"},
          );
      final response = await _client.get(
        uri,
        headers: await _optionalAuthHeaders(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['total'] as num?)?.toInt() ??
            (data['totalComments'] as num?)?.toInt() ??
            (data['count'] as num?)?.toInt() ??
            (data['commentCount'] as num?)?.toInt() ??
            0;
      }
    } catch (_) {}
    return 0;
  }

  Future<(int, dynamic)> getTrackComments({
    required String trackId,
    int offset = 1,
    int limit = 20,
    String sortBy = 'newest',
  }) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");

    try {
      final uri = Uri.parse("$_publicBasePath/tracks/v1/$trackId/comments")
          .replace(
            queryParameters: {
              "offset": offset.toString(),
              "limit": limit.toString(),
              "sortBy": sortBy,
            },
          );

      final response = await _client.get(
        uri,
        headers: await _optionalAuthHeaders(),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, Comment.listFromCommentsResponse(data));
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch comments",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> getCommentReplies({
    required String commentId,
    int offset = 1,
    int limit = 20,
  }) async {
    if (commentId.trim().isEmpty) return (400, "Invalid comment ID");

    try {
      final uri = Uri.parse("$_publicBasePath/comments/v1/$commentId/replies")
          .replace(
            queryParameters: {
              "offset": offset.toString(),
              "limit": limit.toString(),
            },
          );

      final response = await _client.get(
        uri,
        headers: await _optionalAuthHeaders(),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, Comment.listFromRepliesResponse(data));
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to fetch replies",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> postComment({
    required String trackId,
    required String content,
    required int timestamp,
    String? parentCommentId,
    String? mentionedUserId,
  }) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");
    if (content.trim().isEmpty) return (400, "Comment cannot be empty");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final Map<String, dynamic> body = {
        "content": content.trim(),
        "timestamp": timestamp,
      };

      
      if (parentCommentId != null && parentCommentId.trim().isNotEmpty) {
        body["parentCommentId"] = parentCommentId.trim();
      }

      if (mentionedUserId != null && mentionedUserId.trim().isNotEmpty) {
        body["mentionedUserId"] = mentionedUserId.trim();
      }

      final response = await _client.post(
        Uri.parse("$_basePath/tracks/v1/$trackId/comments"),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      
      if (response.statusCode == 201) {
        return (201, Comment.fromJson(data));
      }
      return (response.statusCode, data["message"] ?? "Failed to post comment");
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> deleteComment({required String commentId}) async {
    if (commentId.trim().isEmpty) return (400, "Invalid comment ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final response = await _client.delete(
        Uri.parse("$_basePath/comments/v1/$commentId"),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, data["message"] ?? "Comment deleted successfully.");
      }

      
      if (response.statusCode == 403) {
        return (403, data["message"] ?? "Not enough permissions");
      }
      return (
        response.statusCode,
        data["message"] ?? "Failed to delete comment",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> toggleCommentLike({required String commentId}) async {
    if (commentId.trim().isEmpty) return (400, "Invalid comment ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      final response = await _client.post(
        Uri.parse("$_basePath/comments/v1/$commentId/like"),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) return (200, data);
      return (
        response.statusCode,
        data["message"] ?? "Failed to toggle comment like",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  
  
  
  Future<(int, dynamic)> getMentionFollowers({
    int offset = 1,
    int limit = 20,
  }) async {
    try {
      
      
      
      
      
      
      
      
      
      
      final accessToken = await FlutterSecureStorage().read(
        key: "access_token",
      );
      final response = await http.Client().get(
        Uri.parse("https://beatza.me/api/engagement/mentions/v1/followers"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "User-Agent": "Android",
        },
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        
        
        
        
        
        
        
        

        
        
        
        
        
        
        
        
        

        final users = (data as List<dynamic>)
            .map((e) {
              final map = e as Map<String, dynamic>;

              return MentionUser(
                userId: (map['userId'] ?? '').toString(),
                displayName: (map['displayName'] ?? '').toString(),
                avatarUrl: map['avatarUrl']?.toString(),
              );
            })
            .where((u) => u.userId.isNotEmpty)
            .toList();

        return (200, users);
      }
      return (
        response.statusCode,
        data is Map ? data['message'] ?? 'Failed' : 'Failed',
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }
}

class MentionUser {
  final String userId;
  final String displayName;
  final String? avatarUrl;

  const MentionUser({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });
}
