import 'package:flutter/material.dart';

import 'package:cross_team5/features/authentication_user_management/authentication_user_management_routes.dart';
import 'package:cross_team5/features/library/library_routes.dart';
import 'package:cross_team5/features/playback_streaming_engine/playback_streaming_engine_routes.dart';

final ValueNotifier<bool> globalPopupRouteVisible = ValueNotifier<bool>(false);

class AppOverlayVisibilityState {
  final bool isPopupRouteVisible;
  final String? currentRouteName;

  const AppOverlayVisibilityState({
    required this.isPopupRouteVisible,
    required this.currentRouteName,
  });

  bool get shouldShowMiniPlayerOnCurrentRoute {
    return !_isMiniPlayerHiddenRoute(currentRouteName);
  }

  AppOverlayVisibilityState copyWith({
    bool? isPopupRouteVisible,
    String? currentRouteName,
    bool clearCurrentRouteName = false,
  }) {
    return AppOverlayVisibilityState(
      isPopupRouteVisible: isPopupRouteVisible ?? this.isPopupRouteVisible,
      currentRouteName: clearCurrentRouteName
          ? null
          : (currentRouteName ?? this.currentRouteName),
    );
  }
}

final ValueNotifier<AppOverlayVisibilityState> globalOverlayVisibility =
    ValueNotifier<AppOverlayVisibilityState>(
      const AppOverlayVisibilityState(
        isPopupRouteVisible: false,
        currentRouteName: '/',
      ),
    );

class AppOverlayRouteObserver extends NavigatorObserver {
  int _popupRouteDepth = 0;
  String? _currentRouteName = '/';

  void _syncNotifier() {
    final bool isPopupVisible = _popupRouteDepth > 0;
    globalPopupRouteVisible.value = isPopupVisible;
    globalOverlayVisibility.value = AppOverlayVisibilityState(
      isPopupRouteVisible: isPopupVisible,
      currentRouteName: _currentRouteName,
    );
  }

  bool _isPopup(Route<dynamic>? route) {
    return route is PopupRoute<dynamic>;
  }

  String? _readRouteName(Route<dynamic>? route) {
    final String? explicitName = route?.settings.name;
    if (explicitName != null && explicitName.trim().isNotEmpty) {
      return explicitName;
    }
    return null;
  }

  void _updateCurrentRouteFrom(
    Route<dynamic>? route,
    Route<dynamic>? fallbackRoute,
  ) {
    _currentRouteName =
        _readRouteName(route) ??
        _readRouteName(fallbackRoute) ??
        _currentRouteName;
    _syncNotifier();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPopup(route)) {
      _popupRouteDepth++;
      _syncNotifier();
    } else {
      _updateCurrentRouteFrom(route, previousRoute);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPopup(route)) {
      if (_popupRouteDepth > 0) {
        _popupRouteDepth--;
      }
      _syncNotifier();
    } else {
      _updateCurrentRouteFrom(previousRoute, route);
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPopup(route)) {
      if (_popupRouteDepth > 0) {
        _popupRouteDepth--;
      }
      _syncNotifier();
    } else {
      _updateCurrentRouteFrom(previousRoute, route);
    }
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_isPopup(oldRoute) && _popupRouteDepth > 0) {
      _popupRouteDepth--;
    }
    if (_isPopup(newRoute)) {
      _popupRouteDepth++;
      _syncNotifier();
    } else {
      _updateCurrentRouteFrom(newRoute, oldRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

bool _isMiniPlayerHiddenRoute(String? routeName) {
  if (routeName == null || routeName.trim().isEmpty) {
    return false;
  }

  const Set<String> hiddenExactRoutes = <String>{
    '/',
    AuthenticationRoutes.welcome,
    AuthenticationRoutes.login,
    AuthenticationRoutes.userInfo,
    AuthenticationRoutes.verifyCode,
    LibraryRoutes.qrScanner,
    PlaybackStreamingEngineRoutes.debug,
  };

  const List<String> hiddenRoutePrefixes = <String>[];

  if (hiddenExactRoutes.contains(routeName)) {
    return true;
  }

  for (final String prefix in hiddenRoutePrefixes) {
    if (routeName.startsWith(prefix)) {
      return true;
    }
  }

  return false;
}

final AppOverlayRouteObserver appOverlayRouteObserver =
    AppOverlayRouteObserver();

final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
