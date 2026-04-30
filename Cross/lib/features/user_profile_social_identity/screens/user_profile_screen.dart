import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cross_team5/core/widgets/common_widgets.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/profile_link_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/services/user_profile_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/screens/edit_profile_screen.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/mock_playback_access_service.dart';
import 'package:cross_team5/features/library/services/library_history_api_service.dart';
import '../../audio_upload_track_management/models/track.dart';
import '../../audio_upload_track_management/models/track_model.dart';
import '../../audio_upload_track_management/services/audio_upload_service.dart';
import '../../audio_upload_track_management/services/track_api_service.dart';
import '../../audio_upload_track_management/screens/your_insights_screen.dart';
import '../models/spotlight_models.dart';
import '../../premium_subscription/services/payment_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/chat_screen.dart';
import 'edit_spotlight_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String token;
  final String? currentUserId;

  final bool initialIsFollowing;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.token,
    this.currentUserId,
    this.initialIsFollowing = false,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserProfileService _apiService = UserProfileService();
  final SocialApiService _socialApiService = SocialApiService();
  final TrackApiService _trackApiService = TrackApiService();
  final AuthApiService _authApiService = AuthApiService();

  late Future<_ProfileViewState> _profileFuture;
  late Future<List<PlaybackTrackModel>> _publicTracksFuture;
  late Future<List<PlaybackTrackModel>> _repostedTracksFuture;
  Future<void>? _initialContextFuture;

  TrackModel? _currentlyPlayingTrack;

  late bool _isFollowing;
  bool _isFollowActionLoading = false;
  String? _resolvedCurrentUserId;

  @override
  void initState() {
    super.initState();

    PaymentService.subscriptionSuccessNotifier.checkStatusFromApi();

    _isFollowing = widget.initialIsFollowing;

    _profileFuture = _fetchProfileViewState();
    _publicTracksFuture = _loadLikedTracks();
    _repostedTracksFuture = _loadRepostedTracks();

    _initialContextFuture = _loadInitialContext();
  }

  Future<void> _loadInitialContext() async {
    final storedCurrentUserId = await _authApiService.getStoredUserId();

    _resolvedCurrentUserId =
        (widget.currentUserId != null &&
            widget.currentUserId!.trim().isNotEmpty)
        ? widget.currentUserId!.trim()
        : storedCurrentUserId?.trim();

    _profileFuture = _fetchProfileViewState();
  }

  Future<List<PlaybackTrackModel>> _loadLikedTracks() async {
    final result = await _trackApiService.getUserLikedTracks(
      userId: widget.userId,
    );
    if (result.$1 != 200) return [];
    final tracks = result.$2 as List<Track>;
    return tracks
        .map(
          (t) => PlaybackTrackModel(
            id: t.id,
            title: t.title,
            artistName: t.displayArtist,
            artworkUrl: t.imageUrl,
            accessState: PlaybackAccessState.playable,
            sourceType: PlaybackSourceType.network,
            isPrivate: t.isPrivate,
            numLikes: t.numLikes,
            numPlays: t.numPlays,
            numReposts: t.numReposts,
            numComments: t.numComments,
            genre: t.genre,
            tags: t.tags,
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _playTrack(TrackModel track) {
    setState(() {
      _currentlyPlayingTrack = track;
    });
  }

  void _closePlayer() {
    setState(() {
      _currentlyPlayingTrack = null;
    });
  }

  Future<void> _playLikedTrack(PlaybackTrackModel track, int index) async {
    final result = await _trackApiService.getTrackById(trackId: track.id);
    if (result.$1 != 200) return;
    final fullTrack = result.$2 as Track;
    if (fullTrack.audioLink == null || fullTrack.audioLink!.trim().isEmpty)
      return;
    final playbackTrack = PlaybackTrackModel(
      id: fullTrack.id,
      title: fullTrack.title,
      artistName: fullTrack.displayArtist,
      audioUrl: fullTrack.audioLink!,
      artworkUrl: fullTrack.imageUrl,
      accessState: PlaybackAccessState.playable,
      sourceType: PlaybackSourceType.network,
      isPrivate: fullTrack.isPrivate,
      numLikes: fullTrack.numLikes,
      numPlays: fullTrack.numPlays,
      numReposts: fullTrack.numReposts,
      numComments: fullTrack.numComments,
      genre: fullTrack.genre,
      tags: fullTrack.tags,
    );
    await PlaybackStreamingEngineService.shared.playTrack(
      playbackTrack,
      queue: [playbackTrack],
      startIndex: 0,
    );
  }

  Future<List<PlaybackTrackModel>> _loadRepostedTracks() async {
    try {
      return await LibraryHistoryApiService().getUserRepostedTracks(
        widget.userId,
        widget.token,
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _toggleFollowUser() async {
    if (_isFollowActionLoading) return;

    final previousValue = _isFollowing;

    setState(() {
      _isFollowActionLoading = true;
      _isFollowing = !previousValue;
    });

    final result = previousValue
        ? await _socialApiService.unfollowUser(targetUserId: widget.userId)
        : await _socialApiService.followUser(targetUserId: widget.userId);

    if (!mounted) return;

    if (result.$1 < 200 || result.$1 >= 300) {
      setState(() {
        _isFollowing = previousValue;
        _isFollowActionLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.$2.toString())));
      return;
    }

    setState(() {
      _isFollowActionLoading = false;
      _profileFuture = _fetchProfileViewState();
    });
  }

  void _showTrackOptions(TrackModel track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundDark2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child:
                        track.coverImagePath != null &&
                            track.coverImagePath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              File(track.coverImagePath!),
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.music_note, color: Colors.white54),
                  ),
                  title: Text(
                    track.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    track.genre.isEmpty ? 'Unknown Genre' : track.genre,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: const Icon(Icons.bar_chart, color: Colors.white),
                  title: const Text(
                    'Insights',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const YourInsightsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.white),
                  title: const Text(
                    'Edit Track',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(track);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTrack(track);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditDialog(TrackModel track) {
    final TextEditingController titleCtrl = TextEditingController(
      text: track.title,
    );
    final TextEditingController genreCtrl = TextEditingController(
      text: track.genre,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Edit Track',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: genreCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Genre',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
              ),
              onPressed: () {
                _updateTrackData(track.id, titleCtrl.text, genreCtrl.text);
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _updateTrackData(String id, String newTitle, String newGenre) {
    final currentList = List<TrackModel>.from(
      AudioUploadService.globalMockTracksNotifier.value,
    );
    final index = currentList.indexWhere((t) => t.id == id);

    if (index != -1) {
      final oldTrack = currentList[index];
      final updatedTrack = TrackModel(
        id: oldTrack.id,
        title: newTitle,
        genre: newGenre,
        descriptiveTags: oldTrack.descriptiveTags,
        releaseDate: oldTrack.releaseDate,
        fileFormat: oldTrack.fileFormat,
        processingState: oldTrack.processingState,
        visibility: oldTrack.visibility,
        audioUrl: oldTrack.audioUrl,
        waveformPeaks: oldTrack.waveformPeaks,
        description: oldTrack.description,
        caption: oldTrack.caption,
        recordLabel: oldTrack.recordLabel,
        publisher: oldTrack.publisher,
        isrc: oldTrack.isrc,
        containsExplicitContent: oldTrack.containsExplicitContent,
        pLine: oldTrack.pLine,
        enableDirectDownloads: oldTrack.enableDirectDownloads,
        offlineListening: oldTrack.offlineListening,
        includeInRssFeed: oldTrack.includeInRssFeed,
        displayEmbedCode: oldTrack.displayEmbedCode,
        enableAppPlayback: oldTrack.enableAppPlayback,
        availability: oldTrack.availability,
        licensing: oldTrack.licensing,
        coverImagePath: oldTrack.coverImagePath,
      );

      currentList[index] = updatedTrack;
      AudioUploadService.globalMockTracksNotifier.value = currentList;

      if (_currentlyPlayingTrack?.id == id) {
        setState(() => _currentlyPlayingTrack = updatedTrack);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Track updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteTrack(TrackModel track) {
    final currentList = List<TrackModel>.from(
      AudioUploadService.globalMockTracksNotifier.value,
    );
    currentList.removeWhere((t) => t.id == track.id);
    AudioUploadService.globalMockTracksNotifier.value = currentList;

    if (_currentlyPlayingTrack?.id == track.id) {
      _closePlayer();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Track deleted successfully'),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<_ProfileViewState> _fetchProfileViewState() async {
    final profile = await _apiService.getUserProfile(
      widget.userId,
      widget.token,
    );

    MockPlaybackAccessService.shared.syncCountryFromProfileLocation(
      profile.resolvedLocation,
    );

    final currentUserId = _resolvedCurrentUserId?.trim() ?? '';
    final isOwner = currentUserId.isNotEmpty && currentUserId == profile.userId;

    return _ProfileViewState(profile: profile, isOwner: isOwner);
  }

  Future<void> _openFollowersScreen(String profileUserId) async {
    await Navigator.pushNamed(
      context,
      FollowersSocialGraphRoutes.followers,
      arguments: {
        'userId': profileUserId,
        'token': widget.token,
        'currentUserId': _resolvedCurrentUserId,
        'tabIndex': 0,
      },
    );

    if (!mounted) return;

    setState(() {
      _profileFuture = _fetchProfileViewState();
    });
  }

  Future<void> _openFollowingScreen(
    String profileUserId, {
    int tabIndex = 0,
  }) async {
    await Navigator.pushNamed(
      context,
      FollowersSocialGraphRoutes.following,
      arguments: {
        'userId': profileUserId,
        'token': widget.token,
        'currentUserId': _resolvedCurrentUserId,
        'tabIndex': tabIndex,
      },
    );

    if (!mounted) return;

    setState(() {
      _profileFuture = _fetchProfileViewState();
    });
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
      backgroundColor: AppColors.backgroundVeryDark,
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
                      backgroundColor: AppColors.surface,
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
                    color: AppColors.greyMedium,
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
                    color: AppColors.greyMedium,
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
                    color: AppColors.greyMedium,
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
                      color: AppColors.greyMedium,
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
                          color: AppColors.cardDark3,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: AppColors.greyLight,
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
      backgroundColor: AppColors.backgroundVeryDark,
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
            bgColor: AppColors.whatsAppGreen,
          ),
          const _SheetAction(
            label: 'WhatsApp',
            icon: Icons.phone,
            bgColor: AppColors.messagingGreen,
          ),
          const _SheetAction(
            label: 'Stories',
            icon: Icons.camera_alt_outlined,
            bgColor: AppColors.instagramPink,
          ),
          const _SheetAction(
            label: 'Snapchat',
            icon: Icons.circle,
            bgColor: AppColors.snapchatYellow,
            iconColor: Colors.black,
          ),
          const _SheetAction(label: 'X', icon: Icons.close),
          const _SheetAction(
            label: 'Messenger',
            icon: Icons.message,
            bgColor: AppColors.glowPurple,
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
                  backgroundColor: AppColors.backgroundDark2,
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
                    color: AppColors.greyButton,
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
                        backgroundColor: AppColors.surfaceMid,
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
                        style: const TextStyle(color: AppColors.greyMedium),
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
      body: FutureBuilder<void>(
        future: _initialContextFuture,
        builder: (context, initSnapshot) {
          if (initSnapshot.connectionState == ConnectionState.waiting &&
              _resolvedCurrentUserId == null &&
              (widget.currentUserId == null ||
                  widget.currentUserId!.trim().isEmpty)) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return FutureBuilder<_ProfileViewState>(
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
                return _PrivateProfileView(
                  profile: profile,
                  onFollowersTap: () => _openFollowersScreen(profile.userId),
                  onFollowingTap: () =>
                      _openFollowingScreen(profile.userId, tabIndex: 0),
                  isFollowing: _isFollowing,
                  isFollowActionLoading: _isFollowActionLoading,
                  onFollowToggle: _toggleFollowUser,
                );
              }

              return FutureBuilder<List<PlaybackTrackModel>>(
                future: _publicTracksFuture,
                builder: (context, tracksSnapshot) {
                  final List<PlaybackTrackModel> likedTracks =
                      tracksSnapshot.data ?? const <PlaybackTrackModel>[];

                  return FutureBuilder<List<PlaybackTrackModel>>(
                    future: _repostedTracksFuture,
                    builder: (context, repostedSnapshot) {
                      final List<PlaybackTrackModel> repostedTracks =
                          repostedSnapshot.data ?? const <PlaybackTrackModel>[];

                      return Stack(
                        children: [
                          _SoundCloudProfileView(
                            profile: profile,
                            isOwner: isOwner,
                            token: widget.token,
                            onEdited: () {
                              setState(() {
                                _profileFuture = _fetchProfileViewState();
                                _publicTracksFuture = _loadLikedTracks();
                              });
                            },
                            onMorePressed: () =>
                                _showShareSheet(profile, isOwner: isOwner),
                            showArtistSections: _isArtistRole(profile.role),
                            onTrackTap: _playTrack,
                            onTrackOptionsTap: _showTrackOptions,
                            onLikedTrackTap: _playLikedTrack,
                            currentlyPlayingTrackId: _currentlyPlayingTrack?.id,
                            likedTracks: likedTracks,
                            repostedTracks: repostedTracks,
                            isLoadingLikedTracks:
                                tracksSnapshot.connectionState ==
                                ConnectionState.waiting,
                            likedTracksError: tracksSnapshot.hasError
                                ? tracksSnapshot.error.toString()
                                : null,
                            onFollowersTap: () =>
                                _openFollowersScreen(profile.userId),
                            onFollowingTap: () => _openFollowingScreen(
                              profile.userId,
                              tabIndex: 0,
                            ),
                            isFollowing: _isFollowing,
                            isFollowActionLoading: _isFollowActionLoading,
                            onFollowToggle: _toggleFollowUser,
                          ),
                          const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: CommonBottomNavBar(
                              currentItem: AppNavItem.library,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SoundCloudProfileView extends StatefulWidget {
  final UserProfileModel profile;
  final bool isOwner;
  final String token;
  final VoidCallback onEdited;
  final VoidCallback onMorePressed;
  final bool showArtistSections;
  final Function(TrackModel) onTrackTap;
  final Function(TrackModel) onTrackOptionsTap;
  final Future<void> Function(PlaybackTrackModel track, int index)
  onLikedTrackTap;
  final String? currentlyPlayingTrackId;
  final List<PlaybackTrackModel> likedTracks;
  final List<PlaybackTrackModel> repostedTracks;
  final bool isLoadingLikedTracks;
  final String? likedTracksError;
  final Future<void> Function() onFollowersTap;
  final Future<void> Function() onFollowingTap;
  final bool isFollowing;
  final bool isFollowActionLoading;
  final Future<void> Function() onFollowToggle;

  const _SoundCloudProfileView({
    required this.profile,
    required this.isOwner,
    required this.token,
    required this.onEdited,
    required this.onMorePressed,
    required this.showArtistSections,
    required this.onTrackTap,
    required this.onTrackOptionsTap,
    required this.onLikedTrackTap,
    this.currentlyPlayingTrackId,
    required this.likedTracks,
    required this.repostedTracks,
    required this.isLoadingLikedTracks,
    this.likedTracksError,
    required this.onFollowersTap,
    required this.onFollowingTap,
    required this.isFollowing,
    required this.isFollowActionLoading,
    required this.onFollowToggle,
  });

  @override
  State<_SoundCloudProfileView> createState() => _SoundCloudProfileViewState();
}

class _SoundCloudProfileViewState extends State<_SoundCloudProfileView> {
  List<SpotlightItemModel?> spotlightItems = List.filled(5, null);

  final TrackApiService _trackApiService = TrackApiService();
  List<Track> _serverTracks = [];
  bool _isLoadingTracks = false;
  String? _fetchingPlaybackId;

  bool get _hasBio => widget.profile.bio.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadServerTracks();
  }

  Future<void> _loadServerTracks() async {
    if (widget.profile.trackCount == 0) return;
    setState(() => _isLoadingTracks = true);
    final result = await _trackApiService.getUserPostedTracks(
      userId: widget.profile.userId,
    );
    if (!mounted) return;
    setState(() {
      _isLoadingTracks = false;
      if (result.$1 == 200) _serverTracks = result.$2 as List<Track>;
    });
  }

  Future<void> _playServerTrack(Track track) async {
    if (_fetchingPlaybackId != null) return;
    setState(() => _fetchingPlaybackId = track.id);
    final result = await _trackApiService.getTrackById(trackId: track.id);
    if (!mounted) return;
    setState(() => _fetchingPlaybackId = null);
    if (result.$1 != 200) return;
    final fullTrack = result.$2 as Track;
    if (fullTrack.audioLink == null || fullTrack.audioLink!.trim().isEmpty)
      return;
    final playbackTrack = PlaybackTrackModel(
      id: fullTrack.id,
      title: fullTrack.title,
      artistName: fullTrack.displayArtist,
      audioUrl: fullTrack.audioLink!,
      artworkUrl: fullTrack.imageUrl,
      accessState: PlaybackAccessState.playable,
      sourceType: PlaybackSourceType.network,
      isPrivate: fullTrack.isPrivate,
      numLikes: fullTrack.numLikes,
      numPlays: fullTrack.numPlays,
      numReposts: fullTrack.numReposts,
      numComments: fullTrack.numComments,
      genre: fullTrack.genre,
      tags: fullTrack.tags,
    );
    await PlaybackStreamingEngineService.shared.playTrack(
      playbackTrack,
      queue: [playbackTrack],
      startIndex: 0,
    );
  }

  static const String _defaultImageUrl =
      "https://res.cloudinary.com/dr1sqiouu/image/upload/v1776357570/profile/file_ud25rn.png";

  bool get _hasProfilePhoto {
    final url = widget.profile.profileImgLink.trim();
    return url.isNotEmpty && url != _defaultImageUrl;
  }

  bool get _hasBanner {
    final url = widget.profile.bannerImgLink.trim();
    return url.isNotEmpty && url != _defaultImageUrl;
  }

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

  void _openEditSpotlight() async {
    if (!widget.isOwner) return;

    final updatedSpotlight = await Navigator.push<List<SpotlightItemModel?>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSpotlightScreen(
          initialItems: spotlightItems.whereType<SpotlightItemModel>().toList(),
          artistName: widget.profile.resolvedDisplayName,
        ),
      ),
    );

    if (updatedSpotlight != null && mounted) {
      setState(() {
        for (int i = 0; i < 5; i++) {
          if (i < updatedSpotlight.length) {
            spotlightItems[i] = updatedSpotlight[i];
          } else {
            spotlightItems[i] = null;
          }
        }
      });
    }
  }

  List<_ProfileCompletionCardData> _buildCompletionCards() {
    return <_ProfileCompletionCardData>[
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
      _ProfileCompletionCardData(
        title: 'Add a profile photo',
        subtitle: 'Choose a photo to represent\nyourself on Beatza',
        buttonText: _hasProfilePhoto ? '' : 'Add photo',
        icon: Icons.camera_alt_outlined,
        isComplete: _hasProfilePhoto,
      ),
      _ProfileCompletionCardData(
        title: 'Add a bio',
        subtitle: 'What should people know\nabout you?',
        buttonText: _hasBio ? '' : 'Add bio',
        icon: Icons.chat_bubble_outline,
        isComplete: _hasBio,
      ),
      _ProfileCompletionCardData(
        title: 'Add a profile banner',
        subtitle: 'Choose a banner to further\npersonalize your profile',
        buttonText: _hasBanner ? '' : 'Add banner',
        icon: Icons.image_outlined,
        isComplete: _hasBanner,
      ),
    ];
  }

  Future<void> _openEditProfile(BuildContext context) async {
    if (!widget.isOwner) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          currentProfile: widget.profile,
          token: widget.token,
        ),
      ),
    );

    if (!mounted) return;
    if (updated == true) {
      widget.onEdited();
    }
  }

  Widget _buildSpotlightSlot(int index) {
    return GestureDetector(
      onTap: _openEditSpotlight,
      child: DragTarget<TrackModel>(
        onWillAcceptWithDetails: (details) {
          final track = details.data;
          if (!widget.isOwner) return false;

          final String visibility = track.visibility.toString().toLowerCase();
          if (visibility.contains('private') ||
              visibility.contains('unlisted')) {
            return false;
          }
          return true;
        },
        onAcceptWithDetails: (details) {
          final track = details.data;
          setState(() {
            spotlightItems[index] = SpotlightItemModel.fromTrack(
              track,
              widget.profile.resolvedDisplayName,
            );
          });
        },
        builder: (context, candidateData, rejectedData) {
          final item = spotlightItems[index];
          final isHovered = candidateData.isNotEmpty;

          return AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: isHovered ? Colors.white12 : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: CustomPaint(
                painter: item == null ? DottedBorderPainter() : null,
                child: item != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child:
                                item.imageUrl != null &&
                                    item.imageUrl!.isNotEmpty
                                ? (item.imageUrl!.startsWith('http')
                                      ? Image.network(
                                          item.imageUrl!,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(item.imageUrl!),
                                          fit: BoxFit.cover,
                                        ))
                                : Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                          if (widget.isOwner)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    spotlightItems[index] = null;
                                  });
                                },
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Center(
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.white54,
                          size: 28,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final completionCards = _buildCompletionCards();

    return CustomScrollView(
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
                    color: AppColors.chineseBlack,
                    child: widget.profile.bannerImgLink.trim().isNotEmpty
                        ? Image.network(
                            widget.profile.bannerImgLink,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          )
                        : _AutoBannerFromAvatar(widget.profile.profileImgLink),
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
                      onTap: widget.onMorePressed,
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
                          _SmallAvatar(widget.profile.profileImgLink),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              widget.profile.resolvedDisplayName,
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
            child: Builder(
              builder: (context) {
                final bool shouldShowSpotlight =
                    widget.profile.trackCount > 0 &&
                    (widget.showArtistSections || widget.isOwner);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: AppColors.surface,
                              backgroundImage:
                                  widget.profile.profileImgLink
                                      .trim()
                                      .isNotEmpty
                                  ? NetworkImage(widget.profile.profileImgLink)
                                  : null,
                              child:
                                  widget.profile.profileImgLink.trim().isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white38,
                                      size: 42,
                                    )
                                  : null,
                            ),
                          ),
                          ValueListenableBuilder<SubscriptionState>(
                            valueListenable:
                                PaymentService.subscriptionSuccessNotifier,
                            builder: (context, state, child) {
                              if (state.isPro) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMid,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                            color: AppColors.primaryOrange,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 10,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'ARTIST PRO',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                      child: Text(
                        widget.profile.resolvedDisplayName,
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
                        widget.profile.resolvedLocation,
                        style: const TextStyle(
                          color: AppColors.greyButton,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: widget.onFollowersTap,
                            child: Text(
                              '${widget.profile.followersCount} Followers',
                              style: const TextStyle(
                                color: AppColors.greyButton,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              color: AppColors.greyButton,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onFollowingTap,
                            child: Text(
                              '${widget.profile.followingsCount} Following',
                              style: const TextStyle(
                                color: AppColors.greyButton,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                      child: ValueListenableBuilder<SubscriptionState>(
                        valueListenable:
                            PaymentService.subscriptionSuccessNotifier,
                        builder: (context, state, _) {
                          final displayRole =
                              (state.isPro &&
                                  widget.profile.role.toLowerCase() ==
                                      'listener')
                              ? 'Artist'
                              : widget.profile.role;
                          return Text(
                            displayRole,
                            style: const TextStyle(
                              color: AppColors.greyButton,
                              fontSize: 13,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (widget.profile.bio.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          widget.profile.bio.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          if (widget.isOwner)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _openEditProfile(context),
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white70,
                                size: 22,
                              ),
                            )
                          else
                            Expanded(
                              child: SizedBox(
                                height: 42,
                                child: ElevatedButton(
                                  onPressed: widget.isFollowActionLoading
                                      ? null
                                      : widget.onFollowToggle,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: widget.isFollowing
                                        ? AppColors.containerMid
                                        : AppColors.primaryOrange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: widget.isFollowActionLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          widget.isFollowing
                                              ? 'Following'
                                              : 'Follow',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          if (!widget.isOwner) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white70,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      receiverId: widget.profile.userId,
                                      receiverName:
                                          widget.profile.resolvedDisplayName,
                                      receiverPhotoUrl:
                                          widget.profile.profileImgLink,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.send_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                          ],
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
                    if (widget.profile.favoriteGenres.isNotEmpty)
                      const SizedBox(height: 12),
                    if (widget.profile.favoriteGenres.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.profile.favoriteGenres.map((genre) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardDark3,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                genre,
                                style: const TextStyle(
                                  color: AppColors.greyLight,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (widget.isOwner && _shouldShowCompleteProfile) ...[
                      const SizedBox(height: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(
                              child: Text(
                                'Complete your profile',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
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
                              onPressed: widget.isOwner
                                  ? () => _openEditProfile(context)
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                    if (widget.isOwner && shouldShowSpotlight) ...[
                      const SizedBox(height: 24),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const YourInsightsScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Your insights',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (shouldShowSpotlight) ...[
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
                            color: AppColors.greyButton,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: List.generate(5, (index) {
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < 4 ? 14 : 0,
                              ),
                              child: SizedBox(
                                width: 110,
                                height: 110,
                                child: _buildSpotlightSlot(index),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                    if (shouldShowSpotlight) ...[
                      const SizedBox(height: 28),
                      const _SectionHeader(title: 'All tracks', actionText: ''),
                      const SizedBox(height: 10),
                      if (_isLoadingTracks)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.orange,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        )
                      else
                        ..._serverTracks.map((track) {
                          final isFetching = _fetchingPlaybackId == track.id;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 2,
                            ),
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: track.imageUrl != null
                                    ? Image.network(
                                        track.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stack) =>
                                            const Icon(
                                              Icons.music_note,
                                              color: Colors.white24,
                                            ),
                                      )
                                    : const Icon(
                                        Icons.music_note,
                                        color: Colors.white24,
                                      ),
                              ),
                            ),
                            title: Text(
                              track.title,
                              style: TextStyle(
                                color: isFetching
                                    ? Colors.orange
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              track.displayArtist,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isFetching
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.orange,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                            onTap: () => _playServerTrack(track),
                          );
                        }),
                    ],
                    const SizedBox(height: 28),
                    const _SectionHeader(title: 'Playlists', actionText: ''),
                    const SizedBox(height: 14),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PlaylistCard(
                              title: 'Untitled playlist',
                              subtitle: 'ozOo',
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
                    _SectionHeader(
                      title: 'Reposts',
                      actionText: 'See all',
                      onActionTap: widget.repostedTracks.isEmpty
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => _AllRepostsScreen(
                                  tracks: widget.repostedTracks,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _ProfileRepostsTracksSection(
                        tracks: widget.repostedTracks,
                        isLoading: false,
                        errorMessage: null,
                      ),
                    ),
                    const SizedBox(height: 26),
                    _SectionHeader(
                      title: 'Likes',
                      actionText: 'See all',
                      onActionTap: widget.likedTracks.isEmpty
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    _AllLikesScreen(tracks: widget.likedTracks),
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _ProfileLikesTracksSection(
                        tracks: widget.likedTracks,
                        isLoading: widget.isLoadingLikedTracks,
                        errorMessage: widget.likedTracksError,
                        onTrackTap: widget.onLikedTrackTap,
                      ),
                    ),
                    const SizedBox(height: 150),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DottedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
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
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    required this.actionText,
    this.onActionTap,
  });

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
          if (actionText.isNotEmpty)
            GestureDetector(
              onTap: onActionTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                actionText,
                style: const TextStyle(
                  color: AppColors.greyButton,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surfaceMid,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: imageUrl.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud, color: Colors.white24, size: 42),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                          Container(
                            width: 4,
                            height: 24,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                          Container(
                            width: 4,
                            height: 16,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                          Container(
                            width: 4,
                            height: 8,
                            color: Colors.white24,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
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
          style: const TextStyle(color: AppColors.greyButton, fontSize: 13),
        ),
      ],
    );
  }
}

class _ProfileRepostsTracksSection extends StatelessWidget {
  final List<PlaybackTrackModel> tracks;
  final bool isLoading;
  final String? errorMessage;

  const _ProfileRepostsTracksSection({
    required this.tracks,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Column(
        children: [
          _ProfileLikeTrackPlaceholder(),
          SizedBox(height: 16),
          _ProfileLikeTrackPlaceholder(),
        ],
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.chineseBlack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Could not load reposted tracks right now.',
          style: TextStyle(
            color: AppColors.greyButton,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    if (tracks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.chineseBlack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'No reposts yet.',
          style: TextStyle(
            color: AppColors.greyButton,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    final visibleTracks = tracks.take(2).toList();

    return Column(
      children: List.generate(visibleTracks.length, (index) {
        final track = visibleTracks[index];
        final Widget row = _TrackRow(track: track);
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == visibleTracks.length - 1 ? 0 : 16,
          ),
          child: row,
        );
      }),
    );
  }
}

class _AllRepostsScreen extends StatelessWidget {
  final List<PlaybackTrackModel> tracks;

  const _AllRepostsScreen({required this.tracks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        foregroundColor: Colors.white,
        title: Text(
          '${tracks.length} Reposts',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        elevation: 0,
      ),
      body: tracks.isEmpty
          ? const Center(
              child: Text(
                'No reposts yet.',
                style: TextStyle(color: AppColors.greyButton, fontSize: 15),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              itemCount: tracks.length,
              separatorBuilder: (_, i) => const SizedBox(height: 16),
              itemBuilder: (_, index) => _TrackRow(track: tracks[index]),
            ),
    );
  }
}

class _AllLikesScreen extends StatefulWidget {
  final List<PlaybackTrackModel> tracks;

  const _AllLikesScreen({required this.tracks});

  @override
  State<_AllLikesScreen> createState() => _AllLikesScreenState();
}

class _AllLikesScreenState extends State<_AllLikesScreen> {
  final TrackApiService _trackApiService = TrackApiService();
  String? _fetchingId;

  Future<void> _play(PlaybackTrackModel track) async {
    if (_fetchingId != null) return;
    setState(() => _fetchingId = track.id);
    final result = await _trackApiService.getTrackById(trackId: track.id);
    if (!mounted) return;
    setState(() => _fetchingId = null);
    if (result.$1 != 200) return;
    final fullTrack = result.$2 as Track;
    if (fullTrack.audioLink == null || fullTrack.audioLink!.trim().isEmpty)
      return;
    final playbackTrack = PlaybackTrackModel(
      id: fullTrack.id,
      title: fullTrack.title,
      artistName: fullTrack.displayArtist,
      audioUrl: fullTrack.audioLink!,
      artworkUrl: fullTrack.imageUrl,
      accessState: PlaybackAccessState.playable,
      sourceType: PlaybackSourceType.network,
      isPrivate: fullTrack.isPrivate,
      numLikes: fullTrack.numLikes,
      numPlays: fullTrack.numPlays,
      numReposts: fullTrack.numReposts,
      numComments: fullTrack.numComments,
      genre: fullTrack.genre,
      tags: fullTrack.tags,
    );
    await PlaybackStreamingEngineService.shared.playTrack(
      playbackTrack,
      queue: [playbackTrack],
      startIndex: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      appBar: AppBar(
        backgroundColor: AppColors.homeBackground,
        foregroundColor: Colors.white,
        title: Text(
          '${widget.tracks.length} Likes',
          style: const TextStyle(color: Colors.white, fontSize: 17),
        ),
        elevation: 0,
      ),
      body: widget.tracks.isEmpty
          ? const Center(
              child: Text(
                'No likes yet.',
                style: TextStyle(color: AppColors.greyButton, fontSize: 15),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              itemCount: widget.tracks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, index) {
                final track = widget.tracks[index];
                final isFetching = _fetchingId == track.id;
                return GestureDetector(
                  onTap: () => _play(track),
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Expanded(child: _TrackRow(track: track)),
                      if (isFetching)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.orange,
                            strokeWidth: 2,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ProfileLikesTracksSection extends StatelessWidget {
  final List<PlaybackTrackModel> tracks;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function(PlaybackTrackModel track, int index)? onTrackTap;

  const _ProfileLikesTracksSection({
    required this.tracks,
    required this.isLoading,
    required this.errorMessage,
    this.onTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Column(
        children: [
          _ProfileLikeTrackPlaceholder(),
          SizedBox(height: 16),
          _ProfileLikeTrackPlaceholder(),
        ],
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.chineseBlack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'Could not load liked tracks right now.',
          style: TextStyle(
            color: AppColors.greyButton,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    if (tracks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.chineseBlack,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: const Text(
          'No likes yet.',
          style: TextStyle(
            color: AppColors.greyButton,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    final visibleTracks = tracks.take(2).toList();

    return Column(
      children: List.generate(visibleTracks.length, (index) {
        final track = visibleTracks[index];
        final Widget row = _TrackRow(track: track);

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == visibleTracks.length - 1 ? 0 : 16,
          ),
          child:
              track.accessState == PlaybackAccessState.blocked ||
                  onTrackTap == null
              ? row
              : GestureDetector(
                  onTap: () => onTrackTap!(track, index),
                  behavior: HitTestBehavior.opaque,
                  child: row,
                ),
        );
      }),
    );
  }
}

class _ProfileLikeTrackPlaceholder extends StatelessWidget {
  const _ProfileLikeTrackPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D1D),
            borderRadius: BorderRadius.circular(8),
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
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 13,
                width: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF1D1D1D),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.more_horiz, color: Colors.white24),
      ],
    );
  }
}

class _TrackRow extends StatelessWidget {
  final PlaybackTrackModel track;

  const _TrackRow({required this.track});

  bool get _isBlocked => track.accessState == PlaybackAccessState.blocked;
  bool get _isPreview => track.accessState == PlaybackAccessState.preview;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isBlocked ? 0.55 : 1,
      child: Row(
        children: [
          _SquareImage(imageUrl: track.artworkUrl ?? ''),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isBlocked ? Colors.white60 : Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.artistName,
                  style: const TextStyle(
                    color: AppColors.greyButton,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _buildMeta(),
                  style: const TextStyle(
                    color: AppColors.greyButton,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz, color: Colors.white54),
        ],
      ),
    );
  }

  String _buildMeta() {
    if (_isBlocked) {
      return '✖ ${track.blockedReason ?? 'Not available'}';
    }
    if (_isPreview) {
      return '▶ Preview only · ${track.effectivePreviewDuration.inSeconds}s';
    }

    final String plays = _formatPlays(track.numPlays);
    final String genre = (track.genre ?? '').trim();

    if (genre.isNotEmpty) {
      return '▶ $plays · $genre';
    }
    return '▶ $plays';
  }

  String _formatPlays(int plays) {
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

class _SquareImage extends StatelessWidget {
  final String imageUrl;

  const _SquareImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1D1D1D),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.music_note, color: Colors.white24),
        ),
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
          color: AppColors.containerMid,
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
      backgroundColor: AppColors.surface,
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
        if (imageUrl.trim().isNotEmpty)
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(),
          ),
        if (imageUrl.trim().isNotEmpty)
          Container(color: Colors.black.withValues(alpha: 0.4)),
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

class _PrivateProfileView extends StatelessWidget {
  final UserProfileModel profile;
  final Future<void> Function() onFollowersTap;
  final Future<void> Function() onFollowingTap;
  final bool isFollowing;
  final bool isFollowActionLoading;
  final Future<void> Function() onFollowToggle;

  const _PrivateProfileView({
    required this.profile,
    required this.onFollowersTap,
    required this.onFollowingTap,
    required this.isFollowing,
    required this.isFollowActionLoading,
    required this.onFollowToggle,
  });

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
                    color: AppColors.backgroundDark,
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
                        backgroundColor: AppColors.surface,
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
                          color: AppColors.greyButton,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: onFollowersTap,
                            child: Text(
                              '${profile.followersCount} Followers',
                              style: const TextStyle(
                                color: AppColors.greyButton,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const Text(
                            ' • ',
                            style: TextStyle(
                              color: AppColors.greyButton,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: onFollowingTap,
                            child: Text(
                              '${profile.followingsCount} Following',
                              style: const TextStyle(
                                color: AppColors.greyButton,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: isFollowActionLoading
                              ? null
                              : onFollowToggle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing
                                ? AppColors.containerMid
                                : AppColors.profileAccentBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isFollowActionLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
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
                            color: AppColors.greyMedium,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 150),
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
          bottom: 0,
          child: CommonBottomNavBar(currentItem: AppNavItem.library),
        ),
      ],
    );
  }
}

class _ShareActionItem extends StatelessWidget {
  final _SheetAction action;

  const _ShareActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    final bgColor = action.bgColor ?? AppColors.containerMid;
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
