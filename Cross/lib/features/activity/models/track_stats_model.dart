class TrackStatsModel {
  final List<FanData> topFans;
  final List<FanData> firstFans;

  TrackStatsModel({
    required this.topFans,
    required this.firstFans,
  });

  factory TrackStatsModel.fromJson(Map<String, dynamic> json) {
    final topFansJson = json['topFans'] as List<dynamic>? ?? [];
    final firstFansJson = json['firstFans'] as List<dynamic>? ?? [];

    return TrackStatsModel(
      topFans: topFansJson
          .whereType<Map<String, dynamic>>()
          .map((f) => FanData.fromJson(f))
          .toList(),
      firstFans: firstFansJson
          .whereType<Map<String, dynamic>>()
          .map((f) => FanData.fromJson(f))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'topFans': topFans.map((f) => f.toJson()).toList(),
      'firstFans': firstFans.map((f) => f.toJson()).toList(),
    };
  }
}

class FanData {
  final String userId;
  final String displayName;
  final String profileImg;
  final String trackId;
  final int totalNumberOfPlay;
  final bool isFanOfArtist;
  final int firstWeekNumPlays;
  final DateTime trackCreatedAt;
  final double playThroughPercentage;
  final int totalListenedDuration;

  FanData({
    required this.userId,
    required this.displayName,
    required this.profileImg,
    required this.trackId,
    required this.totalNumberOfPlay,
    required this.isFanOfArtist,
    required this.firstWeekNumPlays,
    required this.trackCreatedAt,
    required this.playThroughPercentage,
    required this.totalListenedDuration,
  });

  factory FanData.fromJson(Map<String, dynamic> json) {
    final userIdData = json['userId'] as Map<String, dynamic>? ?? {};
    final trackCreatedAtStr = json['trackCreatedAt'] as String? ?? '';
    
    return FanData(
      userId: userIdData['_id']?.toString() ?? userIdData['userId']?.toString() ?? '',
      displayName: userIdData['displayName']?.toString() ?? 'Unknown User',
      profileImg: _extractProfileImg(userIdData),
      trackId: json['trackId']?.toString() ?? '',
      totalNumberOfPlay: json['totalNumberOfPlay'] as int? ?? 0,
      isFanOfArtist: json['isFanOfArtist'] as bool? ?? false,
      firstWeekNumPlays: json['firstWeekNumPlays'] as int? ?? 0,
      trackCreatedAt: DateTime.tryParse(trackCreatedAtStr) ?? DateTime.now(),
      playThroughPercentage: (json['playThroughPercentage'] as num?)?.toDouble() ?? 0.0,
      totalListenedDuration: json['totalListenedDuration'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': {
        '_id': userId,
        'displayName': displayName,
        'profileImg': profileImg,
      },
      'trackId': trackId,
      'totalNumberOfPlay': totalNumberOfPlay,
      'isFanOfArtist': isFanOfArtist,
      'firstWeekNumPlays': firstWeekNumPlays,
      'trackCreatedAt': trackCreatedAt.toIso8601String(),
      'playThroughPercentage': playThroughPercentage,
      'totalListenedDuration': totalListenedDuration,
    };
  }

  static String _extractProfileImg(Map<String, dynamic> userIdData) {
    // Check for direct string fields
    final img1 = userIdData['profileImg'];
    final img2 = userIdData['profileImgLink'];

    if (img1 is String && img1.trim().isNotEmpty) return img1.trim();
    if (img2 is String && img2.trim().isNotEmpty) return img2.trim();

    // Check if it's an object containing imgLink
    if (img1 is Map) {
      final nested = img1['imgLink'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    }
    if (img2 is Map) {
      final nested = img2['imgLink'];
      if (nested is String && nested.trim().isNotEmpty) return nested.trim();
    }

    return '';
  }
}