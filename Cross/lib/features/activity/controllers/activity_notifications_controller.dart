import 'package:cross_team5/features/activity/models/activity_notification_model.dart';
import 'package:cross_team5/features/activity/services/activity_notifications_api_service.dart';
import 'package:cross_team5/features/activity/services/activity_notifications_socket_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:flutter/foundation.dart';

class ActivityNotificationsController extends ChangeNotifier {
  ActivityNotificationsController._shared();

  static final ActivityNotificationsController shared =
      ActivityNotificationsController._shared();

  final ActivityNotificationsApiService _apiService =
      ActivityNotificationsApiService();
  final ActivityNotificationsSocketService _socketService =
      ActivityNotificationsSocketService.shared;
  final List<ActivityNotificationModel> _notifications =
      <ActivityNotificationModel>[];

  ActivityNotificationFilter _filter = ActivityNotificationFilter.all;
  bool _isLoading = false;
  bool _hasInitialized = false;
  String? _errorMessage;
  int _unreadCount = 0;
  String? _activeToken;
  String? _currentUserId;

  List<ActivityNotificationModel> get notifications =>
      List<ActivityNotificationModel>.unmodifiable(_notifications);

  ActivityNotificationFilter get filter => _filter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  List<ActivityNotificationModel> get visibleNotifications {
    return _notifications
        .where((notification) => _filter.matches(notification))
        .toList();
  }

  List<ActivityNotificationModel> get todayNotifications {
    return visibleNotifications.where(_isToday).toList();
  }

  List<ActivityNotificationModel> get olderNotifications {
    return visibleNotifications.where((item) => !_isToday(item)).toList();
  }

  String? get currentUserId => _currentUserId;

  Future<void> initialize() async {
    try {
      final token = await AuthApiService().getStoredAccessToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }

      _currentUserId ??= await AuthApiService().getStoredUserId();

      final shouldDoInitialLoad =
          !_hasInitialized || _activeToken == null || _activeToken != token;

      if (shouldDoInitialLoad) {
        _hasInitialized = true;
        _activeToken = token;
        await refresh();
      }

      await _connectSocket();
    } catch (_) {}
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _apiService.getNotifications(limit: 50);
      final unreadCount = await _apiService.getUnreadCount();

      _notifications
        ..clear()
        ..addAll(page.notifications.where(_isNotSelfAction));

      _notifications.sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      );

      _unreadCount = unreadCount;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _connectSocket() async {
    try {
      final token = await AuthApiService().getStoredAccessToken();
      if (token == null || token.trim().isEmpty) return;

      _activeToken = token;

      await _socketService.connect(
        token: token,
        onNotification: _handleIncomingNotification,
        onReconnect: () async {
          await refresh();
        },
      );
    } catch (_) {}
  }

  void _handleIncomingNotification(ActivityNotificationModel notification) {
    if (!_isNotSelfAction(notification)) return;

    final existingIndex = _notifications.indexWhere(
      (item) => item.notificationId == notification.notificationId,
    );

    if (existingIndex >= 0) {
      _notifications[existingIndex] = notification;
    } else {
      _notifications.insert(0, notification);
    }

    _notifications.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    _unreadCount = _notifications.where((item) => !item.read).length;
    _errorMessage = null;
    notifyListeners();
  }

  void setFilter(ActivityNotificationFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
  }

  void showAllNotifications() {
    setFilter(ActivityNotificationFilter.all);
  }

    Future<void> reconnectIfNeeded() async {
    try {
      final token = await AuthApiService().getStoredAccessToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }

      if (_activeToken != token || !_socketService.isConnected) {
        _activeToken = token;
        await _connectSocket();
      }
    } catch (_) {}
  }

    Future<void> onAppResumed() async {
    await reconnectIfNeeded();
  }
    Future<void> ensureFreshState() async {
    await reconnectIfNeeded();
    await refresh();
  }

  void resetForLogout() {
    _socketService.disconnect();
    _notifications.clear();
    _filter = ActivityNotificationFilter.all;
    _isLoading = false;
    _hasInitialized = false;
    _errorMessage = null;
    _unreadCount = 0;
    _activeToken = null;
    notifyListeners();
  }

    Future<void> markAllAsRead() async {
    final unreadNotifications = _notifications.where((item) => !item.read).toList();
    if (unreadNotifications.isEmpty) return;

    final originalNotifications = List<ActivityNotificationModel>.from(_notifications);
    final originalUnreadCount = _unreadCount;

    for (var i = 0; i < _notifications.length; i++) {
      final item = _notifications[i];
      if (!item.read) {
        _notifications[i] = item.copyWith(read: true);
      }
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await _apiService.markAllAsRead();
    } catch (_) {
      _notifications
        ..clear()
        ..addAll(originalNotifications);
      _unreadCount = originalUnreadCount;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final index = _notifications.indexWhere(
      (item) => item.notificationId == notificationId,
    );

    if (index < 0) return;

    final notification = _notifications[index];
    if (notification.read) return;

    _notifications[index] = notification.copyWith(read: true);
    _unreadCount = _notifications.where((item) => !item.read).length;
    notifyListeners();

    try {
      await _apiService.markSingleAsRead(notificationId);
    } catch (_) {
      _notifications[index] = notification;
      _unreadCount = _notifications.where((item) => !item.read).length;
      notifyListeners();
    }
  }

  bool _isNotSelfAction(ActivityNotificationModel notification) {
    if (_currentUserId == null || _currentUserId!.trim().isEmpty) return true;
    return notification.actor.userId != _currentUserId;
  }

  bool _isToday(ActivityNotificationModel notification) {
    final createdAt = notification.createdAt.toLocal();
    final now = DateTime.now();
    return createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day;
  }
}