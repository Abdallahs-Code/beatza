import 'package:flutter/material.dart';
import 'package:cross_team5/features/activity/screens/quick_reply_options_menu.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';
import 'package:cross_team5/features/followers_social_graph/followers_social_graph.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_track_api_service.dart';

class QuickReplySheet extends StatefulWidget {
  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final String? trackThumbnailUrl;
  final int numComments;
  final int numReposts;
  final String? initialParentCommentId;
  final String? initialMentionDisplayName;
  final int? initialTimestamp;

  const QuickReplySheet({
    super.key,
    required this.trackId,
    required this.trackTitle,
    this.trackArtist = '',
    this.trackThumbnailUrl,
    this.numComments = 0,
    this.numReposts = 0,
    this.initialParentCommentId,
    this.initialMentionDisplayName,
    this.initialTimestamp,
  });

  @override
  State<QuickReplySheet> createState() => _QuickReplySheetState();
}

class _QuickReplySheetState extends State<QuickReplySheet> {
  final EngagementApiService _engagementApi = EngagementApiService();
  final SocialApiService _socialApi = SocialApiService();
  final AuthApiService _authApi = AuthApiService();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _loadingComments = true;
  bool _posting = false;
  bool _initialReplySetupDone = false;

  // Expanded replies — commentId → list of reply Comments
  final Map<String, List<Comment>> _expandedReplies = {};
  final Set<String> _loadingReplies = {};

  // Reply state — tracks which comment we are replying to
  Comment? _replyingTo;

  // Live playback position for the timestamp suffix
  int _currentPositionSeconds = 0;

  // Live track stats
  int _numComments = 0;
  int _numReposts = 0;
  PlaybackTrackModel? _trackModel;

  // @ mention state
  String? _currentUserId;
  List<Follower> _followingUsers = [];
  List<Follower> _mentionSuggestions = [];
  bool _showMentionSuggestions = false;

  static const _quickReplies = [
    'i love this 🖤',
    'on repeat!!!',
    'this is my vibe 🤝',
  ];

  @override
  void initState() {
    super.initState();
    _numComments = widget.numComments;
    _numReposts = widget.numReposts;
    _loadComments();
    _loadCurrentUser();
    _loadTrackData();
    // Sync initial playback position
    _currentPositionSeconds =
        PlaybackStreamingEngineService.shared.state.currentPosition.inSeconds;
    PlaybackStreamingEngineService.shared.addListener(_onPlayerUpdate);
    _inputController.addListener(_onTextChanged);
  }

