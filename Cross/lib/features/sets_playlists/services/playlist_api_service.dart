import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';
import 'package:flutter/foundation.dart';

/// PlaylistApiService
/// Handles all playlist-related API calls for Module 7.
/// Follows the exact same pattern as TrackApiService and SocialApiService.
///
/// Base paths:
///   Authenticated: /api/playlists/v1
///   Public:        /api/public/playlists/v1
class PlaylistApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;

  late final String _authBase;
  late final String _publicBase;

  PlaylistApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage() {
    _authBase = '${_apiServices.baseUrl}/api/playlists/v1';
    _publicBase = '${_apiServices.baseUrl}/api/public/playlists/v1';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
      };

  Map<String, String> get _publicHeaders => {
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
      };

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
    return raw.isNotEmpty ? raw : fallbackMessage;
  }

  void dispose() {
    _client.close();
  }

  // ── API #2 — GET playlist with tracks (auth) ──────────────────────────────
  // GET /api/playlists/v1/:playlistId?limit=&offset=
  // Auth required. Returns playlist with paginated tracks.
  Future<(int, PlaylistModel?)> getPlaylistWithTracks({
    required String playlistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final uri = Uri.parse('$_authBase/$playlistId').replace(
        queryParameters: {
          'limit': '$limit',
          'offset': '$offset',
        },
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, null);
        final playlist = PlaylistModel.singleFromResponse(decoded);
        return (200, playlist);
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  // ── API #3 — PUT update playlist metadata ─────────────────────────────────
  // PUT /api/playlists/v1/:playlistId
  // multipart/form-data. Auth required. Owner only.
  Future<(int, String)> updatePlaylist({
    required String playlistId,
    String? title,
    String? permalink,
    List<String>? additionalTags,
    String? type,
    String? playlistType,
    String? releaseDate,
    String? genre,
    List<String>? tags,
    String? description,
    String? privacy,
    List<String>? audioTracks,
    int? lengthOfReceivedTracks,
    Map<String, dynamic>? licensing,
    String? buyLink,
    String? recordLabel,
    String? imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_authBase/$playlistId'),
      )..headers.addAll({
          'Authorization': 'Bearer $token',
          'User-Agent': 'Android',
        });

      void addField(String key, String? value) {
        if (value != null) request.fields[key] = value;
      }

      addField('title', title);
      addField('permalink', permalink);
      addField('type', type);
      addField('playlistType', playlistType);
      addField('releaseDate', releaseDate);
      addField('genre', genre);
      addField('description', description);
      addField('Privacy', privacy);
      addField('buyLink', buyLink);
      addField('recordLabel', recordLabel);

      if (additionalTags != null) {
        for (final tag in additionalTags) {
          request.fields['additionalTags'] = tag;
        }
      }
      if (tags != null) {
        for (final tag in tags) {
          request.fields['tags'] = tag;
        }
      }
      if (audioTracks != null) {
        request.fields['audioTracks'] = jsonEncode(audioTracks);
      }
      if (lengthOfReceivedTracks != null) {
        request.fields['lengthOfRecievedTracks'] =
            '$lengthOfReceivedTracks';
      }
      if (licensing != null) {
        request.fields['licensing'] = jsonEncode(licensing);
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      return (
        response.statusCode,
        _extractMessage(response, fallbackMessage: 'Update failed'),
      );
    } catch (_) {
      return (500, 'Internal server error');
    }
  }

  // ── API #4 — GET public playlists (auth, excludes blocked) ────────────────
  // GET /api/playlists/v1?limit=&offset=
  // Auth required. Hides playlists of blocked users.
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsAuth({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse(_authBase).replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #5 — GET public playlists (no auth) ───────────────────────────────
  // GET /api/public/playlists/v1?limit=&offset=
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsGuest({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse(_publicBase).replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _publicHeaders);

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #6 — GET public playlists of a specific artist (auth) ─────────────
  // GET /api/playlists/v1/:playlistId/artist/:artistId?limit=&offset=
  Future<(int, List<PlaylistModel>)> getArtistPlaylistsAuth({
    required String playlistId,
    required String artistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri =
          Uri.parse('$_authBase/$playlistId/artist/$artistId').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #7 — GET public playlists of a specific artist (no auth) ──────────
  // GET /api/public/playlists/v1/:playlistId/artist/:artistId?limit=&offset=
  Future<(int, List<PlaylistModel>)> getArtistPlaylistsGuest({
    required String playlistId,
    required String artistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri =
          Uri.parse('$_publicBase/$playlistId/artist/$artistId').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _publicHeaders);

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #8 — GET playlist with tracks (no auth) ───────────────────────────
  // GET /api/public/playlists/v1/:playlistId?limit=&offset=
  Future<(int, PlaylistModel?)> getPublicPlaylistWithTracks({
    required String playlistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$_publicBase/$playlistId').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _publicHeaders);

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, null);
        return (200, PlaylistModel.singleFromResponse(decoded));
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  // ── API #9/10 — GET artist info for a playlist (auth / no-auth) ──────────
  // GET /api/playlists/v1/:playlistId/artist-info/:artistId
  // GET /api/public/playlists/v1/:playlistId/artist-info/:artistId
  Future<(int, Map<String, dynamic>?)> getArtistInfo({
    required String playlistId,
    required String artistId,
    bool authenticated = true,
  }) async {
    try {
      final String baseUrl;
      final Map<String, String> headers;

      if (authenticated) {
        final token = await _getToken();
        if (token == null) return (401, null);
        baseUrl = _authBase;
        headers = _authHeaders(token);
      } else {
        baseUrl = _publicBase;
        headers = _publicHeaders;
      }

      final uri =
          Uri.parse('$baseUrl/$playlistId/artist-info/$artistId');
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        final data = decoded?['data'] as Map<String, dynamic>?;
        return (200, data);
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  // ── API #11 — GET more playlists from the same artist (auth) ─────────────
  // GET /api/playlists/v1/:playlistId/more/:artistId?limit=&offset=
  Future<(int, List<PlaylistModel>)> getMorePlaylistsFromArtistAuth({
    required String playlistId,
    required String artistId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri =
          Uri.parse('$_authBase/$playlistId/more/$artistId').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #12 — GET more playlists from the same artist (no auth) ──────────
  // GET /api/public/playlists/v1/:playlistId/more/:artistId?limit=&offset=
  Future<(int, List<PlaylistModel>)> getMorePlaylistsFromArtistGuest({
    required String playlistId,
    required String artistId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final uri =
          Uri.parse('$_publicBase/$playlistId/more/$artistId').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _publicHeaders);

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #13 — GET albums from an artist ───────────────────────────────────
  // GET /api/playlists/v1/albums/:artistId?limit=&offset=
  Future<(int, List<PlaylistModel>)> getArtistAlbums({
    required String artistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse('$_authBase/albums/$artistId').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #14 — GET playlist by permalink ──────────────────────────────────
  // GET /api/playlists/v1/permalink/:permalink?limit=&offset=
  Future<(int, List<PlaylistModel>)> getPlaylistByPermalink({
    required String permalink,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri =
          Uri.parse('$_authBase/permalink/$permalink').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #15 — GET current user's playlists ────────────────────────────────
  // GET /api/playlists/v1/mine?limit=&offset=
  // Auth required.
  Future<(int, List<PlaylistModel>)> getMyPlaylists({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      debugPrint("token is $token");
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse('$_authBase/my-playlists').replace(
        queryParameters: {'limit': '$limit', 'offset': '$offset'},
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        debugPrint("response is $response");
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, <PlaylistModel>[]);
        return (200, PlaylistModel.listFromResponse(decoded));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  // ── API #16 — PATCH update playlist image ─────────────────────────────────
  // PATCH /api/playlists/v1/:playlistId/image
  // multipart/form-data. Auth required.
  Future<(int, PlaylistModel?)> updatePlaylistImage({
    required String playlistId,
    required String imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$_authBase/$playlistId/image'),
      )..headers.addAll({
          'Authorization': 'Bearer $token',
          'User-Agent': 'Android',
        });

      request.files
          .add(await http.MultipartFile.fromPath('image', imagePath));

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, null);
        final data = decoded['data'] as Map<String, dynamic>?;
        final playlistJson = data?['playlist'] as Map<String, dynamic>?;
        final playlist =
            playlistJson != null ? PlaylistModel.fromJson(playlistJson) : null;
        return (200, playlist);
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  // ── API #17 — PATCH reorder tracks ───────────────────────────────────────
  // PATCH /api/playlists/v1/:playlistId/reorder
  // Body: { trackId, oldPosition, newPosition }
  // Auth required. Owner only.
  Future<(int, String)> reorderTrack({
    required String playlistId,
    required String trackId,
    required int oldPosition,
    required int newPosition,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.patch(
        Uri.parse('$_authBase/$playlistId/reorder'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'trackId': trackId,
          'oldPosition': oldPosition,
          'newPosition': newPosition,
        }),
      );

      return (
        response.statusCode,
        _extractMessage(response,
            fallbackMessage: 'Failed to reorder track'),
      );
    } catch (_) {
      return (500, 'Internal server error');
    }
  }

  // ── API #18 — POST add track to playlist ──────────────────────────────────
  // POST /api/playlists/v1/:playlistId/tracks/:trackId
  // Auth required. Owner only.
  Future<(int, String)> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.post(
        Uri.parse('$_authBase/$playlistId/tracks/$trackId'),
        headers: _authHeaders(token),
      );

      return (
        response.statusCode,
        _extractMessage(response,
            fallbackMessage: 'Failed to add track'),
      );
    } catch (_) {
      return (500, 'Internal server error');
    }
  }

  // ── API #19 — POST create playlist ───────────────────────────────────────
  // POST /api/playlists/v1
  // Body: { playlistName, tracks[], isPrivate }
  // Auth required. Free users: max 2 playlists.
  Future<(int, PlaylistModel?)> createPlaylist({
    required String playlistName,
    List<String> tracks = const [],
    bool isPrivate = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final response = await _client.post(
        Uri.parse(_authBase),
        headers: _authHeaders(token),
        body: jsonEncode({
          'playlistName': playlistName,
          'tracks': tracks,
          'isPrivate': isPrivate,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = _tryDecodeJson(response.body) as Map<String, dynamic>?;
        if (decoded == null) return (200, null);

        final data = decoded['data'] as Map<String, dynamic>?;
        final playlistsRaw = data?['playlists'] as List<dynamic>?;
        if (playlistsRaw != null && playlistsRaw.isNotEmpty) {
          return (
            response.statusCode,
            PlaylistModel.fromJson(
                playlistsRaw.first as Map<String, dynamic>),
          );
        }
        return (response.statusCode, null);
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  // ── DELETE remove track from playlist ────────────────────────────────────
  // DELETE /api/playlists/v1/:playlistId/tracks/:trackId
  // Auth required. Owner only.
  Future<(int, String)> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.delete(
        Uri.parse('$_authBase/$playlistId/tracks/$trackId'),
        headers: _authHeaders(token),
      );

      return (
        response.statusCode,
        _extractMessage(response,
            fallbackMessage: 'Failed to remove track'),
      );
    } catch (_) {
      return (500, 'Internal server error');
    }
  }

  // ── API #1 — DELETE playlist ──────────────────────────────────────────────
  // DELETE /api/playlists/v1/:playlistId
  // Auth required. Owner only.
  //
  // Success 200: { "message": "Deleted successfully", "data": { "deleted": true } }
  // 400: validation error
  // 401: not authenticated
  // 403: not owner / not enough permissions
  // 404: playlist not found
  // 500: server error
  //
  // Returns (statusCode, wasDeleted).
  // wasDeleted is true only when statusCode==200 AND data.deleted==true.
  Future<(int, bool)> deletePlaylist({required String playlistId}) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, false);

      final response = await _client.delete(
        Uri.parse('$_authBase/$playlistId'),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final decoded =
            _tryDecodeJson(response.body) as Map<String, dynamic>?;
        final data = decoded?['data'] as Map<String, dynamic>?;
        final deleted = data?['deleted'] as bool? ?? false;
        return (200, deleted);
      }

      return (response.statusCode, false);
    } catch (_) {
      return (500, false);
    }
  }
}
