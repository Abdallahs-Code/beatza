// Screen: CommentsScreen
// Full-page comments view for a track.
//
// Design matches SoundCloud (Image 14):
//   AppBar:   "28 comments" + filter icon (sort)
//   Below:    Track thumbnail + title + artist
//   Row:      emoji reactions (🔥👏😢) + total reaction count + comment count
//   Body:     ListView of CommentTile widgets
//   Bottom:   User avatar + "Comment at MM:SS" input + post button
//
// Navigation:
//   Opened from track options bottom sheet "View comments"
//   or from the player bar comment icon.
//   Navigator.pushNamed(context, EngagementRoutes.comments,
//     arguments: {
//       'trackId': track.id,
//       'trackTitle': track.title,
//       'trackArtist': track.artist,
//       'trackThumbnailUrl': track.thumbnailUrl,
//       'currentPositionSeconds': 25 * 60 + 6, // 25:06 from player
//     });
//
// Replies:
//   Tapping "Reply" on a CommentTile sets _replyingTo and focuses input.
//   Input shows "@username" prefix and posts with parentCommentId.
//   Tapping a "View X replies" row expands inline replies.
//
// Optimistic updates:
//   - Post comment: prepend to list immediately, remove on failure.
//   - Like comment: flip isLikedByUser + adjust numLikes locally, revert on failure.
//   - Delete comment: remove from list immediately, re-insert on failure.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/widgets/comment_tile.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';

class CommentsScreen extends StatefulWidget {
  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final String? trackThumbnailUrl;
  final int currentPositionSeconds; // from Module 5 player — defaults to 0

  const CommentsScreen({
    super.key,
    required this.trackId,
    required this.trackTitle,
    required this.trackArtist,
    this.trackThumbnailUrl,
    this.currentPositionSeconds = 0,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final EngagementApiService _service = EngagementApiService();
  final AuthApiService _authService = AuthApiService();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // ── Local like persistence (shared across screen instances this session) ──
  static const FlutterSecureStorage _likeStorage = FlutterSecureStorage();
  static Set<String> _sessionLikedIds = {};
  static bool _sessionLikedLoaded = false;

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isPosting = false;
  String? _errorMessage;
  int _offset = 1;
  static const int _pageSize = 20;

  // Sort state — maps to API sortBy param
  String _sortBy = 'newest';
  static const Map<String, String> _sortLabels = {
    'newest': 'Newest',
    'oldest': 'Oldest',
    'trackTime': 'Track time',
  };

  // Reply state — set when user taps "Reply" on a CommentTile
  Comment? _replyingTo;

  // Expanded replies — commentId → list of reply Comments
  final Map<String, List<Comment>> _expandedReplies = {};
  final Set<String> _loadingReplies = {};

  // Live playback position — updated from player listener
  late int _currentPositionSeconds;

  // Current user identity for avatar and optimistic comments
  String? _currentUserId;
  String _currentUserDisplayName = 'You';
  String? _currentUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentPositionSeconds = widget.currentPositionSeconds;
    PlaybackStreamingEngineService.shared.addListener(_onPlayerUpdate);
    _loadLocalLikedState().then((_) => _loadComments());
    _loadCurrentUser();
  }

  // ── Load persisted liked comment IDs from secure storage ──
  Future<void> _loadLocalLikedState() async {
    if (_sessionLikedLoaded) return;
    try {
      final raw = await _likeStorage.read(key: 'liked_comment_ids');
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _sessionLikedIds = Set<String>.from(list.map((e) => e.toString()));
      }
    } catch (_) {}
    _sessionLikedLoaded = true;
  }

  // ── Persist a like toggle to secure storage ──
  Future<void> _persistLikedId(String commentId, bool isNowLiked) async {
    if (isNowLiked) {
      _sessionLikedIds.add(commentId);
    } else {
      _sessionLikedIds.remove(commentId);
    }
    try {
      await _likeStorage.write(
        key: 'liked_comment_ids',
        value: jsonEncode(_sessionLikedIds.toList()),
      );
    } catch (_) {}
  }

  // ── Apply locally persisted liked state to comments list ──
  void _applyLocalLikedState(List<Comment> comments) {
    for (final c in comments) {
      if (!c.isLikedByUser && _sessionLikedIds.contains(c.commentId)) {
        c.isLikedByUser = true;
      }
    }
  }

