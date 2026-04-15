// Model for a comment (top-level or reply) on a track.
// Used by: CommentsScreen, CommentTile widget
//
// API sources:
//   GET  /api/public/engagement/tracks/v1/{trackId}/comments
//   GET  /api/public/engagement/comments/v1/{commentId}/replies
//   POST /api/engagement/tracks/v1/{trackId}/comments  → 201 returns this shape
//
// Comment object shape (top-level and replies are identical):
// {
//   "commentId":    "507f1f77bcf86cd799439011",
//   "userId":       "507f1f77bcf86cd799439012",
//   "displayName":  "Jane Smith",
//   "avatarUrl":    "https://cdn.example.com/avatars/user.jpg",
//   "content":      "Amazing track!",
//   "timestamp":    30,           ← seconds in the track (int)
//   "numLikes":     5,
//   "replyCount":   2,
//   "isLikedByUser": false,       ← drives heart icon state
//   "isOwnComment":  false,       ← drives delete option visibility
//   "createdAt":    "2025-01-15T12:00:002"
// }
//
// POST request body:
// {
//   "content":         "Great track!",
//   "timestamp":       42.5,          ← current playback position (seconds)
//   "parentCommentId": "cmt_001"      ← optional, omit for top-level comments
// }
//
// NOTE: POST returns 201 (not 200) on success.

class Comment {
  final String _commentId;
  final String _userId;
  final String _displayName;
  final String? _avatarUrl;
  final String _content;
  final int _timestamp; // seconds in the track timeline
  int _numLikes; // mutable — toggled locally on comment like
  final int _replyCount;
  bool _isLikedByUser; // mutable — toggled locally on comment like
  final bool _isOwnComment; // drives delete option in UI
  final String _createdAt;

  Comment(
    this._commentId,
    this._userId,
    this._displayName,
    this._avatarUrl,
    this._content,
    this._timestamp,
    this._numLikes,
    this._replyCount,
    this._isLikedByUser,
    this._isOwnComment,
    this._createdAt,
  );

  // ── Getters ──────────────────────────────────
  String get commentId => _commentId;
  String get userId => _userId;
  String get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  String get content => _content;
  int get timestamp => _timestamp;
  int get numLikes => _numLikes;
  int get replyCount => _replyCount;
  bool get isLikedByUser => _isLikedByUser;
  bool get isOwnComment => _isOwnComment;
  String get createdAt => _createdAt;

  // ── Mutable setters (optimistic UI updates) ──
  // Called by CommentsScreen after toggleCommentLike API call.
  set isLikedByUser(bool value) => _isLikedByUser = value;
  set numLikes(int value) => _numLikes = value;

  // ─────────────────────────────────────────────
  // Helper: formats timestamp int (seconds) into
  // MM:SS string for the blue pill in CommentTile.
  // e.g. 289 → "4:49"
  // ─────────────────────────────────────────────
  String get formattedTimestamp {
    final minutes = _timestamp ~/ 60;
    final seconds = _timestamp % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────
  // Factory: parse a single comment object.
  // Works for both top-level comments and replies
  // since the API returns identical shapes for both.
  // ─────────────────────────────────────────────
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      json['commentId']?.toString() ?? '',
      json['userId']?.toString() ?? '',
      json['displayName']?.toString() ?? '',
      json['avatarUrl']?.toString(),
      json['content']?.toString() ?? '',
      (json['timestamp'] as num?)?.toInt() ??
          (json['trackTimestamp'] as num?)?.toInt() ??
          (json['track_timestamp'] as num?)?.toInt() ??
          (json['position'] as num?)?.toInt() ??
          (json['timePosition'] as num?)?.toInt() ??
          0,
      json['numLikes'] as int? ?? 0,
      json['replyCount'] as int? ?? 0,
      json['isLikedByUser'] is bool ? json['isLikedByUser'] as bool : json['isLikedByUser'] == 1 || json['isLikedByUser'] == 'true',
      json['isOwnComment'] as bool? ?? false,
      json['createdAt']?.toString() ?? '',
    );
  }

  // ─────────────────────────────────────────────
  // Factory: parse the "comments" array from the
  // paginated GET track comments response.
  // ─────────────────────────────────────────────
  static List<Comment> listFromCommentsResponse(Map<String, dynamic> json) {
    final List<dynamic> comments = json['comments'] ?? [];
    return comments
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ─────────────────────────────────────────────
  // Factory: parse the "replies" array from the
  // paginated GET comment replies response.
  // ─────────────────────────────────────────────
  static List<Comment> listFromRepliesResponse(Map<String, dynamic> json) {
    final List<dynamic> replies = json['replies'] ?? [];
    return replies
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