  Future<void> _loadTrackData() async {
    try {
      final track =
          await PlaybackTrackApiService().getSingleTrackById(widget.trackId);
      if (!mounted) return;
      setState(() {
        _trackModel = track;
        _numComments = track.numComments;
        _numReposts = track.numReposts;
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    PlaybackStreamingEngineService.shared.removeListener(_onPlayerUpdate);
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlayerUpdate() {
    final pos =
        PlaybackStreamingEngineService.shared.state.currentPosition.inSeconds;
    if (mounted && _currentPositionSeconds != pos) {
      setState(() => _currentPositionSeconds = pos);
    }
  }

  Future<void> _loadCurrentUser() async {
    final userId = await _authApi.getStoredUserId();
    if (!mounted || userId == null) return;
    setState(() => _currentUserId = userId);
    // Load following list for @ mention suggestions
    final result = await _socialApi.getFollowing(userId: userId);
    if (!mounted) return;
    if (result.$1 == 200 && result.$2 is List) {
      setState(() => _followingUsers = result.$2 as List<Follower>);
    }
  }

  // Detects @ in the text field and filters following users for suggestions
  void _onTextChanged() {
    final text = _inputController.text;
    final cursor =
        _inputController.selection.baseOffset.clamp(0, text.length);
    final beforeCursor = text.substring(0, cursor);
    final atIndex = beforeCursor.lastIndexOf('@');

    if (atIndex >= 0) {
      final query = beforeCursor.substring(atIndex + 1);
      if (!query.contains(' ')) {
        final filtered = query.isEmpty
            ? _followingUsers
            : _followingUsers
                .where((u) => u.displayName
                    .toLowerCase()
                    .contains(query.toLowerCase()))
                .toList();
        if (filtered.isNotEmpty) {
          setState(() {
            _mentionSuggestions = filtered.take(5).toList();
            _showMentionSuggestions = true;
          });
          return;
        }
      }
    }
    if (_showMentionSuggestions) {
      setState(() => _showMentionSuggestions = false);
    }
  }

  // Inserts @displayName into the text field replacing the current @query
  void _insertMention(Follower user) {
    final text = _inputController.text;
    final cursor =
        _inputController.selection.baseOffset.clamp(0, text.length);
    final beforeCursor = text.substring(0, cursor);
    final afterCursor = text.substring(cursor);
    final atIndex = beforeCursor.lastIndexOf('@');
    final newBefore = atIndex >= 0
        ? '${beforeCursor.substring(0, atIndex)}@${user.displayName} '
        : beforeCursor;
    _inputController.value = TextEditingValue(
      text: '$newBefore$afterCursor',
      selection: TextSelection.collapsed(offset: newBefore.length),
    );
    setState(() => _showMentionSuggestions = false);
  }

  Future<void> _loadComments() async {
    final result = await _engagementApi.getTrackComments(
      trackId: widget.trackId,
      limit: 50,
    );
    if (!mounted) return;
    setState(() {
      _loadingComments = false;
      if (result.$1 == 200 && result.$2 is List) {
        _comments = (result.$2 as List).whereType<Comment>().toList();
      }
    });
    if (!_initialReplySetupDone) {
      _initialReplySetupDone = true;
      _setupInitialReply();
    }
  }

  void _setupInitialReply() {
    final parentId = widget.initialParentCommentId;
    if (parentId == null || parentId.isEmpty) return;
    final match = _comments.cast<Comment?>().firstWhere(
          (c) => c?.commentId == parentId,
          orElse: () => null,
        );
    if (match != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _startReply(match);
      });
    } else {
      // Fallback: pre-fill mention and timestamp without a found comment
      final mention = widget.initialMentionDisplayName;
      if (mention != null && mention.isNotEmpty) {
        _inputController.text = '@$mention ';
        _inputController.selection =
            TextSelection.collapsed(offset: _inputController.text.length);
      }
      if (widget.initialTimestamp != null) {
        setState(() => _currentPositionSeconds = widget.initialTimestamp!);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  // Timestamp used when posting: reply uses parent's track timestamp,
  // otherwise use live playback position.
  int get _effectiveTimestamp =>
      _replyingTo?.timestamp ?? _currentPositionSeconds;

  String get _formattedTimestamp {
    final s = _effectiveTimestamp;
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  Future<void> _postComment(String content) async {
    if (content.trim().isEmpty || _posting) return;
    setState(() => _posting = true);
    _inputController.clear();
    _focusNode.unfocus();

    final replyingTo = _replyingTo;
    setState(() {
      _replyingTo = null;
      _showMentionSuggestions = false;
    });

    final userId = await _authApi.getStoredUserId() ?? '';
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final optimistic = Comment(
      tempId, userId, 'You', null, content,
      _effectiveTimestamp, 0, 0, false, false,
      DateTime.now().toIso8601String(),
    );

    // Insert optimistic: replies go directly after their parent in the list
    if (replyingTo != null) {
      final parentIdx =
          _comments.indexWhere((c) => c.commentId == replyingTo.commentId);
      setState(() => _comments.insert(
          parentIdx >= 0 ? parentIdx + 1 : 0, optimistic));
    } else {
      setState(() => _comments.insert(0, optimistic));
    }

    final result = await _engagementApi.postComment(
      trackId: widget.trackId,
      content: content,
      timestamp: _effectiveTimestamp,
      parentCommentId: replyingTo?.commentId,
    );
    if (!mounted) return;

    if (result.$1 == 201 && result.$2 is Comment) {
      final real = result.$2 as Comment;
      setState(() {
        final i = _comments.indexWhere((c) => c.commentId == tempId);
        if (i >= 0) _comments[i] = real;
      });
      _loadComments();
    } else {
      setState(() => _comments.removeWhere((c) => c.commentId == tempId));
    }
    setState(() => _posting = false);
  }

  // Exact same pattern as CommentsScreen._toggleCommentLike
  Future<void> _toggleCommentLike(Comment comment) async {
    final wasLiked = comment.isLikedByUser;
    setState(() {
      comment.isLikedByUser = !wasLiked;
      comment.numLikes = wasLiked ? comment.numLikes - 1 : comment.numLikes + 1;
    });
    final result = await _engagementApi.toggleCommentLike(
      commentId: comment.commentId,
    );
    if (!mounted) return;
    if (result.$1 == 200) {
      final bool nowLiked = result.$2['liked'] as bool? ?? !wasLiked;
      setState(() {
        comment.isLikedByUser = nowLiked;
        comment.numLikes = result.$2['numLikes'] as int? ?? comment.numLikes;
      });
    } else {
      setState(() {
        comment.isLikedByUser = wasLiked;
        comment.numLikes = wasLiked ? comment.numLikes + 1 : comment.numLikes - 1;
      });
    }
  }

  Future<void> _seekToTimestamp(int seconds) async {
    final service = PlaybackStreamingEngineService.shared;
    if (service.state.currentTrack?.id == widget.trackId) {
      service.seek(Duration(seconds: seconds));
    } else {
      final track = _trackModel;
      if (track == null) return;
      await service.playTrack(track);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) service.seek(Duration(seconds: seconds));
    }
  }

  Future<void> _navigateToProfile(String userId) async {
    if (userId.isEmpty) return;
    final token = await _authApi.getStoredAccessToken() ?? '';
    final currentUserId = await _authApi.getStoredUserId();
    if (!mounted) return;
    Navigator.pushNamed(context, '/user_profile', arguments: {
      'userId': userId,
      'token': token,
      'currentUserId': currentUserId,
    });
  }

  Future<void> _toggleReplies(Comment comment) async {
    final id = comment.commentId;
    if (_expandedReplies.containsKey(id)) {
      setState(() => _expandedReplies.remove(id));
      return;
    }
    setState(() => _loadingReplies.add(id));
    final result = await _engagementApi.getCommentReplies(commentId: id);
    setState(() {
      _loadingReplies.remove(id);
      if (result.$1 == 200 && result.$2 is List) {
        _expandedReplies[id] = (result.$2 as List).whereType<Comment>().toList();
      }
    });
  }

  Future<void> _deleteComment(Comment comment) async {
    final topIdx = _comments.indexWhere((c) => c.commentId == comment.commentId);
    String? replyParentId;
    int replyIdx = -1;

    if (topIdx >= 0) {
      setState(() => _comments.removeAt(topIdx));
    } else {
      for (final entry in _expandedReplies.entries) {
        final i = entry.value.indexWhere((c) => c.commentId == comment.commentId);
        if (i >= 0) {
          replyParentId = entry.key;
          replyIdx = i;
          final updated = List<Comment>.from(entry.value)..removeAt(i);
          setState(() => _expandedReplies[replyParentId!] = updated);
          break;
        }
      }
      if (replyParentId == null) return;
    }

    final result = await _engagementApi.deleteComment(commentId: comment.commentId);
    if (!mounted) return;
    if (result.$1 != 200) {
      setState(() {
        if (replyParentId != null) {
          final replies = List<Comment>.from(_expandedReplies[replyParentId] ?? []);
          if (replyIdx >= 0) replies.insert(replyIdx, comment);
          _expandedReplies[replyParentId] = replies;
        } else if (topIdx >= 0) {
          _comments.insert(topIdx, comment);
        }
      });
    }
  }

  void _confirmDelete(Comment comment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete comment',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this comment?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(comment);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Sets _replyingTo, pre-fills @username, focuses input
  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _showMentionSuggestions = false;
    });
    _inputController.text = '@${comment.displayName} ';
    _inputController.selection =
        TextSelection.collapsed(offset: _inputController.text.length);
    _focusNode.requestFocus();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTrackCard(),
          _buildStatsRow(),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          Expanded(child: _buildCommentList()),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          if (_replyingTo != null) _buildReplyIndicator(),
          if (_showMentionSuggestions) _buildMentionSuggestions(),
          _buildQuickChips(),
          _buildInputRow(),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Expanded(
            child: Text(
              'Quick Reply',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTrackCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: widget.trackThumbnailUrl?.isNotEmpty == true
                ? Image.network(
                    widget.trackThumbnailUrl!,
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _thumbPlaceholder(),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                if (widget.trackArtist.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(widget.trackArtist,
                      style: const TextStyle(
                          color: Color(0xFF888888), fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFF222222),
      alignment: Alignment.center,
      child: const Icon(Icons.graphic_eq_rounded,
          color: Color(0xFF555555), size: 24),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$_numComments comments · $_numReposts reposts',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentList() {
    if (_loadingComments) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFFF5500), strokeWidth: 2));
    }
    if (_comments.isEmpty) {
      return const Center(
        child: Text('No comments yet. Be the first!',
            style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
      );
    }

    final items = <Widget>[];
    for (final comment in _comments) {
      items.add(_buildCommentRow(comment, isReply: false));
      items.add(const Divider(color: Color(0xFF1E1E1E), height: 1));

      if (comment.replyCount > 0 ||
          _expandedReplies.containsKey(comment.commentId)) {
        final isExpanded = _expandedReplies.containsKey(comment.commentId);
        final isLoadingThis = _loadingReplies.contains(comment.commentId);

        items.add(Padding(
          padding: const EdgeInsets.only(left: 52, bottom: 4),
          child: isLoadingThis
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFFFF5500)),
                )
              : GestureDetector(
                  onTap: () => _toggleReplies(comment),
                  child: Text(
                    isExpanded
                        ? 'Hide replies'
                        : 'View ${comment.replyCount} '
                              'repl${comment.replyCount == 1 ? 'y' : 'ies'}',
                    style: const TextStyle(
                        color: Color(0xFFFF5500),
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ),
        ));

        if (isExpanded) {
          for (final reply in _expandedReplies[comment.commentId] ?? []) {
            items.add(_buildCommentRow(reply, isReply: true));
            items.add(const Divider(color: Color(0xFF1E1E1E), height: 1));
          }
        }
      }
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items,
    );
  }

  Widget _buildCommentRow(Comment comment, {bool isReply = false}) {
    return Padding(
      padding: EdgeInsets.only(
          left: isReply ? 52 : 14, right: 14, top: 10, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(comment.userId),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF2A2A2A),
              backgroundImage: comment.avatarUrl?.isNotEmpty == true
                  ? NetworkImage(comment.avatarUrl!)
                  : null,
              child: comment.avatarUrl?.isNotEmpty != true
                  ? Text(
                      comment.displayName.isNotEmpty
                          ? comment.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _seekToTimestamp(comment.timestamp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A4BB8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'at ${comment.formattedTimestamp}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatAge(comment.createdAt),
                      style: const TextStyle(
                          color: Color(0xFF777777), fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content,
                    style: const TextStyle(
                        color: Color(0xFFDDDDDD), fontSize: 14)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (!isReply) ...[
                      GestureDetector(
                        onTap: () => _startReply(comment),
                        child: const Text('Reply',
                            style: TextStyle(
                                color: Color(0xFF888888),
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 12),
                    ],
                    GestureDetector(
                      onTap: () => QuickReplyOptionsMenu.show(
                        context,
                        comment: comment,
                        onTimestampTap: () => _seekToTimestamp(comment.timestamp),
                        onGoToProfileTap: comment.userId.isNotEmpty
                            ? () => _navigateToProfile(comment.userId)
                            : null,
                        onDeleteTap: (comment.isOwnComment ||
                                comment.userId == _currentUserId)
                            ? () => _confirmDelete(comment)
                            : null,
                      ),
                      child: const Text('···',
                          style: TextStyle(
                              color: Color(0xFF888888), fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Like heart — exact same pattern as CommentsScreen comment tile
          GestureDetector(
            onTap: () => _toggleCommentLike(comment),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Column(
                children: [
                  Icon(
                    comment.isLikedByUser
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: comment.isLikedByUser
                        ? const Color(0xFFFF5500)
                        : const Color(0xFF777777),
                    size: 18,
                  ),
                  if (comment.numLikes > 0)
                    Text('${comment.numLikes}',
                        style: const TextStyle(
                            color: Color(0xFF777777), fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Shows "Replying to @username" bar with a dismiss X
  Widget _buildReplyIndicator() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Replying to @${_replyingTo!.displayName}',
            style: const TextStyle(color: Color(0xFFFF5500), fontSize: 12),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() {
              _replyingTo = null;
              _inputController.clear();
            }),
            child: const Icon(Icons.close, color: Colors.grey, size: 16),
          ),
        ],
      ),
    );
  }

  // Floating suggestion list shown when user types @query
  Widget _buildMentionSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      color: const Color(0xFF1A1A1A),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _mentionSuggestions.length,
        itemBuilder: (_, i) {
          final user = _mentionSuggestions[i];
          return InkWell(
            onTap: () => _insertMention(user),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF2A2A2A),
                    backgroundImage:
                        user.profileImgLink?.isNotEmpty == true
                            ? NetworkImage(user.profileImgLink!)
                            : null,
                    child: user.profileImgLink?.isNotEmpty != true
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text('@${user.displayName}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: _quickReplies
            .map((text) => GestureDetector(
                  onTap: () {
                    _inputController.text = text;
                    _inputController.selection = TextSelection.collapsed(
                        offset: text.length);
                    _focusNode.requestFocus();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF222222),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF333333)),
                    ),
                    child: Text(text,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildInputRow() {
    return Container(
      color: const Color(0xFF111111),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF2A2A2A),
            child: Icon(Icons.person_rounded,
                color: Colors.white54, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: _postComment,
              decoration: InputDecoration(
                hintText: 'Add a comment at...',
                hintStyle: const TextStyle(
                    color: Color(0xFF666666), fontSize: 14),
                border: InputBorder.none,
                // Dynamic timestamp: uses parent comment's timestamp when
                // replying, otherwise live playback position.
                suffixText: _formattedTimestamp,
                suffixStyle: const TextStyle(
                    color: Color(0xFF666666), fontSize: 13),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          if (_posting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Color(0xFFFF5500), strokeWidth: 2),
            )
          else
            GestureDetector(
              onTap: () => _postComment(_inputController.text),
              child: const Icon(Icons.send_rounded,
                  color: Color(0xFFFF5500), size: 20),
            ),
        ],
      ),
    );
  }

  String _formatAge(String createdAt) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