  @override
  void dispose() {
    PlaybackStreamingEngineService.shared.removeListener(_onPlayerUpdate);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlayerUpdate() {
    final int pos = PlaybackStreamingEngineService.shared
        .state.currentPosition.inSeconds;
    if (_currentPositionSeconds != pos) {
      setState(() => _currentPositionSeconds = pos);
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final token = await _authService.getStoredAccessToken();
      final userId = await _authService.getStoredUserId();
      if (token == null || userId == null) return;
      if (mounted) setState(() => _currentUserId = userId);
      final profile =
          await UserProfileService().getUserProfile(userId, token);
      if (!mounted) return;
      setState(() {
        _currentUserDisplayName = profile.resolvedDisplayName;
        _currentUserAvatarUrl = profile.profileImgLink.trim().isEmpty
            ? null
            : profile.profileImgLink.trim();
      });
    } catch (_) {}
  }

  Future<void> _navigateToProfile(String userId) async {
    try {
      final token = await _authService.getStoredAccessToken() ?? '';
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        UserProfileSocialIdentityRoutes.userProfileRoute,
        arguments: {
          'userId': userId,
          'token': token,
          'currentUserId': _currentUserId ?? '',
        },
      );
    } catch (_) {}
  }

  // ─────────────────────────────────────────────
  // Load first page of comments
  // ─────────────────────────────────────────────
  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _service.getTrackComments(
      trackId: widget.trackId,
      offset: 1,
      limit: _pageSize,
      sortBy: _sortBy,
    );

