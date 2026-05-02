// Model: Track
// API response model for tracks returned from the backend.
//
// Two JSON shapes from the API:
//
// SHAPE A — feed/trending (flat):
//   track_id, title, image_url, main_artist{displayName}, genre,
//   tags[], privacy, num_of_plays, num_of_likes, num_of_comments,
//   num_of_reposts, created_at
//
// SHAPE B — detail / history / posted / liked (nested):
//   _id/trackId, basicInfo{title, permalink, mainArtists[], genre, tags[],
//   description, caption, isPrivate}, audio{audioLink, id},
//   image{imgLink, publicId}, permissions{…}, license{type, …},
//   geoBlocking{mode, regions[], countries[]}, numLikes, numPlays,
//   numReposts, numComments, releaseDate

class Track {
  // ── Core ─────────────────────────────────────────────────────────────────
  final String _id;
  final String _title;
  final String _permalink;
  final List<String> _mainArtists;
  final String _genre;
  final List<String> _tags;
  final String _description;
  final String _caption;
  final bool _isPrivate;
  final String? _audioLink;
  final String? _imageUrl;
  int numLikes;
  final int _numPlays;
  int numReposts;
  final int _numComments;
  final String _releaseDate;

  // ── Permissions ──────────────────────────────────────────────────────────
  final bool _enableDirectDownload;
  final bool _offlineListening;
  final bool _includeInRssFeed;
  final bool _displayedEmbedCode;
  final bool _enableAppPlayback;

  // ── License ──────────────────────────────────────────────────────────────
  // 'allRightsReserved' | 'creativeCommons'
  final String _licenseType;

  // ── Geo-blocking ─────────────────────────────────────────────────────────
  // mode: 'worldwide' | 'exclusive' | 'blocked'
  final String _geoBlockingMode;
  final List<String> _geoBlockingRegions;
  final List<String> _geoBlockingCountries;

  // ── Advanced ─────────────────────────────────────────────────────────────
  final bool _explicitContent;
  final String? _recordLabel;
  final String? _publisher;
  final String? _isrc;
  final String? _pLine;

