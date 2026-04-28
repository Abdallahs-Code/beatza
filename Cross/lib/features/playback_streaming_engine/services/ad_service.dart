import 'dart:async';

import 'package:flutter/foundation.dart';

class AdService extends ChangeNotifier {
  static final AdService shared = AdService._();
  AdService._();

  static const int tracksPerAd = 3;
  static const int totalAdSeconds = 15;
  static const int skipAfterSeconds = 5;

  int _tracksCompleted = 0;
  bool _hasUsedSkip = false;
  bool _isAdPlaying = false;
  VoidCallback? _onAdFinished;

  int _remainingSeconds = totalAdSeconds;
  Timer? _countdownTimer;

  bool get isAdPlaying => _isAdPlaying;
  bool get canSkipAd => !_hasUsedSkip;
  int get remainingSeconds => _remainingSeconds;

  /// True once enough seconds have elapsed to show the Skip button.
  bool get skipReady =>
      (totalAdSeconds - _remainingSeconds) >= skipAfterSeconds;

  /// Call when a track naturally completes or is skipped (non-Pro users only).
  /// Returns true if an ad was scheduled.
  bool checkAndScheduleAd({VoidCallback? onAdFinished}) {
    _tracksCompleted++;
    if (_tracksCompleted % tracksPerAd == 0) {
      _isAdPlaying = true;
      _onAdFinished = onAdFinished;
      _remainingSeconds = totalAdSeconds;
      _startCountdown();
      notifyListeners();
      return true;
    }
    return false;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      }
      if (_remainingSeconds == 0) {
        t.cancel();
        _finishAd();
      }
    });
  }

  /// Consume the user's one-time skip. No-op if already used.
  void skipAd() {
    if (!canSkipAd) return;
    _hasUsedSkip = true;
    _finishAd();
  }

  /// Call when the ad finishes naturally (timer expires).
  void onAdCompleted() => _finishAd();

  void _finishAd() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isAdPlaying = false;
    final cb = _onAdFinished;
    _onAdFinished = null;
    notifyListeners();
    cb?.call();
  }
}