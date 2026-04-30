import 'package:cross_team5/features/activity/services/push_notification_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/models/follower.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';
import 'package:cross_team5/features/library/services/notification_settings_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/models/chat_model.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_socket_service.dart';
import 'package:flutter/foundation.dart';

class MessagingNotificationService {
  MessagingNotificationService._shared();
  static final MessagingNotificationService shared =
      MessagingNotificationService._shared();

  String? _currentUserId;
  String? _activeChatId;

  // "everyone" | "followed" | "off"  — mirrors the backend setting.
  // Defaults to "everyone" so notifications always appear until the setting loads.
  String _newMessageDevicesSetting = 'everyone';

  // IDs of users the current user follows — used for the "followed" filter.
  Set<String> _followedUserIds = {};

  /// Call once after login (or on HomeScreen init).
  Future<void> initialize() async {
    _currentUserId = await AuthApiService().getStoredUserId();
    final token = await AuthApiService().getStoredAccessToken() ?? '';

    debugPrint(
      '[MessagingNotificationService] initialize — userId=$_currentUserId',
    );

    if (token.isEmpty) {
      debugPrint(
        '[MessagingNotificationService] No token — skipping socket connect',
      );
      return;
    }

    // Load notification preference and following list in parallel.
    // Failures are silenced — we fall back to showing all notifications.
    await Future.wait([
      _loadDeviceSetting(token),
      _loadFollowingList(),
    ]);

    await MessagingSocketService.shared.connect(token: token);
    MessagingSocketService.shared.onMessageNotifyPush = _onIncoming;
    debugPrint(
      '[MessagingNotificationService] Listening for push notifications',
    );
  }

  Future<void> _loadDeviceSetting(String token) async {
    try {
      final settings =
          await NotificationSettingsApiService().getSettings(token);
      _newMessageDevicesSetting = settings.newMessageDevices;
    } catch (_) {}
  }

  Future<void> _loadFollowingList() async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) return;
      final result =
          await SocialApiService().getFollowing(userId: userId);
      if (result.$1 == 200 && result.$2 is List) {
        _followedUserIds = (result.$2 as List)
            .whereType<Follower>()
            .map((f) => f.userId.trim())
            .toSet();
      }
    } catch (_) {}
  }

  /// Call on logout so we stop showing notifications.
  void reset() {
    _currentUserId = null;
    _activeChatId = null;
    _newMessageDevicesSetting = 'everyone';
    _followedUserIds = {};
    MessagingSocketService.shared.onMessageNotifyPush = null;
  }

  /// ChatScreen calls this with its chatId when it opens, and null when it closes.
  void setActiveChatId(String? chatId) {
    _activeChatId = chatId;
    debugPrint('[MessagingNotificationService] activeChatId=$chatId');
  }

  void _onIncoming(ChatModel chat) {
    final lm = chat.lastMessage;
    if (lm == null) return;

    // Don't notify for own messages.
    if (lm.senderId == _currentUserId) return;

    // Don't notify if the user is already looking at this chat.
    if (_activeChatId != null && _activeChatId == chat.id) return;

    // Respect the newMessageDevices setting.
    switch (_newMessageDevicesSetting) {
      case 'off':
        return;
      case 'followed':
        if (!_followedUserIds.contains(lm.senderId.trim())) return;
    }

    final senderName = chat.otherPerson?.displayName ?? 'New message';
    debugPrint(
      '[MessagingNotificationService] Showing push for chatId=${chat.id} from="$senderName" content="${lm.content}"',
    );

    PushNotificationService.shared.showMessage(
      senderName: senderName,
      content: lm.content,
      chatId: chat.id,
      receiverPhotoUrl: chat.otherPerson?.photoUrl ?? '',
    );
  }
}