  // ── Mobile Pro Preview ───────────────────────────────────────────────────
  final bool _mobileProPreview;

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
    this._releaseDate, {
    String caption = '',
    bool enableDirectDownload = false,
    bool offlineListening = true,
    bool includeInRssFeed = true,
    bool displayedEmbedCode = false,
    bool enableAppPlayback = true,
    String licenseType = 'allRightsReserved',
    String geoBlockingMode = 'worldwide',
    List<String> geoBlockingRegions = const [],
    List<String> geoBlockingCountries = const [],
    bool explicitContent = false,
    String? recordLabel,
    String? publisher,
    String? isrc,
    String? pLine,
    bool mobileProPreview = false,
  })  : _caption = caption,
        _mobileProPreview = mobileProPreview,
        _enableDirectDownload = enableDirectDownload,
        _offlineListening = offlineListening,
        _includeInRssFeed = includeInRssFeed,
        _displayedEmbedCode = displayedEmbedCode,
        _enableAppPlayback = enableAppPlayback,
        _licenseType = licenseType,
        _geoBlockingMode = geoBlockingMode,
        _geoBlockingRegions = geoBlockingRegions,
        _geoBlockingCountries = geoBlockingCountries,
        _explicitContent = explicitContent,
        _recordLabel = recordLabel,
        _publisher = publisher,
        _isrc = isrc,
        _pLine = pLine;

  // ── Getters ───────────────────────────────────────────────────────────────
  String get id => _id;
  String get title => _title;
  String get permalink => _permalink;
  List<String> get mainArtists => _mainArtists;
  String get displayArtist =>
      _mainArtists.isNotEmpty ? _mainArtists.first : 'Unknown Artist';
  String get genre => _genre;
  List<String> get tags => _tags;
  String get description => _description;
  String get caption => _caption;
  bool get isPrivate => _isPrivate;
  String? get audioLink => _audioLink;
  String? get imageUrl => _imageUrl;
  int get numPlays => _numPlays;
  int get numComments => _numComments;
  String get releaseDate => _releaseDate;

  bool get enableDirectDownload => _enableDirectDownload;
  bool get offlineListening => _offlineListening;
  bool get includeInRssFeed => _includeInRssFeed;
  bool get displayedEmbedCode => _displayedEmbedCode;
  bool get enableAppPlayback => _enableAppPlayback;

  // 'allRightsReserved' | 'creativeCommons'
  String get licenseType => _licenseType;

  // 'worldwide' | 'exclusive' | 'blocked'
  String get geoBlockingMode => _geoBlockingMode;
  List<String> get geoBlockingRegions => _geoBlockingRegions;
  List<String> get geoBlockingCountries => _geoBlockingCountries;

  bool get explicitContent => _explicitContent;
  String? get recordLabel => _recordLabel;
  String? get publisher => _publisher;
  String? get isrc => _isrc;
  String? get pLine => _pLine;
  bool get mobileProPreview => _mobileProPreview;

  // ─────────────────────────────────────────────
  // Factory: SHAPE B — nested (history, detail, posted, liked)
  // ─────────────────────────────────────────────
  factory Track.fromNestedJson(Map<String, dynamic> json) {
    final basicInfo = json['basicInfo'] as Map<String, dynamic>? ?? {};
    final audio = json['audio'] as Map<String, dynamic>?;
    final image = json['image'] as Map<String, dynamic>?;
    final permissions = json['permissions'] as Map<String, dynamic>?;
    final license = json['license'] as Map<String, dynamic>?;
    final geoBlocking = json['geoBlocking'] as Map<String, dynamic>?;
    final advanced = json['advanced'] as Map<String, dynamic>?;

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
      (json['_id'] ?? json['id'] ?? json['trackId'])?.toString() ?? '',
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
      caption: basicInfo['caption']?.toString() ?? '',
      enableDirectDownload:
          permissions?['enableDirectDownload'] as bool? ?? false,
      offlineListening: permissions?['offlineListening'] as bool? ?? true,
      includeInRssFeed: permissions?['includeInRssFeed'] as bool? ?? true,
      displayedEmbedCode: permissions?['displayedEmbedCode'] as bool? ?? false,
      enableAppPlayback: permissions?['enableAppPlayback'] as bool? ?? true,
      licenseType: license?['type']?.toString() ?? 'allRightsReserved',
      geoBlockingMode: geoBlocking?['mode']?.toString() ?? 'worldwide',
      geoBlockingRegions: (geoBlocking?['regions'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      geoBlockingCountries:
          (geoBlocking?['countries'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList(),
      explicitContent: advanced?['explicitContent'] as bool? ?? false,
      recordLabel: advanced?['recordLabel']?.toString(),
      publisher: advanced?['publisher']?.toString(),
      isrc: advanced?['ISRC']?.toString(),
      pLine: advanced?['pLine']?.toString(),
      mobileProPreview: json['mobileProPreview'] as bool? ?? false,
    );
  }

  // ─────────────────────────────────────────────
  // Factory: SHAPE A — flat (feed, trending)
  // ─────────────────────────────────────────────
  factory Track.fromFlatJson(Map<String, dynamic> json) {
    final mainArtist = json['main_artist'] as Map<String, dynamic>?;
    return Track(
      (json['track_id'] ?? json['trackId'] ?? json['_id'])?.toString() ?? '',
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
      // permissions/license/geoBlocking not available in flat shape — defaults apply
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

  /// GET /api/public/tracks/v1/posted/{id} or /liked/{id} → nested, no audio
  static List<Track> listFromUserTracksResponse(Map<String, dynamic> json) {
    final List<dynamic> data = json['data'] ?? [];
    return data
        .map((item) => Track.fromNestedJson(item as Map<String, dynamic>))
        .toList();
  }
}
