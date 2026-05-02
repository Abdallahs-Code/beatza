// Dart imports
import 'dart:io' show Platform;
import 'package:flutter/material.dart';

// Package imports
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/theme/app_text.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';
import 'package:cross_team5/features/library/library_routes.dart';
import 'package:cross_team5/features/library/screens/settings_screen.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';

import '../../premium_subscription/screens/premium_subscription.dart';
import '../../premium_subscription/services/payment_service.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          ValueListenableBuilder<SubscriptionState>(
            valueListenable: PaymentService.subscriptionSuccessNotifier,
            builder: (context, state, _) {
              final isPro = state.isPro;
              return GestureDetector(
                onTap: () {
                  if (!isPro) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PremiumSubscriptionScreen(),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.chipPink, AppColors.inferno],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isPro ? 'Artist Pro' : 'Get Artist Pro',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          Text(
            AppText.libraryTitle,
            style: TextStyle(
              color: AppColors.whiteSmoke,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (Platform.isAndroid) const QrCodeScanButton(),
          if (Platform.isAndroid) const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: Icon(
              Icons.settings_outlined,
              color: AppColors.whiteSmoke,
              size: 28,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class LibraryMenuItem extends StatelessWidget {
  final String title;

  const LibraryMenuItem({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppColors.whiteSmoke, fontSize: 18),
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.white60, size: 28),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onActionTap;

  const SectionHeader({
    super.key,
    required this.title,
    required this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget action = Text(
      actionText,
      style: TextStyle(
        color: AppColors.white60,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.whiteSmoke,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onActionTap == null
              ? action
              : GestureDetector(onTap: onActionTap, child: action),
        ],
      ),
    );
  }
}

class AlbumPlaceholder extends StatelessWidget {
  const AlbumPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: AppColors.tileDark,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 14, width: 90, color: AppColors.tileDark2),
          const SizedBox(height: 6),
          Container(height: 12, width: 60, color: AppColors.tileDark3),
        ],
      ),
    );
  }
}

class TrackPlaceholder extends StatelessWidget {
  const TrackPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.tileDark,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: double.infinity,
                color: AppColors.tileDark2,
              ),
              const SizedBox(height: 6),
              Container(height: 12, width: 120, color: AppColors.tileDark3),
              const SizedBox(height: 6),
              Container(height: 10, width: 80, color: AppColors.tileDark4),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.more_horiz, color: AppColors.white60),
      ],
    );
  }
}

enum RecentlyPlayedMockItemType { playlist, profile }

class RecentlyPlayedMockItem {
  final RecentlyPlayedMockItemType type;
  final String title;
  final String subtitle;
  final String metadata;
  final String? imageUrl;
  final bool isVerified;

  const RecentlyPlayedMockItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.metadata,
    this.imageUrl,
    this.isVerified = false,
  });
}

class RecentlyPlayedPreviewCard extends StatelessWidget {
  final RecentlyPlayedMockItem item;

  const RecentlyPlayedPreviewCard({super.key, required this.item});

