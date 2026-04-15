import 'package:flutter/material.dart';

final ValueNotifier<bool> globalPopupRouteVisible = ValueNotifier<bool>(false);

class AppOverlayRouteObserver extends NavigatorObserver {
  int _popupRouteDepth = 0;

  void _syncNotifier() {
    globalPopupRouteVisible.value = _popupRouteDepth > 0;
  }

  bool _isPopup(Route<dynamic>? route) {
    return route is PopupRoute<dynamic>;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPopup(route)) {
      _popupRouteDepth++;
      _syncNotifier();
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPopup(route) && _popupRouteDepth > 0) {
      _popupRouteDepth--;
      _syncNotifier();
    }
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isPopup(route) && _popupRouteDepth > 0) {
      _popupRouteDepth--;
      _syncNotifier();
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
    }
    _syncNotifier();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

final AppOverlayRouteObserver appOverlayRouteObserver =
    AppOverlayRouteObserver();