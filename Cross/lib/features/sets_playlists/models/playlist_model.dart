import 'package:flutter/foundation.dart';

// Model: PlaylistModel
// Represents a playlist returned from the backend API.
//
// API response shape (full — with tracks):
//   _id, artistId, title, description, genre, listOfTracks[], additionalTags[],
//   permalink, isPrivate, secretToken (optional — secret share links),
//   numOfLikes, numOfReposts, playlistType, playlistLengthInSeconds,
//   likedUser[], isLiked, isReposted, image{imgLink, publicId},
//   createdAt, updatedAt, totalTracks, totalPages, page, tracks[]
//
// API response shape (list — without tracks):
//   same as above but without totalTracks, totalPages, page, tracks

class PlaylistImage {
  final String imgLink;
  final String publicId;

  const PlaylistImage({required this.imgLink, required this.publicId});

  factory PlaylistImage.fromJson(Map<String, dynamic> json) {
    return PlaylistImage(
      imgLink: json['imgLink']?.toString() ?? '',
      publicId: json['publicId']?.toString() ?? '',
    );
  }
}

class PlaylistTrack {
  final String id;
  final String title;
  final String permalink;
  final List<String> mainArtists;
  final String? audioLink;
  final String? imageUrl;
  final int durationInSeconds;
  final int numOfPlays;
  final int numOfLikes;
  final bool isLiked;
  final bool isReposted;

  /// Original track object from the playlist API (full audio + permissions).
  final Map<String, dynamic>? rawApiJson;

  PlaylistTrack({
    required this.id,
    required this.title,
    required this.permalink,
    required this.mainArtists,
    this.audioLink,
    this.imageUrl,
    required this.durationInSeconds,
    required this.numOfPlays,
    required this.numOfLikes,
    required this.isLiked,
    required this.isReposted,
    this.rawApiJson,
  });

  String get displayArtist =>
      mainArtists.isNotEmpty ? mainArtists.first : 'Unknown Artist';