    setState(() {
      _isLoading = false;
      if (result.$1 == 200) {
        _comments = result.$2 as List<Comment>;
        _applyLocalLikedState(_comments);
        _offset = 1;
      } else {
        _errorMessage = result.$2.toString();
      }
    });
  }

  // ─────────────────────────────────────────────
  // Load next page (pagination)
  // ─────────────────────────────────────────────
  Future<void> _loadMore() async {
    if (_isLoadingMore || _comments.length < _pageSize) return;
    setState(() => _isLoadingMore = true);

    final result = await _service.getTrackComments(
      trackId: widget.trackId,
      offset: _offset + 1,
      limit: _pageSize,
      sortBy: _sortBy,
    );

    setState(() {
      _isLoadingMore = false;
      if (result.$1 == 200) {
        _comments.addAll(result.$2 as List<Comment>);
        _offset++;
      }
    });
  }

  // ─────────────────────────────────────────────
  // Post a new comment or reply — optimistic
  // ─────────────────────────────────────────────
  Future<void> _postComment() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);

    // Build optimistic comment with the live player position and real user info.
    final optimistic = Comment(
      'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      _currentUserId ?? '',
      _currentUserDisplayName,
      _currentUserAvatarUrl,
      content,
      _currentPositionSeconds,
      0,
      0,
      false,
      true, // isOwnComment = true
      DateTime.now().toIso8601String(),
    );

    // Optimistically prepend.
    setState(() {
      if (_replyingTo != null) {
        // Add as first reply in expanded list.
        final replies = _expandedReplies[_replyingTo!.commentId] ?? [];
        _expandedReplies[_replyingTo!.commentId] = [optimistic, ...replies];
      } else {
        _comments.insert(0, optimistic);
      }
    });

    _inputController.clear();
    final replyingToId = _replyingTo?.commentId;
    setState(() => _replyingTo = null);

    final result = await _service.postComment(
      trackId: widget.trackId,
      content: content,
      timestamp: _currentPositionSeconds,
      parentCommentId: replyingToId,
    );

    if (!mounted) return;

    setState(() => _isPosting = false);

    if (result.$1 == 201) {
      if (replyingToId != null) {
        // Reload replies for the parent comment to get fresh server data.
        final repliesResult = await _service.getCommentReplies(commentId: replyingToId);
        if (!mounted) return;
        if (repliesResult.$1 == 200) {
          final fresh = repliesResult.$2 as List<Comment>;
          _applyLocalLikedState(fresh);
          setState(() => _expandedReplies[replyingToId] = fresh);
        } else {
          // Fallback: just replace optimistic with real.
          final real = result.$2 as Comment;
          final replies = _expandedReplies[replyingToId] ?? [];
          final idx = replies.indexWhere((c) => c.commentId == optimistic.commentId);
          if (idx != -1) replies[idx] = real;
          setState(() => _expandedReplies[replyingToId] = replies);
        }
      } else {
        // Reload full comment list so count and ordering are accurate.
        _loadComments();
      }
    } else {
      // Rollback optimistic insert.
      setState(() {
        if (replyingToId != null) {
          final replies = _expandedReplies[replyingToId] ?? [];
          replies.removeWhere((c) => c.commentId == optimistic.commentId);
          _expandedReplies[replyingToId] = replies;
        } else {
          _comments.removeWhere((c) => c.commentId == optimistic.commentId);
        }
      });
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Toggle like on a comment — optimistic
  // ─────────────────────────────────────────────
  Future<void> _toggleCommentLike(Comment comment) async {
    // Optimistic update.
    final wasLiked = comment.isLikedByUser;
    setState(() {
      comment.isLikedByUser = !wasLiked;
      comment.numLikes = wasLiked
          ? comment.numLikes - 1
          : comment.numLikes + 1;
    });

    final result = await _service.toggleCommentLike(
      commentId: comment.commentId,
    );

    if (!mounted) return;

    if (result.$1 == 200) {
      // Sync with server's authoritative count.
      final bool nowLiked = result.$2['liked'] as bool? ?? !wasLiked;
      setState(() {
        comment.isLikedByUser = nowLiked;
        comment.numLikes = result.$2['numLikes'] as int? ?? comment.numLikes;
      });
      _persistLikedId(comment.commentId, nowLiked);
    } else {
      // Revert.
      setState(() {
        comment.isLikedByUser = wasLiked;
        comment.numLikes = wasLiked
            ? comment.numLikes + 1
            : comment.numLikes - 1;
      });
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Delete a comment or reply — optimistic
  // ─────────────────────────────────────────────
  Future<void> _deleteComment(Comment comment) async {
    // Determine if this is a top-level comment or a reply.
    final int topIdx = _comments.indexOf(comment);
    String? replyParentId;
    int replyIdx = -1;

    if (topIdx >= 0) {
      // Top-level comment — remove from list.
      setState(() => _comments.removeAt(topIdx));
    } else {
      // Search expanded reply lists.
      for (final entry in _expandedReplies.entries) {
        final int i = entry.value.indexOf(comment);
        if (i >= 0) {
          replyParentId = entry.key;
          replyIdx = i;
          final updated = List<Comment>.from(entry.value)..removeAt(i);
          setState(() => _expandedReplies[replyParentId!] = updated);
          break;
        }
      }
      if (replyParentId == null) return; // comment not found anywhere
    }

    final result = await _service.deleteComment(
      commentId: comment.commentId,
    );

    if (!mounted) return;

    if (result.$1 != 200) {
      // Revert optimistic removal.
      setState(() {
        if (replyParentId != null) {
          final replies = List<Comment>.from(
              _expandedReplies[replyParentId] ?? <Comment>[]);
          if (replyIdx >= 0 && replyIdx <= replies.length) {
            replies.insert(replyIdx, comment);
          } else {
            replies.add(comment);
          }
          _expandedReplies[replyParentId] = replies;
        } else {
          if (topIdx >= 0 && topIdx <= _comments.length) {
            _comments.insert(topIdx, comment);
          } else {
            _comments.add(comment);
          }
        }
      });
      _showSnackbar(result.$2.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Load replies for a comment (expand/collapse)
  // ─────────────────────────────────────────────
  Future<void> _toggleReplies(Comment comment) async {
    final id = comment.commentId;

    // Collapse if already expanded.
    if (_expandedReplies.containsKey(id)) {
      setState(() => _expandedReplies.remove(id));
      return;
    }

    // Fetch replies.
    setState(() => _loadingReplies.add(id));

    final result = await _service.getCommentReplies(commentId: id);

    setState(() {
      _loadingReplies.remove(id);
      if (result.$1 == 200) {
        final replies = result.$2 as List<Comment>;
        _applyLocalLikedState(replies);
        _expandedReplies[id] = replies;
      } else {
        _showSnackbar(result.$2.toString());
      }
    });
  }

  // ─────────────────────────────────────────────
  // Set up reply input
  // ─────────────────────────────────────────────
  void _startReply(Comment comment) {
    setState(() => _replyingTo = comment);
    _inputFocusNode.requestFocus();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ─────────────────────────────────────────────
  // Format live playback position as MM:SS
  // ─────────────────────────────────────────────
  String get _formattedPosition {
    final m = _currentPositionSeconds ~/ 60;
    final s = _currentPositionSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLoading
              ? 'Comments'
              : '${_comments.length} comment${_comments.length == 1 ? '' : 's'}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          // Sort filter icon
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white, size: 20),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Track info header ──────────────────
          _buildTrackHeader(),

          const Divider(color: Color(0xFF1A1A1A), height: 1),

          // ── Comments list ──────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _comments.isEmpty
                        ? _buildEmptyState()
                        : _buildCommentsList(),
          ),

          // ── Reply-to indicator ─────────────────
          if (_replyingTo != null) _buildReplyIndicator(),

          // ── Comment input bar ──────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Track header (thumbnail + title + artist) ──
  Widget _buildTrackHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: widget.trackThumbnailUrl != null
                ? Image.network(
                    widget.trackThumbnailUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => _thumbPlaceholder(),
                  )
                : _thumbPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.trackTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.trackArtist,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      color: Colors.grey[800],
      child: const Icon(Icons.music_note, color: Colors.grey, size: 20),
    );
  }

  // ── Comments list with inline replies ──────────
  Widget _buildCommentsList() {
    // Flatten comments + their inline replies into one list.
    final List<Widget> items = [];

    for (final comment in _comments) {
      items.add(CommentTile(
        comment: comment,
        isReply: false,
        onLikeTap: () => _toggleCommentLike(comment),
        onReplyTap: () => _startReply(comment),
        onTimestampTap: () {
          PlaybackStreamingEngineService.shared
              .seek(Duration(seconds: comment.timestamp))
              .then((_) => PlaybackStreamingEngineService.shared.resume());
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Playing from ${comment.formattedTimestamp}'),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF1A1A1A),
          ));
        },
        onDeleteTap: (comment.isOwnComment ||
                (comment.userId.isNotEmpty &&
                    comment.userId == _currentUserId))
            ? () => _confirmDelete(comment)
            : null,
        onGoToProfileTap: comment.userId.isNotEmpty
            ? () => _navigateToProfile(comment.userId)
            : null,
      ));

      // Show expand/collapse replies button if comment has replies (or
      // if we've already added replies programmatically, e.g. after posting).
      if (comment.replyCount > 0 ||
          _expandedReplies.containsKey(comment.commentId)) {
        final isExpanded = _expandedReplies.containsKey(comment.commentId);
        final isLoadingThis = _loadingReplies.contains(comment.commentId);

        items.add(
          Padding(
            padding: const EdgeInsets.only(left: 52, bottom: 4),
            child: isLoadingThis
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  )
                : GestureDetector(
                    onTap: () => _toggleReplies(comment),
                    child: Text(
                      isExpanded
                          ? 'Hide replies'
                          : 'View ${comment.replyCount} '
                              'repl${comment.replyCount == 1 ? 'y' : 'ies'}',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        );

        // Render expanded replies inline.
        if (isExpanded) {
          final replies = _expandedReplies[comment.commentId] ?? [];
          for (final reply in replies) {
            items.add(CommentTile(
              comment: reply,
              isReply: true,
              onLikeTap: () => _toggleCommentLike(reply),
              onReplyTap: () => _startReply(comment), // reply to parent
              onTimestampTap: () {
                PlaybackStreamingEngineService.shared.seek(
                  Duration(seconds: reply.timestamp),
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Playing from ${reply.formattedTimestamp}'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF1A1A1A),
                ));
              },
              onDeleteTap: (reply.isOwnComment ||
                      (reply.userId.isNotEmpty &&
                          reply.userId == _currentUserId))
                  ? () => _confirmDelete(reply)
                  : null,
              onGoToProfileTap: reply.userId.isNotEmpty
                  ? () => _navigateToProfile(reply.userId)
                  : null,
            ));
          }
        }
      }

      items.add(Divider(height: 1, color: Colors.grey[900]));
    }

    // Load more at the bottom.
    if (_comments.length >= _pageSize) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _isLoadingMore
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.orange))
              : Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text('Load more',
                        style: TextStyle(color: Colors.orange)),
                  ),
                ),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      children: items,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!,
              style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadComments,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              color: Colors.grey[700], size: 48),
          const SizedBox(height: 12),
          Text(
            'No comments yet.\nBe the first to comment!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Reply-to indicator bar ──────────────────────
  Widget _buildReplyIndicator() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Replying to ${_replyingTo!.displayName}',
            style:
                const TextStyle(color: Colors.orange, fontSize: 12),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: const Icon(Icons.close, color: Colors.grey, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Comment input bar ──────────────────────────
  Widget _buildInputBar() {
    return Container(
      color: const Color(0xFF111111),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 20,
      ),
      child: Row(
        children: [
          // Current user avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.grey[800],
            backgroundImage: _currentUserAvatarUrl != null
                ? NetworkImage(_currentUserAvatarUrl!)
                : null,
            child: _currentUserAvatarUrl == null
                ? Text(
                    _currentUserDisplayName.isNotEmpty
                        ? _currentUserDisplayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          // Text input
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _postComment(),
              decoration: InputDecoration(
                hintText: _replyingTo != null
                    ? '@${_replyingTo!.displayName}'
                    : 'Comment at $_formattedPosition',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF222222),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Post button
          GestureDetector(
            onTap: _isPosting ? null : _postComment,
            child: _isPosting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.orange),
                  )
                : const Icon(Icons.send, color: Colors.orange, size: 22),
          ),
        ],
      ),
    );
  }

  // ── Sort bottom sheet ──────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort by',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            ..._sortLabels.entries.map((entry) => ListTile(
                  title: Text(entry.value,
                      style: const TextStyle(color: Colors.white)),
                  trailing: _sortBy == entry.key
                      ? const Icon(Icons.check, color: Colors.orange)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (_sortBy != entry.key) {
                      setState(() => _sortBy = entry.key);
                      _loadComments();
                    }
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Delete confirmation dialog ─────────────────
  void _confirmDelete(Comment comment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete comment',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(comment);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
