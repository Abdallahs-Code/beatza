import 'package:flutter/foundation.dart';

import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';

enum PlaybackAccessState { playable, preview, blocked }

enum PlaybackSourceType { network, deviceFile }

class TrackGeoBlocking {
  final String? mode;
  final List<String> regions;
  final List<String> countries;

  const TrackGeoBlocking({this.mode, this.regions = const [], this.countries = const []});

  factory TrackGeoBlocking.fromJson(Map<String, dynamic> json) {
    final String raw = (json['mode'] ?? '').toString().trim();
    return TrackGeoBlocking(
      mode: raw.isEmpty ? null : raw,
      regions: (json['regions'] as List<dynamic>? ?? []).map((r) => r.toString()).toList(),
      countries: (json['countries'] as List<dynamic>? ?? []).map((c) => c.toString()).toList(),
    );
  }
}

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

  
  final String? artistId;

  
  final List<double> waveformPeaks;

  
  final bool isLikedByUser;
  final bool isRepostedByUser;
  final bool isAvailableForUser;
  final TrackGeoBlocking? geoBlocking;

  
  
  
  final bool mobileProPreview;

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
    this.isLikedByUser = false,
    this.isRepostedByUser = false,
    this.isAvailableForUser = true,
    this.geoBlocking,
    this.mobileProPreview = false,
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

    
    final bool isAvailableForUser = json['isAvailableForUser'] != false;
    final bool isLikedByUser = json['isLikedByUser'] == true;
    final bool isRepostedByUser = json['isRepostedByUser'] == true;
    final TrackGeoBlocking? geoBlocking =
        json['geoBlocking'] is Map<String, dynamic>
            ? TrackGeoBlocking.fromJson(json['geoBlocking'] as Map<String, dynamic>)
            : null;

    
    
    final dynamic mobileProPreviewRaw = json['mobileProPreview'];
    final bool mobileProPreview = mobileProPreviewRaw is bool
        ? mobileProPreviewRaw
        : (mobileProPreviewRaw is Map<String, dynamic> &&
                  mobileProPreviewRaw['mobileProPreview'] == true);

    final bool effectivelyPlayable = canPlay && isAvailableForUser;

    
    
    
    
    final bool isProListener =
        PaymentService.subscriptionSuccessNotifier.value.isPro;
    final bool gateToPreview =
        effectivelyPlayable && mobileProPreview && !isProListener;

    final PlaybackAccessState resolvedAccessState = effectivelyPlayable
        ? (gateToPreview
              ? PlaybackAccessState.preview
              : PlaybackAccessState.playable)
        : PlaybackAccessState.blocked;

    final String? audioUrl =
        _nullableString(audio['audioLink']) ??
        _nullableString(json['audio_url']) ??
        _nullableString(json['audioUrl']) ??
        _nullableString(json['stream_url']) ??
        _nullableString(json['streamUrl']) ??
        _nullableString(json['file_url']) ??
        _nullableString(json['fileUrl']);

    
    
    final String resolvedId = (json['trackId'] ?? json['_id'] ?? '')
        .toString()
        .trim();

    
    final String? resolvedArtistId =
        _nullableString(json['posterId']) ??
        _nullableString(json['userId']) ??
        _nullableString(json['user_id']) ??
        _nullableString(basicInfo['userId']) ??
        _nullableString(basicInfo['user_id']) ??
        _nullableString(json['creator']);

    
    if (resolvedId.isEmpty) {
      debugPrint(
        '[PlaybackTrackModel.fromApiJson] ⚠️ EMPTY id resolved. '
        "json keys: ${json.keys.toList()}. "
        "_id='${json['_id']}' trackId='${json['trackId']}'",
      );
    } else {
      debugPrint(
        '[PlaybackTrackModel.fromApiJson] ✅ id="$resolvedId" '
        "artistId='$resolvedArtistId' title='${basicInfo['title']}'",
      );
    }

    return PlaybackTrackModel(
      id: resolvedId,
      title: (basicInfo['title'] ?? 'Unknown title').toString(),
      artistName: mainArtists.isEmpty
          ? 'Unknown artist'
          : mainArtists.join(', '),
      audioUrl: audioUrl,
      artworkUrl:
          _nullableString(json['image_url']) ??
          _nullableString(image['imgLink']),
      accessState: resolvedAccessState,
      previewDuration: gateToPreview ? const Duration(seconds: 30) : null,
      blockedReason: effectivelyPlayable
          ? null
          : (!isAvailableForUser
              ? 'This track is not available in your region.'
              : 'Playback is disabled for this track.'),
      permalink: _nullableString(basicInfo['permalink']),
      genre: _nullableString(basicInfo['genre']),
      tags: tags,
      isPrivate: basicInfo['isPrivate'] == true,
      numLikes: _toInt(json['numLikes']),
      numComments: _toInt(json['numComments']),
      numPlays: _toInt(json['numPlays']),
      numReposts: _toInt(json['numReposts'] ?? json['num_reposts']),
      duration: _toInt(json['durationInSeconds']) > 0
          ? Duration(seconds: _toInt(json['durationInSeconds']))
          : null,
      imagePublicId: _nullableString(image['publicId']),
      releaseDate: _parseDateTime(json['releaseDate']),
      enableDirectDownload: permissions['enableDirectDownload'] == true,
      offlineListening: permissions['offlineListening'] == true,
      includeInRssFeed: permissions['includeInRssFeed'] == true,
      displayedEmbedCode: permissions['displayedEmbedCode'] == true,
      enableAppPlayback: canPlay,
      artistId: resolvedArtistId,
      waveformPeaks: const [],
      isLikedByUser: isLikedByUser,
      isRepostedByUser: isRepostedByUser,
      isAvailableForUser: isAvailableForUser,
      geoBlocking: geoBlocking,
      mobileProPreview: mobileProPreview,
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
    bool? isLikedByUser,
    bool? isRepostedByUser,
    bool? isAvailableForUser,
    TrackGeoBlocking? geoBlocking,
    bool? mobileProPreview,
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
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      isRepostedByUser: isRepostedByUser ?? this.isRepostedByUser,
      isAvailableForUser: isAvailableForUser ?? this.isAvailableForUser,
      geoBlocking: geoBlocking ?? this.geoBlocking,
      mobileProPreview: mobileProPreview ?? this.mobileProPreview,
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
