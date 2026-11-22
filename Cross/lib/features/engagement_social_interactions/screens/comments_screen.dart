































import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/models/comment.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';
import 'package:cross_team5/features/engagement_social_interactions/widgets/comment_tile.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_track_api_service.dart';
import 'package:cross_team5/core/navigation/profile_navigator.dart';
import 'package:cross_team5/features/user_profile_social_identity/user_profile_social_identity.dart';

class CommentsScreen extends StatefulWidget {
  final String trackId;
  final String trackTitle;
  final String trackArtist;
  final String? trackThumbnailUrl;
  final int currentPositionSeconds; 
  final bool syncWithPlayer; 

  const CommentsScreen({
    super.key,
    required this.trackId,
    required this.trackTitle,
    required this.trackArtist,
    this.trackThumbnailUrl,
    this.currentPositionSeconds = 0,
    this.syncWithPlayer = true,
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

  
  List<MentionUser> _mentionFollowers = [];
  List<MentionUser> _mentionSuggestions = [];
  bool _showMentionSuggestions = false;
  String? _pendingMentionedUserId;

  
  static const FlutterSecureStorage _likeStorage = FlutterSecureStorage();
  static Set<String> _sessionLikedIds = {};
  static bool _sessionLikedLoaded = false;

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isPosting = false;
  String? _errorMessage;
  int _offset = 1;
  int _totalCommentCount = 0;
  static const int _pageSize = 20;

  
  String _sortBy = 'newest';
  static const Map<String, String> _sortLabels = {
    'newest': 'Newest',
    'oldest': 'Oldest',
    'trackTime': 'Track time',
  };

  
  Comment? _replyingTo;

  
  final Map<String, List<Comment>> _expandedReplies = {};
  final Set<String> _loadingReplies = {};

  
  late int _currentPositionSeconds;

  
  String? _currentUserId;
  String _currentUserDisplayName = 'You';
  String? _currentUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _currentPositionSeconds = widget.currentPositionSeconds;
    if (widget.syncWithPlayer) {
      PlaybackStreamingEngineService.shared.addListener(_onPlayerUpdate);
    }
    _loadLocalLikedState().then((_) => _loadComments());
    _loadCurrentUser();
    _fetchTotalCommentCount();
    _inputController.addListener(_onMentionTextChanged);
  }

  
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

  
  void _applyLocalLikedState(List<Comment> comments) {
    for (final c in comments) {
      if (!c.isLikedByUser && _sessionLikedIds.contains(c.commentId)) {
        c.isLikedByUser = true;
      }
    }
  }

  @override
  void dispose() {
    if (widget.syncWithPlayer) {
      PlaybackStreamingEngineService.shared.removeListener(_onPlayerUpdate);
    }
    _inputController.removeListener(_onMentionTextChanged);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPlayerUpdate() {
    final int pos =
        PlaybackStreamingEngineService.shared.state.currentPosition.inSeconds;
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
      final profile = await UserProfileService().getUserProfile(userId, token);
      if (!mounted) return;
      setState(() {
        _currentUserDisplayName = profile.resolvedDisplayName;
        _currentUserAvatarUrl = profile.profileImgLink.trim().isEmpty
            ? null
            : profile.profileImgLink.trim();
      });
      
      final mentionResult = await _service.getMentionFollowers();
      if (!mounted) return;
      if (mentionResult.$1 == 200 && mentionResult.$2 is List) {
        setState(
          () => _mentionFollowers = (mentionResult.$2 as List)
              .cast<MentionUser>(),
        );
      }
    } catch (_) {}
  }

  
  void _onMentionTextChanged() {
    final text = _inputController.text;
    final cursor = _inputController.selection.baseOffset.clamp(0, text.length);
    final beforeCursor = text.substring(0, cursor);
    final atIndex = beforeCursor.lastIndexOf('@');

    if (atIndex >= 0) {
      final query = beforeCursor.substring(atIndex + 1);
      if (!query.contains(' ')) {
        final filtered = query.isEmpty
            ? _mentionFollowers
            : _mentionFollowers
                  .where(
                    (u) => u.displayName.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
                  )
                  .toList();
        if (filtered.isNotEmpty) {
          setState(() {
            _mentionSuggestions = filtered.take(5).toList();
            _showMentionSuggestions = true;
            _pendingMentionedUserId = null;
          });
          return;
        }
      }
    }
    if (_showMentionSuggestions) {
      setState(() => _showMentionSuggestions = false);
    }
  }

  
  void _insertMention(MentionUser user) {
    final text = _inputController.text;
    final cursor = _inputController.selection.baseOffset.clamp(0, text.length);
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
    setState(() {
      _showMentionSuggestions = false;
      _pendingMentionedUserId = user.userId;
    });
  }

  Future<void> _navigateToProfile(String userId) async {
    await ProfileNavigator.push(context, userId);
  }

  Future<void> _fetchTotalCommentCount() async {
    try {
      final track = await PlaybackTrackApiService().getSingleTrackById(
        widget.trackId,
      );
      if (!mounted) return;
      setState(() => _totalCommentCount = track.numComments);
    } catch (_) {}
  }

  
  
  
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

  
  
  
  Future<void> _postComment() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);

    
    final int postTimestamp = _replyingTo != null ? 0 : _currentPositionSeconds;

    
    final optimistic = Comment(
      'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      _currentUserId ?? '',
      _currentUserDisplayName,
      _currentUserAvatarUrl,
      content,
      postTimestamp,
      0,
      0,
      false,
      true, 
      DateTime.now().toIso8601String(),
    );

    
    setState(() {
      if (_replyingTo != null) {
        
        final replies = _expandedReplies[_replyingTo!.commentId] ?? [];
        _expandedReplies[_replyingTo!.commentId] = [optimistic, ...replies];
      } else {
        _comments.insert(0, optimistic);
      }
    });