  factory PlaylistTrack.fromJson(Map<String, dynamic> json) {
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

    return PlaylistTrack(
      id: json['_id']?.toString() ?? '',
      title: basicInfo['title']?.toString() ?? '',
      permalink: basicInfo['permalink']?.toString() ?? '',
      mainArtists: artists,
      audioLink: audio?['audioLink']?.toString(),
      imageUrl: image?['imgLink']?.toString(),
      durationInSeconds: (json['durationInSeconds'] as num?)?.toInt() ?? 0,
      numOfPlays: (json['numOfPlays'] as num?)?.toInt() ?? 0,
      numOfLikes: (json['numOfLikes'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      isReposted: json['isReposted'] as bool? ?? false,
      rawApiJson: Map<String, dynamic>.from(json),
    );
  }
}

class PlaylistModel {
  final String id;
  final String artistId;
  final String title;
  final String description;
  final String genre;
  final List<String> listOfTracks;
  final List<String> additionalTags;
  final String permalink;
  final bool isPrivate;

  /// Present for secret/private playlists — required to open the playlist via share URL.
  final String? secretToken;
  final int numOfLikes;
  final int numOfReposts;
  final String playlistType; 
  final int playlistLengthInSeconds;
  final List<String> likedUser;
  final bool isLiked;
  final bool isReposted;
  final PlaylistImage? image;
  final String createdAt;
  final String updatedAt;

  
  final int? totalTracks;
  final int? totalPages;
  final int? page;
  final List<PlaylistTrack> tracks;

  const PlaylistModel({
    required this.id,
    required this.artistId,
    required this.title,
    required this.description,
    required this.genre,
    required this.listOfTracks,
    required this.additionalTags,
    required this.permalink,
    required this.isPrivate,
    this.secretToken,
    required this.numOfLikes,
    required this.numOfReposts,
    required this.playlistType,
    required this.playlistLengthInSeconds,
    required this.likedUser,
    required this.isLiked,
    required this.isReposted,
    this.image,
    required this.createdAt,
    required this.updatedAt,
    this.totalTracks,
    this.totalPages,
    this.page,
    this.tracks = const [],
  });

  bool get isAlbum => playlistType == 'album';

  int get trackCount => totalTracks ?? listOfTracks.length;

  /// Web URL anyone can use to open this playlist while it stays secret (needs token).
  String? secretShareUrl(
    String apiBaseUrl, {
    String? secretOverride,
  }) {
    if (!isPrivate) return null;
    final secret = (secretOverride ?? secretToken)?.trim();
    if (secret == null || secret.isEmpty) return null;
    final origin = Uri.parse(apiBaseUrl).origin;
    final slug =
        permalink.trim().isNotEmpty ? permalink.trim() : id.trim();
    if (slug.isEmpty) return null;
    return '$origin/playlist/$slug'
        '?secretToken=${Uri.encodeQueryComponent(secret)}';
  }

  /// Beatza web embed player URL (iframe `src`). Uses permalink when set, else `_id`.
  /// Secret playlists append `secretToken` like the full-page secret link.
  String embedIframeSrc(
    String apiBaseUrl, {
    String? secretOverride,
  }) {
    final origin = Uri.parse(apiBaseUrl).origin;
    final slug =
        permalink.trim().isNotEmpty ? permalink.trim() : id.trim();
    if (slug.isEmpty) return origin;
    final base =
        '$origin/embed/playlist/${Uri.encodeComponent(slug)}';
    if (!isPrivate) return base;
    final secret = (secretOverride ?? secretToken)?.trim();
    if (secret == null || secret.isEmpty) return base;
    return '$base?secretToken=${Uri.encodeQueryComponent(secret)}';
  }

  /// HTML iframe snippet for blogs / external sites (`width="100%"`, fixed height).
  String embedIframeSnippet(
    String apiBaseUrl, {
    String? secretOverride,
    int height = 380,
  }) {
    final src = embedIframeSrc(apiBaseUrl, secretOverride: secretOverride);
    final safeSrc = src.replaceAll('&', '&amp;');
    return '<iframe src="$safeSrc" width="100%" height="$height" '
        'frameborder="0" scrolling="no" allowfullscreen '
        'allow="autoplay; clipboard-write; encrypted-media; fullscreen; '
        'picture-in-picture"></iframe>';
  }

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    final imageJson = json['image'] as Map<String, dynamic>?;
    final tracksRaw = json['tracks'] as List<dynamic>? ?? [];

    
    
    bool parseIsPrivate() {
      final direct = json['isPrivate'];
      if (direct is bool) return direct;
      final type = json['type']?.toString() ?? '';
      return type == 'private';
    }

    return PlaylistModel(
      id: json['_id']?.toString() ?? '',
      artistId: json['artistId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      genre: json['genre']?.toString() ?? '',
      listOfTracks: (json['listOfTracks'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      additionalTags: (json['additionalTags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      permalink: json['permalink']?.toString() ?? '',
      isPrivate: parseIsPrivate(),
      secretToken: json['secretToken']?.toString() ??
          json['secret_token']?.toString() ??
          json['shareToken']?.toString(),
      numOfLikes: (json['numOfLikes'] as num?)?.toInt() ?? 0,
      numOfReposts: (json['numOfReposts'] as num?)?.toInt() ?? 0,
      playlistType: json['playlistType']?.toString() ?? 'playlist',
      playlistLengthInSeconds:
          (json['playlistLengthInSeconds'] as num?)?.toInt() ?? 0,
      likedUser: (json['likedUser'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isLiked: json['isLiked'] as bool? ?? false,
      isReposted: json['isReposted'] as bool? ?? false,
      image: imageJson != null ? PlaylistImage.fromJson(imageJson) : null,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      totalTracks: (json['totalTracks'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      page: (json['page'] as num?)?.toInt(),
      tracks: tracksRaw
          .map((t) => PlaylistTrack.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  

  
  static List<PlaylistModel> listFromResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final List<dynamic> playlists = data['playlists'] ?? [];
    return playlists
        .map((p) => PlaylistModel.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  /// Parses single full playlist response.
  /// The API returns data.playlist as either an array [{…}] or a plain
  /// object {…} depending on the endpoint version — mirrors the frontend's
  /// Array.isArray check to handle both shapes.
  static PlaylistModel? singleFromResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final playlistRaw = data['playlist'];

    debugPrint('[singleFromResponse] playlist field type: ${playlistRaw.runtimeType}');
    debugPrint('[singleFromResponse] playlist value: $playlistRaw');

    Map<String, dynamic>? playlistJson;
    if (playlistRaw is List) {
      if (playlistRaw.isEmpty) return null;
      playlistJson = playlistRaw.first as Map<String, dynamic>?;
    } else if (playlistRaw is Map<String, dynamic>) {
      playlistJson = playlistRaw;
    }

    if (playlistJson == null) return null;
    return PlaylistModel.fromJson(playlistJson);
  }
}
