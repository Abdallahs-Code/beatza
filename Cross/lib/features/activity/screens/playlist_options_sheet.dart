import 'package:flutter/material.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/chat_screen.dart';
import 'package:cross_team5/features/messaging_track_sharing/screens/send_to_sheet.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';
import 'package:cross_team5/features/sets_playlists/models/playlist_model.dart';

class PlaylistOptionsSheet extends StatefulWidget {
  final PlaylistModel playlist;

  /// True when the current user owns the playlist/album.
  final bool isOwner;

  /// Owner-only: opens the edit playlist screen.
  final VoidCallback? onEdit;

  /// Owner-only: toggles private ↔ public.
  final VoidCallback? onTogglePrivacy;

  /// Owner-only: deletes the playlist.
  final VoidCallback? onDelete;

  /// Non-owner: navigates to the creator's profile.
  final VoidCallback? onGoToProfile;

  /// Non-owner: reposts the playlist.
  final VoidCallback? onRepost;

  const PlaylistOptionsSheet({
    super.key,
    required this.playlist,
    this.isOwner = false,
    this.onEdit,
    this.onTogglePrivacy,
    this.onDelete,
    this.onGoToProfile,
    this.onRepost,
  });

  @override
  State<PlaylistOptionsSheet> createState() => _PlaylistOptionsSheetState();
}

class _PlaylistOptionsSheetState extends State<PlaylistOptionsSheet> {
  List<({String receiverId, String name, String photoUrl})> _recentContacts =
      [];
  String? _playlistPermalink;

  @override
  void initState() {
    super.initState();
    _loadSendToData();
  }

  Future<void> _loadSendToData() async {
    final currentUserId = await AuthApiService().getStoredUserId();
    if (currentUserId == null || currentUserId.isEmpty) return;

    final permalink = widget.playlist.permalink.isNotEmpty
        ? widget.playlist.permalink
        : null;

    String profileLink = '';
    if (widget.playlist.artistId.isNotEmpty) {
      try {
        profileLink =
            await MessagingApiService().getUserProfileLink(
                  userId: widget.playlist.artistId,
                ) ??
            '';
      } catch (_) {}
    }

    String buildPayload() {
      if (permalink == null) return '';
      return 'playlist::permalink:"$permalink",profilelink:"$profileLink"';
    }

    try {
      final result = await SocialApiService().getFollowers(
        userId: currentUserId,
      );
      if (result.$1 != 200) {
        if (mounted) setState(() => _playlistPermalink = buildPayload());
        return;
      }
      final rawList = result.$2;
      List<Follower> followers = [];
      if (rawList is List) {
        followers = rawList.whereType<Follower>().toList();
      }
      final valid = followers.where((f) => f.userId.isNotEmpty).toList();
      if (!mounted) return;
      setState(() {
        _recentContacts = valid
            .take(6)
            .map(
              (f) => (
                receiverId: f.userId,
                name: f.displayName,
                photoUrl: f.profileImgLink ?? '',
              ),
            )
            .toList();
        _playlistPermalink = buildPayload();
      });
    } catch (_) {
      if (mounted) setState(() => _playlistPermalink = buildPayload());
    }
  }

