import 'package:flutter/material.dart';

import '../services/ad_service.dart';

/// No-op — the ad renders inside the expanded player sheet.
class AdOverlay extends StatelessWidget {
  const AdOverlay({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─────────────────────────────────────────────────────────────────────────────

/// Ad placeholder rendered inside the expanded player.
/// All countdown state lives in [AdService] so it survives the widget being
/// disposed when the player is minimised.
class AdPlayerWidget extends StatelessWidget {
  const AdPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AdService.shared,
      builder: (context, _) {
        final int remaining = AdService.shared.remainingSeconds;
        final bool skipReady = AdService.shared.skipReady;
        final bool canSkip = AdService.shared.canSkipAd;
        final int secsUntilSkip =
            AdService.skipAfterSeconds -
            (AdService.totalAdSeconds - remaining);

        return Material(
          color: Colors.black,
          child: Stack(
            children: [
              // ── Centre content ──────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        size: 56,
                        color: Colors.white38,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Advertisement',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$remaining s',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // ── "Ad" badge — top-left ───────────────────────────────────
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
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

              // ── Skip / countdown — bottom-right ─────────────────────────
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildSkipControl(
                  skipReady: skipReady,
                  canSkip: canSkip,
                  remaining: remaining,
                  secsUntilSkip: secsUntilSkip,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkipControl({
    required bool skipReady,
    required bool canSkip,
    required int remaining,
    required int secsUntilSkip,
  }) {
    // No skips left — tell the user immediately, no countdown needed.
    if (!canSkip) return _Pill('No skips remaining');

    if (!skipReady) {
      return _Pill('Skip in $secsUntilSkip s');
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

    return _Pill('No skips remaining');
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