  bool get _isProfile => item.type == RecentlyPlayedMockItemType.profile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArtworkImage(
            imageUrl: item.imageUrl,
            size: 148,
            isCircular: _isProfile,
            fallbackIcon: _isProfile ? Icons.person : Icons.album_rounded,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.isVerified)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.verified,
                    color: AppColors.blueHyperlink,
                    size: 18,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.white60, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            item.metadata,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.white60, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class RecentlyPlayedListTile extends StatelessWidget {
  final RecentlyPlayedMockItem item;

  const RecentlyPlayedListTile({super.key, required this.item});

  bool get _isProfile => item.type == RecentlyPlayedMockItemType.profile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ArtworkImage(
          imageUrl: item.imageUrl,
          size: 118,
          isCircular: _isProfile,
          fallbackIcon: _isProfile ? Icons.person : Icons.album_rounded,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (item.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(
                          Icons.verified,
                          color: AppColors.blueHyperlink,
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white60, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _isProfile
                          ? Icons.person_rounded
                          : Icons.favorite_rounded,
                      size: 18,
                      color: AppColors.white60,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.white60,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryTrackTile extends StatelessWidget {
  final PlaybackTrackModel track;
  final VoidCallback? onTap;

  const HistoryTrackTile({super.key, required this.track, this.onTap});

  bool get _isBlocked => track.accessState == PlaybackAccessState.blocked;
  bool get _isPreview => track.accessState == PlaybackAccessState.preview;

  @override
  Widget build(BuildContext context) {
    final String bottomMeta = _buildBottomMeta();

    return Opacity(
      opacity: _isBlocked ? 0.55 : 1,
      child: InkWell(
        onTap: _isBlocked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ArtworkImage(
              imageUrl: track.artworkUrl,
              size: 86,
              fallbackIcon: _isBlocked
                  ? Icons.block_rounded
                  : Icons.music_note_rounded,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _isBlocked
                            ? AppColors.white60
                            : AppColors.whiteSmoke,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      track.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.white60, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isBlocked
                              ? Icons.location_off_rounded
                              : _isPreview
                              ? Icons.lock_clock_rounded
                              : Icons.play_arrow_rounded,
                          color: AppColors.white60,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            bottomMeta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white60,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: null,
              icon: Icon(
                Icons.more_horiz_rounded,
                color: AppColors.white60,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildBottomMeta() {
    if (_isBlocked) {
      return track.blockedReason ?? 'Not available in your country';
    }

    if (_isPreview) {
      return 'Preview only · ${track.effectivePreviewDuration.inSeconds} sec';
    }

    if (track.genre != null && track.genre!.trim().isNotEmpty) {
      return '${_formatPlayCount(track.numPlays)} · ${track.genre}';
    }

    return _formatPlayCount(track.numPlays);
  }

  String _formatPlayCount(int plays) {
    if (plays >= 1000000) {
      final double value = plays / 1000000;
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}M';
    }

    if (plays >= 1000) {
      final double value = plays / 1000;
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}K';
    }

    return plays.toString();
  }
}

class ArtworkImage extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool isCircular;
  final IconData fallbackIcon;

  const ArtworkImage({
    super.key,
    required this.imageUrl,
    required this.size,
    this.isCircular = false,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius borderRadius = BorderRadius.circular(
      isCircular ? size / 2 : 12,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tileDark,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: (imageUrl ?? '').trim().isEmpty
          ? _fallback()
          : Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            ),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tileDark,
        borderRadius: BorderRadius.circular(isCircular ? size / 2 : 12),
      ),
      child: Icon(fallbackIcon, color: AppColors.white60, size: size * 0.36),
    );
  }
}

class ImportCard extends StatelessWidget {
  const ImportCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            const Text('💎', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppText.transferFaves,
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    AppText.importDesc,
                    style: TextStyle(
                      color: AppColors.white60,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.whiteSmoke,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Text(
                AppText.importButton,
                style: TextStyle(
                  color: AppColors.pureBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.whiteSmoke,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.play_arrow_rounded,
              color: AppColors.pureBlack,
              size: 34,
            ),
          ),
          const SizedBox(width: 10),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pagan - Hey Papi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pagan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.white60, fontSize: 15),
                ),
                SizedBox(height: 2),
                Text(
                  AppText.nowPlaying,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.whiteSmoke, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.library_music_outlined,
            color: AppColors.brilliantOrange,
            size: 30,
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.favorite_border_rounded,
            color: AppColors.whiteSmoke,
            size: 30,
          ),
        ],
      ),
    );
  }
}

class LibraryBottomArea extends StatelessWidget {
  const LibraryBottomArea({super.key});

  @override
  Widget build(BuildContext context) {
    return const CommonBottomNavBar(currentItem: AppNavItem.library);
  }
}

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white10),
        ),
        child: Icon(icon, color: AppColors.whiteSmoke, size: 22),
      ),
    );
  }
}

class QrCodeScanButton extends StatelessWidget {
  const QrCodeScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushReplacementNamed(context, LibraryRoutes.qrScanner);
      },
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(10),
      ),
      child: const Icon(Icons.qr_code_scanner),
    );
  }
}
