// Widget: RepostBottomSheet
// Modal bottom sheet for reposting a track or playlist.
//
// Design matches SoundCloud (Image 12) with one change:
//   Real app button says "Add caption" → OUR clone says "Repost" (confirmed).
//
// Behaviour differences between track and playlist:
//   Track:    Shows caption text field (optional, max 140 chars).
//             Fetches existing repost status on open to pre-fill caption.
//             If already reposted → button says "Remove Repost".
//             Allows editing the caption via PATCH after reposting.
//   Playlist: NO caption field. Button is always "Repost" or "Remove Repost".
//
// Usage (from parent screen):
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,    ← required to resize above keyboard
//     backgroundColor: Colors.transparent,
//     builder: (_) => RepostBottomSheet(
//       trackId: track.id,         ← pass trackId OR playlistId, not both
//       trackTitle: track.title,
//       trackArtist: track.artist,
//       trackThumbnailUrl: track.thumbnailUrl,
//       onRepostToggled: (isNowReposted, newCount) {
//         setState(() {
//           _isReposted = isNowReposted;
//           _repostCount = newCount;
//         });
//       },
//     ),
//   );
//
// After dismiss:
//   The sheet shows a snackbar "Reposted to your profile" on success
//   (matching Image 2), using the parent's ScaffoldMessenger.

import 'package:flutter/material.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/repost_status.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';

class RepostBottomSheet extends StatefulWidget {
  // Pass trackId for tracks, playlistId for playlists. Never both.
  final String? trackId;
  final String? playlistId;

  // Display info shown in the preview card inside the sheet.
  final String title;
  final String artist;
  final String? thumbnailUrl;

  // Current repost state — passed in so sheet knows initial button label.
  final bool isCurrentlyReposted;
  final int currentRepostCount;

  // Callback fired after successful toggle so parent updates its state.
  final void Function(bool isNowReposted, int newCount) onRepostToggled;

  const RepostBottomSheet({
    super.key,
    this.trackId,
    this.playlistId,
    required this.title,
    required this.artist,
    this.thumbnailUrl,
    required this.isCurrentlyReposted,
    required this.currentRepostCount,
    required this.onRepostToggled,
  }) : assert(
          (trackId != null) != (playlistId != null),
          'Provide exactly one of trackId or playlistId.',
        );

  @override
  State<RepostBottomSheet> createState() => _RepostBottomSheetState();
}

class _RepostBottomSheetState extends State<RepostBottomSheet> {
  final EngagementApiService _service = EngagementApiService();
  final TextEditingController _captionController = TextEditingController();
  final int _maxCaptionLength = 140;

  bool _isLoading = false;
  bool _isFetchingStatus = false;

  // True when this is a track (not playlist) — tracks have caption field.
  bool get _isTrack => widget.trackId != null;

  // True after we fetch repost status and confirm user already reposted.
  late bool _alreadyReposted;

  @override
  void initState() {
    super.initState();
    _alreadyReposted = widget.isCurrentlyReposted;

    // For tracks only: fetch existing caption to pre-fill the field.
    if (_isTrack && widget.isCurrentlyReposted) {
      _fetchExistingCaption();
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Fetch existing repost status to pre-fill caption.
  // Only called for tracks where isCurrentlyReposted == true.
  // ─────────────────────────────────────────────
  Future<void> _fetchExistingCaption() async {
    setState(() => _isFetchingStatus = true);

    final result = await _service.getTrackRepostStatus(
      trackId: widget.trackId!,
    );

    if (mounted && result.$1 == 200) {
      final status = result.$2 as RepostStatus;
      if (status.caption != null && status.caption!.isNotEmpty) {
        _captionController.text = status.caption!;
      }
    }

    if (mounted) setState(() => _isFetchingStatus = false);
  }

  // ─────────────────────────────────────────────
  // Main action: toggle repost or update caption.
  // ─────────────────────────────────────────────
  Future<void> _handleAction() async {
    setState(() => _isLoading = true);

    final caption = _captionController.text.trim();

    int statusCode;
    dynamic responseData;

    if (_isTrack) {
      // If already reposted and caption changed → PATCH (update caption).
      // Otherwise → POST (toggle repost).
      if (_alreadyReposted && caption.isNotEmpty) {
        final patchResult = await _service.updateTrackRepostCaption(
          trackId: widget.trackId!,
          caption: caption,
        );
        statusCode = patchResult.$1;
        responseData = patchResult.$2;
      } else {
        final postResult = await _service.toggleTrackRepost(
          trackId: widget.trackId!,
          caption: caption.isNotEmpty ? caption : null,
        );
        statusCode = postResult.$1;
        responseData = postResult.$2;
      }
    } else {
      // Playlist repost — no caption.
      final result = await _service.togglePlaylistRepost(
        playlistId: widget.playlistId!,
      );
      statusCode = result.$1;
      responseData = result.$2;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (statusCode == 200) {
      // Parse new state from response.
      bool isNowReposted;
      int newCount;

      if (responseData is Map<String, dynamic>) {
        isNowReposted = responseData['reposted'] as bool? ?? !_alreadyReposted;
        newCount = responseData['numberOfReposts'] as int? ??
            widget.currentRepostCount;
      } else {
        // PATCH caption update — repost state unchanged, count unchanged.
        isNowReposted = true;
        newCount = widget.currentRepostCount;
      }

      widget.onRepostToggled(isNowReposted, newCount);
      Navigator.pop(context);

      // Show snackbar in parent scaffold — matches Image 2.
      final message = isNowReposted
          ? 'Reposted to your profile'
          : 'Repost removed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF1A1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      _showSnackbar(responseData.toString());
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // isScrollControlled: true in parent ensures this resizes above keyboard.
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ───────────────────
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // ── Header row: × + title ────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Repost',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(color: Color(0xFF2A2A2A), height: 1),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Caption field (tracks only) ──
                    if (_isTrack) ...[
                      _isFetchingStatus
                          ? const SizedBox(
                              height: 80,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orange,
                                ),
                              ),
                            )
                          : TextField(
                              controller: _captionController,
                              maxLength: _maxCaptionLength,
                              maxLines: 3,
                              minLines: 2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add a caption (optional)',
                                hintStyle:
                                    TextStyle(color: Colors.grey[600]),
                                counterStyle:
                                    TextStyle(color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey[800]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: Colors.grey[800]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Colors.orange),
                                ),
                                filled: true,
                                fillColor: const Color(0xFF252525),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                      const SizedBox(height: 12),
                    ],

                    // ── Track/playlist preview card ──
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF252525),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: widget.thumbnailUrl != null
                                ? Image.network(
                                    widget.thumbnailUrl!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _placeholderThumb(),
                                  )
                                : _placeholderThumb(),
                          ),
                          const SizedBox(width: 12),
                          // Title + artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.artist,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Action button ─────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _alreadyReposted
                              ? Colors.grey[800]
                              : Colors.white,
                          foregroundColor: _alreadyReposted
                              ? Colors.white
                              : Colors.black,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          disabledBackgroundColor: Colors.grey[700],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _alreadyReposted
                                    ? 'Remove Repost'
                                    : 'Repost',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[800],
      child: const Icon(Icons.music_note, color: Colors.grey, size: 24),
    );
  }
}
