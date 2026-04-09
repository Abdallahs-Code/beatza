enum TrackProcessingState { processing, finished }
enum TrackVisibility { public, private, unlisted }

class TrackModel {
  final String id;
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
}