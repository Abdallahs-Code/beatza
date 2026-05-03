































class Comment {
  final String _commentId;
  final String _userId;
  final String _displayName;
  final String? _avatarUrl;
  final String _content;
  final int _timestamp; 
  int numLikes; 
  final int _replyCount;
  bool isLikedByUser; 
  final bool _isOwnComment; 
  final String _createdAt;

  Comment(
    this._commentId,
    this._userId,
    this._displayName,
    this._avatarUrl,
    this._content,
    this._timestamp,
    this.numLikes,
    this._replyCount,
    this.isLikedByUser,
    this._isOwnComment,
    this._createdAt,
  );

  
  String get commentId => _commentId;
  String get userId => _userId;
  String get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  String get content => _content;
  int get timestamp => _timestamp;
  int get replyCount => _replyCount;
  bool get isOwnComment => _isOwnComment;
  String get createdAt => _createdAt;

  
  
  
  
  
  String get formattedTimestamp {
    final minutes = _timestamp ~/ 60;
    final seconds = _timestamp % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  
  
  
  
  
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
      json['isLikedByUser'] is bool
          ? json['isLikedByUser'] as bool
          : json['isLikedByUser'] == 1 || json['isLikedByUser'] == 'true',
      json['isOwnComment'] as bool? ?? false,
      json['createdAt']?.toString() ?? '',
    );
  }

  
  
  
  
  static List<Comment> listFromCommentsResponse(Map<String, dynamic> json) {
    final List<dynamic> comments = json['comments'] ?? [];
    return comments
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  
  
  
  
  static List<Comment> listFromRepliesResponse(Map<String, dynamic> json) {
    final List<dynamic> replies = json['replies'] ?? [];
    return replies
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
