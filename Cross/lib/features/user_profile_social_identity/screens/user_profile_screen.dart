// Dart imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Package imports
import 'package:cross_team5/features/user_profile_social_identity/models/profile_link_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/services/user_profile_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/screens/edit_profile_screen.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String token;
  final String? currentUserId;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.token,
    this.currentUserId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserProfileService _apiService = UserProfileService();
  late Future<_ProfileViewState> _profileFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = _fetchProfileViewState();
  }

  Future<_ProfileViewState> _fetchProfileViewState() async {
    final profile = await _apiService.getUserProfile(
      widget.userId,
      widget.token,
    );
    final currentUserId = widget.currentUserId?.trim() ?? '';
    final isOwner = currentUserId.isNotEmpty && currentUserId == profile.userId;

    return _ProfileViewState(profile: profile, isOwner: isOwner);
  }

  Future<void> _openUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;

    final normalized =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
        ? trimmed
        : 'https://$trimmed';

    final uri = Uri.tryParse(normalized);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _copyProfileLink(UserProfileModel profile) async {
    final link = profile.profileUrl.trim();
    if (link.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No profile link available.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: link));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile link copied.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSheet(UserProfileModel profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B0B0B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1C1C1C),
                      backgroundImage: profile.profileImgLink.trim().isNotEmpty
                          ? NetworkImage(profile.profileImgLink)
                          : null,
                      child: profile.profileImgLink.trim().isEmpty
                          ? const Icon(
                              Icons.person,
                              color: Colors.white38,
                              size: 22,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        profile.resolvedDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Location',
                  style: TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.resolvedLocation,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Role',
                  style: TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.role,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bio',
                  style: TextStyle(
                    color: Color(0xFF9A9A9A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.bio.trim().isEmpty
                      ? 'No bio added yet.'
                      : profile.bio.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                if (profile.favoriteGenres.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Favorite genres',
                    style: TextStyle(
                      color: Color(0xFF9A9A9A),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.favoriteGenres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF171717),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: Color(0xFFCCCCCC),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showShareSheet(UserProfileModel profile, {required bool isOwner}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B0B0B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        final actions = <_SheetAction>[
          _SheetAction(
            label: 'Copy link',
            icon: Icons.copy_outlined,
            onTap: () async {
              Navigator.pop(context);
              await _copyProfileLink(profile);
            },
          ),
          const _SheetAction(label: 'Message', icon: Icons.send_outlined),
          const _SheetAction(label: 'QR code', icon: Icons.qr_code_2),
          const _SheetAction(
            label: 'SMS',
            icon: Icons.chat_bubble,
            bgColor: Color(0xFF32D74B),
          ),
          const _SheetAction(
            label: 'WhatsApp',
            icon: Icons.phone,
            bgColor: Color(0xFF25D366),
          ),
          const _SheetAction(
            label: 'Stories',
            icon: Icons.camera_alt_outlined,
            bgColor: Color(0xFFE1306C),
          ),
          const _SheetAction(
            label: 'Snapchat',
            icon: Icons.circle,
            bgColor: Color(0xFFFFFC00),
            iconColor: Colors.black,
          ),
          const _SheetAction(label: 'X', icon: Icons.close),
          const _SheetAction(
            label: 'Messenger',
            icon: Icons.message,
            bgColor: Color(0xFF8B5CF6),
          ),
          const _SheetAction(label: 'More', icon: Icons.more_horiz),
        ];

        final linkedProfiles = profile.visibleLinks;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                CircleAvatar(
                  radius: 52,
                  backgroundColor: const Color(0xFF141414),
                  backgroundImage: profile.profileImgLink.trim().isNotEmpty
                      ? NetworkImage(profile.profileImgLink)
                      : null,
                  child: profile.profileImgLink.trim().isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white38,
                          size: 38,
                        )
                      : null,
                ),
                const SizedBox(height: 14),
                Text(
                  profile.resolvedDisplayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.followersCount} followers',
                  style: const TextStyle(
                    color: Color(0xFFB3B3B3),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    scrollDirection: Axis.horizontal,
                    itemCount: actions.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = actions[index];
                      return _ShareActionItem(action: item);
                    },
                  ),
                ),
                if (linkedProfiles.isNotEmpty) ...[
                  const Divider(color: Colors.white12, height: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                    child: Row(
                      children: const [
                        Icon(Icons.link, color: Colors.white70, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Linked profiles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...linkedProfiles.map(
                    (link) => ListTile(
                      onTap: () async {
                        Navigator.pop(context);
                        await _openUrl(link.normalizedUrl);
                      },
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF1E1E1E),
                        child: Icon(
                          _iconForLink(link),
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(
                        link.title.trim().isEmpty ? 'Link' : link.title,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        link.link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF9A9A9A)),
                      ),
                    ),
                  ),
                ],
                const Divider(color: Colors.white12, height: 20),
                if (isOwner)
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.block,
                      color: Colors.white70,
                      size: 20,
                    ),
                    title: const Text(
                      'Blocked users',
                      style: TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        FollowersSocialGraphRoutes.blockedUsers,
                      );
                    },
                  ),
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.info_outline,
                    color: Colors.white70,
                    size: 20,
                  ),
                  title: const Text(
                    'View info',
                    style: TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showInfoSheet(profile);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconForLink(ProfileLinkModel link) {
    final platform = link.platform.toLowerCase();
    final title = link.title.toLowerCase();

    if (platform.contains('instagram') || title.contains('instagram')) {
      return Icons.camera_alt_outlined;
    }
    if (platform.contains('twitter') ||
        platform == 'x' ||
        title.contains('twitter') ||
        title == 'x') {
      return Icons.close;
    }
    if (platform.contains('website') || title.contains('website')) {
      return Icons.language;
    }
    if (platform.contains('facebook') || title.contains('facebook')) {
      return Icons.facebook;
    }
    if (platform.contains('youtube') || title.contains('youtube')) {
      return Icons.play_arrow;
    }
    if (platform.contains('tiktok') || title.contains('tiktok')) {
      return Icons.music_note;
    }

    return Icons.link;
  }

  bool _isArtistRole(String role) {
    return role.toLowerCase().contains('artist');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<_ProfileViewState>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load profile.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final profile = data.profile;
          final isOwner = data.isOwner;

          if (profile.isPrivate && !isOwner) {
            return _PrivateProfileView(profile: profile);
          }

          return _SoundCloudProfileView(
            profile: profile,
            isOwner: isOwner,
            token: widget.token,
            onEdited: () {
              setState(() {
                _loadProfile();
              });
            },
            onMorePressed: () => _showShareSheet(profile, isOwner: isOwner),
            showArtistSections: _isArtistRole(profile.role),
          );
        },
      ),
    );
  }
}

