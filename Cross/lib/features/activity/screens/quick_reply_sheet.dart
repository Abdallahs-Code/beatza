import 'package:flutter/material.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/engagement_social_interactions.dart';

// ── Quick Reply sheet — shown when tapping Reply on a comment/mention notification
// Matches the SoundCloud Quick Reply bottom sheet UI:
//   ↓  Quick Reply              (header row)
//   [thumb] Title / Artist      (track mini-card)
//   🔥👏😢 N  · X comments · X reposts
//   ──────────────────────────
//   [Comment list]
//   ──────────────────────────
//   "i love this 🖤"  "on repeat!!!"  "this is my vibe 🤝"
//   [○]  Add a comment at...   0:00

class QuickReplySheet extends StatefulWidget {
  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final String? trackThumbnailUrl;
  final int numComments;
  final int numReposts;

  const QuickReplySheet({
    super.key,
    required this.trackId,
    required this.trackTitle,
    this.trackArtist = '',
    this.trackThumbnailUrl,
    this.numComments = 0,
    this.numReposts = 0,
  });

  @override
  State<QuickReplySheet> createState() => _QuickReplySheetState();
}

class _QuickReplySheetState extends State<QuickReplySheet> {
  final _engagementApi = EngagementApiService();
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _loadingComments = true;
  bool _posting = false;

  static const _quickReplies = [
    'i love this 🖤',
    'on repeat!!!',
    'this is my vibe 🤝',
  ];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    final result = await _engagementApi.getTrackComments(
      trackId: widget.trackId,
      limit: 20,
    );
    if (!mounted) return;
    setState(() {
      _loadingComments = false;
      if (result.$1 == 200 && result.$2 is List) {
        _comments = (result.$2 as List).whereType<Comment>().toList();
      }
    });
  }

  Future<void> _postComment(String content) async {
    if (content.trim().isEmpty || _posting) return;
    setState(() => _posting = true);
    _inputController.clear();
    _focusNode.unfocus();

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = await AuthApiService().getStoredUserId() ?? '';
    // Optimistic insert
    final optimistic = Comment(
      tempId, userId, 'You', null, content, 0, 0, 0, false, false, DateTime.now().toIso8601String(),
    );
    setState(() => _comments.insert(0, optimistic));

    final result = await _engagementApi.postComment(
      trackId: widget.trackId,
      content: content,
      timestamp: 0,
    );
    if (!mounted) return;

    if (result.$1 == 201 && result.$2 is Comment) {
      setState(() {
        final idx = _comments.indexWhere((c) => c.commentId == tempId);
        if (idx >= 0) _comments[idx] = result.$2 as Comment;
      });
    } else {
      setState(() => _comments.removeWhere((c) => c.commentId == tempId));
    }
    setState(() => _posting = false);
  }

  Future<void> _toggleCommentLike(Comment comment) async {
    setState(() {
      comment.isLikedByUser = !comment.isLikedByUser;
      comment.numLikes += comment.isLikedByUser ? 1 : -1;
    });
    final result = await _engagementApi.toggleCommentLike(
      commentId: comment.commentId,
    );
    if (!mounted) return;
    if (result.$1 != 200) {
      setState(() {
        comment.isLikedByUser = !comment.isLikedByUser;
        comment.numLikes += comment.isLikedByUser ? 1 : -1;
      });
    }
  }

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
                    errorBuilder: (context, error, stackTrace) => _thumbPlaceholder(),
                  )
                : _thumbPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.trackTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
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
        children: [
          // Emoji reactions (static visual — matches SoundCloud)
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text('👏', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text('😢', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '${widget.numComments}',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
          ),
          const Spacer(),
          Text(
            '${widget.numComments} comments · ${widget.numReposts} reposts',
            style:
                const TextStyle(color: Color(0xFF888888), fontSize: 12),
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
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _comments.length,
      separatorBuilder: (context, index) =>
          const Divider(color: Color(0xFF1E1E1E), height: 1),
      itemBuilder: (context, i) => _buildCommentRow(_comments[i]),
    );
  }

  Widget _buildCommentRow(Comment comment) {
    final age = _formatAge(comment.createdAt);
    final ts = _formatTimestamp(comment.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name row: displayName | blue timestamp pill | age
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4BB8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'at $ts',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(age,
                        style: const TextStyle(
                            color: Color(0xFF777777), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                // Comment text
                Text(
                  comment.content,
                  style: const TextStyle(
                      color: Color(0xFFDDDDDD), fontSize: 14),
                ),
                const SizedBox(height: 6),
                // Actions: Reply · ···
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        _inputController.text =
                            '@${comment.displayName} ';
                        _inputController.selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset: _inputController.text.length),
                        );
                        _focusNode.requestFocus();
                      },
                      child: const Text('Reply',
                          style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 12),
                    const Text('···',
                        style: TextStyle(
                            color: Color(0xFF888888), fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          // Like heart
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

  Widget _buildQuickChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: _quickReplies
            .map((text) => GestureDetector(
                  onTap: () => _postComment(text),
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
                suffixText: '0:00',
                suffixStyle: const TextStyle(
                    color: Color(0xFF666666), fontSize: 13),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 6),
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

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatTimestamp(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
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
