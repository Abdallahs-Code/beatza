import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/message_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:http/http.dart' as http;

class MessagingApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final AuthApiService _authApiService;
  late final String _msgBase;
  late final String _tracksBase;

  MessagingApiService({
    ApiServices? apiServices,
    http.Client? client,
    AuthApiService? authApiService,
  })  : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client(),
        _authApiService = authApiService ?? AuthApiService() {
    _msgBase = '${_apiServices.baseUrl}/api/messages/v1';
    _tracksBase = '${_apiServices.baseUrl}/api/public/tracks/v1';
  }

  Future<String> _token() async {
    final t = await _authApiService.getStoredAccessToken();
    if (t == null || t.trim().isEmpty) throw Exception('Unauthorized');
    return t;
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Agent': 'Android',
        'accept': 'application/json'
      };

  dynamic _decode(http.Response r) {
    if (r.body.trim().isEmpty) return null;
    try {
      return jsonDecode(r.body);
    } catch (_) {
      return null;
    }
  }

  // GET /api/messages/v1/chats
  Future<List<ChatModel>> getChats({int limit = 20}) async {
    final token = await _token();
    final uri = Uri.parse('$_msgBase/chats')
        .replace(queryParameters: {'limit': '$limit'});
    final res = await _client.get(uri, headers: _headers(token));
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ChatModel.fromJson)
          .toList();
    }
    throw Exception(
        (data is Map ? data['message']?.toString() : null) ??
            'Failed to load chats');
  }

  // GET /api/messages/v1/chat/message/{chatId}
  Future<({List<MessageModel> messages, bool isReceiverBlocked, bool isBlockedByReceiver})>
      getChatMessages({
    required String chatId,
    int limit = 20,
    String? before,
  }) async {
    final token = await _token();
    final params = <String, String>{'limit': '$limit'};
    if (before != null && before.isNotEmpty) params['before'] = before;
    final uri = Uri.parse('$_msgBase/chat/message/$chatId')
        .replace(queryParameters: params);
    final res = await _client.get(uri, headers: _headers(token));
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final inner = data['data'] as Map<String, dynamic>? ?? {};
      debugPrint('[getChatMessages] data.keys=${inner.keys.toList()}');
      for (final k in inner.keys) {
        if (k != 'messages') debugPrint('[getChatMessages]   $k = ${inner[k]}');
      }
      final msgList = inner['messages'] as List<dynamic>? ?? [];
      // Try every field name the backend might use for "you were blocked by them"
      final isBlockedByReceiver =
          inner['isBlockedByReceiver'] == true ||
          inner['isSenderBlocked'] == true ||
          inner['isCurrentUserBlocked'] == true ||
          inner['blockedBySender'] == true ||
          inner['isBlocked'] == true;
      return (
        messages: msgList
            .whereType<Map<String, dynamic>>()
            .map(MessageModel.fromJson)
            .toList(),
        isReceiverBlocked: inner['isReceiverBlocked'] == true,
        isBlockedByReceiver: isBlockedByReceiver,
      );
    }
    throw Exception(
        (data is Map ? data['message']?.toString() : null) ??
            'Failed to load messages');
  }

  // Find existing chat with receiverId.
  // Pass 1: match via lastMessage.senderId (fast, no extra calls).
  // Pass 2: for chats where WE sent the last message, fetch their messages
  //         and scan for any message from the receiver.
  // (the /chats API doesn't include userId in participant objects)
  Future<String?> findOrCreateChat({required String receiverId}) async {
    try {
      final token = await _token();
      final currentUserId = await _authApiService.getStoredUserId() ?? '';
      final uri = Uri.parse('$_msgBase/chats').replace(queryParameters: {'limit': '100'});
      debugPrint('[MessagingApiService.findOrCreateChat] GET $uri receiverId=$receiverId');
      final res = await _client.get(uri, headers: _headers(token));
      final data = _decode(res);
      if (res.statusCode != 200 || data is! Map) {
        debugPrint('[MessagingApiService.findOrCreateChat] chats fetch failed: ${res.statusCode}');
        return null;
      }
      final list = (data['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      debugPrint('[MessagingApiService.findOrCreateChat] ${list.length} chats to search');

      // Pass 1: quick match — the receiver sent the last message
      final needsDeepSearch = <String>[];
      for (final item in list) {
        final chatId = item['_id']?.toString() ?? '';
        if (chatId.isEmpty) continue;
        final lm = item['lastMessage'];
        final senderId = lm is Map ? lm['senderId']?.toString() ?? '' : '';
        debugPrint('[MessagingApiService.findOrCreateChat] pass1 chatId=$chatId senderId=$senderId');
        if (senderId == receiverId) {
          debugPrint('[MessagingApiService.findOrCreateChat] Pass 1 match. chatId=$chatId');
          return chatId;
        }
        // We sent the last message — need to look deeper
        if (senderId == currentUserId) needsDeepSearch.add(chatId);
      }

      // Pass 2: fetch messages for ambiguous chats and scan for receiverId
      debugPrint('[MessagingApiService.findOrCreateChat] Pass 2: deep-searching ${needsDeepSearch.length} chats');
      for (final chatId in needsDeepSearch) {
        try {
          final msgUri = Uri.parse('$_msgBase/chat/message/$chatId')
              .replace(queryParameters: {'limit': '20'});
          final msgRes = await _client.get(msgUri, headers: _headers(token));
          final msgData = _decode(msgRes);
          if (msgRes.statusCode == 200 && msgData is Map) {
            final inner = msgData['data'];
            final msgs = (inner is Map ? inner['messages'] : null) as List<dynamic>? ?? [];
            for (final m in msgs) {
              if (m is Map && m['senderId']?.toString() == receiverId) {
                debugPrint('[MessagingApiService.findOrCreateChat] Pass 2 match. chatId=$chatId');
                return chatId;
              }
            }
          }
        } catch (e) {
          debugPrint('[MessagingApiService.findOrCreateChat] pass2 error for $chatId: $e');
        }
      }

      debugPrint('[MessagingApiService.findOrCreateChat] No existing chat found');
      return null;
    } catch (e) {
      debugPrint('[MessagingApiService.findOrCreateChat] error: $e');
      return null;
    }
  }

  // POST /api/messages/v1/send
  Future<ChatModel> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final token = await _token();
    final uri = Uri.parse('$_msgBase/send');
    final res = await _client.post(
      uri,
      headers: _headers(token),
      body: jsonEncode({'receiverId': receiverId, 'content': content}),
    );
    debugPrint('[sendMessage] status=${res.statusCode} body=${res.body.length > 300 ? res.body.substring(0, 300) : res.body}');
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return ChatModel.fromJson(inner);
    }
    final errorMsg = (data is Map ? data['message']?.toString() : null) ?? 'Failed to send message';
    debugPrint('[sendMessage] ERROR → status=${res.statusCode} message="$errorMsg"');
    throw Exception(errorMsg);
  }

  // PATCH /api/messages/v1/archive
  Future<void> archiveChat({required String chatId}) async {
    final token = await _token();
    final uri = Uri.parse('$_msgBase/archive');
    final res = await _client.patch(
      uri,
      headers: _headers(token),
      body: jsonEncode({'chatId': chatId}),
    );
    if (res.statusCode != 200) {
      final data = _decode(res);
      throw Exception(
          (data is Map ? data['message']?.toString() : null) ??
              'Failed to archive chat');
    }
  }

  // PATCH /api/messages/v1/chat/read/{chatId}
  // Future<void> markChatAsRead({required String chatId}) async {
  //   final token = await _token();
  //   final uri = Uri.parse('$_msgBase/chat/read/$chatId');
  //   await _client.patch(
  //     uri,
  //     headers: _headers(token),
  //     body: jsonEncode({'chatId': chatId}),
  //   );
  // }

    // PATCH /api/messages/v1/chat/read
  // PATCH /api/messages/v1/chat/read
  Future<void> markChatAsRead({required String chatId}) async {
    try {
      final token = await _token();
      
      // ✅ URL is correct now
      final uri = Uri.parse('${_msgBase}/chat/read');
      
      // ✅ FIXED: Backend expects 'id', not 'chatId'
      final requestBody = {'id': chatId};
      
      // 🔍 DEBUG: Log exact request
      print('📤 [DEBUG] PATCH $uri');
      print('📤 [DEBUG] Body: ${jsonEncode(requestBody)}');

      final response = await _client.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(requestBody),
      );

      // 🔍 DEBUG: Log response
      print('📥 [DEBUG] Status: ${response.statusCode}');
      print('📥 [DEBUG] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Chat $chatId marked as read');
        return;
      }

      // Handle errors
      switch (response.statusCode) {
        case 400:
          final data = _decode(response);
          final msg = data is Map ? data['message'] ?? 'Validation failed' : 'Bad Request';
          throw Exception('Invalid request: $msg');
        case 401:
          throw Exception('Unauthorized: Token invalid/expired');
        case 404:
          throw Exception('Endpoint not found: $uri');
        default:
          throw Exception('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      print('💥 [ERROR] markChatAsRead: $e');
      print('📍 Stack: $stack');
      rethrow;
    }
  }
  // PATCH /api/messages/v1/chat/unread/{chatId}
  // PATCH /api/messages/v1/chat/unread
  // PATCH /api/messages/v1/chat/unread
  // PATCH /api/messages/v1/chat/unread
  Future<void> markChatAsUnread({required String chatId}) async {
    try {
      final token = await _token();
      
      // ✅ URL construction (same pattern as markChatAsRead)
      final uri = Uri.parse('${_msgBase}/chat/unread');
      
      // ✅ Body: Backend expects 'id' field (same as markChatAsRead)
      final requestBody = {'id': chatId};
      
      // 🔍 DEBUG: Log outgoing request
      print('📤 [DEBUG] PATCH $uri');
      print('📤 [DEBUG] Body: ${jsonEncode(requestBody)}');
      print('📤 [DEBUG] Headers: ${_headers(token)}');

      final response = await _client.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(requestBody),
      );

      // 🔍 DEBUG: Log incoming response
      print('📥 [DEBUG] Status: ${response.statusCode}');
      print('📥 [DEBUG] Body: ${response.body}');
      print('📥 [DEBUG] Headers: ${response.headers}');

      // ✅ Handle success codes
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Chat $chatId marked as unread successfully');
        return;
      }

      // ❌ Handle error codes with specific messages
      switch (response.statusCode) {
        case 400:
          final data = _decode(response);
          final errors = data is Map ? data['errors'] : null;
          final msg = data is Map ? data['message'] ?? 'Validation failed' : 'Bad Request';
          
          if (errors is List) {
            print('⚠️ [DEBUG] Validation errors: $errors');
          }
          throw Exception('Invalid request: $msg');
          
        case 401:
          throw Exception('Unauthorized: Token invalid or expired');
        case 403:
          throw Exception('Forbidden: You do not have permission for this action');
        case 404:
          throw Exception('Endpoint not found: $uri');
        default:
          throw Exception('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      print('💥 [ERROR] markChatAsUnread failed: $e');
      print('📍 Stack: $stack');
      rethrow; // Let UI handle error display
    }
  }

  // GET /api/public/tracks/v1/liked/{userId}
  // Future<List<PlaybackTrackModel>> getLikedTracks({
  //   required String userId,
  // }) async {
  //   final token = await _token();
  //   final uri = Uri.parse('$_tracksBase/liked/$userId');
  //   debugPrint('[MessagingApiService.getLikedTracks] GET $uri');
  //   final res = await _client.get(uri, headers: _headers(token));
  //   final preview = res.body.length > 400 ? res.body.substring(0, 400) : res.body;
  //   debugPrint('[MessagingApiService.getLikedTracks] status=${res.statusCode} bodyPreview=$preview');
  //   final data = _decode(res);
  //   if (res.statusCode == 200 && data is Map) {
  //     final rawData = data['data'];
  //     debugPrint('[MessagingApiService.getLikedTracks] data["data"] runtimeType=${rawData.runtimeType} value=$rawData');
  //     final list = _extractTrackList(rawData);
  //     debugPrint('[MessagingApiService.getLikedTracks] extracted ${list.length} items');
  //     return list
  //         .whereType<Map<String, dynamic>>()
  //         .map(PlaybackTrackModel.fromApiJson)
  //         .toList();
  //   }
  //   debugPrint('[MessagingApiService.getLikedTracks] Non-200 or bad body. status=${res.statusCode}');
  //   return [];
  // }


    // GET /api/public/tracks/v1/liked/{userId}
    // GET /api/public/tracks/v1/liked/{userId}
  Future<List<PlaybackTrackModel>> getLikedTracks({
    required String userId,
  }) async {
    try {
      final token = await _token();
      final uri = Uri.parse('$_tracksBase/liked/$userId');
      
      print('📤 [DEBUG] GET $uri');
      print('📤 [DEBUG] Headers: ${_headers(token)}');
      
      final res = await _client.get(uri, headers: _headers(token));
      
      print('📥 [DEBUG] Status: ${res.statusCode}');
      print('📥 [DEBUG] Body: ${res.body}');
      
      final data = _decode(res);
      
      if (res.statusCode == 200 && data is Map) {
        final rawData = data['data'];
        print('📥 [DEBUG] data["data"] type: ${rawData?.runtimeType}');
        final list = _extractTrackList(rawData);
        print('✅ Extracted ${list.length} liked tracks');
        return list
            .whereType<Map<String, dynamic>>()
            .map(PlaybackTrackModel.fromApiJson)
            .toList();
      }
      
      // ⚠️ WORKAROUND: Return empty list on 500 (backend bug)
      if (res.statusCode == 500) {
        print('⚠️ [DEBUG] 500: Backend error on liked tracks — returning empty list');
        print('📌 [DEBUG] This is a known backend issue for userId=$userId');
        return [];
      }
      
      // Handle 404 - user not found
      if (res.statusCode == 404) {
        print('⚠️ [DEBUG] 404: User $userId not found');
        return [];
      }
      
      throw Exception(
          (data is Map ? data['message']?.toString() : null) ??
              'Failed to load liked tracks: ${res.statusCode}');
    } catch (e, stack) {
      print('💥 [ERROR] getLikedTracks: $e');
      print('📍 Stack: $stack');
      rethrow;
    }
  }

  // GET /api/public/tracks/v1/user/{userId}
  // Future<List<PlaybackTrackModel>> getUserPostedTracks({
  //   required String userId,
  // }) async {
  //   final token = await _token();
  //   final uri = Uri.parse('$_tracksBase/user/$userId');
  //   debugPrint('[MessagingApiService.getUserPostedTracks] GET $uri');
  //   final res = await _client.get(uri, headers: _headers(token));
  //   final preview = res.body.length > 400 ? res.body.substring(0, 400) : res.body;
  //   debugPrint('[MessagingApiService.getUserPostedTracks] status=${res.statusCode} bodyPreview=$preview');
  //   final data = _decode(res);
  //   if (res.statusCode == 200 && data is Map) {
  //     final rawData = data['data'];
  //     debugPrint('[MessagingApiService.getUserPostedTracks] data["data"] runtimeType=${rawData.runtimeType}');
  //     final list = _extractTrackList(rawData);
  //     debugPrint('[MessagingApiService.getUserPostedTracks] extracted ${list.length} items');
  //     return list
  //         .whereType<Map<String, dynamic>>()
  //         .map(PlaybackTrackModel.fromApiJson)
  //         .toList();
  //   }
  //   debugPrint('[MessagingApiService.getUserPostedTracks] Non-200 or bad body. status=${res.statusCode}');
  //   return [];
  // }

    // GET /api/public/tracks/v1/user/{userId}
    // GET /api/public/tracks/v1/posted/{userId}
  Future<List<PlaybackTrackModel>> getUserPostedTracks({
    required String userId,
  }) async {
    try {
      final token = await _token();
      
      // ✅ CORRECTED: Use /posted/{id} as per API documentation
      final uri = Uri.parse('${_apiServices.baseUrl}/api/public/tracks/v1/posted/$userId');
      
      print('📤 [DEBUG] GET $uri');
      print('📤 [DEBUG] Headers: ${_headers(token)}');
      
      final res = await _client.get(uri, headers: _headers(token));
      
      print('📥 [DEBUG] Status: ${res.statusCode}');
      print('📥 [DEBUG] Body: ${res.body}');
      
      final data = _decode(res);
      
      if (res.statusCode == 200 && data is Map) {
        final rawData = data['data'];
        print('📥 [DEBUG] data["data"] type: ${rawData?.runtimeType}');
        final list = _extractTrackList(rawData);
        print('✅ Extracted ${list.length} uploaded tracks');
        return list
            .whereType<Map<String, dynamic>>()
            .map(PlaybackTrackModel.fromApiJson)
            .toList();
      }
      
      // Handle 404 - user not found or has no public tracks
      if (res.statusCode == 404) {
        print('⚠️ [DEBUG] 404: User $userId not found or has no public tracks');
        return []; // Return empty list instead of throwing
      }
      
      throw Exception(
          (data is Map ? data['message']?.toString() : null) ??
              'Failed to load uploaded tracks: ${res.statusCode}');
    } catch (e, stack) {
      print('💥 [ERROR] getUserPostedTracks: $e');
      print('📍 Stack: $stack');
      rethrow;
    }
  }

  /// Handles the API returning data as:
  ///   List directly            → [{...}, {...}]
  ///   Map with "tracks" key    → {"tracks": [...], ...}
  ///   Map with "data" key      → {"data": [...], ...}
  ///   Nested paginationInfo    → {"tracks": [...], "paginationInfo": {...}}
  List<dynamic> _extractTrackList(dynamic rawData) {
    if (rawData is List) return rawData;
    if (rawData is Map) {
      if (rawData['tracks'] is List) {
        debugPrint('[MessagingApiService._extractTrackList] Found tracks under "tracks" key: ${(rawData["tracks"] as List).length} items');
        return rawData['tracks'] as List;
      }
      if (rawData['data'] is List) {
        debugPrint('[MessagingApiService._extractTrackList] Found tracks under nested "data" key: ${(rawData["data"] as List).length} items');
        return rawData['data'] as List;
      }
      debugPrint('[MessagingApiService._extractTrackList] Map keys: ${rawData.keys.toList()}');
    }
    return [];
  }

  // GET /api/public/tracks/v1/permalink/{permalink}
  Future<PlaybackTrackModel?> getTrackByPermalink({
    required String permalink,
  }) async {
    final uri = Uri.parse('$_tracksBase/permalink/$permalink');
    final res = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'Android',
    });
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final inner = data['data'] as Map<String, dynamic>? ?? {};
      if (inner.isNotEmpty) return PlaybackTrackModel.fromApiJson(inner);
    }
    return null;
  }

  // GET /api/public/tracks/v1/{trackId} — returns permalink
  Future<String?> getTrackPermalink({required String trackId}) async {
    final uri = Uri.parse('$_tracksBase/$trackId');
    final res = await _client.get(uri, headers: {
      'Content-Type': 'application/json',
      'User-Agent': 'Android',
    });
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final inner = data['data'] as Map<String, dynamic>? ?? {};
      final basic = inner['basicInfo'] as Map<String, dynamic>? ?? {};
      final pl = basic['permalink']?.toString() ?? '';
      return pl.isEmpty ? null : pl;
    }
    return null;
  }
}
