import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/audio_upload_track_management/models/track.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';

class TrackApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  final AuthApiService _authService = AuthApiService();

  late final String _authBase1;
  late final String _authBase2;
  late final String _publicV2Base;
  late final String _playbackBase;

  TrackApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _apiServices = apiServices ?? ApiServices(),
       _client = client ?? http.Client(),
       _storage = storage ?? const FlutterSecureStorage() {

    _authBase1 = '${_apiServices.baseUrl}/api/tracks/v1';
    _authBase2 = '${_apiServices.baseUrl}/api/tracks/v2';

    _publicV2Base = '${_apiServices.baseUrl}/api/public/tracks/v2';
    _playbackBase = '${_apiServices.baseUrl}/api/playback/v1';
  }

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

  
  Future<(int, dynamic)> uploadTrack({
    required String audioFilePath,
    required String audioFileName,
    String? imageFilePath,
    required String title,
    required String permalink,
    required List<String> artists,
    String genre = '',
    List<String> tags = const [],
    String description = '',
    bool privacy = false,
    String caption = '',
    
    bool enableDirectDownload = false,
    bool offlineListening = true,
    bool includeInRssFeed = true,
    bool displayedEmbedCode = true,
    bool enableAppPlayback = true,
    
    String licensing = 'all_rights',
    
    bool containsExplicit = false,
    String? releaseDate,
    String? recordLabel,
    String? publisher,
    String? isrc,
    String? pLine,
    
    String availability = 'worldwide',
    List<String> geoBlockingRegions = const [],
    List<String> geoBlockingCountries = const [],
    
    bool mobileProPreview = false,
  }) async {
    try {

      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) return (401, 'Authorization failed');

      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${_apiServices.baseUrl}/api/tracks/v2'))
        ..headers.addAll({
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'Android',
        });

      
      if (audioFilePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'audio',
            audioFilePath,
            filename: audioFileName,
          ),
        );
      }
      else {
        return (400, 'Audio file is required');
      }

      
      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFilePath),
        );
      }

      
      final basicInfoMap = <String, dynamic>{
        'title': title,
        'permalink': permalink,
        'mainArtists': artists,
        'isPrivate': privacy,
      };
      if (genre.isNotEmpty) basicInfoMap['genre'] = genre;
      if (tags.isNotEmpty) basicInfoMap['tags'] = tags;
      if (description.isNotEmpty) basicInfoMap['description'] = description;
      if (caption.isNotEmpty) basicInfoMap['caption'] = caption;
      request.fields['basicInfo'] = jsonEncode(basicInfoMap);

      
      request.fields['permissions'] = jsonEncode({
        'enableDirectDownload': enableDirectDownload,
        'offlineListening': offlineListening,
        'includeInRssFeed': includeInRssFeed,
        'displayedEmbedCode': displayedEmbedCode,
        'enableAppPlayback': enableAppPlayback,
      });

      
      final licenseType = licensing == 'creative_commons'
          ? 'creativeCommons'
          : 'allRightsReserved';
      request.fields['license'] = jsonEncode({
        'type': licenseType,
        'attribution': false,
        'nonCommercial': false,
        'noDerivativeWorks': false,
        'shareAlike': false,
      });

      
      final advancedMap = <String, dynamic>{
        'explicitContent': containsExplicit,
      };
      if (releaseDate != null) advancedMap['releaseDate'] = releaseDate;
      if (recordLabel != null && recordLabel.isNotEmpty) advancedMap['recordLabel'] = recordLabel;
      if (publisher != null && publisher.isNotEmpty) advancedMap['publisher'] = publisher;
      if (isrc != null && isrc.isNotEmpty) advancedMap['ISRC'] = isrc;
      if (pLine != null && pLine.isNotEmpty) advancedMap['pLine'] = pLine;
      request.fields['advanced'] = jsonEncode(advancedMap);

      
      request.fields['geoBlocking'] = jsonEncode({
        'mode': availability,
        'regions': geoBlockingRegions,
        'countries': geoBlockingCountries,
      });

      
      request.fields['mobileProPreview'] = jsonEncode({
        'mobileProPreview': mobileProPreview,
      });

      debugPrint('[uploadTrack] POST ${request.url}');
      debugPrint('[uploadTrack] Fields: ${request.fields}');

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      debugPrint('[uploadTrack] ${response.statusCode} - ${data['message'] ?? response.body}');
      debugPrint('[uploadTrack] Response data: $data');

      if (response.statusCode == 201) {
        final responseData = data["data"];
        return (201, responseData ?? data["message"] ?? "Track created successfully");
      }
      else if (response.statusCode == 400) {
        debugPrint('[uploadTrack] Errors: ${data['errors']}');
        return (400, data['errors'] ?? data['message'] ?? "Validation failed");
      }
      else if (response.statusCode == 401) {
        return (401, "Authorization failed");
      }
      else {
        return (500, "Internal server error");
      }
    } catch (err) {
      debugPrint('[uploadTrack] Exception: $err');
      return (500, "Network error: $err");
    }
  }

  
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
    
    bool enableDirectDownload = false,
    bool offlineListening = true,
    bool includeInRssFeed = true,
    bool displayedEmbedCode = true,
    bool enableAppPlayback = true,
    
    String licensing = 'all_rights',
    
    bool containsExplicit = false,
    String? releaseDate,
    String? recordLabel,
    String? publisher,
    String? isrc,
    String? pLine,
    
    String availability = 'worldwide',
    List<String> geoBlockingRegions = const [],
    List<String> geoBlockingCountries = const [],
  }) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) return (401, 'Unauthorized');

      final request = http.MultipartRequest('PATCH', Uri.parse('${_apiServices.baseUrl}/api/tracks/v2/'))
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

      
      final hasBasicUpdate =
          title != null ||
          permalink != null ||
          mainArtists != null ||
          genre != null ||
          tags != null ||
          description != null ||
          isPrivate != null ||
          caption != null;

      if (hasBasicUpdate) {
        request.fields['basicInfo'] = jsonEncode(
          {
            'title': title,
            'permalink': permalink,
            'mainArtists': mainArtists,
            'genre': genre,
            if (tags != null && tags.isNotEmpty) 'tags': tags,
            'description': description,
            'isPrivate': isPrivate,
            'caption': caption,
          }..removeWhere((key, value) => value == null),
        );
      }

      
      request.fields['permissions'] = jsonEncode({
        'enableDirectDownload': enableDirectDownload,
        'offlineListening': offlineListening,
        'includeInRssFeed': includeInRssFeed,
        'displayedEmbedCode': displayedEmbedCode,
        'enableAppPlayback': enableAppPlayback,
      });

      
      final licenseType = licensing == 'creative_commons'
          ? 'creativeCommons'
          : 'allRightsReserved';
      request.fields['license'] = jsonEncode({
        'type': licenseType,
        'attribution': false,
        'nonCommercial': false,
        'noDerivativeWorks': false,
        'shareAlike': false,
      });

      
      final advancedMap = <String, dynamic>{
        'explicitContent': containsExplicit,
      };
      if (releaseDate != null) advancedMap['releaseDate'] = releaseDate;
      if (recordLabel != null && recordLabel.isNotEmpty) advancedMap['recordLabel'] = recordLabel;
      if (publisher != null && publisher.isNotEmpty) advancedMap['publisher'] = publisher;
      if (isrc != null && isrc.isNotEmpty) advancedMap['ISRC'] = isrc;
      if (pLine != null && pLine.isNotEmpty) advancedMap['pLine'] = pLine;
      request.fields['advanced'] = jsonEncode(advancedMap);

      
      request.fields['geoBlocking'] = jsonEncode({
        'mode': availability,
        'regions': geoBlockingRegions,
        'countries': geoBlockingCountries,
      });

      debugPrint('[updateTrack] PATCH ${request.url}');
      debugPrint('[updateTrack] Fields: ${request.fields}');

      final streamed = await _client.send(request);
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      debugPrint('[updateTrack] ${response.statusCode} - ${data['message'] ?? response.body}');
      debugPrint('[updateTrack] Response data: $data');

      if (response.statusCode == 200) {
        final trackData = data['data'] as Map<String, dynamic>?;
        if (trackData != null) {
          return (200, Track.fromNestedJson(trackData));
        }
        return (200, data['message'] ?? 'Track updated');
      }
      if (response.statusCode == 400) {
        final errors = data['errors'] as List?;
        if (errors != null && errors.isNotEmpty) {
          final detail = errors
              .map((e) => '${e['field']}: ${e['message']}')
              .join('\n');
          debugPrint('[updateTrack] Validation errors: $detail');
          return (400, detail);
        }
      }
      return (response.statusCode, data['message'] ?? 'Failed to update track');
    } catch (err) {
      debugPrint('[updateTrack] Exception: $err');
      return (500, 'Network error: $err');
    }
  }

  
  
  
  
  
  
  
  
  Future<(int, dynamic)> deleteTrack({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.delete(
        Uri.parse('$_authBase1/$trackId'),
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

  
  
  
  
  
  
  Future<(int, dynamic)> getAllTracksPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final uri = Uri.parse('$_authBase2/').replace(
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

  
  
  
  
  
  
  Future<(int, dynamic)> getTrackById({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      final headers = token != null
          ? _authHeaders(token)
          : {'Content-Type': 'application/json', 'User-Agent': 'Android'};

      final response = await _client.get(
        Uri.parse('$_publicV2Base/$trackId'),
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

  
  
  
  
  
  
  Future<(int, dynamic)> getUserPostedTracks({required String userId}) async {
    if (userId.trim().isEmpty) return (400, 'Invalid user ID');
    try {
      final token = await _getToken();
      final response = await _client.get(
        Uri.parse('$_publicV2Base/posted/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      final trackCount = (data['data'] as List?)?.length ?? 0;

      debugPrint('[getUserPostedTracks] ${response.statusCode} - ${data['message']} ($trackCount tracks)');
      debugPrint('[getUserPostedTracks] Response data: $data');

      if (response.statusCode == 200) {
        return (200, Track.listFromUserTracksResponse(data));
      }
      return (
        response.statusCode,
        data['message'] ?? 'Failed to fetch user tracks',
      );
    } catch (err) {
      debugPrint('[getUserPostedTracks] Exception: $err');
      return (500, 'Network error: $err');
    }
  }

  
  
  
  
  
  
  Future<(int, dynamic)> getUserLikedTracks({required String userId}) async {
    if (userId.trim().isEmpty) return (400, 'Invalid user ID');
    try {
      final response = await _client.get(
        Uri.parse('$_publicV2Base/liked/$userId'),
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

  
  
  
  
  
  
  
  Future<(int, dynamic)> incrementPlayCount({
    required String trackId,
    required int listenedDuration,
    String? sessionIdPlay,
  }) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.patch(
        Uri.parse('$_authBase2/listen'),
        headers: _authHeaders(token),
        body: jsonEncode({
          'trackId': trackId,
          'listenedDuration': listenedDuration,
          'sessionIdPlay': sessionIdPlay ?? _generateUuid(),
        }),
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

  
  String _generateUuid() {
    final rng = Random.secure();
    final b = List<int>.generate(16, (_) => rng.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40; 
    b[8] = (b[8] & 0x3f) | 0x80; 
    String hex(int v) => v.toRadixString(16).padLeft(2, '0');
    return '${hex(b[0])}${hex(b[1])}${hex(b[2])}${hex(b[3])}-'
        '${hex(b[4])}${hex(b[5])}-'
        '${hex(b[6])}${hex(b[7])}-'
        '${hex(b[8])}${hex(b[9])}-'
        '${hex(b[10])}${hex(b[11])}${hex(b[12])}${hex(b[13])}${hex(b[14])}${hex(b[15])}';
  }

  
  
  
  
  
  Future<(int, dynamic)> addToHistory({required String trackId}) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.post(
        Uri.parse('$_authBase1/played/$trackId'),
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
  
  
  
  
  
  
  
  
  Future<(int, dynamic)> updateMobileProPreview({
    required String trackId,
    required bool mobileProPreview,
  }) async {
    if (trackId.trim().isEmpty) return (400, 'Invalid track ID');
    try {
      final token = await _getToken();
      if (token == null) return (401, 'Unauthorized');

      final response = await _client.patch(
        Uri.parse('$_authBase1/mobile-pro-preview/$trackId'),
        headers: _authHeaders(token),
        body: jsonEncode({'mobileProPreview': mobileProPreview}),
      );
      final data = jsonDecode(response.body);

      debugPrint('[updateMobileProPreview] ${response.statusCode} - ${data['message'] ?? response.body}');

      if (response.statusCode == 200) {
        final isChanged = (data['data'] as Map<String, dynamic>?)?['isChanged'] as bool? ?? false;
        return (200, {'message': data['message'], 'isChanged': isChanged});
      }
      return (response.statusCode, data['message'] ?? 'Failed to update mobile pro preview');
    } catch (err) {
      debugPrint('[updateMobileProPreview] Exception: $err');
      return (500, 'Network error: $err');
    }
  }
}
