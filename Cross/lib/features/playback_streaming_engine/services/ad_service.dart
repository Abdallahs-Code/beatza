import 'package:flutter/foundation.dart';

class AdService extends ChangeNotifier {
  static final AdService shared = AdService._();
  AdService._();

  static const String adVideoId = 'cIw17g53Jd4';
  static const int tracksPerAd = 3;

  int _tracksCompleted = 0;
  bool _hasUsedSkip = false;
  bool _isAdPlaying = false;
  VoidCallback? _onAdFinished;

  bool get isAdPlaying => _isAdPlaying;

  /// True only if the user has NOT yet used their one session skip.
  bool get canSkipAd => !_hasUsedSkip;

  /// Call when a track naturally completes (non-Pro users only).
  /// Returns true if an ad was scheduled — the caller should pause
  /// auto-advance and wait for [onAdFinished] before continuing.
  bool checkAndScheduleAd({VoidCallback? onAdFinished}) {
    _tracksCompleted++;
    if (_tracksCompleted % tracksPerAd == 0) {
      _isAdPlaying = true;
      _onAdFinished = onAdFinished;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Consume the user's one-time skip. No-op if already used.
  void skipAd() {
    if (!canSkipAd) return;
    _hasUsedSkip = true;
    _finishAd();
  }

  /// Call when the ad video finishes playing naturally.
  void onAdCompleted() => _finishAd();

  void _finishAd() {
    _isAdPlaying = false;
    final cb = _onAdFinished;
    _onAdFinished = null;
    notifyListeners();
    cb?.call();
  }
}
