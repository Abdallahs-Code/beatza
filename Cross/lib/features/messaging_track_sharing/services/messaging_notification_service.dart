import 'package:cross_team5/features/activity/services/push_notification_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_socket_service.dart';
import 'package:flutter/foundation.dart';

class MessagingNotificationService {
  MessagingNotificationService._shared();
  static final MessagingNotificationService shared =
      MessagingNotificationService._shared();

  String? _currentUserId;
  String? _activeChatId;

  /// Call once after login (or on HomeScreen init).
  Future<void> initialize() async {
    _currentUserId = await AuthApiService().getStoredUserId();
    final token = await AuthApiService().getStoredAccessToken() ?? '';

    debugPrint('[MessagingNotificationService] initialize — userId=$_currentUserId');

    if (token.isEmpty) {
      debugPrint('[MessagingNotificationService] No token — skipping socket connect');
      return;
    }

    await MessagingSocketService.shared.connect(token: token);
    MessagingSocketService.shared.onMessageNotifyPush = _onIncoming;
    debugPrint('[MessagingNotificationService] Listening for push notifications');
  }

  /// Call on logout so we stop showing notifications.
  void reset() {
    _currentUserId = null;
    _activeChatId = null;
    MessagingSocketService.shared.onMessageNotifyPush = null;
    debugPrint('[MessagingNotificationService] reset');
  }

  /// ChatScreen calls this with its chatId when it opens, and null when it closes.
  void setActiveChatId(String? chatId) {
    _activeChatId = chatId;
    debugPrint('[MessagingNotificationService] activeChatId=$chatId');
  }

  void _onIncoming(ChatModel chat) {
    final lm = chat.lastMessage;
    if (lm == null) return;

    // Don't notify for own messages
    if (lm.senderId == _currentUserId) return;

    // Don't notify if the user is already looking at this chat
    if (_activeChatId != null && _activeChatId == chat.id) return;

    final senderName = chat.otherPerson?.displayName ?? 'New message';
    debugPrint('[MessagingNotificationService] Showing push for chatId=${chat.id} from="$senderName" content="${lm.content}"');

    PushNotificationService.shared.showMessage(
      senderName: senderName,
      content: lm.content,
      chatId: chat.id,
    );
  }
}