    _inputController.clear();
    final replyingToId = _replyingTo?.commentId;
    setState(() => _replyingTo = null);

    final mentionId = _pendingMentionedUserId;
    setState(() => _pendingMentionedUserId = null);

    final result = await _service.postComment(
      trackId: widget.trackId,
      content: content,
      timestamp: postTimestamp,
      parentCommentId: replyingToId,
      mentionedUserId: mentionId,
    );

    if (!mounted) return;

    setState(() => _isPosting = false);

    if (result.$1 == 201) {
      if (replyingToId != null) {
        
        final repliesResult = await _service.getCommentReplies(
          commentId: replyingToId,
        );
        if (!mounted) return;
        if (repliesResult.$1 == 200) {
          final fresh = repliesResult.$2 as List<Comment>;
          _applyLocalLikedState(fresh);
          setState(() => _expandedReplies[replyingToId] = fresh);
        } else {
          
          final real = result.$2 as Comment;
          final replies = _expandedReplies[replyingToId] ?? [];
          final idx = replies.indexWhere(
            (c) => c.commentId == optimistic.commentId,
          );
          if (idx != -1) replies[idx] = real;
          setState(() => _expandedReplies[replyingToId] = replies);
        }
        _fetchTotalCommentCount();
      } else {
        
        _loadComments();
        _fetchTotalCommentCount();
      }
    } else {
      
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

  
  
  
  Future<void> _toggleCommentLike(Comment comment) async {
    
    final wasLiked = comment.isLikedByUser;
    setState(() {
      comment.isLikedByUser = !wasLiked;
      comment.numLikes = wasLiked ? comment.numLikes - 1 : comment.numLikes + 1;
    });

    final result = await _service.toggleCommentLike(
      commentId: comment.commentId,
    );

    if (!mounted) return;

    if (result.$1 == 200) {
      
      final bool nowLiked = result.$2['liked'] as bool? ?? !wasLiked;
      setState(() {
        comment.isLikedByUser = nowLiked;
        comment.numLikes = result.$2['numLikes'] as int? ?? comment.numLikes;
      });
      _persistLikedId(comment.commentId, nowLiked);
    } else {
      
      setState(() {
        comment.isLikedByUser = wasLiked;
        comment.numLikes = wasLiked
            ? comment.numLikes + 1
            : comment.numLikes - 1;
      });
      _showSnackbar(result.$2.toString());
    }
  }

  
  
  
  Future<void> _deleteComment(Comment comment) async {
    
    final int topIdx = _comments.indexOf(comment);
    String? replyParentId;
    int replyIdx = -1;

    if (topIdx >= 0) {
      
      setState(() => _comments.removeAt(topIdx));
    } else {
      
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
      if (replyParentId == null) return; 
    }

    final result = await _service.deleteComment(commentId: comment.commentId);

    if (!mounted) return;

    if (result.$1 != 200) {
      
      setState(() {
        if (replyParentId != null) {
          final replies = List<Comment>.from(
            _expandedReplies[replyParentId] ?? <Comment>[],
          );
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

  
  
  
  Future<void> _toggleReplies(Comment comment) async {
    final id = comment.commentId;

    
    if (_expandedReplies.containsKey(id)) {
      setState(() => _expandedReplies.remove(id));
      return;
    }

    
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

  
  
  
  void _startReply(Comment comment) {
    setState(() => _replyingTo = comment);
    _inputFocusNode.requestFocus();
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  
  
  
  String get _formattedPosition {
    final m = _currentPositionSeconds ~/ 60;
    final s = _currentPositionSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        backgroundColor: AppColors.pureBlack,
        foregroundColor: AppColors.whiteSmoke,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isLoading
              ? 'Comments'
              : '$_totalCommentCount comment${_totalCommentCount == 1 ? '' : 's'}',
          style: TextStyle(
            color: AppColors.whiteSmoke,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          
          IconButton(
            icon: Icon(Icons.tune, color: AppColors.whiteSmoke, size: 20),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          
          _buildTrackHeader(),

          Divider(color: AppColors.container, height: 1),

          
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primaryOrange),
                  )
                : _errorMessage != null
                ? _buildErrorState()
                : _comments.isEmpty
                ? _buildEmptyState()
                : _buildCommentsList(),
          ),

          
          if (_replyingTo != null) _buildReplyIndicator(),

          
          if (_showMentionSuggestions) _buildMentionSuggestions(),

          
          _buildInputBar(),
        ],
      ),
    );
  }

  
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
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.trackArtist,
                  style: TextStyle(color: AppColors.white54, fontSize: 12),
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
      color: AppColors.tileDark,
      child: Icon(Icons.music_note, color: AppColors.greyMuted, size: 20),
    );
  }

  
  Widget _buildCommentsList() {
    
    final List<Widget> items = [];

    for (final comment in _comments) {
      items.add(
        CommentTile(
          comment: comment,
          isReply: false,
          onLikeTap: () => _toggleCommentLike(comment),
          onReplyTap: () => _startReply(comment),
          onTimestampTap: () {
            PlaybackStreamingEngineService.shared
                .seek(Duration(seconds: comment.timestamp))
                .then((_) => PlaybackStreamingEngineService.shared.resume());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing from ${comment.formattedTimestamp}'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppColors.container,
              ),
            );
          },
          onDeleteTap:
              (comment.isOwnComment ||
                  (comment.userId.isNotEmpty &&
                      comment.userId == _currentUserId))
              ? () => _confirmDelete(comment)
              : null,
          onGoToProfileTap: comment.userId.isNotEmpty
              ? () => _navigateToProfile(comment.userId)
              : null,
        ),
      );

      
      
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
                      color: AppColors.primaryOrange,
                    ),
                  )
                : GestureDetector(
                    onTap: () => _toggleReplies(comment),
                    child: Text(
                      isExpanded
                          ? 'Hide replies'
                          : 'View ${comment.replyCount} '
                                'repl${comment.replyCount == 1 ? 'y' : 'ies'}',
                      style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
          ),
        );

        
        if (isExpanded) {
          final replies = _expandedReplies[comment.commentId] ?? [];
          for (final reply in replies) {
            items.add(
              CommentTile(
                comment: reply,
                isReply: true,
                onLikeTap: () => _toggleCommentLike(reply),
                onReplyTap: () => _startReply(comment), 
                onTimestampTap: () {
                  PlaybackStreamingEngineService.shared.seek(
                    Duration(seconds: reply.timestamp),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing from ${reply.formattedTimestamp}'),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.container,
                    ),
                  );
                },
                onDeleteTap:
                    (reply.isOwnComment ||
                        (reply.userId.isNotEmpty &&
                            reply.userId == _currentUserId))
                    ? () => _confirmDelete(reply)
                    : null,
                onGoToProfileTap: reply.userId.isNotEmpty
                    ? () => _navigateToProfile(reply.userId)
                    : null,
              ),
            );
          }
        }
      }

      items.add(Divider(height: 1, color: AppColors.borderDark));
    }

    
    if (_comments.length >= _pageSize) {
      items.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _isLoadingMore
              ? const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryOrange,
                  ),
                )
              : Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text(
                      'Load more',
                      style: TextStyle(color: AppColors.primaryOrange),
                    ),
                  ),
                ),
        ),
      );
    }

    return ListView(controller: _scrollController, children: items);
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_errorMessage!, style: TextStyle(color: AppColors.white54)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadComments,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: AppColors.whiteSmoke,
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
          Icon(Icons.chat_bubble_outline, color: AppColors.greyMedium, size: 48),
          const SizedBox(height: 12),
          Text(
            'No comments yet.\nBe the first to comment!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.greyMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  
  Widget _buildReplyIndicator() {
    return Container(
      color: AppColors.container,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Replying to ${_replyingTo!.displayName}',
            style: TextStyle(color: AppColors.primaryOrange, fontSize: 12),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _replyingTo = null),
            child: Icon(Icons.close, color: AppColors.greyMuted, size: 16),
          ),
        ],
      ),
    );
  }

  
  Widget _buildMentionSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      color: AppColors.container,
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _mentionSuggestions.length,
        itemBuilder: (_, i) {
          final user = _mentionSuggestions[i];
          return InkWell(
            onTap: () => _insertMention(user),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.tileDark,
                    backgroundImage: user.avatarUrl?.isNotEmpty == true
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl?.isNotEmpty != true
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.whiteSmoke,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '@${user.displayName}',
                    style: TextStyle(color: AppColors.whiteSmoke, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  
  Widget _buildInputBar() {
    return Container(
      color: AppColors.backgroundDark,
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 10 : 20,
      ),
      child: Row(
        children: [
          
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.tileDark,
            backgroundImage: _currentUserAvatarUrl != null
                ? NetworkImage(_currentUserAvatarUrl!)
                : null,
            child: _currentUserAvatarUrl == null
                ? Text(
                    _currentUserDisplayName.isNotEmpty
                        ? _currentUserDisplayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.whiteSmoke,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),

          
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              style: TextStyle(color: AppColors.whiteSmoke, fontSize: 14),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _postComment(),
              decoration: InputDecoration(
                hintText: _replyingTo != null
                    ? '@${_replyingTo!.displayName}'
                    : 'Comment at $_formattedPosition',
                hintStyle: TextStyle(color: AppColors.white54, fontSize: 13),
                filled: true,
                fillColor: AppColors.cardDark2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          
          GestureDetector(
            onTap: _isPosting ? null : _postComment,
            child: _isPosting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primaryOrange,
                    ),
                  )
                : const Icon(Icons.send, color: AppColors.primaryOrange, size: 22),
          ),
        ],
      ),
    );
  }

  
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.container,
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
                color: AppColors.greyMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sort by',
                  style: TextStyle(
                    color: AppColors.whiteSmoke,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            ..._sortLabels.entries.map(
              (entry) => ListTile(
                title: Text(
                  entry.value,
                  style: TextStyle(color: AppColors.whiteSmoke),
                ),
                trailing: _sortBy == entry.key
                    ? Icon(Icons.check, color: AppColors.primaryOrange)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  if (_sortBy != entry.key) {
                    setState(() => _sortBy = entry.key);
                    _loadComments();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  
  void _confirmDelete(Comment comment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.container,
        title: Text(
          'Delete comment',
          style: TextStyle(color: AppColors.whiteSmoke),
        ),
        content: Text(
          'Are you sure you want to delete this comment?',
          style: TextStyle(color: AppColors.greyMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.greyMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(comment);
            },
            child: Text('Delete', style: TextStyle(color: AppColors.deepRed)),
          ),
        ],
      ),
    );
  }
}
