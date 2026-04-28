import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

import '../services/ad_service.dart';

/// Full-screen ad overlay driven by [AdService].
/// Returns [SizedBox.shrink] when no ad is active — zero size, no hit-testing.
class AdOverlay extends StatelessWidget {
  const AdOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdService.shared,
      builder: (context, _) {
        if (!AdService.shared.isAdPlaying) return const SizedBox.shrink();
        return const _AdPlayer();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared constants
// ─────────────────────────────────────────────────────────────────────────────

String get _watchUrl =>
    'https://www.youtube.com/watch?v=${AdService.adVideoId}&autoplay=1';

const String _desktopUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/124.0.0.0 Safari/537.36';

const String _mobileUserAgent =
    'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/112.0.0.0 Mobile Safari/537.36';

/// [completionSignal] — JS expression fired when the video ends naturally.
/// [startedSignal]   — JS expression fired the first time the video plays.
String _buildInjectionScript(String completionSignal, String startedSignal) => '''
(function() {
  // ── Immediate black backdrop while the player repositions ─────────────────
  var backdrop = document.createElement('div');
  backdrop.style.cssText =
    'position:fixed;inset:0;z-index:2147483638;background:#000;pointer-events:none;';
  document.documentElement.appendChild(backdrop);

  // ── Hide every YouTube UI element — leave only the raw <video> ───────────
  var s = document.createElement('style');
  s.textContent =
    '.ytp-chrome-bottom,.ytp-chrome-top,' +
    '.ytp-gradient-top,.ytp-gradient-bottom,' +
    '.ytp-pause-overlay,.ytp-more-videos-over-endscreen,' +
    '.ytp-endscreen-content,.videowall-endscreen,' +
    '.ytp-ce-element,.ytp-ce-covering-overlay,.ytp-ce-element-shadow,' +
    '.ytp-cards-teaser,.ytp-cards-button,.ytp-cards-chip-no-icon,' +
    '.ytp-watermark,.ytp-youtube-button,.ytp-branding,' +
    '.ytp-large-play-button,.ytp-cued-thumbnail-overlay,' +
    '.ytp-cued-thumbnail-overlay-image,' +
    '.annotation,.iv-module,.video-annotations,' +
    '.ytp-iv-video-content,.iv-branding,' +
    '.ytp-contextmenu,.ytp-title,.ytp-title-channel,' +
    '.ytp-title-text,.ytp-share-button-visible' +
    '{display:none!important}';
  document.head.appendChild(s);

  // ── Wait for #movie_player + <video>, then take over the viewport ─────────
  function setup() {
    var player = document.getElementById('movie_player');
    if (!player) { setTimeout(setup, 400); return; }
    var v = player.querySelector('video');
    if (!v) { setTimeout(setup, 400); return; }

    // Move player to <html> root — escapes every CSS-transform stacking context
    document.documentElement.appendChild(player);
    player.style.cssText =
      'position:fixed!important;top:0!important;left:0!important;' +
      'width:100vw!important;height:100vh!important;' +
      'z-index:2147483640!important;background:#000!important;';

    // Make the <video> fill the player
    v.style.cssText =
      'width:100%!important;height:100%!important;' +
      'object-fit:contain!important;background:#000!important;';

    backdrop.remove();

    // Transparent guard — absorbs all pointer events (no pause/seek/clicks)
    var g = document.createElement('div');
    g.style.cssText =
      'position:fixed!important;inset:0!important;' +
      'z-index:2147483647!important;background:transparent!important;';
    document.documentElement.appendChild(g);

    // Seek prevention — revert any forward scrub > 2 s
    var lastTime = 0, reverting = false;
    v.addEventListener('seeking', function() {
      if (reverting) return;
      if (v.currentTime - lastTime > 2) { reverting = true; v.currentTime = lastTime; }
    }, true);
    v.addEventListener('seeked', function() {
      reverting = false;
      if (v.currentTime < lastTime) lastTime = v.currentTime;
    }, true);
    v.addEventListener('timeupdate', function() {
      if (!reverting && !v.seeking) lastTime = v.currentTime;
    }, true);

    // Started signal — fires once when playback begins
    var _sent = false;
    v.addEventListener('play', function() {
      if (!_sent) { _sent = true; $startedSignal; }
    }, true);

    // Completion signal
    v.addEventListener('ended', function() { $completionSignal; }, true);
  }

  setup();
})();
''';

// ─────────────────────────────────────────────────────────────────────────────

class _AdPlayer extends StatefulWidget {
  const _AdPlayer();

  @override
  State<_AdPlayer> createState() => _AdPlayerState();
}

class _AdPlayerState extends State<_AdPlayer> {
  static const int _skipDelaySec = 5;
  static const int _maxDurationSec = 120;

  int _countdown = _skipDelaySec;
  bool _skipReady = false;

  /// True once the video emits its first 'play' event — only then do we render.
  bool _videoStarted = false;

  Timer? _countdownTimer;
  Timer? _maxDurationTimer;

  // ── Mobile (Android / iOS / macOS) ────────────────────────────────────────
  WebViewController? _mobileController;

  // ── Windows (WebView2) ────────────────────────────────────────────────────
  WebviewController? _windowsController;
  StreamSubscription<dynamic>? _windowsMsgSub;
  StreamSubscription<LoadingState>? _windowsLoadSub;

  /// True once WebView2 is initialised and its widget can be placed in the tree.
  bool _windowsWidgetReady = false;

  bool get _isMobile =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  static final String _mobileScript = _buildInjectionScript(
    "AdChannel.postMessage('completed')",
    "AdChannel.postMessage('started')",
  );

  static final String _windowsScript = _buildInjectionScript(
    "window.chrome.webview.postMessage('completed')",
    "window.chrome.webview.postMessage('started')",
  );

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      _initMobile();
    } else if (Platform.isWindows) {
      _initWindows();
    }
    _maxDurationTimer = Timer(
      const Duration(seconds: _maxDurationSec),
      () { if (mounted) AdService.shared.onAdCompleted(); },
    );
  }

