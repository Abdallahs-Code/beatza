// Model for a user who liked or reposted a track/playlist.
// Used by: LikersScreen, RepostersScreen (EngagementListScreen)
//
// API sources (both return identical user shape):
//   GET /api/public/engagement/tracks/v1/{trackId}/likes
//   GET /api/public/engagement/tracks/v1/{trackId}/reposts
//   GET /api/public/engagement/playlists/v1/{playlistId}/likes
//   GET /api/public/engagement/playlists/v1/{playlistId}/reposts
//
// 200 response shape:
// {
//   "total": 120,
//   "offset": 1,
//   "limit": 20,
//   "users": [
//     {
//       "userId": "usr_001",
//       "displayName": "John Doe",
//       "avatarUrl": "https://cdn.example.com/avatars/usr_001.jpg",
//       "followersCount": 134
//     }
//   ]
// }

class EngagementUser {
  final String _userId;
  final String _displayName;
  final String? _avatarUrl;
  final int _followersCount;

  EngagementUser(
    this._userId,
    this._displayName,
    this._avatarUrl,
    this._followersCount,
  );

  String get userId => _userId;
  String get displayName => _displayName;
  String? get avatarUrl => _avatarUrl;
  int get followersCount => _followersCount;

  // ─────────────────────────────────────────────
  // Factory: parse a single user object from the
  // "users" array in the paginated API response.
  // ─────────────────────────────────────────────
  factory EngagementUser.fromJson(Map<String, dynamic> json) {
    return EngagementUser(
      json['userId']?.toString() ?? '',
      json['displayName']?.toString() ?? '',
      json['avatarUrl']?.toString(),
      json['followersCount'] as int? ?? 0,
    );
  }

  // ─────────────────────────────────────────────
  // Factory: parse the full paginated response and
  // return only the list of users.
  // Call: EngagementUser.listFromResponse(data)
  // ─────────────────────────────────────────────
  static List<EngagementUser> listFromResponse(Map<String, dynamic> json) {
    final List<dynamic> users = json['users'] ?? [];
    return users
        .map((item) => EngagementUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
