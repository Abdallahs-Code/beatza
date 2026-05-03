import "dart:convert";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:http/http.dart" as http;
import "package:cross_team5/core/services/api_services.dart";
import "package:cross_team5/features/sets_playlists/models/playlist_model.dart";























class PlaylistApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  late final String _v1Base;
  late final String _publicBase;

  PlaylistApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage() {
    _v1Base = "${_apiServices.baseUrl}/api/playlists/v1";
    _publicBase = "${_apiServices.baseUrl}/api/public/playlists/v1";
  }

  Future<String?> _getToken() async {
    final token = await _storage.read(key: "access_token");
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  Future<String?> _getUserId() async {
    return _storage.read(key: "user_id");
  }

  Map<String, String> _authHeaders(String token) => {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "User-Agent": "Android",
      };

  

  Future<(int, PlaylistModel?)> createPlaylist({
    required String playlistName,
    List<String> tracks = const [],
    bool isPrivate = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final response = await _client.post(
        Uri.parse(_v1Base),
        headers: _authHeaders(token),
        body: jsonEncode({
          "playlistName": playlistName,
          "tracks": tracks,
          "isPrivate": isPrivate,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistsRaw = data["data"]?["playlists"] as List<dynamic>?;
        if (playlistsRaw != null && playlistsRaw.isNotEmpty) {
          return (
            response.statusCode,
            PlaylistModel.fromJson(playlistsRaw.first as Map<String, dynamic>),
          );
        }
        return (response.statusCode, null);
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  

  Future<(int, PlaylistModel?)> createPlaylistWithImage({
    required String title,
    required String imagePath,
    String? description,
    List<String> listOfTracks = const [],
    bool isPrivate = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final request =
          http.MultipartRequest("POST", Uri.parse("$_v1Base/with-image"))
            ..headers.addAll({
              "Authorization": "Bearer $token",
              "User-Agent": "Android",
            });

      request.fields["title"] = title;
      request.fields["isPrivate"] = isPrivate.toString();
      if (description != null && description.isNotEmpty) {
        request.fields["description"] = description;
      }
      for (final trackId in listOfTracks) {
        request.fields["listOfTracks"] = trackId;
      }
      request.files.add(await http.MultipartFile.fromPath("image", imagePath));

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistsRaw = data["data"]?["playlists"] as List<dynamic>?;
        if (playlistsRaw != null && playlistsRaw.isNotEmpty) {
          return (
            response.statusCode,
            PlaylistModel.fromJson(playlistsRaw.first as Map<String, dynamic>),
          );
        }
        return (response.statusCode, null);
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  

  Future<void> addPlaylistToHistory({required String playlistId}) async {
    try {
      final token = await _getToken();
      if (token == null || playlistId.isEmpty) return;

      await _client.post(
        Uri.parse("$_v1Base/$playlistId/history"),
        headers: _authHeaders(token),
      );
    } catch (_) {}
  }

  

  Future<(int, List<PlaylistModel>)> getMyPlaylists() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final response = await _client.get(
        Uri.parse("$_v1Base/my-playlists"),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  

  Future<(int, PlaylistModel?)> getPlaylistWithTracks({
    required String playlistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final uri = Uri.parse("$_v1Base/$playlistId").replace(
        queryParameters: {
          "limit": limit.toString(),
          "offset": offset.toString(),
        },
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.singleFromResponse(data));
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  

  Future<(int, List<PlaylistModel>)> getPublicPlaylistsAuth({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse(_v1Base).replace(queryParameters: {
        "limit": limit.toString(),
        "offset": offset.toString(),
      });
      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  

  Future<(int, List<PlaylistModel>)> getArtistPlaylistsAuth({
    required String artistId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse("$_v1Base/playlists/$artistId");
      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  

  Future<(int, Map<String, dynamic>?)> getArtistInfo({
    required String creatorId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final uri = Uri.parse("$_v1Base/creator/$creatorId");
      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final artistList = data["data"]?["artist"] as List<dynamic>?;
        if (artistList != null && artistList.isNotEmpty) {
          return (200, artistList.first as Map<String, dynamic>);
        }
        return (200, null);
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  

  Future<(int, List<PlaylistModel>)> getMorePlaylistsFromArtistAuth({
    required String playlistId,
    required String artistId,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse(
        "$_v1Base/$playlistId/recommend/$artistId",
      ).replace(queryParameters: {
        "limit": limit.toString(),
        "offset": offset.toString(),
      });
      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  

  Future<(int, List<PlaylistModel>)> getArtistAlbums({
    required String artistId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse(
        "$_publicBase/creator/$artistId/albums",
      ).replace(queryParameters: {
        "limit": limit.toString(),
        "offset": offset.toString(),
      });
      final response = await _client.get(uri, headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (_) {
      return (500, <PlaylistModel>[]);
    }
  }

  

  Future<(int, String)> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    String? genre,
    bool? isPrivate,
    List<String>? listOfTracks,
    String? imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, "Unauthorized");

      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("$_v1Base/$playlistId"),
      )..headers.addAll({
          "Authorization": "Bearer $token",
          "User-Agent": "Android",
        });

      if (title != null) request.fields["title"] = title;
      if (description != null) request.fields["description"] = description;
      if (genre != null) request.fields["genre"] = genre;
      if (isPrivate != null) {
        request.fields["isPrivate"] = isPrivate.toString();
      }
      if (listOfTracks != null) {
        request.fields["listOfTracks"] = jsonEncode(listOfTracks);
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files
            .add(await http.MultipartFile.fromPath("image", imagePath));
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data["message"]?.toString() ?? "Update failed",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  

  Future<(int, bool)> deletePlaylist({required String playlistId}) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, false);

      final response = await _client.delete(
        Uri.parse("$_v1Base/$playlistId"),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final deleted = data["data"]?["deleted"] as bool? ?? false;
        return (200, deleted);
      }

      return (response.statusCode, false);
    } catch (_) {
      return (500, false);
    }
  }

  

  Future<(int, String)> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, "Unauthorized");

      final response = await _client.patch(
        Uri.parse("$_v1Base/$playlistId/tracks/$trackId"),
        headers: _authHeaders(token),
      );

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data["message"]?.toString() ?? "Failed to add track",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  

  Future<(int, String)> reorderTrack({
    required String playlistId,
    required String trackId,
    required int oldPosition,
    required int newPosition,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, "Unauthorized");

      final response = await _client.patch(
        Uri.parse("$_v1Base/$playlistId/tracks"),
        headers: _authHeaders(token),
        body: jsonEncode({
          "trackId": trackId,
          "oldPosition": oldPosition,
          "newPosition": newPosition,
        }),
      );

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data["message"]?.toString() ?? "Failed to reorder track",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  

  Future<(int, String)> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, "Unauthorized");

      final response = await _client.delete(
        Uri.parse("$_v1Base/$playlistId/tracks/$trackId"),
        headers: _authHeaders(token),
      );

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      return (
        response.statusCode,
        body["message"]?.toString() ?? "Failed to remove track",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  

  Future<(int, PlaylistModel?)> updatePlaylistImage({
    required String playlistId,
    required String imagePath,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final request = http.MultipartRequest(
        "PATCH",
        Uri.parse("$_v1Base/$playlistId/image"),
      )..headers.addAll({
          "Authorization": "Bearer $token",
          "User-Agent": "Android",
        });

      request.files
          .add(await http.MultipartFile.fromPath("image", imagePath));

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistJson =
            data["data"]?["playlist"] as Map<String, dynamic>?;
        return (
          200,
          playlistJson != null ? PlaylistModel.fromJson(playlistJson) : null,
        );
      }

      return (response.statusCode, null);
    } catch (_) {
      return (500, null);
    }
  }

  

  Future<(int, List<String>)> getTrendingTrackIds() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <String>[]);

      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) return (401, <String>[]);

      final uri = Uri.parse(
        "${_apiServices.baseUrl}/api/public/feed/v1/trending-tracks/$userId",
      ).replace(queryParameters: {"offset": "0", "limit": "20"});

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          final ids = body
              .map((e) =>
                  (e as Map<String, dynamic>)["id"]?.toString() ?? "")
              .where((id) => id.isNotEmpty)
              .toList();
          return (200, ids);
        }
      }

      return (response.statusCode, <String>[]);
    } catch (_) {
      return (500, <String>[]);
    }
  }

  

  Future<(int, Map<String, dynamic>)> getPublicTracksPaginated({
    int page = 1,
    int limit = 30,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <String, dynamic>{});

      final uri =
          Uri.parse("${_apiServices.baseUrl}/api/tracks/v2/").replace(
        queryParameters: {
          "page": page.toString(),
          "limit": limit.toString(),
        },
      );

      final response = await _client.get(uri, headers: _authHeaders(token));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body["data"] as Map<String, dynamic>? ?? {};
        return (200, data);
      }

      return (response.statusCode, <String, dynamic>{});
    } catch (_) {
      return (500, <String, dynamic>{});
    }
  }
}
