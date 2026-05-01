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
  }) : _apiServices = apiServices ?? ApiServices(),
       _client = client ?? http.Client(),
       _authApiService = authApiService ?? AuthApiService() {
    _msgBase = '${_apiServices.baseUrl}/api/messages/v1';
    _tracksBase = '${_apiServices.baseUrl}/api/tracks/v1';
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
    'accept': 'application/json',
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
    final uri = Uri.parse(
      '$_msgBase/chats',
    ).replace(queryParameters: {'limit': '$limit'});
    debugPrint('[getChats] GET $uri');
    final res = await _client.get(uri, headers: _headers(token));
    debugPrint('[getChats] status=${res.statusCode}');
    debugPrint(
      '[getChats] raw body=${res.body.length > 600 ? res.body.substring(0, 600) : res.body}',
    );
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final rawList = data['data'];
      debugPrint('[getChats] data["data"] runtimeType=${rawList.runtimeType}');
      final list = (rawList as List<dynamic>? ?? []);
      debugPrint('[getChats] ${list.length} items in list');
      final chats = <ChatModel>[];
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is Map<String, dynamic>) {
          // Log EVERY key so we can see the full structure
          debugPrint('[getChats] item[$i] ALL KEYS: ${item.keys.toList()}');
          for (final k in item.keys) {
            final v = item[k];
            if (v is! List && v is! Map) {
              debugPrint('[getChats] item[$i]   "$k" = $v');
            } else if (v is List) {
              debugPrint(
                '[getChats] item[$i]   "$k" = List(${v.length}) first=${v.isEmpty ? "empty" : v.first}',
              );
            } else {
              debugPrint(
                '[getChats] item[$i]   "$k" = Map keys=${(v as Map).keys.toList()}',
              );
            }
          }
          final chat = ChatModel.fromJson(item);
          debugPrint(
            '[getChats] item[$i] → parsed chat.id="${chat.id}" participants=${chat.participants}',
          );
          chats.add(chat);
        } else {
          debugPrint(
            '[getChats] item[$i] NOT A MAP — type=${item.runtimeType} value=$item',
          );
        }
      }
      return chats;
    }
    throw Exception(
      (data is Map ? data['message']?.toString() : null) ??
          'Failed to load chats',
    );
  }

  // GET /api/messages/v1/chat/message/{chatId}
  Future<
    ({
      List<MessageModel> messages,
      bool isReceiverBlocked,
      bool isBlockedByReceiver,
    })
  >
  getChatMessages({
    required String chatId,
    int limit = 20,
    String? before,
  }) async {
    debugPrint('━━━ [getChatMessages] ━━━');
    debugPrint('[getChatMessages] chatId="$chatId" (empty=${chatId.isEmpty})');
    final token = await _token();
    final params = <String, String>{'limit': '$limit'};
    if (before != null && before.isNotEmpty) params['before'] = before;
    final uri = Uri.parse(
      '$_msgBase/chat/message/$chatId',
    ).replace(queryParameters: params);
    debugPrint('[getChatMessages] GET $uri');
    final res = await _client.get(uri, headers: _headers(token));
    debugPrint(
      '[getChatMessages] status=${res.statusCode} body=${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
    );
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
      final isReceiverBlocked = inner['isReceiverBlocked'] == true;
      debugPrint(
        '[getChatMessages] isReceiverBlocked=$isReceiverBlocked  isBlockedByReceiver=$isBlockedByReceiver',
      );
      return (
        messages: msgList
            .whereType<Map<String, dynamic>>()
            .map(MessageModel.fromJson)
            .toList(),
        isReceiverBlocked: isReceiverBlocked,
        isBlockedByReceiver: isBlockedByReceiver,
      );
    }
    throw Exception(
      (data is Map ? data['message']?.toString() : null) ??
          'Failed to load messages',
    );
  }

  // Find an existing chat that includes receiverId in its participants array.
  // The GET /chats API now returns participants: [userId1, userId2], so we
  // can find the right chat in a single request with no deep message scanning.
  Future<String?> findOrCreateChat({required String receiverId}) async {
    try {
      final token = await _token();
      final uri = Uri.parse(
        '$_msgBase/chats',
      ).replace(queryParameters: {'limit': '100'});
      debugPrint(
        '[MessagingApiService.findOrCreateChat] GET $uri receiverId=$receiverId',
      );
      final res = await _client.get(uri, headers: _headers(token));
      final data = _decode(res);
      if (res.statusCode != 200 || data is! Map) {
        debugPrint(
          '[MessagingApiService.findOrCreateChat] chats fetch failed: ${res.statusCode}',
        );
        return null;
      }
      final list = (data['data'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      debugPrint(
        '[MessagingApiService.findOrCreateChat] ${list.length} chats to search',
      );

      for (final item in list) {
        // Key is "chat" in current API; fall back to chatId / _id / id
        String chatId = '';
        for (final key in ['chat', 'chatId', '_id', 'id']) {
          final v = item[key]?.toString() ?? '';
          if (v.isNotEmpty) {
            chatId = v;
            break;
          }
        }
        if (chatId.isEmpty) continue;

        // Participants are full user objects — extract _id strings
        final participantIds = <String>[];
        final rawP = item['participants'];
        if (rawP is List) {
          for (final p in rawP) {
            if (p is String && p.isNotEmpty) {
              participantIds.add(p);
            } else if (p is Map) {
              final pid = p['_id']?.toString() ?? p['id']?.toString() ?? '';
              if (pid.isNotEmpty) participantIds.add(pid);
            }
          }
        }
        debugPrint(
          '[MessagingApiService.findOrCreateChat] chatId=$chatId participantIds=$participantIds',
        );

        if (participantIds.contains(receiverId)) {
          debugPrint(
            '[MessagingApiService.findOrCreateChat] ✅ Match via participants. chatId=$chatId',
          );
          return chatId;
        }
      }

      debugPrint(
        '[MessagingApiService.findOrCreateChat] No existing chat found — will create new',
      );
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
    debugPrint(
      '[sendMessage] status=${res.statusCode} body=${res.body.length > 300 ? res.body.substring(0, 300) : res.body}',
    );
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return ChatModel.fromJson(inner);
    }
    final errorMsg =
        (data is Map ? data['message']?.toString() : null) ??
        'Failed to send message';
    debugPrint(
      '[sendMessage] ERROR → status=${res.statusCode} message="$errorMsg"',
    );
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
            'Failed to archive chat',
      );
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
      final uri = Uri.parse('$_msgBase/chat/read');

      // ✅ FIXED: Backend expects 'id', not 'chatId'
      final requestBody = {'id': chatId};

      // 🔍 DEBUG: Log exact request
      debugPrint('📤 [DEBUG] PATCH $uri');
      debugPrint('📤 [DEBUG] Body: ${jsonEncode(requestBody)}');

      final response = await _client.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(requestBody),
      );

      // 🔍 DEBUG: Log response
      debugPrint('📥 [DEBUG] Status: ${response.statusCode}');
      debugPrint('📥 [DEBUG] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Chat $chatId marked as read');
        return;
      }

      // Handle errors
      switch (response.statusCode) {
        case 400:
          final data = _decode(response);
          final msg = data is Map
              ? data['message'] ?? 'Validation failed'
              : 'Bad Request';
          throw Exception('Invalid request: $msg');
        case 401:
          throw Exception('Unauthorized: Token invalid/expired');
        case 404:
          throw Exception('Endpoint not found: $uri');
        default:
          throw Exception('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('💥 [ERROR] markChatAsRead: $e');
      debugPrint('📍 Stack: $stack');
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
      final uri = Uri.parse('$_msgBase/chat/unread');

      // ✅ Body: Backend expects 'id' field (same as markChatAsRead)
      final requestBody = {'id': chatId};

      // 🔍 DEBUG: Log outgoing request
      debugPrint('📤 [DEBUG] PATCH $uri');
      debugPrint('📤 [DEBUG] Body: ${jsonEncode(requestBody)}');
      debugPrint('📤 [DEBUG] Headers: ${_headers(token)}');

      final response = await _client.patch(
        uri,
        headers: _headers(token),
        body: jsonEncode(requestBody),
      );

      // 🔍 DEBUG: Log incoming response
      debugPrint('📥 [DEBUG] Status: ${response.statusCode}');
      debugPrint('📥 [DEBUG] Body: ${response.body}');
      debugPrint('📥 [DEBUG] Headers: ${response.headers}');

      // ✅ Handle success codes
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ Chat $chatId marked as unread successfully');
        return;
      }

      // ❌ Handle error codes with specific messages
      switch (response.statusCode) {
        case 400:
          final data = _decode(response);
          final errors = data is Map ? data['errors'] : null;
          final msg = data is Map
              ? data['message'] ?? 'Validation failed'
              : 'Bad Request';

          if (errors is List) {
            debugPrint('⚠️ [DEBUG] Validation errors: $errors');
          }
          throw Exception('Invalid request: $msg');

        case 401:
          throw Exception('Unauthorized: Token invalid or expired');
        case 403:
          throw Exception(
            'Forbidden: You do not have permission for this action',
          );
        case 404:
          throw Exception('Endpoint not found: $uri');
        default:
          throw Exception('Failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('💥 [ERROR] markChatAsUnread failed: $e');
      debugPrint('📍 Stack: $stack');
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

      debugPrint('📤 [DEBUG] GET $uri');
      debugPrint('📤 [DEBUG] Headers: ${_headers(token)}');

      final res = await _client.get(uri, headers: _headers(token));

      debugPrint('📥 [DEBUG] Status: ${res.statusCode}');
      debugPrint('📥 [DEBUG] Body: ${res.body}');

      final data = _decode(res);

      if (res.statusCode == 200 && data is Map) {
        final rawData = data['data'];
        debugPrint('📥 [DEBUG] data["data"] type: ${rawData?.runtimeType}');
        final list = _extractTrackList(rawData);
        debugPrint('✅ Extracted ${list.length} liked tracks');
        return list
            .whereType<Map<String, dynamic>>()
            .map(PlaybackTrackModel.fromApiJson)
            .toList();
      }

      // ⚠️ WORKAROUND: Return empty list on 500 (backend bug)
      if (res.statusCode == 500) {
        debugPrint(
          '⚠️ [DEBUG] 500: Backend error on liked tracks — returning empty list',
        );
        debugPrint(
          '📌 [DEBUG] This is a known backend issue for userId=$userId',
        );
        return [];
      }

      // Handle 404 - user not found
      if (res.statusCode == 404) {
        debugPrint('⚠️ [DEBUG] 404: User $userId not found');
        return [];
      }

      throw Exception(
        (data is Map ? data['message']?.toString() : null) ??
            'Failed to load liked tracks: ${res.statusCode}',
      );
    } catch (e, stack) {
      debugPrint('💥 [ERROR] getLikedTracks: $e');
      debugPrint('📍 Stack: $stack');
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
  // GET /api/public/tracks/v2/posted/{userId}
  Future<List<PlaybackTrackModel>> getUserPostedTracks({
    required String userId,
  }) async {
    try {
      final token = await _token();

      final uri = Uri.parse('$_tracksBase/posted/$userId');

      debugPrint('📤 [DEBUG] GET $uri');
      debugPrint('📤 [DEBUG] Headers: ${_headers(token)}');

      final res = await _client.get(uri, headers: _headers(token));

      debugPrint('📥 [DEBUG] Status: ${res.statusCode}');
      debugPrint('📥 [DEBUG] Body: ${res.body}');

      final data = _decode(res);

      if (res.statusCode == 200 && data is Map) {
        final rawData = data['data'];
        debugPrint('📥 [DEBUG] data["data"] type: ${rawData?.runtimeType}');
        final list = _extractTrackList(rawData);
        debugPrint('✅ Extracted ${list.length} uploaded tracks');
        return list
            .whereType<Map<String, dynamic>>()
            .map(PlaybackTrackModel.fromApiJson)
            .toList();
      }

      // Handle 404 - user not found or has no public tracks
      if (res.statusCode == 404) {
        debugPrint(
          '⚠️ [DEBUG] 404: User $userId not found or has no public tracks',
        );
        return []; // Return empty list instead of throwing
      }

      throw Exception(
        (data is Map ? data['message']?.toString() : null) ??
            'Failed to load uploaded tracks: ${res.statusCode}',
      );
    } catch (e, stack) {
      debugPrint('💥 [ERROR] getUserPostedTracks: $e');
      debugPrint('📍 Stack: $stack');
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
        debugPrint(
          '[MessagingApiService._extractTrackList] Found tracks under "tracks" key: ${(rawData["tracks"] as List).length} items',
        );
        return rawData['tracks'] as List;
      }
      if (rawData['data'] is List) {
        debugPrint(
          '[MessagingApiService._extractTrackList] Found tracks under nested "data" key: ${(rawData["data"] as List).length} items',
        );
        return rawData['data'] as List;
      }
      debugPrint(
        '[MessagingApiService._extractTrackList] Map keys: ${rawData.keys.toList()}',
      );
    }
    return [];
  }

  // GET /api/profile/v1/{userId} — returns blockingMe field (private endpoint).
  Future<bool> getProfileBlockingMe({required String userId}) async {
    debugPrint('━━━ [getProfileBlockingMe] ━━━');
    if (userId.isEmpty) {
      debugPrint('[getProfileBlockingMe] ❌ Empty userId — aborting');
      return false;
    }
    try {
      final token = await _token();
      final uri = Uri.parse('${_apiServices.baseUrl}/api/profile/v1/$userId');
      debugPrint('[getProfileBlockingMe] GET $uri');
      final res = await _client.get(uri, headers: _headers(token));
      debugPrint('[getProfileBlockingMe] status=${res.statusCode}');
      debugPrint(
        '[getProfileBlockingMe] body=${res.body.length > 500 ? "${res.body.substring(0, 500)}...(truncated)" : res.body}',
      );
      final data = _decode(res);
      if (res.statusCode != 200 || data is! Map) {
        debugPrint(
          '[getProfileBlockingMe] ❌ Non-200 or non-Map. status=${res.statusCode}',
        );
        return false;
      }
      final blockingMe = data['amIBlocked'] == true;
      debugPrint('[getProfileBlockingMe] ✅ amIBlocked=$blockingMe');
      return blockingMe;
    } catch (e) {
      debugPrint('[getProfileBlockingMe] ❌ EXCEPTION: $e');
      return false;
    }
  }

  // GET /api/public/profile/v1/{userId} — returns the user's profileLink slug
  Future<String?> getUserProfileLink({required String userId}) async {
    debugPrint('━━━ [getUserProfileLink] ━━━');
    debugPrint(
      '[getUserProfileLink] userId="$userId" (empty=${userId.isEmpty})',
    );
    if (userId.isEmpty) {
      debugPrint('[getUserProfileLink] ❌ Empty userId — aborting');
      return null;
    }
    final token = await _token();
    final uri = Uri.parse(
      '${_apiServices.baseUrl}/api/profile/v1/$userId',
    );
    debugPrint('[getUserProfileLink] GET $uri');
    final res = await _client.get(uri, headers: _headers(token));
    debugPrint('[getUserProfileLink] status=${res.statusCode}');
    debugPrint(
      '[getUserProfileLink] body=${res.body.length > 500 ? "${res.body.substring(0, 500)}...(truncated)" : res.body}',
    );
    final data = _decode(res);
    if (res.statusCode != 200 || data is! Map) {
      debugPrint(
        '[getUserProfileLink] ❌ Non-200 or non-Map. status=${res.statusCode}',
      );
      return null;
    }
    final profileLink = data['profileLink']?.toString().trim() ?? '';
    debugPrint('[getUserProfileLink] ✅ profileLink="$profileLink"');
    return profileLink.isEmpty ? null : profileLink;
  }

  // GET /api/public/tracks/v2/permalink/{profileLink}/{permalink}
  // Public endpoint — requires the track owner's profile slug AND the track's permalink.
  // profileLink is fetched once at attach-time via getUserProfileLink and stored in the
  // message body so both sender and receiver use the same value.
  Future<PlaybackTrackModel?> getTrackByPermalink({
    required String profileLink,
    required String permalink,
  }) async {
    debugPrint('━━━ [getTrackByPermalink] ━━━');
    debugPrint(
      '[getTrackByPermalink] profileLink="$profileLink"  permalink="$permalink"',
    );
    if (profileLink.isEmpty) {
      debugPrint(
        '[getTrackByPermalink] ❌ profileLink is empty — cannot call API. Was it fetched correctly?',
      );
      return null;
    }
    if (permalink.isEmpty) {
      debugPrint('[getTrackByPermalink] ❌ permalink is empty — aborting');
      return null;
    }
    // Public endpoint — no auth header needed, but include it anyway for consistency
    final token = await _token();
    final uri = Uri.parse(
      '${_apiServices.baseUrl}/api/public/tracks/v2/permalink/$profileLink/$permalink',
    );
    debugPrint('[getTrackByPermalink] GET $uri');
    final res = await _client.get(uri, headers: _headers(token));
    debugPrint('[getTrackByPermalink] status=${res.statusCode}');
    debugPrint(
      '[getTrackByPermalink] body=${res.body.length > 1000 ? "${res.body.substring(0, 1000)}...(truncated)" : res.body}',
    );
    final data = _decode(res);
    if (res.statusCode != 200 || data is! Map) {
      debugPrint(
        '[getTrackByPermalink] ❌ Non-200 or non-Map. status=${res.statusCode} dataType=${data.runtimeType}',
      );
      return null;
    }
    debugPrint('[getTrackByPermalink] response keys=${data.keys.toList()}');
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    debugPrint(
      '[getTrackByPermalink] data["data"] keys=${inner.keys.toList()} (empty=${inner.isEmpty})',
    );
    if (inner.isEmpty) {
      debugPrint('[getTrackByPermalink] ❌ data["data"] is empty');
      return null;
    }
    final basicInfo = inner['basicInfo'] as Map<String, dynamic>? ?? {};
    final audio = inner['audio'] as Map<String, dynamic>? ?? {};
    final image = inner['image'] as Map<String, dynamic>? ?? {};
    debugPrint(
      '[getTrackByPermalink] trackId="${inner['trackId']}"  posterId="${inner['posterId']}"',
    );
    debugPrint(
      '[getTrackByPermalink] basicInfo.title="${basicInfo['title']}"  basicInfo.permalink="${basicInfo['permalink']}"',
    );
    debugPrint(
      '[getTrackByPermalink] basicInfo.mainArtists=${basicInfo['mainArtists']}',
    );
    debugPrint('[getTrackByPermalink] audio.audioLink="${audio['audioLink']}"');
    debugPrint('[getTrackByPermalink] image.imgLink="${image['imgLink']}"');
    debugPrint(
      '[getTrackByPermalink] durationInSeconds="${inner['durationInSeconds']}"',
    );
    final track = PlaybackTrackModel.fromApiJson(inner);
    debugPrint(
      '[getTrackByPermalink] ✅ parsed → id="${track.id}" title="${track.title}" artist="${track.artistName}"',
    );
    debugPrint(
      '[getTrackByPermalink]    audioUrl="${track.audioUrl}"  artworkUrl="${track.artworkUrl}"  permalink="${track.permalink}"',
    );
    return track;
  }

  // GET /api/tracks/v1/{trackId} — returns full track model by database ID
  Future<PlaybackTrackModel?> getTrackById({required String trackId}) async {
    debugPrint('━━━ [getTrackById] ━━━');
    debugPrint('[getTrackById] trackId="$trackId" (empty=${trackId.isEmpty})');
    if (trackId.isEmpty) {
      debugPrint('[getTrackById] ❌ Empty trackId — aborting');
      return null;
    }
    final token = await _token();
    final uri = Uri.parse('$_tracksBase/$trackId');
    debugPrint('[getTrackById] GET $uri');
    final res = await _client.get(uri, headers: _headers(token));
    debugPrint('[getTrackById] status=${res.statusCode}');
    debugPrint(
      '[getTrackById] body=${res.body.length > 1000 ? "${res.body.substring(0, 1000)}...(truncated)" : res.body}',
    );
    final data = _decode(res);
    if (res.statusCode != 200 || data is! Map) {
      debugPrint(
        '[getTrackById] ❌ Non-200 or non-Map. status=${res.statusCode} dataType=${data.runtimeType}',
      );
      return null;
    }
    debugPrint('[getTrackById] response keys=${data.keys.toList()}');
    final inner = data['data'] as Map<String, dynamic>? ?? {};
    debugPrint(
      '[getTrackById] data["data"] keys=${inner.keys.toList()} (empty=${inner.isEmpty})',
    );
    if (inner.isEmpty) {
      debugPrint('[getTrackById] ❌ data["data"] is empty');
      return null;
    }
    final basicInfo = inner['basicInfo'] as Map<String, dynamic>? ?? {};
    final audio = inner['audio'] as Map<String, dynamic>? ?? {};
    final image = inner['image'] as Map<String, dynamic>? ?? {};
    debugPrint(
      '[getTrackById] trackId="${inner['trackId']}"  posterId="${inner['posterId']}"',
    );
    debugPrint(
      '[getTrackById] title="${basicInfo['title']}"  permalink="${basicInfo['permalink']}"',
    );
    debugPrint('[getTrackById] audio.audioLink="${audio['audioLink']}"');
    debugPrint('[getTrackById] image.imgLink="${image['imgLink']}"');
    final track = PlaybackTrackModel.fromApiJson(inner);
    debugPrint(
      '[getTrackById] ✅ parsed → id="${track.id}" title="${track.title}" artist="${track.artistName}" audioUrl="${track.audioUrl}"',
    );
    return track;
  }

  // GET /api/public/tracks/v1/{trackId} — returns permalink
  Future<String?> getTrackPermalink({required String trackId}) async {
    final uri = Uri.parse('$_tracksBase/$trackId');
    final res = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json', 'User-Agent': 'Android'},
    );
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
