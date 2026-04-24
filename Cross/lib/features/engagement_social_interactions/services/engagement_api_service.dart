// Dart imports
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Package imports
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/engagement_user.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/repost_status.dart';

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

  // ─────────────────────────────────────────────
  // PRIVATE HELPERS
  // ─────────────────────────────────────────────

  // Returns auth headers. Used by all authenticated endpoints.
  Future<Map<String, String>?> _authHeaders() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.trim().isEmpty) return null;
    return {
      "Content-Type": "application/json",
      "User-Agent": "Android",
      "Authorization": "Bearer $token",
    };
  }

  // Public endpoints need no auth token.
  Map<String, String> get _publicHeaders => {
    "Content-Type": "application/json",
    "User-Agent": "Android",
  };

  // Returns auth headers when token is available, otherwise public headers.
  // Used by comment endpoints so isLikedByUser/isOwnComment populate correctly.
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

  // ═════════════════════════════════════════════
  // ██╗     ██╗██╗  ██╗███████╗███████╗
  // ██║     ██║██║ ██╔╝██╔════╝██╔════╝
  // ██║     ██║█████╔╝ █████╗  ███████╗
  // ██║     ██║██╔═██╗ ██╔══╝  ╚════██║
  // ███████╗██║██║  ██╗███████╗███████║
  // ╚══════╝╚═╝╚═╝  ╚═╝╚══════╝╚══════╝
  // ═════════════════════════════════════════════

  // ─────────────────────────────────────────────
  // Toggle like on a track.
  // POST /api/engagement/tracks/v1/{trackId}/like
  // No request body required.
  //
  // 200: { "liked": true, "numOfLikes": 42 }
  // 401: Authorization failed
  // 404: Track not found
  //
  // Returns (200, {"liked": bool, "numOfLikes": int}) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Check if the current user has liked a track.
  // GET /api/engagement/tracks/v1/{trackId}/like
  //
  // Returns (200, {"liked": bool}) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Toggle like on a playlist.
  // POST /api/engagement/playlists/v1/{playlistId}/like
  // No request body required.
  //
  // 200: { "liked": true, "numOfLikes": 10 }
  // 401: Authorization failed
  // 404: Playlist not found
  //
  // Returns (200, {"liked": bool, "numOfLikes": int}) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Get paginated list of users who liked a track.
  // GET /api/public/engagement/tracks/v1/{trackId}/likes
  // No authentication required.
  //
  // Query params: offset (default 1), limit (default 20, max 50)
  //
  // 200: { "total": 120, "offset": 1, "limit": 20,
  //        "users": [ { userId, displayName, avatarUrl, followersCount } ] }
  //
  // Returns (200, List<EngagementUser>) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Get paginated list of users who liked a playlist.
  // GET /api/public/engagement/playlists/v1/{playlistId}/likes
  // No authentication required.
  //
  // Same response shape as getTrackLikers.
  // Returns (200, List<EngagementUser>) on success.
  // ─────────────────────────────────────────────
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

  // ═════════════════════════════════════════════
  // ██████╗ ███████╗██████╗  ██████╗ ███████╗████████╗███████╗
  // ██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔════╝╚══██╔══╝██╔════╝
  // ██████╔╝█████╗  ██████╔╝██║   ██║███████╗   ██║   ███████╗
  // ██╔══██╗██╔══╝  ██╔═══╝ ██║   ██║╚════██║   ██║   ╚════██║
  // ██║  ██║███████╗██║     ╚██████╔╝███████║   ██║   ███████║
  // ╚═╝  ╚═╝╚══════╝╚═╝      ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝
  // ═════════════════════════════════════════════

  // ─────────────────────────────────────────────
  // Toggle repost on a track.
  // POST /api/engagement/tracks/v1/{trackId}/repost
  //
  // Request body (caption is optional — send null to omit it):
  //   { "caption": "Love this track!" }
  //
  // 200: { "reposted": true, "numberOfReposts": 15 }
  // 401: Authorization failed
  // 404: Track not found
  //
  // Behavior: if user has NOT reposted → creates repost.
  //           if user HAS reposted    → removes repost (toggle).
  //
  // Returns (200, {"reposted": bool, "numberOfReposts": int}) on success.
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> toggleTrackRepost({
    required String trackId,
    String? caption,
  }) async {
    if (trackId.trim().isEmpty) return (400, "Invalid track ID");

    try {
      final headers = await _authHeaders();
      if (headers == null) return (401, "Unauthorized");

      // Only include caption in body if it was provided and not empty.
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

  // ─────────────────────────────────────────────
  // Toggle repost on a playlist.
  // POST /api/engagement/playlists/v1/{playlistId}/repost
  //
  // NOTE: The real SoundCloud app does NOT show a caption
  // input when reposting a playlist — only tracks have captions.
  // This method accepts no caption parameter intentionally.
  //
  // 200: { "reposted": false, "numberOfReposts": 3 }
  // 401: Authorization failed
  // 404: Playlist not found
  //
  // Returns (200, {"reposted": bool, "numberOfReposts": int}) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Get the authenticated user's repost status for a track.
  // GET /api/engagement/tracks/v1/{trackId}/repost
  //
  // Used by RepostBottomSheet to pre-fill the caption field
  // when the user has already reposted this track.
  //
  // 200: { "reposted": true, "caption": "Love this!", "repostedAt": "..." }
  // 401: Authorization failed
  // 404: Track not found (or user has not reposted it)
  //
  // Returns (200, RepostStatus) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Update the caption of an existing track repost.
  // PATCH /api/engagement/tracks/v1/{trackId}/repost
  //
  // Request body: { "caption": "Updated caption text!" }
  //
  // 200: { "success": true, "caption": "Updated caption text!" }
  // 400: { "error": "You have not reposted this track" }
  //      → Guard in UI: only show edit if getTrackRepostStatus
  //        returned reposted: true.
  // 401: Authorization failed
  // 404: Track not found
  //
  // Returns (200, {"success": true, "caption": String}) on success.
  // ─────────────────────────────────────────────
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

      // 400 means user has not reposted — surface the specific error message.
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

  // ─────────────────────────────────────────────
  // Get paginated list of users who reposted a track.
  // GET /api/public/engagement/tracks/v1/{trackId}/reposts
  // No authentication required.
  //
  // 200: { "total": 120, "offset": 1, "limit": 20,
  //        "users": [ { userId, displayName, avatarUrl, followersCount } ] }
  //
  // Returns (200, List<EngagementUser>) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Get paginated list of users who reposted a playlist.
  // GET /api/public/engagement/playlists/v1/{playlistId}/reposts
  // No authentication required.
  //
  // Same response shape as getTrackReposters.
  // Returns (200, List<EngagementUser>) on success.
  // ─────────────────────────────────────────────
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

  // ═════════════════════════════════════════════
  //  ██████╗ ██████╗ ███╗   ███╗███╗   ███╗███████╗███╗   ██╗████████╗███████╗
  // ██╔════╝██╔═══██╗████╗ ████║████╗ ████║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
  // ██║     ██║   ██║██╔████╔██║██╔████╔██║█████╗  ██╔██╗ ██║   ██║   ███████╗
  // ██║     ██║   ██║██║╚██╔╝██║██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
  // ╚██████╗╚██████╔╝██║ ╚═╝ ██║██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   ███████║
  //  ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
  // ═════════════════════════════════════════════

  // ─────────────────────────────────────────────
  // Get paginated top-level comments for a track.
  // GET /api/public/engagement/tracks/v1/{trackId}/comments
  // No authentication required.
  //
  // Query params:
  //   offset  → page number, 1-based (default 1)
  //   limit   → results per page (default 20, max 50)
  //   sortBy  → "newest" | "oldest" | "trackTime" (default "newest")
  //             "trackTime" sorts by timestamp position in the track.
  //             This maps to the filter icon (top-right) in CommentsScreen.
  //
  // 200: { "total": 50, "offset": 1, "limit": 20,
  //        "comments": [ { commentId, userId, displayName, avatarUrl,
  //                        content, timestamp, numLikes, replyCount,
  //                        isLikedByUser, isOwnComment, createdAt } ] }
  //
  // Returns (200, List<Comment>) on success.
  // ─────────────────────────────────────────────
  /// Returns the total comment count for a track, or 0 on failure.
  /// Calls the comments endpoint with limit=1 and reads the 'total' field.
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

  // ─────────────────────────────────────────────
  // Get paginated replies for a specific comment.
  // GET /api/public/engagement/comments/v1/{commentId}/replies
  // No authentication required.
  //
  // Ordered by createdAt ascending (oldest first — chronological thread).
  //
  // 200: { "total": 10, "offset": 1, "limit": 20,
  //        "replies": [ { same shape as comment } ] }
  //
  // Returns (200, List<Comment>) on success.
  // ─────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // Post a comment on a track.
  // POST /api/engagement/tracks/v1/{trackId}/comments
  //
  // Request body:
  // {
  //   "content":         "Great track!",   ← required
  //   "timestamp":       42.5,             ← required: current playback position
  //   "parentCommentId": "cmt_001"         ← optional: omit for top-level comments
  // }
  //
  // ⚠️  Returns 201 (not 200) on success.
  //
  // 201: full Comment object (same shape as GET comments list item)
  // 401: Authorization failed
  // 404: Track not found
  //
  // Returns (201, Comment) on success.
  // ─────────────────────────────────────────────
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

      // Only include parentCommentId when replying to another comment.
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

      // ⚠️ API returns 201 on successful comment creation, not 200.
      if (response.statusCode == 201) {
        return (201, Comment.fromJson(data));
      }
      return (response.statusCode, data["message"] ?? "Failed to post comment");
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  // ─────────────────────────────────────────────
  // Delete a comment.
  // DELETE /api/engagement/comments/v1/{commentId}
  //
  // Both the comment author AND the track owner can delete.
  // Deleting a parent comment also removes all its replies.
  //
  // 200: { "message": "Comment deleted successfully." }
  // 401: Authorization failed
  // 403: Not enough permissions (neither author nor track owner)
  // 404: Comment not found
  //
  // Returns (200, String message) on success.
  // ─────────────────────────────────────────────
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

      // 403 → surface the permissions error clearly in the UI.
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

  // ─────────────────────────────────────────────
  // Toggle like on a comment.
  // POST /api/engagement/comments/v1/{commentId}/like
  //
  // Likes the comment if not yet liked; unlikes if already liked.
  // Updates numLikes count atomically on the server.
  //
  // 200: { "liked": true, "numLikes": 7 }
  // 401: Authorization failed
  // 404: Comment not found
  //
  // Returns (200, {"liked": bool, "numLikes": int}) on success.
  // Used for optimistic updates in CommentTile:
  //   - on tap: flip Comment.isLikedByUser + adjust Comment.numLikes locally
  //   - on failure: revert both fields and show snackbar
  // ─────────────────────────────────────────────
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

  // GET /api/engagement/mentions/v1/followers
  // Returns follower suggestions for @mention in comments.
  // Response: [{ userId, displayName, avatarUrl, profileLink }]
  Future<(int, dynamic)> getMentionFollowers({
    int offset = 1,
    int limit = 20,
  }) async {
    try {
      // final headers = await _authHeaders();
      // if (headers == null) return (401, "Unauthorized");
      // final uri = Uri.parse("$_basePath/mentions/v1/followers")
      //     .replace(queryParameters: {
      //   'offset': '$offset',
      //   'limit': '$limit',
      // });
      // final response = await _client.get(uri, headers: headers);
      // final data = jsonDecode(response.body);
      // print(response.body);
      final accessToken = await FlutterSecureStorage().read(key: "access_token");
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

        // final users = data
        //     .map((e) => MentionUser(
        //           userId: (e['userId'] ?? '').toString(),
        //           displayName: (e['displayName'] ?? '').toString(),
        //           avatarUrl: e['avatarUrl']?.toString(),
        //         ))
        //     .where((u) => u.userId.isNotEmpty)
        //     .toList();





  
        // final users = (data as List<dynamic>)
        //     .whereType<Map<String, dynamic>>()
        //     .where((e) => (e['userId']?.toString().trim() ?? '').isNotEmpty)
        //     .map((e) => MentionUser(
        //           userId: e['userId']!.toString().trim(),
        //           displayName: (e['displayName']?.toString().trim() ?? ''),
        //           avatarUrl: e['avatarUrl']?.toString(),
        //         ))
        //     .toList();
        


    
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
      return (response.statusCode, data is Map ? data['message'] ?? 'Failed' : 'Failed');
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