class _SoundCloudProfileView extends StatelessWidget {
  final UserProfileModel profile;
  final bool isOwner;
  final String token;
  final VoidCallback onEdited;
  final VoidCallback onMorePressed;
  final bool showArtistSections;

  const _SoundCloudProfileView({
    required this.profile,
    required this.isOwner,
    required this.token,
    required this.onEdited,
    required this.onMorePressed,
    required this.showArtistSections,
  });

  bool get _hasProfilePhoto => profile.profileImgLink.trim().isNotEmpty;
  bool get _hasBio => profile.bio.trim().isNotEmpty;
  bool get _hasBanner => profile.bannerImgLink.trim().isNotEmpty;

  int get _completedStepsCount {
    int count = 2;
    if (_hasProfilePhoto) count++;
    if (_hasBio) count++;
    if (_hasBanner) count++;
    return count;
  }

  bool get _shouldShowCompleteProfile {
    return !_hasProfilePhoto || !_hasBio || !_hasBanner;
  }

  List<_ProfileCompletionCardData> _buildCompletionCards() {
    final cards = <_ProfileCompletionCardData>[
      const _ProfileCompletionCardData(
        title: 'Verify email',
        subtitle: 'Go to your inbox and verify\nyour account',
        buttonText: '',
        icon: Icons.inventory_2_outlined,
        isComplete: true,
      ),
      const _ProfileCompletionCardData(
        title: 'Add your name',
        subtitle: 'Add your name so your friends know it\'s you',
        buttonText: 'Edit name',
        icon: Icons.person_outline,
        isComplete: true,
      ),
    ];

    if (!_hasProfilePhoto) {
      cards.add(
        const _ProfileCompletionCardData(
          title: 'Add a profile photo',
          subtitle: 'Choose a photo to represent\nyourself on SoundCloud',
          buttonText: 'Add photo',
          icon: Icons.camera_alt_outlined,
        ),
      );
    }

    if (!_hasBio) {
      cards.add(
        const _ProfileCompletionCardData(
          title: 'Add a bio',
          subtitle: 'What should people know\nabout you?',
          buttonText: 'Add bio',
          icon: Icons.chat_bubble_outline,
        ),
      );
    }

    if (!_hasBanner) {
      cards.add(
        const _ProfileCompletionCardData(
          title: 'Add a profile banner',
          subtitle: 'Choose a banner to further\npersonalize your profile',
          buttonText: 'Add banner',
          icon: Icons.image_outlined,
        ),
      );
    }

    return cards;
  }

