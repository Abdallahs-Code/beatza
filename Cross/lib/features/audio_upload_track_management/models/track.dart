// Model: Track
// API response model for tracks returned from the backend.
// Used by TrackApiService, YourUploadsScreen (server section),
// and TrackManagementScreen. Completely independent of Module 5/6.
//
// Two JSON shapes from the API:
//
// SHAPE A — feed/trending (flat):
//   track_id, title, image_url, main_artist{displayName}, genre,
//   tags[], privacy, num_of_plays, num_of_likes, num_of_comments,
//   num_of_reposts, created_at
//   NOTE: NO audioLink in this shape.
//
// SHAPE B — detail / history / posted / liked (nested):
//   _id, basicInfo{title, permalink, mainArtists[], genre, tags[],
//   description, isPrivate}, audio{audioLink, id},
//   image{imgLink, publicId}, numLikes, numPlays, numReposts,
//   numComments, releaseDate
//
// Public listing endpoints (posted/liked) have nested shape but NO audio.

class Track {
  final String _id;
  final String _title;
  final String _permalink;
  final List<String> _mainArtists;
  final String _genre;
  final List<String> _tags;
  final String _description;
  final bool _isPrivate;
  final String? _audioLink;
  final String? _imageUrl;
  int numLikes;
  final int _numPlays;
  int numReposts;
  final int _numComments;
  final String _releaseDate;

  Track(
    this._id,
    this._title,
    this._permalink,
    this._mainArtists,
    this._genre,
    this._tags,
    this._description,
    this._isPrivate,
    this._audioLink,
    this._imageUrl,
    this.numLikes,
    this._numPlays,
    this.numReposts,
    this._numComments,
    this._releaseDate,
  );

  // ── Getters ──────────────────────────────────
  String get id => _id;
  String get title => _title;
  String get permalink => _permalink;
  List<String> get mainArtists => _mainArtists;
  String get displayArtist =>
      _mainArtists.isNotEmpty ? _mainArtists.first : 'Unknown Artist';
  String get genre => _genre;
  List<String> get tags => _tags;
  String get description => _description;
  bool get isPrivate => _isPrivate;
  String? get audioLink => _audioLink;
  String? get imageUrl => _imageUrl;
  int get numPlays => _numPlays;
  int get numComments => _numComments;
  String get releaseDate => _releaseDate;

  // ─────────────────────────────────────────────
  // Factory: SHAPE B — nested (history, detail, posted, liked)
  // ─────────────────────────────────────────────
  factory Track.fromNestedJson(Map<String, dynamic> json) {
    final basicInfo = json['basicInfo'] as Map<String, dynamic>? ?? {};
    final audio = json['audio'] as Map<String, dynamic>?;
    final image = json['image'] as Map<String, dynamic>?;

    final mainArtistsRaw = basicInfo['mainArtists'];
    List<String> artists = [];
    if (mainArtistsRaw is List) {
      artists = mainArtistsRaw
          .map<String>((e) {
            if (e is Map) {
              return e['displayName']?.toString() ??
                  e['name']?.toString() ??
                  '';
            }
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return Track(
      json['_id']?.toString() ?? '',
      basicInfo['title']?.toString() ?? '',
      basicInfo['permalink']?.toString() ?? '',
      artists,
      basicInfo['genre']?.toString() ?? '',
      (basicInfo['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      basicInfo['description']?.toString() ?? '',
      basicInfo['isPrivate'] as bool? ?? false,
      audio?['audioLink']?.toString(),
      image?['imgLink']?.toString(),
      json['numLikes'] as int? ?? 0,
      json['numPlays'] as int? ?? 0,
      json['numReposts'] as int? ?? 0,
      json['numComments'] as int? ?? 0,
      json['releaseDate']?.toString() ?? '',
    );
  }

  // ─────────────────────────────────────────────
  // Factory: SHAPE A — flat (feed, trending)
  // ─────────────────────────────────────────────
  factory Track.fromFlatJson(Map<String, dynamic> json) {
    final mainArtist = json['main_artist'] as Map<String, dynamic>?;
    return Track(
      json['track_id']?.toString() ?? '',
      json['title']?.toString() ?? '',
      '',
      mainArtist != null ? [mainArtist['displayName']?.toString() ?? ''] : [],
      json['genre']?.toString() ?? '',
      (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      '',
      (json['privacy']?.toString() ?? 'Public') != 'Public',
      null,
      json['image_url']?.toString(),
      json['num_of_likes'] as int? ?? 0,
      json['num_of_plays'] as int? ?? 0,
      json['num_of_reposts'] as int? ?? 0,
      json['num_of_comments'] as int? ?? 0,
      json['created_at']?.toString() ?? '',
    );
  }

  // ─────────────────────────────────────────────
  // Static list parsers
  // ─────────────────────────────────────────────

  /// GET /api/feed or /api/trending → flat shape
  static List<Track> listFromFeedResponse(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    return data
        .map((item) => Track.fromFlatJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/playback/v1/history/tracks → nested shape
  static List<Track> listFromHistoryResponse(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    return data
        .map((item) => Track.fromNestedJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/public/tracks/v1/ (paginated) → nested shape inside data.tracks
  static List<Track> listFromPaginatedResponse(Map<String, dynamic> json) {
    final dataObj = json['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> tracks = dataObj['tracks'] ?? [];
    return tracks
        .map((item) => Track.fromNestedJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/public/tracks/v2/posted/{id} or /liked/{id} → nested, no audio
  static List<Track> listFromUserTracksResponse(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    return data
        .map((item) => Track.fromNestedJson(item as Map<String, dynamic>))
        .toList();
  }
}
