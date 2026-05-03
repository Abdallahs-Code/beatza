























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

  
  
  
  
  factory EngagementUser.fromJson(Map<String, dynamic> json) {
    return EngagementUser(
      json['userId']?.toString() ?? '',
      json['displayName']?.toString() ?? '',
      json['avatarUrl']?.toString(),
      json['followersCount'] as int? ?? 0,
    );
  }

  
  
  
  
  
  static List<EngagementUser> listFromResponse(Map<String, dynamic> json) {
    final List<dynamic> users = json['users'] ?? [];
    return users
        .map((item) => EngagementUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
