// Dart imports
import "dart:convert";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:http/http.dart" as http;
import "package:cross_team5/core/services/api_services.dart";
import "package:cross_team5/features/sets_playlists/models/playlist_model.dart";
import 'package:flutter/foundation.dart';

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
    _authBase = "${_apiServices.baseUrl}/api/playlists/v1";
    _publicBase = "${_apiServices.baseUrl}/api/public/playlists/v1";
  }

  Future<String?> _getToken() async {
    final token = await _storage.read(key: "access_token");
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  // GET /api/playlists/v1/{playlistId}?limit=&offset=
  Future<(int, PlaylistModel?)> getPlaylistWithTracks({
    required String playlistId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final uri = Uri.parse("$_authBase/$playlistId");

      final response = await _client.get(uri, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.singleFromResponse(data));
      }

      return (response.statusCode, null);
    } catch (err) {
      return (500, null);
    }
  }

  // PUT /api/playlists/v1/{playlistId}
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
      if (token == null) return (401, "Unauthorized");

      final request = http.MultipartRequest(
        "PUT",
        Uri.parse("$_authBase/$playlistId"),
      )..headers.addAll({
          "Authorization": "Bearer $token",
          "User-Agent": "Android",
        });

      void addField(String key, String? value) {
        if (value != null) request.fields[key] = value;
      }

      addField("title", title);
      addField("permalink", permalink);
      addField("type", type);
      addField("playlistType", playlistType);
      addField("releaseDate", releaseDate);
      addField("genre", genre);
      addField("description", description);
      addField("Privacy", privacy);
      addField("buyLink", buyLink);
      addField("recordLabel", recordLabel);

      if (additionalTags != null) {
        for (final tag in additionalTags) {
          request.fields["additionalTags"] = tag;
        }
      }
      if (tags != null) {
        for (final tag in tags) {
          request.fields["tags"] = tag;
        }
      }
      if (audioTracks != null) {
        request.fields["audioTracks"] = jsonEncode(audioTracks);
      }
      if (lengthOfReceivedTracks != null) {
        request.fields["lengthOfRecievedTracks"] = "$lengthOfReceivedTracks";
      }
      if (licensing != null) {
        request.fields["licensing"] = jsonEncode(licensing);
      }
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath("image", imagePath));
      }

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("PUT $_authBase/$playlistId -> ${response.statusCode}");

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data["message"]?.toString() ?? "Update failed",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  // GET /api/playlists/v1?limit=&offset=
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsAuth() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse(_authBase);
      final response = await _client.get(uri, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1?limit=&offset=
  Future<(int, List<PlaylistModel>)> getPublicPlaylistsGuest() async {
    try {
      final uri = Uri.parse(_publicBase);
      final response = await _client.get(uri, headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/playlists/v1/playlists/{artistId}?limit=&offset=
  Future<(int, List<PlaylistModel>)> getArtistPlaylistsAuth({
    required String artistId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse("$_authBase/playlists/$artistId");

      final response = await _client.get(uri, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/playlists/{artistId}?limit=&offset=
  Future<(int, List<PlaylistModel>)> getArtistPlaylistsGuest({
    required String artistId,
  }) async {
    try {
      final uri = Uri.parse("$_publicBase/playlists/$artistId");

      final response = await _client.get(uri, headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/{playlistId}?limit=&offset=
  Future<(int, PlaylistModel?)> getPublicPlaylistWithTracks({
    required String playlistId,
  }) async {
    try {
      final uri = Uri.parse("$_publicBase/$playlistId");

      final response = await _client.get(uri, headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.singleFromResponse(data));
      }

      return (response.statusCode, null);
    } catch (err) {
      return (500, null);
    }
  }

  // GET /api/playlists/v1/creator/{creatorId}         (authenticated)
  // GET /api/public/playlists/v1/creator/{creatorId}  (guest)
  Future<(int, Map<String, dynamic>?)> getArtistInfo({
    required String creatorId,
    bool authenticated = true,
  }) async {
    try {
      final String baseUrl;
      final Map<String, String> headers;

      if (authenticated) {
        final token = await _getToken();
        if (token == null) return (401, null);
        baseUrl = _authBase;
        headers = {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Android",
        };
      } else {
        baseUrl = _publicBase;
        headers = {
          "Content-Type": "application/json",
          "User-Agent": "Android",
        };
      }

      final uri = Uri.parse("$baseUrl/creator/$creatorId");
      final response = await _client.get(uri, headers: headers);

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, data["data"] as Map<String, dynamic>?);
      }

      return (response.statusCode, null);
    } catch (err) {
      return (500, null);
    }
  }

  // GET /api/playlists/v1/{playlistId}/recommend/{artistId}?limit=&offset=
  Future<(int, List<PlaylistModel>)> getMorePlaylistsFromArtistAuth({
    required String playlistId,
    required String artistId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final uri = Uri.parse("$_authBase/$playlistId/recommend/$artistId");

      final response = await _client.get(uri, headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/{playlistId}/recommend/{artistId}?limit=&offset=
  Future<(int, List<PlaylistModel>)> getMorePlaylistsFromArtistGuest({
    required String playlistId,
    required String artistId,
  }) async {
    try {
      final uri = Uri.parse("$_publicBase/$playlistId/recommend/$artistId");

      final response = await _client.get(uri, headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/creator/{artistId}/albums?limit=&offset=
  Future<(int, List<PlaylistModel>)> getArtistAlbums({
    required String artistId,
  }) async {
    try {
      final uri = Uri.parse("$_publicBase/creator/$artistId/albums");

      final response = await _client.get(uri, headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/public/playlists/v1/permalink/{permalink}?limit=&offset=
  Future<(int, List<PlaylistModel>)> getPlaylistByPermalink({
    required String permalink,
  }) async {
    try {
      final uri = Uri.parse("$_publicBase/permalink/$permalink");

      final response = await _client.get(uri, headers: {
        "Content-Type": "application/json",
        "User-Agent": "Android",
      });

      debugPrint("GET $uri -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
    }
  }

  // GET /api/playlists/v1/my-playlists
  Future<(int, List<PlaylistModel>)> getMyPlaylists() async {
    try {
      final token = await _getToken();
      if (token == null) return (401, <PlaylistModel>[]);

      final response = await _client.get(
        Uri.parse("$_authBase/my-playlists"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
          "User-Agent": "Android",
        },
      );

      debugPrint("GET $_authBase/my-playlists -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (200, PlaylistModel.listFromResponse(data));
      }

      return (response.statusCode, <PlaylistModel>[]);
    } catch (err) {
      return (500, <PlaylistModel>[]);
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

      final request = http.MultipartRequest(
        "PATCH",
        Uri.parse("$_authBase/$playlistId/image"),
      )..headers.addAll({
          "Authorization": "Bearer $token",
          "User-Agent": "Android",
        });

      request.files.add(await http.MultipartFile.fromPath("image", imagePath));

      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("PATCH $_authBase/$playlistId/image -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final playlistJson = data["data"]?["playlist"] as Map<String, dynamic>?;
        return (200, playlistJson != null ? PlaylistModel.fromJson(playlistJson) : null);
      }

      return (response.statusCode, null);
    } catch (err) {
      return (500, null);
    }
  }

  // PATCH /api/playlists/v1/{playlistId}/tracks
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
        Uri.parse("$_authBase/$playlistId/tracks"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Android",
        },
        body: jsonEncode({
          "trackId": trackId,
          "oldPosition": oldPosition,
          "newPosition": newPosition,
        }),
      );

      debugPrint("PATCH $_authBase/$playlistId/tracks -> ${response.statusCode}");

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data["message"]?.toString() ?? "Failed to reorder track",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  // PATCH /api/playlists/v1/{playlistId}/tracks/{trackId}
  Future<(int, String)> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, "Unauthorized");

      final response = await _client.patch(
        Uri.parse("$_authBase/$playlistId/tracks/$trackId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Android",
        },
      );

      debugPrint("PATCH $_authBase/$playlistId/tracks/$trackId -> ${response.statusCode}");

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data["message"]?.toString() ?? "Failed to add track",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  // POST /api/v1/playlists
  Future<(int, PlaylistModel?)> createPlaylist({
    required String playlistName,
    List<String> tracks = const [],
    bool isPrivate = false,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, null);

      final response = await _client.post(
        Uri.parse("${_apiServices.baseUrl}/api/v1/playlists"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Android",
        },
        body: jsonEncode({
          "playlistName": playlistName,
          "tracks": tracks,
          "isPrivate": isPrivate,
        }),
      );

      debugPrint("POST ${_apiServices.baseUrl}/api/v1/playlists -> ${response.statusCode}");

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
    } catch (err) {
      return (500, null);
    }
  }

  // DELETE /api/playlists/v1/{playlistId}/tracks/{trackId}
  Future<(int, String)> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, "Unauthorized");

      final response = await _client.delete(
        Uri.parse("$_authBase/$playlistId/tracks/$trackId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Android",
        },
      );

      debugPrint("DELETE $_authBase/$playlistId/tracks/$trackId -> ${response.statusCode}");

      final data = jsonDecode(response.body);
      return (
        response.statusCode,
        data["message"]?.toString() ?? "Failed to remove track",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  // DELETE /api/playlists/v1/{playlistId}
  Future<(int, bool)> deletePlaylist({required String playlistId}) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, false);

      final response = await _client.delete(
        Uri.parse("$_authBase/$playlistId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "User-Agent": "Android",
        },
      );

      debugPrint("DELETE $_authBase/$playlistId -> ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final deleted = data["data"]?["deleted"] as bool? ?? false;
        return (200, deleted);
      }

      return (response.statusCode, false);
    } catch (err) {
      return (500, false);
    }
  }
}
