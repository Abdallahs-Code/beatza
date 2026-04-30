import 'package:flutter/material.dart';

/// Total vertical space the mini player occupies from the bottom of the screen:
/// 92 px bottom gap + 64 px card height (10+10 padding + 44 px row).
const double kMiniPlayerTotalHeight = 156.0;

/// Height of the common bottom nav bar.
const double kNavBarHeight = 84.0;

/// Notified with [kMiniPlayerTotalHeight] when the mini player is visible,
/// 0.0 when it is hidden. Listen to this to push content above the player.
final ValueNotifier<double> miniPlayerHeightNotifier =
    ValueNotifier<double>(0.0);

/// A zero-height spacer when no mini player is active, growing to
/// [kMiniPlayerTotalHeight] when the player appears. Use as
/// `bottomNavigationBar: const MiniPlayerSpacer()` on Scaffolds that have
/// no nav bar, so scrollable content is never hidden beneath the player.
class MiniPlayerSpacer extends StatelessWidget {
  const MiniPlayerSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: miniPlayerHeightNotifier,
      builder: (_, h, _) => SizedBox(height: h),
    );
  }
}
