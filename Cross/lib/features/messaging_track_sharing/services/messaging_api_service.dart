import 'dart:convert';
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
  Future<({List<MessageModel> messages, bool isReceiverBlocked})>
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
      final msgList = inner['messages'] as List<dynamic>? ?? [];
      return (
        messages: msgList
            .whereType<Map<String, dynamic>>()
            .map(MessageModel.fromJson)
            .toList(),
        isReceiverBlocked: inner['isReceiverBlocked'] == true,
      );
    }
    throw Exception(
        (data is Map ? data['message']?.toString() : null) ??
            'Failed to load messages');
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
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return ChatModel.fromJson(inner);
    }
    throw Exception(
        (data is Map ? data['message']?.toString() : null) ??
            'Failed to send message');
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
  Future<void> markChatAsRead({required String chatId}) async {
    final token = await _token();
    final uri = Uri.parse('$_msgBase/chat/read/$chatId');
    await _client.patch(
      uri,
      headers: _headers(token),
      body: jsonEncode({'chatId': chatId}),
    );
  }

  // PATCH /api/messages/v1/chat/unread/{chatId}
  Future<void> markChatAsUnread({required String chatId}) async {
    final token = await _token();
    final uri = Uri.parse('$_msgBase/chat/unread/$chatId');
    await _client.patch(
      uri,
      headers: _headers(token),
      body: jsonEncode({'chatId': chatId}),
    );
  }

  // GET /api/public/tracks/v1/liked/{userId}
  Future<List<PlaybackTrackModel>> getLikedTracks({
    required String userId,
  }) async {
    final token = await _token();
    final uri = Uri.parse('$_tracksBase/liked/$userId');
    final res = await _client.get(uri, headers: _headers(token));
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(PlaybackTrackModel.fromApiJson)
          .toList();
    }
    return [];
  }

  // GET /api/public/tracks/v1/user/{userId}
  Future<List<PlaybackTrackModel>> getUserPostedTracks({
    required String userId,
  }) async {
    final token = await _token();
    final uri = Uri.parse('$_tracksBase/user/$userId');
    final res = await _client.get(uri, headers: _headers(token));
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map) {
      final list = data['data'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(PlaybackTrackModel.fromApiJson)
          .toList();
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
