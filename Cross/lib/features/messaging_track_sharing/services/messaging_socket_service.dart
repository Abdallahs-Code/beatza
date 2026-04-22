import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class MessagingSocketService {
  MessagingSocketService._shared();
  static final MessagingSocketService shared = MessagingSocketService._shared();

  io.Socket? _socket;
  String? _currentToken;

  // Called when a new message arrives in a chat the user is NOT viewing
  void Function(ChatModel chat)? onMessageNotify;

  // Called when a new message arrives in the chat room the user IS viewing
  void Function(ChatModel chat)? onMessageInRoom;

  // Called on socket errors
  void Function(String message)? onError;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({required String token}) async {
    if (_socket != null && _currentToken == token) {
      if (!isConnected) _socket?.connect();
      _rebindListeners();
      return;
    }

    disconnect();
    _currentToken = token;

    final socket = io.io(
      ApiServices().baseUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(100000)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setTimeout(20000)
          .setQuery(<String, String>{'token': token})
          .setExtraHeaders(<String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'User-Agent': 'Android',
            'token': token,
          })
          .build(),
    );

    _socket = socket;
    _rebindListeners();

    socket.onConnect((_) {});
    socket.onDisconnect((_) {});
    socket.onConnectError((_) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (_socket == socket && !socket.connected) socket.connect();
      });
    });

    socket.connect();
  }

  void _rebindListeners() {
    final s = _socket;
    if (s == null) return;

    s.off('message:notify');
    s.off('message:send');
    s.off('error');

    s.on('message:notify', (dynamic data) {
      if (data is Map) {
        try {
          final chat = ChatModel.fromJson(Map<String, dynamic>.from(data));
          onMessageNotify?.call(chat);
        } catch (_) {}
      }
    });

    s.on('message:send', (dynamic data) {
      if (data is Map) {
        try {
          final chat = ChatModel.fromJson(Map<String, dynamic>.from(data));
          onMessageInRoom?.call(chat);
        } catch (_) {}
      }
    });

    s.on('error', (dynamic data) {
      if (data is Map) {
        onError?.call(data['message']?.toString() ?? 'Socket error');
      }
    });
  }

  void joinChat(String chatId) {
    _socket?.emit('chat:join', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _socket?.emit('chat:leave', {'chatId': chatId});
  }

  void sendMessage({required String chatId, required String content}) {
    _socket?.emit('message:send', {'chatId': chatId, 'content': content});
  }

  void disconnect() {
    _socket?.off('message:notify');
    _socket?.off('message:send');
    _socket?.off('error');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentToken = null;
  }
}
