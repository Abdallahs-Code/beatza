import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class ActivityNotificationsSocketService {
  ActivityNotificationsSocketService._shared();

  static final ActivityNotificationsSocketService shared =
      ActivityNotificationsSocketService._shared();

  io.Socket? _socket;
  String? _currentToken;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({
    required String token,
    required void Function(ActivityNotificationModel notification)
        onNotification,
    void Function()? onReconnect,
  }) async {
    if (_socket != null && _currentToken == token) {
      _socket!
        ..off('notification:receive')
        ..on('notification:receive', (dynamic data) {
          _handleIncoming(data, onNotification);
        });

      if (!(_socket?.connected ?? false)) {
        _socket?.connect();
      }
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

    socket.off('notification:receive');
    socket.on('notification:receive', (dynamic data) {
      _handleIncoming(data, onNotification);
    });

    socket.onReconnect((_) {
      onReconnect?.call();
    });

    socket.onReconnectAttempt((_) {});

    socket.onConnect((_) {});

    socket.onDisconnect((_) {});

    socket.onConnectError((_) {
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (_socket == socket && !(socket.connected)) {
          socket.connect();
        }
      });
    });

    socket.onError((_) {});

    socket.connect();
  }

  void _handleIncoming(
    dynamic data,
    void Function(ActivityNotificationModel notification) onNotification,
  ) {
    try {
      if (data is Map) {
        final notification = ActivityNotificationModel.fromJson(
          Map<String, dynamic>.from(data),
        );
        onNotification(notification);
      }
    } catch (_) {}
  }

  void disconnect() {
    _socket?.off('notification:receive');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentToken = null;
  }
}