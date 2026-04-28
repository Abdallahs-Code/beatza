// Model: TrendingItemModel
// Shape returned by GET /api/feed/v1/trending-tracks/{userId}
// Response: [ { "id": "string" } ]
// Only returns IDs — we use these IDs to fetch full track details
// via GET /api/public/tracks/v1/{id} (PlaybackTrackApiService or similar)
// before displaying or playing.

class TrendingItemModel {
  final String _id;

  TrendingItemModel(this._id);

  String get id => _id;

  factory TrendingItemModel.fromJson(Map<String, dynamic> json) {
    return TrendingItemModel(json['id']?.toString() ?? '');
  }

  static List<TrendingItemModel> listFromJson(List<dynamic> list) {
    return list
        .map((item) => TrendingItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
