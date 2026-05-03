import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

/// `GET .../playlists/v1?limit=&offset=` — server validates `limit` in 1..20.
const int _kPlaylistCatalogLimitMax = 20;

int _clampPlaylistCatalogLimit(int value) {
  if (value < 1) return 1;
  if (value > _kPlaylistCatalogLimitMax) return _kPlaylistCatalogLimitMax;
  return value;
}

/// Backend requires `permalink` length >= 1 whenever it is included in the update body.
String _slugifyPlaylistPermalink(String raw) {
  var s = raw.toLowerCase().trim();
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'-{2,}'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  return s.isEmpty ? 'playlist' : s;
}

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
      debugPrint('[getPlaylistWithTracks] body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.singleFromResponse(data));
      }
      return (response.statusCode, null);
    } catch (e, st) {
      debugPrint('[getPlaylistWithTracks] EXCEPTION: $e\n$st');
      return (500, null);
    }
  }

  // GET /api/public/playlists/v1/{playlistId}
  // Optional [secretToken] — grants access to secret playlists via share link.
  Future<(int, PlaylistModel?)> getPublicPlaylistWithTracks({
    required String playlistId,
    String? secretToken,
  }) async {
    try {
      var uri = Uri.parse('$_publicBase/$playlistId');
      final st = secretToken?.trim();
      if (st != null && st.isNotEmpty) {
        uri = uri.replace(
          queryParameters: {...uri.queryParameters, 'secretToken': st},
        );
      }
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
  /// Paginated catalog of playlists (across users), auth context.
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsAuth({
    int? limit,
    int? offset,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);
      var uri = Uri.parse(_authBase);
      final params = <String, String>{};
      if (limit != null) {
        final safe = _clampPlaylistCatalogLimit(limit);
        if (safe != limit) {
          debugPrint(
            '[PlaylistApi catalog auth] clamped limit $limit → $safe '
            '(API max=$_kPlaylistCatalogLimitMax)',
          );
        }
        params['limit'] = safe.toString();
      }
      if (offset != null) params['offset'] = offset.toString();
      if (params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      );
      debugPrint(
        '[PlaylistApi catalog auth] GET $uri → ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = PlaylistModel.listFromResponse(data);
        debugPrint(
          '[PlaylistApi catalog auth] parsed playlists length=${parsed.length}',
        );
        return (200, parsed);
      }
      debugPrint(
        '[PlaylistApi catalog auth] body (truncated): '
        '${response.body.length > 600 ? '${response.body.substring(0, 600)}…' : response.body}',
      );
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e, st) {
      debugPrint('[PlaylistApi catalog auth] EXCEPTION: $e\n$st');
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1?limit=&offset=
  /// Paginated catalog of public playlists (across users), no auth.
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsGuest({
    int? limit,
    int? offset,
  }) async {
    try {
      var uri = Uri.parse(_publicBase);
      final params = <String, String>{};
      if (limit != null) {
        final safe = _clampPlaylistCatalogLimit(limit);
        if (safe != limit) {
          debugPrint(
            '[PlaylistApi catalog guest] clamped limit $limit → $safe '
            '(API max=$_kPlaylistCatalogLimitMax)',
          );
        }
        params['limit'] = safe.toString();
      }
      if (offset != null) params['offset'] = offset.toString();
      if (params.isNotEmpty) {
        uri = uri.replace(queryParameters: params);
      }
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
      );
      debugPrint(
        '[PlaylistApi catalog guest] GET $uri → ${response.statusCode}',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final parsed = PlaylistModel.listFromResponse(data);
        debugPrint(
          '[PlaylistApi catalog guest] parsed playlists length=${parsed.length}',
        );
        return (200, parsed);
      }
      debugPrint(
        '[PlaylistApi catalog guest] body (truncated): '
        '${response.body.length > 600 ? '${response.body.substring(0, 600)}…' : response.body}',
      );
      return (response.statusCode, <PlaylistModel>[]);
    } catch (e, st) {
      debugPrint('[PlaylistApi catalog guest] EXCEPTION: $e\n$st');
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
    String? secretToken,
  }) async {
    try {
      var uri = Uri.parse('$_publicBase/permalink/$permalink');
      final st = secretToken?.trim();
      if (st != null && st.isNotEmpty) {
        uri = uri.replace(
          queryParameters: {...uri.queryParameters, 'secretToken': st},
        );
      }
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

  // POST /api/playlists/v1/with-image (same as web: multipart `data` JSON +
  // optional `image` file — see playlists.service createPlaylistWithImage).
  Future<(int, PlaylistModel?)> createPlaylistWithImage({
    required String title,
    String description = '',
    bool isPrivate = false,
    List<String> listOfTracks = const [],
    String? buyLink,
    String? recordLabel,
    String? imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        debugPrint('[createPlaylistWithImage] No token – returning 401');
        return (401, null);
      }

      final url = '$_authBase/with-image';

      final payloadMap = <String, dynamic>{
        'title': title,
        'description': description,
        'isPrivate': isPrivate,
        'listOfTracks': listOfTracks,
      };
      if (buyLink != null && buyLink.isNotEmpty) {
        payloadMap['buyLink'] = buyLink;
      }
      if (recordLabel != null && recordLabel.isNotEmpty) {
        payloadMap['recordLabel'] = recordLabel;
      }
      final dataPayload = jsonEncode(payloadMap);

      debugPrint('[createPlaylistWithImage] POST $url');
      debugPrint('[createPlaylistWithImage] data field: $dataPayload');
      debugPrint('[createPlaylistWithImage] imagePath: $imagePath');

      final request = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'User-Agent': 'Android',
        });

      request.fields['data'] = dataPayload;

      final img = imagePath?.trim();
      if (img != null && img.isNotEmpty) {
        final file = File(img);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('image', file.path));
        } else {
          debugPrint('[createPlaylistWithImage] image path missing on disk: $img');
        }
      }

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
  // Mirrors the frontend: all metadata is JSON-stringified under a single
  // "data" field; image (if any) is a separate "image" file field.
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
    bool? isPrivate,
    List<String>? listOfTracks,
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

      final jsonPayload = <String, dynamic>{};
      if (title != null)            jsonPayload['title']            = title;
      final permalinkTrimmed = permalink?.trim();
      if (permalinkTrimmed != null && permalinkTrimmed.isNotEmpty) {
        jsonPayload['permalink'] = permalinkTrimmed;
      } else if (title != null && title.trim().isNotEmpty) {
        jsonPayload['permalink'] =
            _slugifyPlaylistPermalink(title.trim());
      }
      if (type != null)             jsonPayload['type']             = type;
      if (playlistType != null)     jsonPayload['playlistType']     = playlistType;
      if (releaseDate != null)      jsonPayload['releaseDate']      = releaseDate;
      if (genre != null)            jsonPayload['genre']            = genre;
      if (description != null)      jsonPayload['description']      = description;
      if (isPrivate != null)        jsonPayload['isPrivate']        = isPrivate;
      if (buyLink != null)          jsonPayload['buyLink']          = buyLink;
      if (recordLabel != null)      jsonPayload['recordLabel']      = recordLabel;
      if (additionalTags != null)   jsonPayload['additionalTags']   = additionalTags;
      if (tags != null)             jsonPayload['tags']             = tags;
      if (licensing != null)        jsonPayload['licensing']        = licensing;
      if (lengthOfReceivedTracks != null) {
        jsonPayload['lengthOfRecievedTracks'] = lengthOfReceivedTracks;
      }
      final tracks = listOfTracks ?? audioTracks;
      if (tracks != null)           jsonPayload['listOfTracks']     = tracks;

      final request =
          http.MultipartRequest('PUT', Uri.parse('$_authBase/$playlistId'))
            ..headers.addAll({
              'Authorization': 'Bearer $token',
              'User-Agent': 'Android',
            });

      request.fields['data'] = jsonEncode(jsonPayload);

      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imagePath),
        );
      }

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      debugPrint('PUT $_authBase/$playlistId -> ${response.statusCode}');
      debugPrint('PUT body: ${response.body}');

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

  // PATCH /api/playlists/v1/{playlistId}/tracks/order  (reorder)
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
        Uri.parse('$_authBase/$playlistId/tracks/order'),
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

  // PATCH /api/playlists/v1/{playlistId}/secret-token
  // Mirrors web `playlists.service`: playlist sub-resources use the same base as
  // `reorderPlaylistTracks` (PATCH …/tracks/order) and `updatePlaylistImage`
  // (PATCH …/image). The pasted front repo had no explicit secret-token call;
  // POST on this path returned 404 — backend appears to register PATCH here.
  /// Returns updated playlist when the body includes full `playlist`; otherwise a loose token string.
  Future<(int, PlaylistModel?, String?)> rotatePlaylistSecretToken({
    required String playlistId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null, null);

      final uri = Uri.parse('$_authBase/$playlistId/secret-token');
      final headers = <String, String>{
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
      };

      var response = await _client.patch(
        uri,
        headers: headers,
        body: '{}',
      );
      debugPrint('PATCH $uri -> ${response.statusCode}');

      // Fallback if gateway only wires POST under /api/v1/playlists (like history).
      if (response.statusCode == 404) {
        final fallback = Uri.parse(
          '${_apiServices.baseUrl}/api/v1/playlists/$playlistId/secret-token',
        );
        response = await _client.post(
          fallback,
          headers: headers,
          body: '{}',
        );
        debugPrint('POST $fallback -> ${response.statusCode}');
      }

      debugPrint('rotatePlaylistSecretToken body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final model = PlaylistModel.singleFromResponse(data);
        if (model != null) {
          return (response.statusCode, model, model.secretToken);
        }
        final inner = data['data'];
        if (inner is Map<String, dynamic>) {
          final st = inner['secretToken']?.toString() ??
              inner['secret_token']?.toString();
          if (st != null && st.trim().isNotEmpty) {
            return (response.statusCode, null, st.trim());
          }
        }
        return (response.statusCode, null, null);
      }
      return (response.statusCode, null, null);
    } catch (e, st) {
      debugPrint('rotatePlaylistSecretToken error: $e\n$st');
      return (500, null, null);
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