  void _openSendToSheet() {
    final link = _playlistPermalink ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) =>
          SendToSheet(trackLink: link, trackTitle: widget.playlist.title),
    );
  }

  void _sendToContact(String receiverId, String name, String photoUrl) {
    final link = _playlistPermalink ?? '';
    Navigator.of(context, rootNavigator: true).pop();
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: receiverId,
          receiverName: name,
          receiverPhotoUrl: photoUrl,
          initialContent: link,
        ),
      ),
    );
  }

  Future<void> _goToProfile() async {
    final artistId = widget.playlist.artistId;
    if (artistId.isEmpty) return;
    final nav = Navigator.of(context, rootNavigator: true);
    nav.pop();
    await ProfileNavigator.pushViaState(nav, artistId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundDeepest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Playlist header card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _PlaylistHeaderCard(playlist: widget.playlist),
                ),
                const SizedBox(height: 22),

                // ── Send To ────────────────────────────────────────────────
                if (_recentContacts.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'SEND TO',
                      style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 2.2,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: _recentContacts
                          .map(
                            (c) => _SendToContact(
                              name: c.name,
                              photoUrl: c.photoUrl,
                              onTap: () => _sendToContact(
                                c.receiverId,
                                c.name,
                                c.photoUrl,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Colors.white12, height: 1),
                ],

                // ── Share ──────────────────────────────────────────────────
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'SHARE',
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 2.2,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      _ShareAction(
                        icon: Icons.send_outlined,
                        label: 'Message',
                        onTap: _openSendToSheet,
                      ),
                      const _ShareAction(
                        icon: Icons.copy_outlined,
                        label: 'Copy link',
                      ),
                      const _ShareAction(
                        icon: Icons.qr_code_2_outlined,
                        label: 'QR code',
                      ),
                      const _ShareAction(
                        icon: Icons.sms_outlined,
                        label: 'SMS',
                      ),
                      const _ShareAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'WhatsApp',
                      ),
                      const _ShareAction(
                        icon: Icons.camera_alt_outlined,
                        label: 'Stories',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                // ── Options ────────────────────────────────────────────────
                const _OptionTile(
                  icon: Icons.playlist_play_rounded,
                  label: 'Play next',
                ),
                const _OptionTile(
                  icon: Icons.format_list_bulleted_rounded,
                  label: 'Play last',
                ),
                const _OptionTile(
                  icon: Icons.copy_all_outlined,
                  label: 'Copy playlist',
                ),
                const SizedBox(height: 10),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 10),

                if (widget.isOwner) ...[
                  // Owner-only options
                  _OptionTile(
                    icon: Icons.edit_outlined,
                    label: 'Edit playlist',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      widget.onEdit?.call();
                    },
                  ),
                  _OptionTile(
                    icon: widget.playlist.isPrivate
                        ? Icons.public_outlined
                        : Icons.lock_outline,
                    label: widget.playlist.isPrivate
                        ? 'Make playlist public'
                        : 'Make playlist private',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      widget.onTogglePrivacy?.call();
                    },
                  ),
                  _OptionTile(
                    icon: Icons.delete_outline,
                    label: 'Delete playlist',
                    color: Colors.red,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      widget.onDelete?.call();
                    },
                  ),
                ] else ...[
                  // Non-owner options
                  _OptionTile(
                    icon: Icons.repeat_rounded,
                    label: 'Repost on Beatza',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      widget.onRepost?.call();
                    },
                  ),
                  _OptionTile(
                    icon: Icons.person_outline_rounded,
                    label: 'Go to profile',
                    onTap: widget.onGoToProfile != null
                        ? () {
                            Navigator.of(context, rootNavigator: true).pop();
                            widget.onGoToProfile?.call();
                          }
                        : _goToProfile,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Playlist header card ─────────────────────────────────────────────────────

class _PlaylistHeaderCard extends StatelessWidget {
  final PlaylistModel playlist;

  const _PlaylistHeaderCard({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final trackCount = playlist.listOfTracks.length;
    final label = playlist.isAlbum ? 'Album' : 'Playlist';

    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.cardDark2,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Cover art
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: playlist.image?.imgLink.isNotEmpty == true
                  ? Image.network(
                      playlist.image!.imgLink,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crusta.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.crusta,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    playlist.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$trackCount ${trackCount == 1 ? 'track' : 'tracks'}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 76,
      height: 76,
      color: AppColors.tileDark,
      child: const Icon(Icons.queue_music, color: Colors.white24, size: 32),
    );
  }
}

// ── Share action ─────────────────────────────────────────────────────────────

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ShareAction({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Send-to contact ───────────────────────────────────────────────────────────

class _SendToContact extends StatelessWidget {
  final String name;
  final String photoUrl;
  final VoidCallback onTap;

  const _SendToContact({
    required this.name,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 31,
              backgroundColor: AppColors.containerMid,
              backgroundImage:
                  photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
              child: photoUrl.isEmpty
                  ? Text(
                      _initials(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String text) {
    final parts = text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

// ── Option tile ───────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  const _OptionTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 2),
      leading: Icon(icon, color: color, size: 33),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }
}
