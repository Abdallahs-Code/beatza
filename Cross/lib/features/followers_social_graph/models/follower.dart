class Follower {
  final String _userId;
  final String _displayName;
  final String? _profileImgLink;
  final int _trackCount;
  final int _followersCount;

  /// Fixed meaning:
  /// "Does the currently authenticated app user follow this user?"
  bool isFollowing;

  /// Fixed meaning:
  /// "Has the currently authenticated app user blocked this user?"
  bool isBlocked;

  Follower(
    this._userId,
    this._displayName,
    this._profileImgLink,
    this._trackCount,
    this._followersCount,
    this.isFollowing, {
    this.isBlocked = false,
  });

  String get userId => _userId;
  String get displayName => _displayName;
  String? get profileImgLink => _profileImgLink;
  int get trackCount => _trackCount;
  int get followersCount => _followersCount;
}