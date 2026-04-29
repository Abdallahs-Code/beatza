// Model: SearchResultModel
// Shape from GET /api/public/feed/v1/search
// Response:
// {
//   "counts": { "tracks": 0, "users": 0, "playlists": 0, "albums": 0 },
//   "results": [ { "id": "string", "type": "track" } ]
// }

class SearchCountsModel {
  final int tracks;
  final int users;
  final int playlists;
  final int albums;

  SearchCountsModel({
    required this.tracks,
    required this.users,
    required this.playlists,
    required this.albums,
  });

  factory SearchCountsModel.fromJson(Map<String, dynamic> json) {
    return SearchCountsModel(
      tracks: json['tracks'] as int? ?? 0,
      users: json['users'] as int? ?? 0,
      playlists: json['playlists'] as int? ?? 0,
      albums: json['albums'] as int? ?? 0,
    );
  }
}

class SearchResultItem {
  final String _id;
  final String _type; // 'track' | 'user' | 'playlist' | 'album'

  SearchResultItem(this._id, this._type);

  String get id => _id;
  String get type => _type;

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      json['id']?.toString() ?? '',
      json['type']?.toString() ?? 'track',
    );
  }
}

class SearchResultModel {
  final SearchCountsModel counts;
  final List<SearchResultItem> results;

  SearchResultModel({required this.counts, required this.results});

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      counts: SearchCountsModel.fromJson(
        json['counts'] as Map<String, dynamic>? ?? {},
      ),
      results: (json['results'] as List<dynamic>? ?? [])
          .map((item) =>
              SearchResultItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
