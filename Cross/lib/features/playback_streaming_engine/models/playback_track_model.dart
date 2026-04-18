enum PlaybackAccessState { playable, preview, blocked }

enum PlaybackSourceType { network, deviceFile }

class PlaybackTrackModel {
  final String id;
  final String title;
  final String artistName;
  final String? audioUrl;
  final String? artworkUrl;
  final String? localFilePath;
  final Duration? duration;
  final PlaybackAccessState accessState;
  final PlaybackSourceType sourceType;
  final String? previewAudioUrl;
  final Duration? previewDuration;
  final String? blockedReason;

  final String? permalink;
  final String? genre;
  final List<String> tags;
  final bool isPrivate;
  final int numLikes;
  final int numComments;
  final int numPlays;
  final int numReposts;
  final String? imagePublicId;
  final DateTime? releaseDate;

  final bool enableDirectDownload;
  final bool offlineListening;
  final bool includeInRssFeed;
  final bool displayedEmbedCode;
  final bool enableAppPlayback;

  /// The user ID of the artist/uploader — used to navigate to their profile.
  final String? artistId;

  /// Precomputed normalized waveform values from 0.0 to 1.0
  final List<double> waveformPeaks;

  const PlaybackTrackModel({
    required this.id,
    required this.title,
    required this.artistName,
    this.audioUrl,
    this.artworkUrl,
    this.localFilePath,
    this.duration,
    this.accessState = PlaybackAccessState.playable,
    this.sourceType = PlaybackSourceType.network,
    this.previewAudioUrl,
    this.previewDuration,
    this.blockedReason,
    this.permalink,
    this.genre,
    this.tags = const [],
    this.isPrivate = false,
    this.numLikes = 0,
    this.numComments = 0,
    this.numPlays = 0,
    this.numReposts = 0,
    this.imagePublicId,
    this.releaseDate,
    this.enableDirectDownload = false,
    this.offlineListening = false,
    this.includeInRssFeed = false,
    this.displayedEmbedCode = false,
    this.enableAppPlayback = true,
    this.artistId,
    this.waveformPeaks = const [],
  });

  bool get isLocalFile {
    return sourceType == PlaybackSourceType.deviceFile &&
        localFilePath != null &&
        localFilePath!.trim().isNotEmpty;
  }

  bool get hasNetworkAudioSource {
    return (audioUrl ?? '').trim().isNotEmpty;
  }

  bool get hasPreviewSource {
    return (previewAudioUrl ?? '').trim().isNotEmpty;
  }

  bool get hasAnyPlayableSource {
    if (isLocalFile) {
      return true;
    }

    if (accessState == PlaybackAccessState.preview && hasPreviewSource) {
      return true;
    }

    return hasNetworkAudioSource;
  }

  String get playbackUrl {
    if (isLocalFile) {
      return localFilePath!.trim();
    }

    if (accessState == PlaybackAccessState.preview &&
        previewAudioUrl != null &&
        previewAudioUrl!.trim().isNotEmpty) {
      return previewAudioUrl!.trim();
    }

    return (audioUrl ?? '').trim();
  }

  Duration get effectivePreviewDuration {
    return previewDuration ?? const Duration(seconds: 30);
  }

