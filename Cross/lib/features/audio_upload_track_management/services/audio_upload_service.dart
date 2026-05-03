import 'dart:async';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/track_model.dart';

class AudioUploadService {
  static ValueNotifier<List<TrackModel>> globalMockTracksNotifier =
      ValueNotifier<List<TrackModel>>([]);
  Future<PlatformFile?> pickAudioFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'aac'],
    );

    if (result != null) {
      return result.files.single;
    }
    return null;
  }

  List<double> generateMockWaveform(int length) {
    final random = Random();
    return List.generate(length, (_) => random.nextDouble() * 100);
  }

  Stream<int> mockUploadStream() async* {
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 250));
      yield i;
    }
  }

  Future<bool> saveTrackData(
    PlatformFile file,
    Map<String, dynamic> metadata, {
    String? serverId,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    TrackVisibility visibility = TrackVisibility.public;
    if (metadata['visibility'] == 'private') {
      visibility = TrackVisibility.private;
    }
      
    if (metadata['visibility'] == 'unlisted') {
      visibility = TrackVisibility.unlisted;
    }

    final localId = DateTime.now().millisecondsSinceEpoch.toString();

    final newTrack = TrackModel(
      id: localId,
      serverId: serverId,
      title:
          metadata['title'] != null && metadata['title'].toString().isNotEmpty
          ? metadata['title']
          : file.name,
      genre: metadata['genre'] ?? '',
      descriptiveTags: metadata['tags'] != null
          ? metadata['tags'].toString().split(',')
          : [],
      releaseDate: DateTime.now(),
      fileFormat: file.extension?.toUpperCase() ?? 'AUDIO',
      audioUrl: file.path ?? '',
      waveformPeaks: generateMockWaveform(30),
      visibility: visibility,
      processingState: TrackProcessingState.processing,
      description: metadata['description'] ?? '',
      caption: metadata['caption'] ?? '',
      recordLabel: metadata['recordLabel'] ?? '',
      publisher: metadata['publisher'] ?? '',
      isrc: metadata['isrc'] ?? '',
      containsExplicitContent: metadata['containsExplicitContent'] ?? false,
      pLine: metadata['pLine'] ?? '',
      enableDirectDownloads: metadata['enableDirectDownloads'] ?? false,
      offlineListening: metadata['offlineListening'] ?? true,
      includeInRssFeed: metadata['includeInRssFeed'] ?? true,
      displayEmbedCode: metadata['displayEmbedCode'] ?? false,
      enableAppPlayback: metadata['enableAppPlayback'] ?? true,
      availability: metadata['availability'] ?? 'worldwide',
      licensing: metadata['licensing'] ?? 'all_rights',
      coverImagePath: metadata['coverImagePath'],
    );

    final updatedList = List<TrackModel>.from(globalMockTracksNotifier.value);
    updatedList.insert(0, newTrack);
    globalMockTracksNotifier.value = updatedList;

    
    Future.delayed(const Duration(seconds: 4), () {
      final list = List<TrackModel>.from(globalMockTracksNotifier.value);
      final idx = list.indexWhere((t) => t.id == localId);
      if (idx != -1) {
        list[idx] = list[idx].copyWith(
          processingState: TrackProcessingState.finished,
        );
        globalMockTracksNotifier.value = list;
      }
    });

    return true;
  }
}
