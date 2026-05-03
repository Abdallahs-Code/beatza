import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

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
  }) : _apiServices = apiServices ?? ApiServices(),
       _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage() {
    _authBase = '${_apiServices.baseUrl}/api/playlists/v1';
    _publicBase = '${_apiServices.baseUrl}/api/public/playlists/v1';
  }

  Future<String?> _getToken() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  // GET /api/playlists/v1/{playlistId}
  Future<(int, PlaylistModel?)> getPlaylistWithTracks({
    required String playlistId,
    int? limit,
    int? offset,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);
      final params = <String, String>{};
      if (limit != null) params['limit'] = limit.toString();
      if (offset != null) params['offset'] = offset.toString();
      final uri = params.isEmpty
          ? Uri.parse('$_authBase/$playlistId')
          : Uri.parse('$_authBase/$playlistId').replace(queryParameters: params);
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.singleFromResponse(data));
      }
      return (response.statusCode, null);
    } catch (e) {
      return (500, null);
    }
  }

  // GET /api/public/playlists/v1/{playlistId}
  Future<(int, PlaylistModel?)> getPublicPlaylistWithTracks({
    required String playlistId,
  }) async {
    try {
      final uri = Uri.parse('$_publicBase/$playlistId');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.singleFromResponse(data));
      }
      return (response.statusCode, null);
    } catch (e) {
      return (500, null);
    }
  }

  // GET /api/playlists/v1/my-playlists
  Future<(int, List<PlaylistModel>)> getMyPlaylists() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);
      final uri = Uri.parse('$_authBase/my-playlists');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/playlists/v1?limit=&offset=
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsAuth() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);
      final uri = Uri.parse(_authBase);
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1?limit=&offset=
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsGuest() async {
    try {
      final uri = Uri.parse(_publicBase);
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/playlists/v1/playlists/{artistId}
  Future<(int, List<PlaylistModel>)> getArtistPlaylistsAuth({
    required String artistId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);
      final uri = Uri.parse('$_authBase/playlists/$artistId');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/playlists/{artistId}
  Future<(int, List<PlaylistModel>)> getArtistPlaylistsGuest({
    required String artistId,
  }) async {
    try {
      final uri = Uri.parse('$_publicBase/playlists/$artistId');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/playlists/v1/creator/{creatorId}  (authenticated)
  Future<(int, Map<String, dynamic>?)> getArtistInfo({
    required String creatorId,
    bool authenticated = true,
  }) async {
    try {
      final String base;
      final Map<String, String> headers;
      if (authenticated) {
        final token = await _getToken();
        if (token == null) return (401, null);
        base = _authBase;
        headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        };
      } else {
        base = _publicBase;
        headers = {'Content-Type': 'application/json', 'User-Agent': 'Android'};
      }
      final uri = Uri.parse('$base/creator/$creatorId');
      final response = await _client.get(uri, headers: headers);
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, data['data'] as Map<String, dynamic>?);
      }
      return (response.statusCode, null);
    } catch (e) {
      return (500, null);
    }
  }

  // GET /api/playlists/v1/{playlistId}/recommend/{artistId}
  Future<(int, List<PlaylistModel>)> getMorePlaylistsFromArtistAuth({
    required String playlistId,
    required String artistId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);
      final uri = Uri.parse('$_authBase/$playlistId/recommend/$artistId');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/{playlistId}/recommend/{artistId}
  Future<(int, List<PlaylistModel>)> getMorePlaylistsFromArtistGuest({
    required String playlistId,
    required String artistId,
  }) async {
    try {
      final uri = Uri.parse('$_publicBase/$playlistId/recommend/$artistId');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/creator/{artistId}/albums
  Future<(int, List<PlaylistModel>)> getArtistAlbums({
    required String artistId,
  }) async {
    try {
      final uri = Uri.parse('$_publicBase/creator/$artistId/albums');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/permalink/{permalink}
  Future<(int, List<PlaylistModel>)> getPlaylistByPermalink({
    required String permalink,
  }) async {
    try {
      final uri = Uri.parse('$_publicBase/permalink/$permalink');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e) {
      return (500, <PlaylistModel>[]);
    }
  }

  // POST /api/v1/playlists/{playlistId}/history
  Future<(int, String)> addPlaylistToHistory({required String playlistId}) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');
      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/v1/playlists/$playlistId/history',
      );
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint('POST $uri -> ${response.statusCode}');
      final data = jsonDecode(response.body);
      return (response.statusCode, data['message']?.toString() ?? '');
    } catch (e) {
      return (500, 'Network error: $e');
    }
  }

  // GET /api/tracks/v2/ — paginated public tracks (raw JSON for track-picker screens)
  Future<(int, Map<String, dynamic>)> getPublicTracksPaginated({
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <String, dynamic>{});
      final uri = Uri.parse(
        '${_apiServices.baseUrl}/api/tracks/v2/',
      ).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint('GET $uri -> ${response.statusCode}');
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>? ?? {};
        return (200, data);
      }
      return (response.statusCode, <String, dynamic>{});
    } catch (e) {
      return (500, <String, dynamic>{});
    }
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  // POST /api/playlists/v1  (JSON — no image; used for copy-playlist feature)
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
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
        body: jsonEncode({
          'playlistName': playlistName,
          if (tracks.isNotEmpty) 'tracks': tracks,
          'isPrivate': isPrivate,
        }),
      );
      debugPrint('POST $_authBase -> ${response.statusCode} | ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistsRaw = data['data']?['playlists'] as List<dynamic>?;
        if (playlistsRaw != null && playlistsRaw.isNotEmpty) {
          return (
            response.statusCode,
            PlaylistModel.fromJson(playlistsRaw.first as Map<String, dynamic>),
          );
        }
        final single = data['data']?['playlist'] as Map<String, dynamic>?;
        if (single != null) {
          return (response.statusCode, PlaylistModel.fromJson(single));
        }
        return (response.statusCode, null);
      }
      return (response.statusCode, null);
    } catch (e) {
      debugPrint('createPlaylist error: $e');
      return (500, null);
    }
  }

  // POST /api/playlists/v1/with-image
  // Multipart payload mirrors the front-end: a single "data" field holding a
  // JSON-stringified body, plus the "image" file.
  // NOTE: the server requires listOfTracks to contain >= 1 item.
  Future<(int, PlaylistModel?)> createPlaylistWithImage({
    required String title,
    String description = '',
    bool isPrivate = false,
    List<String> listOfTracks = const [],
    String? buyLink,
    String? recordLabel,
    required String imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint('[createPlaylistWithImage] No token – returning 401');
        return (401, null);
      }

      final url = '$_authBase/with-image';

      final dataPayload = jsonEncode({
        'title': title,
        'description': description,
        'isPrivate': isPrivate,
        'listOfTracks': listOfTracks,
        'buyLink': ?buyLink,
        'recordLabel': ?recordLabel,
      });

      debugPrint('[createPlaylistWithImage] POST $url');
      debugPrint('[createPlaylistWithImage] data field: $dataPayload');
      debugPrint('[createPlaylistWithImage] imagePath: $imagePath');

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'User-Agent': 'Android',
        });

      request.fields['data'] = dataPayload;
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      debugPrint('[createPlaylistWithImage] fields: ${request.fields}');
      debugPrint('[createPlaylistWithImage] files: ${request.files.map((f) => '${f.field}=${f.filename}').toList()}');

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      debugPrint('[createPlaylistWithImage] response status: ${response.statusCode}');
      debugPrint('[createPlaylistWithImage] response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistsRaw = data['data']?['playlists'] as List<dynamic>?;
        debugPrint('[createPlaylistWithImage] playlists array: $playlistsRaw');
        if (playlistsRaw != null && playlistsRaw.isNotEmpty) {
          return (
            response.statusCode,
            PlaylistModel.fromJson(playlistsRaw.first as Map<String, dynamic>),
          );
        }
        final single = data['data']?['playlist'] as Map<String, dynamic>?;
        debugPrint('[createPlaylistWithImage] single playlist: $single');
        if (single != null) {
          return (response.statusCode, PlaylistModel.fromJson(single));
        }
        debugPrint('[createPlaylistWithImage] WARNING: 2xx but no playlist found in response');
        return (response.statusCode, null);
      }

      // Log server validation errors clearly
      try {
        final errBody = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[createPlaylistWithImage] ERROR message: ${errBody['message']}');
        final errors = errBody['errors'] as List<dynamic>?;
        if (errors != null) {
          for (final e in errors) {
            debugPrint('[createPlaylistWithImage]   field=${e['field']}  msg=${e['message']}');
          }
        }
      } catch (_) {}

      return (response.statusCode, null);
    } catch (e, st) {
      debugPrint('[createPlaylistWithImage] EXCEPTION: $e');
      debugPrint('[createPlaylistWithImage] STACKTRACE: $st');
      return (500, null);
    }
  }

  // ── Update ──────────────────────────────────────────────────────────────────

  // PUT /api/playlists/v1/{playlistId}  (multipart)
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
    bool? isPrivate,
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

      final request =
          http.MultipartRequest('PUT', Uri.parse('$_authBase/$playlistId'))
            ..headers.addAll({
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
      if (isPrivate != null) request.fields['isPrivate'] = isPrivate.toString();
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
        request.fields['lengthOfRecievedTracks'] = '$lengthOfReceivedTracks';
      }
      if (licensing != null) {
        request.fields['licensing'] = jsonEncode(licensing);
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      debugPrint('PUT $_authBase/$playlistId -> ${response.statusCode}');

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data['message']?.toString() ?? 'Update failed',
      );
    } catch (e) {
      return (500, 'Network error: $e');
    }
  }

  // PATCH /api/playlists/v1/{playlistId}/image
  Future<(int, PlaylistModel?)> updatePlaylistImage({
    required String playlistId,
    required String imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final request =
          http.MultipartRequest(
              'PATCH',
              Uri.parse('$_authBase/$playlistId/image'),
            )
            ..headers.addAll({
              'Authorization': 'Bearer $token',
              'User-Agent': 'Android',
            });

      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      debugPrint(
        'PATCH $_authBase/$playlistId/image -> ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistJson = data['data']?['playlist'] as Map<String, dynamic>?;
        return (
          200,
          playlistJson != null ? PlaylistModel.fromJson(playlistJson) : null,
        );
      }
      return (response.statusCode, null);
    } catch (e) {
      return (500, null);
    }
  }

  // ── Tracks ──────────────────────────────────────────────────────────────────

  // PATCH /api/playlists/v1/{playlistId}/tracks  (reorder)
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
        Uri.parse('$_authBase/$playlistId/tracks'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
        body: jsonEncode({
          'trackId': trackId,
          'oldPosition': oldPosition,
          'newPosition': newPosition,
        }),
      );

      debugPrint(
        'PATCH $_authBase/$playlistId/tracks -> ${response.statusCode}',
      );

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data['message']?.toString() ?? 'Failed to reorder track',
      );
    } catch (e) {
      return (500, 'Network error: $e');
    }
  }

  // PATCH /api/playlists/v1/{playlistId}/tracks/{trackId}  (add track)
  Future<(int, String)> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.patch(
        Uri.parse('$_authBase/$playlistId/tracks/$trackId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );

      debugPrint(
        'PATCH $_authBase/$playlistId/tracks/$trackId -> ${response.statusCode}',
      );

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data['message']?.toString() ?? 'Failed to add track',
      );
    } catch (e) {
      return (500, 'Network error: $e');
    }
  }

  // DELETE /api/playlists/v1/{playlistId}/tracks/{trackId}
  Future<(int, String)> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.delete(
        Uri.parse('$_authBase/$playlistId/tracks/$trackId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );

      debugPrint(
        'DELETE $_authBase/$playlistId/tracks/$trackId -> ${response.statusCode}',
      );

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data['message']?.toString() ?? 'Failed to remove track',
      );
    } catch (e) {
      return (500, 'Network error: $e');
    }
  }

  // ── Delete ──────────────────────────────────────────────────────────────────

  // DELETE /api/playlists/v1/{playlistId}
  Future<(int, bool)> deletePlaylist({required String playlistId}) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, false);

      final response = await _client.delete(
        Uri.parse('$_authBase/$playlistId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );

      debugPrint('DELETE $_authBase/$playlistId -> ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final deleted = data['data']?['deleted'] as bool? ?? true;
        return (200, deleted);
      }
      return (response.statusCode, false);
    } catch (e) {
      return (500, false);
    }
  }
}
