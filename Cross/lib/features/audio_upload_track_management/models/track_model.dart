// Model: TrackModel
// Local upload model — used by UploadTrackScreen, YourUploadsScreen,
// and AudioUploadService. Completely independent of API Track model.
// This is the in-memory representation of a locally uploaded track.

enum TrackProcessingState { processing, finished }

enum TrackVisibility { public, private, unlisted }

class TrackModel {
  final String id;
  final String? serverId;
  final String title;
  final String genre;
  final List<String> descriptiveTags;
  final DateTime releaseDate;
  final String fileFormat;
  final TrackProcessingState processingState;
  final TrackVisibility visibility;
  final String audioUrl;
  final List<double> waveformPeaks;
  final String description;
  final String caption;
  final String recordLabel;
  final String publisher;
  final String isrc;
  final bool containsExplicitContent;
  final String pLine;
  final bool enableDirectDownloads;
  final bool offlineListening;
  final bool includeInRssFeed;
  final bool displayEmbedCode;
  final bool enableAppPlayback;
  final String availability;
  final String licensing;
  final String? coverImagePath;

  TrackModel({
    required this.id,
    this.serverId,
    required this.title,
    required this.genre,
    required this.descriptiveTags,
    required this.releaseDate,
    required this.fileFormat,
    this.processingState = TrackProcessingState.processing,
    this.visibility = TrackVisibility.public,
    required this.audioUrl,
    required this.waveformPeaks,
    this.description = '',
    this.caption = '',
    this.recordLabel = '',
    this.publisher = '',
    this.isrc = '',
    this.containsExplicitContent = false,
    this.pLine = '',
    this.enableDirectDownloads = false,
    this.offlineListening = true,
    this.includeInRssFeed = true,
    this.displayEmbedCode = false,
    this.enableAppPlayback = true,
    this.availability = 'worldwide',
    this.licensing = 'all_rights',
    this.coverImagePath,
  });

  TrackModel copyWith({
    String? id,
    String? serverId,
    String? title,
    String? genre,
    List<String>? descriptiveTags,
    DateTime? releaseDate,
    String? fileFormat,
    TrackProcessingState? processingState,
    TrackVisibility? visibility,
    String? audioUrl,
    List<double>? waveformPeaks,
    String? description,
    String? caption,
    String? recordLabel,
    String? publisher,
    String? isrc,
    bool? containsExplicitContent,
    String? pLine,
    bool? enableDirectDownloads,
    bool? offlineListening,
    bool? includeInRssFeed,
    bool? displayEmbedCode,
    bool? enableAppPlayback,
    String? availability,
    String? licensing,
    String? coverImagePath,
  }) {
    return TrackModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      descriptiveTags: descriptiveTags ?? this.descriptiveTags,
      releaseDate: releaseDate ?? this.releaseDate,
      fileFormat: fileFormat ?? this.fileFormat,
      processingState: processingState ?? this.processingState,
      visibility: visibility ?? this.visibility,
      audioUrl: audioUrl ?? this.audioUrl,
      waveformPeaks: waveformPeaks ?? this.waveformPeaks,
      description: description ?? this.description,
      caption: caption ?? this.caption,
      recordLabel: recordLabel ?? this.recordLabel,
      publisher: publisher ?? this.publisher,
      isrc: isrc ?? this.isrc,
      containsExplicitContent:
          containsExplicitContent ?? this.containsExplicitContent,
      pLine: pLine ?? this.pLine,
      enableDirectDownloads:
          enableDirectDownloads ?? this.enableDirectDownloads,
      offlineListening: offlineListening ?? this.offlineListening,
      includeInRssFeed: includeInRssFeed ?? this.includeInRssFeed,
      displayEmbedCode: displayEmbedCode ?? this.displayEmbedCode,
      enableAppPlayback: enableAppPlayback ?? this.enableAppPlayback,
      availability: availability ?? this.availability,
      licensing: licensing ?? this.licensing,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }
}
