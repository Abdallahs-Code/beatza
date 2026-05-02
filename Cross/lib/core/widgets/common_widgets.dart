// Dart imports
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/playback_streaming_engine/mini_player_state.dart';
import 'package:cross_team5/features/home/home_routes.dart';
import 'package:cross_team5/features/library/library_routes.dart';
import 'package:cross_team5/features/feed_search_discovery/feed_search_discovery_routes.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';
import '../../features/audio_upload_track_management/screens/upload_track_screen.dart';
import '../../features/audio_upload_track_management/services/audio_upload_service.dart';
import '../../features/premium_subscription/screens/premium_subscription.dart';

enum AppNavItem { home, feed, search, library, upgrade, upload }

class CommonBottomNavBar extends StatelessWidget {
  final AppNavItem currentItem;

  const CommonBottomNavBar({super.key, required this.currentItem});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: miniPlayerHeightNotifier,
      builder: (ctx, miniPlayerH, _) {
        final double spacer = (miniPlayerH - kNavBarHeight).clamp(
          0.0,
          double.infinity,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: spacer),
            _buildBar(ctx),
          ],
        );
      },
    );
  }

  Widget _buildBar(BuildContext context) {
    return Container(
      height: kNavBarHeight,
      decoration: BoxDecoration(
        color: AppColors.chineseBlack,
        border: Border(top: BorderSide(color: AppColors.white10)),
      ),
      child: ValueListenableBuilder<SubscriptionState>(
        valueListenable: PaymentService.subscriptionSuccessNotifier,
        builder: (context, state, _) {
          final isPro = state.isPro;
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_filled,
                label: 'Home',
                active: currentItem == AppNavItem.home,
                onTap: () {
                  if (currentItem != AppNavItem.home) {
                    Navigator.pushNamed(context, HomeRoutes.home);
                  }
                },
              ),
              _NavItem(
                icon: Icons.feed_outlined,
                label: 'Feed',
                active: currentItem == AppNavItem.feed,
                onTap: () {
                  if (currentItem != AppNavItem.feed) {
                    Navigator.pushNamed(
                      context,
                      FeedSearchDiscoveryRoutes.feed,
                    );
                  }
                },
              ),

              if (isPro) ...[
                _NavItem(
                  icon: Icons.add_box_outlined,
                  label: '',
                  active: currentItem == AppNavItem.upload,
                  onTap: () {
                    _showUploadMenuBottomSheet(context, isPro);
                  },
                ),
                _NavItem(
                  icon: Icons.search,
                  label: 'Search',
                  active: currentItem == AppNavItem.search,
                  onTap: () {
                    if (currentItem != AppNavItem.search) {
                      Navigator.pushNamed(
                        context,
                        FeedSearchDiscoveryRoutes.search,
                      );
                    }
                  },
                ),
                _NavItem(
                  icon: Icons.library_books_outlined,
                  label: 'Library',
                  active: currentItem == AppNavItem.library,
                  onTap: () {
                    if (currentItem != AppNavItem.library) {
                      Navigator.pushNamed(context, LibraryRoutes.library);
                    }
                  },
                ),
              ] else ...[
                _NavItem(
                  icon: Icons.search,
                  label: 'Search',
                  active: currentItem == AppNavItem.search,
                  onTap: () {
                    if (currentItem != AppNavItem.search) {
                      Navigator.pushNamed(
                        context,
                        FeedSearchDiscoveryRoutes.search,
                      );
                    }
                  },
                ),
                _NavItem(
                  icon: Icons.library_books_outlined,
                  label: 'Library',
                  active: currentItem == AppNavItem.library,
                  onTap: () {
                    if (currentItem != AppNavItem.library) {
                      Navigator.pushNamed(context, LibraryRoutes.library);
                    }
                  },
                ),
                _NavItem(
                  icon: Icons.graphic_eq,
                  label: 'Upgrade',
                  active: currentItem == AppNavItem.upgrade,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PremiumSubscriptionScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.whiteSmoke : AppColors.white54;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

void _showUploadMenuBottomSheet(BuildContext context, bool isPro) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surfaceMid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.whiteSmoke,
                  size: 28,
                ),
                title: Text(
                  'Upload a track',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  nav.pop();

                  final AudioUploadService audioService = AudioUploadService();
                  final int currentUploads =
                      AudioUploadService.globalMockTracksNotifier.value.length;

                  if (!isPro && currentUploads >= 3) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Free tier limited to 3 uploads. Please upgrade to Pro.',
                        ),
                        backgroundColor: AppColors.primaryOrange,
                      ),
                    );
                    nav.push(
                      MaterialPageRoute(
                        builder: (_) => const PremiumSubscriptionScreen(),
                      ),
                    );
                    return;
                  }
                  final file = await audioService.pickAudioFile();
                  if (file != null) {
                    nav.push(
                      MaterialPageRoute(
                        builder: (context) => const UploadTrackScreen(),
                        settings: RouteSettings(arguments: file),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.library_add_outlined,
                  color: AppColors.whiteSmoke,
                  size: 28,
                ),
                title: Text(
                  'Create new playlist',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCreatePlaylistBottomSheet(context);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

void _showCreatePlaylistBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceMid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const CreatePlaylistBottomSheet(),
  );
}

class CreatePlaylistBottomSheet extends StatefulWidget {
  const CreatePlaylistBottomSheet({super.key});

  @override
  State<CreatePlaylistBottomSheet> createState() =>
      _CreatePlaylistBottomSheetState();
}

class _CreatePlaylistBottomSheetState extends State<CreatePlaylistBottomSheet> {
  late TextEditingController _titleController;
  late FocusNode _focusNode;
  bool _isPublic = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: 'Untitled playlist');
    _focusNode = FocusNode();

    _titleController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _titleController.text.length,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: AppColors.white54, size: 24),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      focusNode: _focusNode,
                      maxLength: 100,
                      style: TextStyle(
                        color: AppColors.whiteSmoke,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.white54),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: AppColors.blueAccent),
                        ),
                        contentPadding: const EdgeInsets.only(bottom: 8),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '${_titleController.text.length}/100',
                      style: TextStyle(color: AppColors.white54, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Make this playlist public',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Switch(
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                    activeThumbColor: AppColors.whiteSmoke,
                    activeTrackColor: AppColors.primaryOrange,
                    inactiveThumbColor: AppColors.whiteSmoke,
                    inactiveTrackColor: AppColors.white24,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.whiteSmoke, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Create playlist',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
