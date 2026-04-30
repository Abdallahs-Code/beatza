import 'package:flutter/foundation.dart';

/// Total vertical space the mini player occupies from the bottom of the screen:
/// 92 px bottom gap + 64 px card height (10+10 padding + 44 px row).
const double kMiniPlayerTotalHeight = 156.0;

/// Height of the common bottom nav bar.
const double kNavBarHeight = 84.0;

/// Notified with [kMiniPlayerTotalHeight] when the mini player is visible,
/// 0.0 when it is hidden. Listen to this to push content above the player.
final ValueNotifier<double> miniPlayerHeightNotifier =
    ValueNotifier<double>(0.0);