  Future<void> _openEditProfile(BuildContext context) async {
    if (!isOwner) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            EditProfileScreen(currentProfile: profile, token: token),
      ),
    );

    if (updated == true) {
      onEdited();
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final completionCards = _buildCompletionCards();

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.black,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              expandedHeight: 190,
              automaticallyImplyLeading: false,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final collapsed =
                      constraints.maxHeight <= kToolbarHeight + topPadding + 24;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        color: const Color(0xFF121212),
                        child: profile.bannerImgLink.trim().isNotEmpty
                            ? Image.network(
                                profile.bannerImgLink,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              )
                            : _AutoBannerFromAvatar(profile.profileImgLink),
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.18)),
                      Positioned(
                        top: topPadding + 10,
                        left: 16,
                        child: _RoundIconButton(
                          icon: Icons.arrow_back_ios_new,
                          onTap: () => Navigator.maybePop(context),
                        ),
                      ),
                      Positioned(
                        top: topPadding + 10,
                        right: 16,
                        child: _RoundIconButton(
                          icon: Icons.more_horiz,
                          onTap: onMorePressed,
                        ),
                      ),
                      if (collapsed)
                        Positioned(
                          left: 60,
                          right: 60,
                          top: topPadding + 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SmallAvatar(profile.profileImgLink),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  profile.resolvedDisplayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: const Color(0xFF1C1C1C),
                          backgroundImage:
                              profile.profileImgLink.trim().isNotEmpty
                              ? NetworkImage(profile.profileImgLink)
                              : null,
                          child: profile.profileImgLink.trim().isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white38,
                                  size: 42,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Text(
                        profile.resolvedDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                      child: Text(
                        profile.resolvedLocation,
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                FollowersSocialGraphRoutes.followers,
                                arguments: {'userId': profile.userId},
                              );
                            },
                            child: Text(
                              '${profile.followersCount} Followers',
                              style: const TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                FollowersSocialGraphRoutes.followers,
                                arguments: {
                                  'userId': profile.userId,
                                  'tabIndex': 1,
                                },
                              );
                            },
                            child: Text(
                              '${profile.followingsCount} Following',
                              style: const TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                      child: Text(
                        profile.role,
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: isOwner
                                ? () => _openEditProfile(context)
                                : null,
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {},
                            icon: const Icon(
                              Icons.shuffle,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Colors.black,
                                size: 34,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (profile.bio.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          profile.bio.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    if (profile.favoriteGenres.isNotEmpty)
                      const SizedBox(height: 12),
                    if (profile.favoriteGenres.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.favoriteGenres.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF171717),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                genre,
                                style: const TextStyle(
                                  color: Color(0xFFCCCCCC),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (_shouldShowCompleteProfile) ...[
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Text(
                                'Complete your profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$_completedStepsCount OF 5 ',
                                style: const TextStyle(
                                  color: Color(0xFFFF6A00),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const TextSpan(
                                text: 'COMPLETE',
                                style: TextStyle(
                                  color: Color(0xFFD0D0D0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 350,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          scrollDirection: Axis.horizontal,
                          itemCount: completionCards.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 14),
                          itemBuilder: (context, index) {
                            final card = completionCards[index];
                            return _CompleteProfileCard(
                              data: card,
                              onPressed: isOwner
                                  ? () => _openEditProfile(context)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                    if (showArtistSections) ...[
                      const SizedBox(height: 28),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Spotlight',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'Pin your gems to your profile',
                          style: TextStyle(
                            color: Color(0xFFB3B3B3),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Expanded(child: _SpotlightCard()),
                            SizedBox(width: 14),
                            Expanded(child: _SpotlightCard()),
                            SizedBox(width: 14),
                            Expanded(child: _SpotlightCard()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'All tracks',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: _TrackRow(
                          imageUrl:
                              'https://images.unsplash.com/photo-1511379938547-c1f69419868d?q=80&w=300&auto=format&fit=crop',
                          title: 'Mango.mp3',
                          subtitle: 'Abdelrahman Kamal',
                          meta: '3:47',
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'Playlists',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PlaylistCard(
                              title: 'Untitled playlist',
                              subtitle: 'darus 123',
                              imageUrl: '',
                            ),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: _PlaylistCard(
                              title: 'Songs',
                              subtitle: 'darus 123',
                              imageUrl:
                                  'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?q=80&w=800&auto=format&fit=crop',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionHeader(title: 'Reposts', actionText: 'See all'),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _UserMusicRow(
                            imageUrl:
                                'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=300&auto=format&fit=crop',
                            title: 'husd',
                            subtitle: 'Daniel',
                            meta: '0 • 9 tracks',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    _SectionHeader(title: 'Likes', actionText: 'See all'),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        children: [
                          _TrackRow(
                            imageUrl:
                                'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?q=80&w=300&auto=format&fit=crop',
                            title: 'Best Afro House 2025',
                            subtitle: 'Raven Musik',
                            meta: 'Album · 2025',
                          ),
                          SizedBox(height: 16),
                          _TrackRow(
                            imageUrl:
                                'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=300&auto=format&fit=crop',
                            title: 'ورده .. ف يوم و ليله',
                            subtitle: 'Yousra Yousry',
                            meta: '766.9K · 51:09',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 130),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 56,
          child: _MiniPlayerReplica(),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomNavReplica(),
        ),
      ],
    );
  }
}

class _ProfileCompletionCardData {
  final String title;
  final String subtitle;
  final String buttonText;
  final IconData icon;
  final bool isComplete;

  const _ProfileCompletionCardData({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.icon,
    this.isComplete = false,
  });
}

class _CompleteProfileCard extends StatelessWidget {
  final _ProfileCompletionCardData data;
  final VoidCallback? onPressed;

  const _CompleteProfileCard({required this.data, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white12),
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: data.isComplete
                ? Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Color(0xFF49D17D),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.black,
                      size: 22,
                    ),
                  )
                : const SizedBox(width: 34, height: 34),
          ),
          const SizedBox(height: 12),
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Icon(data.icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB8B8B8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          if (data.buttonText.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  data.buttonText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;

  const _SectionHeader({required this.title, required this.actionText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            actionText,
            style: const TextStyle(
              color: Color(0xFFB3B3B3),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white38, width: 1.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: Icon(Icons.lock_outline, color: Colors.white54, size: 28),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;

  const _PlaylistCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            border: Border.all(color: Colors.white10),
          ),
          child: imageUrl.isEmpty
              ? const Center(
                  child: Icon(Icons.cloud, color: Colors.white24, size: 42),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
        ),
      ],
    );
  }
}

class _UserMusicRow extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String meta;

  const _UserMusicRow({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SquareImage(imageUrl: imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '♥ $meta',
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(Icons.more_horiz, color: Colors.white54),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String meta;

  const _TrackRow({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  @override
  Widget build(BuildContext context) {
    final looksLikeAlbum = meta.toLowerCase().contains('album');

    return Row(
      children: [
        _SquareImage(imageUrl: imageUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                looksLikeAlbum ? meta : '▶ $meta',
                style: const TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
              ),
            ],
          ),
        ),
        const Icon(Icons.more_horiz, color: Colors.white54),
      ],
    );
  }
}

class _SquareImage extends StatelessWidget {
  final String imageUrl;

  const _SquareImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      color: const Color(0xFF1D1D1D),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.music_note, color: Colors.white24),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final String imageUrl;

  const _SmallAvatar(this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: const Color(0xFF1C1C1C),
      backgroundImage: imageUrl.trim().isNotEmpty
          ? NetworkImage(imageUrl)
          : null,
    );
  }
}

class _AutoBannerFromAvatar extends StatelessWidget {
  final String imageUrl;

  const _AutoBannerFromAvatar(this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background image
        if (imageUrl.trim().isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(),
          ),

        // Blur effect
        if (imageUrl.trim().isNotEmpty)
          Container(color: Colors.black.withValues(alpha: 0.4)),

        // Gradient overlay (dark bottom fade like SoundCloud)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54, Colors.black],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniPlayerReplica extends StatelessWidget {
  const _MiniPlayerReplica();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.black),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amelie Lens - Falling Into Aci...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Amelie Lens',
                    style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.picture_in_picture_alt_outlined,
              color: Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 14),
            const Icon(Icons.favorite_border, color: Colors.white70, size: 22),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _BottomNavReplica extends StatelessWidget {
  const _BottomNavReplica();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFF0A0A0A),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomTabItem(icon: Icons.home_outlined, label: 'Home'),
          _BottomTabItem(icon: Icons.feed_outlined, label: 'Feed'),
          _BottomTabItem(icon: Icons.search, label: 'Search'),
          _BottomTabItem(
            icon: Icons.library_music,
            label: 'Library',
            active: true,
          ),
          _BottomTabItem(icon: Icons.cloud_outlined, label: 'Upgrade'),
        ],
      ),
    );
  }
}

class _BottomTabItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomTabItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : const Color(0xFF9B9B9B);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: color, fontSize: 11)),
      ],
    );
  }
}

class _PrivateProfileView extends StatelessWidget {
  final UserProfileModel profile;

  const _PrivateProfileView({required this.profile});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 260,
                    width: double.infinity,
                    color: const Color(0xFF111111),
                    child: profile.bannerImgLink.trim().isNotEmpty
                        ? Image.network(
                            profile.bannerImgLink,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          )
                        : null,
                  ),
                  Container(
                    height: 260,
                    color: Colors.black.withValues(alpha: 0.18),
                  ),
                  Positioned(
                    top: topPadding + 10,
                    left: 16,
                    child: _RoundIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onTap: () => Navigator.maybePop(context),
                    ),
                  ),
                  Positioned(
                    top: topPadding + 10,
                    right: 16,
                    child: _RoundIconButton(
                      icon: Icons.more_horiz,
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -5),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFF1C1C1C),
                        backgroundImage:
                            profile.profileImgLink.trim().isNotEmpty
                            ? NetworkImage(profile.profileImgLink)
                            : null,
                        child: profile.profileImgLink.trim().isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.white38,
                                size: 44,
                              )
                            : null,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        profile.resolvedDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.resolvedLocation,
                        style: const TextStyle(
                          color: Color(0xFFB3B3B3),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                FollowersSocialGraphRoutes.followers,
                                arguments: {
                                  'userId': profile.userId,
                                  'tabIndex': 0,
                                },
                              );
                            },
                            child: Text(
                              '${profile.followersCount} Followers',
                              style: const TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              color: Color(0xFFB3B3B3),
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                FollowersSocialGraphRoutes.followers,
                                arguments: {
                                  'userId': profile.userId,
                                  'tabIndex': 0,
                                },
                              );
                            },
                            child: Text(
                              '${profile.followingsCount} Following',
                              style: const TextStyle(
                                color: Color(0xFFB3B3B3),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F5DFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Follow',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Center(
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 82,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'This account is private',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Follow this account to see their tracks\nand activity.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF9A9A9A),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 56,
          child: _MiniPlayerReplica(),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomNavReplica(),
        ),
      ],
    );
  }
}

