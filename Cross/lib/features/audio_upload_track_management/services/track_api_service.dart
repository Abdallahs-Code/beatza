// Service: TrackApiService
// All track-related API calls. No dependency on Module 5 or 6.
//
// Base paths:
//   Authenticated : /api/tracks/v1
//   Public        : /api/public/tracks/v1
//   Playback      : /api/playback/v1  (history — used by Module 5 later)
//
// Every method returns Future<(int statusCode, dynamic body)>.
// Token is read from FlutterSecureStorage key 'access_token'.
// User ID is read from FlutterSecureStorage key 'user_id'.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
//import 'package:flutter/foundation.dart';

class TrackApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  late final String _authBase;
  late final String _publicBase;
  late final String _playbackBase;

  TrackApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _apiServices = apiServices ?? ApiServices(),
       _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage() {
    _authBase = '${_apiServices.baseUrl}/api/tracks/v1';
    _publicBase = '${_apiServices.baseUrl}/api/public/tracks/v1';
    _playbackBase = '${_apiServices.baseUrl}/api/playback/v1';
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  // Future<String?> _getUserId() async {
  //   return await _storage.read(key: 'user_id');
  // }

  Map<String, String> _authHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'User-Agent': 'Android',
  };

  // ─────────────────────────────────────────────
  // Upload a new track
  // POST /api/tracks/v1
  // multipart/form-data
  //
  // Fields:
  //   audio    → required binary
  //   image    → optional binary
  //   basicInfo → stringified JSON:
  //     { title, permalink, mainArtists[], genre, tags[],
  //       description, isPrivate, caption }
  //
  // Returns 201 on success.
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> uploadTrack({
    required String audioFilePath,
    required String audioFileName,
    String? imageFilePath,
    required String title,
    required String permalink,
    required List<String> mainArtists,
    String genre = '',
    List<String> tags = const [],
    String description = '',
    bool isPrivate = false,
    String caption = '',
    Map<String, dynamic>? permissions,
    Map<String, dynamic>? license,
    Map<String, dynamic>? advanced,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final request = http.MultipartRequest('POST', Uri.parse(_authBase))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'User-Agent': 'Android',
          'Accept': 'application/json',
        });

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFilePath,
          filename: audioFileName,
        ),
      );

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFilePath),
        );
      }

      // Ensure at least one tag
      final List<String> processedTags = tags.isNotEmpty
          ? tags
          : (genre.isNotEmpty ? [genre] : ['uncategorized']);

      request.fields['basicInfo'] = jsonEncode({
        'title': title,
        'permalink': permalink,
        'mainArtists': mainArtists,
        'genre': genre,
        'tags': processedTags,
        'description': description,
        'isPrivate': isPrivate,
        'caption': caption,
      });

      request.fields['permissions'] = jsonEncode(
        permissions ??
            {
              'enableDirectDownload': true,
              'offlineListening': true,
              'includeInRssFeed': true,
              'displayedEmbedCode': true,
              'enableAppPlayback': true,
            },
      );

      request.fields['license'] = jsonEncode(
        license ??
            {
              'type': 'allRightsReserved',
              'attribution': false,
              'nonCommercial': false,
              'noDerivativeWorks': false,
              'shareAlike': false,
            },
      );

      // FIX: Handle ISRC - use provided or generate valid format
      // final String isrc =
      //     advanced?['ISRC']?.toString().trim().isNotEmpty == true
      //     ? advanced!['ISRC']
      //     : _generateValidISRC(); // Generate proper ISRC format

      request.fields['advanced'] = jsonEncode({
        // 'buyLink': advanced?['buyLink'] ?? '',
        // 'recordLabel': advanced?['recordLabel'] ?? '',
        // 'releaseDate': advanced?['releaseDate'] ?? '',
        // 'publisher': advanced?['publisher'] ?? '',
        // 'ISRC': advanced?['ISRC'] ?? '', // Use validated/generated ISRC
        // 'explicitContent': advanced?['explicitContent'] ?? false,
        // 'pLine': advanced?['pLine'] ?? '',
        // 'audioClipStart': advanced?['audioClipStart'] ?? 0,
        // 'audioClipEnd': advanced?['audioClipEnd'] ?? 0,
        // 'composer': advanced?['composer'] ?? '',
        // 'ISWC': advanced?['ISWC'] ?? '',
        // 'albumTitle': advanced?['albumTitle'] ?? '',
      });

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 201) {
        return (201, data['message'] ?? 'Track created successfully');
      } else if (response.statusCode == 400) {
        return (400, data['errors'] ?? data['message'] ?? 'Validation failed');
      }
      return (response.statusCode, data['message'] ?? 'Failed to upload track');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // Generate a valid ISRC in format: CC-XXX-YY-NNNNN
  // String _generateValidISRC() {
  //   final now = DateTime.now();
  //   final year = now.year.toString().substring(2); // Last 2 digits
  //   final unique = (DateTime.now().millisecondsSinceEpoch % 100000)
  //       .toString()
  //       .padLeft(5, '0');

  //   // Format: US-SCL-YY-NNNNN (valid ISRC structure)
  //   return 'US-SCL-$year-$unique';
  // }

  // Helper to generate a temporary ISRC
  // String _generateTemporaryISRC() {
  //   // Format: CC-XXX-YY-NNNNN
  //   // CC = Country Code (US for example)
  //   // XXX = Registrant Code (placeholder)
  //   // YY = Year (last 2 digits)
  //   // NNNNN = Unique number
  //   final now = DateTime.now();
  //   final year = now.year.toString().substring(2);
  //   final random = (DateTime.now().millisecondsSinceEpoch % 100000)
  //       .toString()
  //       .padLeft(5, '0');
  //   return 'US-SCL-$year-$random';
  // }

  // ─────────────────────────────────────────────
  // Update track metadata / cover image
  // PATCH /api/tracks/v1/
  // multipart/form-data, all fields optional
  // Must include `id` field.
  //
  // Returns 200 + updated Track on success.
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> updateTrack({
    required String trackId,
    String? imageFilePath,
    String? title,
    String? permalink,
    List<String>? mainArtists,
    String? genre,
    List<String>? tags,
    String? description,
    bool? isPrivate,
    String? caption,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final request = http.MultipartRequest('PATCH', Uri.parse(_authBase))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'User-Agent': 'Android',
        });

      request.fields['id'] = trackId;

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFilePath),
        );
      }

      final hasUpdate =
          title != null ||
          permalink != null ||
          mainArtists != null ||
          genre != null ||
          tags != null ||
          description != null ||
          isPrivate != null ||
          caption != null;

      if (hasUpdate) {
        request.fields['basicInfo'] = jsonEncode(
          {
            'title': title,
            'permalink': permalink,
            'mainArtists': mainArtists,
            'genre': genre,
            'tags': tags,
            'description': description,
            'isPrivate': isPrivate,
            'caption': caption,
          }..removeWhere((key, value) => value == null),
        );
      }

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final trackData = data['data'] as Map<String, dynamic>?;
        if (trackData != null) {
          return (200, Track.fromNestedJson(trackData));
        }
        return (200, data['message'] ?? 'Track updated');
      }
      return (response.statusCode, data['message'] ?? 'Failed to update track');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Delete a track
  // DELETE /api/tracks/v1/{id}
  //
  // 200: { message: "Track Deleted Sucessfully" }
  // 403: not owner
  // 404: not found
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> deleteTrack({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.delete(
        Uri.parse('$_authBase/$trackId'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, data['message'] ?? 'Track deleted');
      }
      return (response.statusCode, data['message'] ?? 'Failed to delete track');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Get all tracks paginated (your own tracks list)
  // GET /api/public/tracks/v1/?page=1&limit=20
  //
  // Returns (200, { tracks: List<Track>, hasNext: bool, page: int })
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getAllTracksPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final uri = Uri.parse('$_publicBase/').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tracks = Track.listFromPaginatedResponse(data);
        final paginationInfo =
            (data['data'] as Map<String, dynamic>?)?['paginationInfo']
                as Map<String, dynamic>?;

        final hasNext = paginationInfo?['hasNext'] as bool? ?? false;
        final currentPage = paginationInfo?['page'] as int? ?? page;
        final totalPages = paginationInfo?['totalPages'] as int? ?? 1;

        return (
          200,
          {
            'tracks': tracks,
            'hasNext': hasNext,
            'page': currentPage,
            'totalPages': totalPages,
          },
        );
      }
      return (response.statusCode, data['message'] ?? 'Failed to fetch tracks');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Get a single track by ID (full nested shape with audioLink)
  // GET /api/public/tracks/v1/{id}
  //
  // Returns (200, Track)
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getTrackById({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      final headers = token != null
          ? _authHeaders(token)
          : {'Content-Type': 'application/json', 'User-Agent': 'Android'};

      final response = await _client.get(
        Uri.parse('$_publicBase/$trackId'),
        headers: headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final trackData = data['data'] as Map<String, dynamic>?;
        if (trackData != null) {
          return (200, Track.fromNestedJson(trackData));
        }
        return (404, 'Track not found');
      }
      return (response.statusCode, data['message'] ?? 'Failed to fetch track');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Get tracks posted by a user (public — no audioLink)
  // GET /api/public/tracks/v1/posted/{userId}
  //
  // Returns (200, List<Track>)
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getUserPostedTracks({required String userId}) async {
    if (userId.trim().isEmpty) return (400, 'Invalid user ID');
    try {
      final response = await _client.get(
        Uri.parse('$_publicBase/posted/$userId'),
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, Track.listFromUserTracksResponse(data));
      }
      return (
        response.statusCode,
        data['message'] ?? 'Failed to fetch user tracks',
      );
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Get tracks liked by a user (public — no audioLink)
  // GET /api/public/tracks/v1/liked/{userId}
  //
  // Returns (200, List<Track>)
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getUserLikedTracks({required String userId}) async {
    if (userId.trim().isEmpty) return (400, 'Invalid user ID');
    try {
      final response = await _client.get(
        Uri.parse('$_publicBase/liked/$userId'),
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, Track.listFromUserTracksResponse(data));
      }
      return (
        response.statusCode,
        data['message'] ?? 'Failed to fetch liked tracks',
      );
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Increment play count — fire-and-forget
  // PATCH /api/tracks/v1/listen/{id}
  // Called by Module 5 PlayerController on play start.
  // Included here so Module 5 can import this service.
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> incrementPlayCount({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.patch(
        Uri.parse('$_authBase/listen/$trackId'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, data['message'] ?? 'Play count updated');
      }
      return (
        response.statusCode,
        data['message'] ?? 'Failed to increment play count',
      );
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Add track to listening history — fire-and-forget
  // POST /api/tracks/v1/played/{id}
  // Called by Module 5 PlayerController on play start.
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> addToHistory({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.post(
        Uri.parse('$_authBase/played/$trackId'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, data['message'] ?? 'Track added to history');
      }
      return (
        response.statusCode,
        data['message'] ?? 'Failed to add to history',
      );
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Get listening history (used by Module 5 HistoryScreen)
  // GET /api/playback/v1/history/tracks
  //
  // Returns (200, List<Track>) — full nested shape WITH audioLink
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getListeningHistory() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.get(
        Uri.parse('$_playbackBase/history/tracks'),
        headers: _authHeaders(token),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, Track.listFromHistoryResponse(data));
      }
      return (
        response.statusCode,
        data['message'] ?? 'Failed to fetch history',
      );
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Get user feed (used by Module 8 / Home screen later)
  // GET /api/feed?offset=0&limit=20
  //
  // Returns (200, List<Track>) — flat shape, NO audioLink
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getUserFeed({int offset = 0, int limit = 20}) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final uri = Uri.parse('${_apiServices.baseUrl}/api/feed').replace(
        queryParameters: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, Track.listFromFeedResponse(data));
      }
      return (response.statusCode, data['message'] ?? 'Failed to fetch feed');
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }

  // ─────────────────────────────────────────────
  // Get trending tracks (used by Module 8 / Home screen later)
  // GET /api/trending?offset=0&limit=20
  //
  // Returns (200, List<Track>) — flat shape, NO audioLink
  // ─────────────────────────────────────────────
  Future<(int, dynamic)> getTrendingTracks({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final uri = Uri.parse('${_apiServices.baseUrl}/api/trending').replace(
        queryParameters: {
          'offset': offset.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _client.get(uri, headers: _authHeaders(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (200, Track.listFromFeedResponse(data));
      }
      return (
        response.statusCode,
        data['message'] ?? 'Failed to fetch trending',
      );
    } catch (err) {
      return (500, 'Network error: $err');
    }
  }
}