  // ── Mobile init ───────────────────────────────────────────────────────────

  void _initMobile() {
    _mobileController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(_mobileUserAgent)
      ..addJavaScriptChannel(
        'AdChannel',
        onMessageReceived: (JavaScriptMessage msg) {
          if (msg.message == 'started' && mounted) {
            setState(() => _videoStarted = true);
            _startCountdown();
          }
          if (msg.message == 'completed') AdService.shared.onAdCompleted();
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest req) {
          if (!req.isMainFrame) return NavigationDecision.navigate;
          return req.url.contains(AdService.adVideoId)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent;
        },
        onPageFinished: (_) =>
            _mobileController?.runJavaScript(_mobileScript),
      ))
      ..loadRequest(Uri.parse(_watchUrl));
  }

  // ── Windows init ──────────────────────────────────────────────────────────

  Future<void> _initWindows() async {
    try {
      _windowsController = WebviewController();
      await _windowsController!.initialize();
      await _windowsController!.setUserAgent(_desktopUserAgent);

      _windowsMsgSub = _windowsController!.webMessage.listen((dynamic raw) {
        final msg = raw.toString();
        if (msg == 'started' && mounted) {
          setState(() => _videoStarted = true);
          _startCountdown();
        }
        if (msg == 'completed') AdService.shared.onAdCompleted();
      });

      _windowsLoadSub = _windowsController!.loadingState
          .where((s) => s == LoadingState.navigationCompleted)
          .listen((_) => _windowsController!.executeScript(_windowsScript));

      await _windowsController!.loadUrl(_watchUrl);

      // Widget can now be inserted — the page will load while it's hidden.
      if (mounted) setState(() => _windowsWidgetReady = true);
    } catch (_) {
      // WebView2 unavailable — max-duration timer auto-dismisses.
    }
  }

  // ── Countdown — starts only once the video is actually playing ────────────

  void _startCountdown() {
    if (_countdownTimer != null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 1) {
          _countdown--;
        } else {
          _countdown = 0;
          _skipReady = true;
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _maxDurationTimer?.cancel();
    _windowsMsgSub?.cancel();
    _windowsLoadSub?.cancel();
    _windowsController?.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final videoArea = _buildVideoArea();

    return Stack(
      children: [
        // Video layer — always present once the controller is ready so the
        // webview surface exists, but invisible until _videoStarted.
        if (videoArea != null)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_videoStarted,
              child: AnimatedOpacity(
                opacity: _videoStarted ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: videoArea,
              ),
            ),
          ),

        // Controls layer — only rendered (and interactive) once video plays.
        if (_videoStarted) ...[
          // "Ad" badge — top-left.
          Positioned(
            top: 0, left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Ad',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Skip / countdown — bottom-right.
          Positioned(
            bottom: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSkipControl(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Returns the video widget, or null if not yet ready to insert into the tree.
  Widget? _buildVideoArea() {
    if (_isMobile && _mobileController != null) {
      return WebViewWidget(controller: _mobileController!);
    }
    if (Platform.isWindows && _windowsWidgetReady && _windowsController != null) {
      return SizedBox.expand(child: Webview(_windowsController!));
    }
    return null;
  }

  Widget _buildSkipControl() {
    final canSkip = AdService.shared.canSkipAd;

    if (!_skipReady) {
      return _Pill(canSkip ? 'Skip in $_countdown s' : 'Watch full ad');
    }

    if (canSkip) {
      return GestureDetector(
        onTap: AdService.shared.skipAd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Skip Ad',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.skip_next_rounded, color: Colors.black, size: 18),
            ],
          ),
        ),
      );
    }

    return const _Pill('No skips remaining');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
    );
  }
}