  factory PlaybackTrackModel.fromApiJson(Map<String, dynamic> json) {
    final Map<String, dynamic> basicInfo =
        (json['basicInfo'] as Map<String, dynamic>?) ?? {};
    final Map<String, dynamic> permissions =
        (json['permissions'] as Map<String, dynamic>?) ?? {};
    final Map<String, dynamic> image =
        (json['image'] as Map<String, dynamic>?) ?? {};
    final Map<String, dynamic> audio =
        (json['audio'] as Map<String, dynamic>?) ?? {};

    final List<String> mainArtists =
        (basicInfo['mainArtists'] as List<dynamic>? ?? [])
            .map((artist) => artist.toString())
            .toList();

    final List<String> tags = (basicInfo['tags'] as List<dynamic>? ?? [])
        .map((tag) => tag.toString())
        .toList();

    final bool canPlay = permissions.isEmpty
        ? true
        : permissions['enableAppPlayback'] == true;

    final String? audioUrl =
        _nullableString(audio['audioLink']) ??
        _nullableString(json['audio_url']) ??
        _nullableString(json['audioUrl']) ??
        _nullableString(json['stream_url']) ??
        _nullableString(json['streamUrl']) ??
        _nullableString(json['file_url']) ??
        _nullableString(json['fileUrl']);

    return PlaybackTrackModel(
      id: (json['_id'] ?? '').toString(),
      title: (basicInfo['title'] ?? 'Unknown title').toString(),
      artistName: mainArtists.isEmpty
          ? 'Unknown artist'
          : mainArtists.join(', '),
      audioUrl: audioUrl,
      artworkUrl:
          _nullableString(json['image_url']) ??
          _nullableString(image['imgLink']),
      accessState: canPlay
          ? PlaybackAccessState.playable
          : PlaybackAccessState.blocked,
      blockedReason: canPlay ? null : 'Playback is disabled for this track.',
      permalink: _nullableString(basicInfo['permalink']),
      genre: _nullableString(basicInfo['genre']),
      tags: tags,
      isPrivate: basicInfo['isPrivate'] == true,
      numLikes: _toInt(json['numLikes']),
      numComments: _toInt(json['numComments']),
      numPlays: _toInt(json['numPlays']),
      numReposts: _toInt(json['numReposts'] ?? json['num_reposts']),
      imagePublicId: _nullableString(image['publicId']),
      releaseDate: _parseDateTime(json['releaseDate']),
      enableDirectDownload: permissions['enableDirectDownload'] == true,
      offlineListening: permissions['offlineListening'] == true,
      includeInRssFeed: permissions['includeInRssFeed'] == true,
      displayedEmbedCode: permissions['displayedEmbedCode'] == true,
      enableAppPlayback: canPlay,
      artistId:
          _nullableString(json['userId']) ??
          _nullableString(json['user_id']) ??
          _nullableString(basicInfo['userId']) ??
          _nullableString(basicInfo['user_id']) ??
          _nullableString(json['creator']),
      waveformPeaks: const [],
    );
  }

  PlaybackTrackModel copyWith({
    String? id,
    String? title,
    String? artistName,
    String? audioUrl,
    String? artworkUrl,
    String? localFilePath,
    Duration? duration,
    PlaybackAccessState? accessState,
    PlaybackSourceType? sourceType,
    String? previewAudioUrl,
    Duration? previewDuration,
    String? blockedReason,
    String? permalink,
    String? genre,
    List<String>? tags,
    bool? isPrivate,
    int? numLikes,
    int? numComments,
    int? numPlays,
    int? numReposts,
    String? imagePublicId,
    DateTime? releaseDate,
    bool? enableDirectDownload,
    bool? offlineListening,
    bool? includeInRssFeed,
    bool? displayedEmbedCode,
    bool? enableAppPlayback,
    String? artistId,
    List<double>? waveformPeaks,
  }) {
    return PlaybackTrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      artistName: artistName ?? this.artistName,
      audioUrl: audioUrl ?? this.audioUrl,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      duration: duration ?? this.duration,
      accessState: accessState ?? this.accessState,
      sourceType: sourceType ?? this.sourceType,
      previewAudioUrl: previewAudioUrl ?? this.previewAudioUrl,
      previewDuration: previewDuration ?? this.previewDuration,
      blockedReason: blockedReason ?? this.blockedReason,
      permalink: permalink ?? this.permalink,
      genre: genre ?? this.genre,
      tags: tags ?? this.tags,
      isPrivate: isPrivate ?? this.isPrivate,
      numLikes: numLikes ?? this.numLikes,
      numComments: numComments ?? this.numComments,
      numPlays: numPlays ?? this.numPlays,
      numReposts: numReposts ?? this.numReposts,
      imagePublicId: imagePublicId ?? this.imagePublicId,
      releaseDate: releaseDate ?? this.releaseDate,
      enableDirectDownload: enableDirectDownload ?? this.enableDirectDownload,
      offlineListening: offlineListening ?? this.offlineListening,
      includeInRssFeed: includeInRssFeed ?? this.includeInRssFeed,
      displayedEmbedCode: displayedEmbedCode ?? this.displayedEmbedCode,
      artistId: artistId ?? this.artistId,
      enableAppPlayback: enableAppPlayback ?? this.enableAppPlayback,
      waveformPeaks: waveformPeaks ?? this.waveformPeaks,
    );
  }

  static String? _nullableString(dynamic value) {
    final String text = (value ?? '').toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    final String text = (value ?? '').toString().trim();
    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text);
  }
}