// class _PrivateTabIcon extends StatelessWidget {
//   final IconData icon;
//   final bool active;

//   const _PrivateTabIcon({required this.icon, this.active = false});

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           color: active ? Colors.white : const Color(0xFF6F6F6F),
//           size: 30,
//         ),
//         const SizedBox(height: 10),
//         Container(
//           width: 56,
//           height: 3,
//           decoration: BoxDecoration(
//             color: active ? Colors.white70 : Colors.transparent,
//             borderRadius: BorderRadius.circular(99),
//           ),
//         ),
//       ],
//     );
//   }
// }

class _ShareActionItem extends StatelessWidget {
  final _SheetAction action;

  const _ShareActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final bgColor = action.bgColor ?? const Color(0xFF2A2A2A);
    final iconColor = action.iconColor ?? Colors.white;

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(action.icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              action.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetAction {
  final String label;
  final IconData icon;
  final Color? bgColor;
  final Color? iconColor;
  final Future<void> Function()? onTap;

  const _SheetAction({
    required this.label,
    required this.icon,
    this.bgColor,
    this.iconColor,
    this.onTap,
  });
}

class _ProfileViewState {
  final UserProfileModel profile;
  final bool isOwner;

  const _ProfileViewState({required this.profile, required this.isOwner});
}
