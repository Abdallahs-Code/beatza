class Follower 
{
  final String _userId;
  final String _displayName;
  final String? _profileImgLink;
  final int _trackCount;
  bool isFollowing;

  Follower(
    this._userId,
    this._displayName,
    this._profileImgLink,
    this._trackCount,
    this.isFollowing,
  );

  String get userId          => _userId;
  String get displayName     => _displayName;
  String? get profileImgLink => _profileImgLink;
  int    get trackCount      => _trackCount;
}