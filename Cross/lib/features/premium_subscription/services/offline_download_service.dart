import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/mock_playback_access_service.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';

class OfflineDownloadService {
  static final OfflineDownloadService shared = OfflineDownloadService._internal();

  bool _wasPro = false;

  OfflineDownloadService._internal() {
    _wasPro = PaymentService.subscriptionSuccessNotifier.isPro;
    PaymentService.subscriptionSuccessNotifier.addListener(_onSubscriptionChanged);
  }

  void _onSubscriptionChanged() {
    final isPro = PaymentService.subscriptionSuccessNotifier.isPro;
    if (_wasPro && !isPro) {
      clearAllDownloads();
    }
    _wasPro = isPro;
  }

  Future<void> clearAllDownloads() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final tracks = List<PlaybackTrackModel>.from(downloadedTracksNotifier.value);
      for (final track in tracks) {
        final file = File('${dir.path}/${track.id}.mp3');
        if (await file.exists()) await file.delete();
      }
      downloadedTracksNotifier.value = [];
      downloadProgressNotifier.value = {};
      await _storage.delete(key: 'offline_track_ids');
    } catch (e) {
      debugPrint('Error clearing downloads: $e');
    }
  }

  final _storage = const FlutterSecureStorage();

  final ValueNotifier<List<PlaybackTrackModel>> downloadedTracksNotifier = ValueNotifier([]);
  final ValueNotifier<Map<String, double>> downloadProgressNotifier = ValueNotifier({});

  Future<void> loadDownloadedTracks() async {
    if (!PaymentService.subscriptionSuccessNotifier.isPro) {
      await clearAllDownloads();
      return;
    }
    try {
      final String? data = await _storage.read(key: 'offline_track_ids');
      if (data != null && data.isNotEmpty) {
        final List<dynamic> ids = jsonDecode(data);
        final allMockTracks = MockPlaybackAccessService.shared.accessibilityDemoTracks;
        final loadedTracks = allMockTracks.where((t) => ids.contains(t.id)).toList();

        final dir = await getApplicationDocumentsDirectory();
        final List<PlaybackTrackModel> verifiedTracks = [];

        for (var track in loadedTracks) {
          final file = File('${dir.path}/${track.id}.mp3');
          if (await file.exists()) {
            verifiedTracks.add(track);
          }
        }
        downloadedTracksNotifier.value = verifiedTracks;
      }
    } catch (e) {
      debugPrint('Error loading offline tracks: $e');
    }
  }

  void _updateProgress(String trackId, double progress) {
    final progressMap = Map<String, double>.from(downloadProgressNotifier.value);
    progressMap[trackId] = progress;
    downloadProgressNotifier.value = progressMap;
  }

  Future<void> downloadTrack(PlaybackTrackModel track) async {
    if (isTrackDownloaded(track.id)) return;

    try {
      _updateProgress(track.id, 0.05);

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${track.id}.mp3');

      final request = http.Request('GET', Uri.parse(track.playbackUrl));
      final response = await http.Client().send(request);

      final contentLength = response.contentLength ?? 1;
      int downloadedBytes = 0;
      final sink = file.openWrite();

      await for (var chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        _updateProgress(track.id, downloadedBytes / contentLength);
      }

      await sink.close();
      _updateProgress(track.id, 1.0);

      final currentList = List<PlaybackTrackModel>.from(downloadedTracksNotifier.value);
      currentList.add(track);
      downloadedTracksNotifier.value = currentList;

      final progressMap = Map<String, double>.from(downloadProgressNotifier.value);
      progressMap.remove(track.id);
      downloadProgressNotifier.value = progressMap;

      await _saveToStorage();
    } catch (e) {
      debugPrint('Download error: $e');
      final progressMap = Map<String, double>.from(downloadProgressNotifier.value);
      progressMap.remove(track.id);
      downloadProgressNotifier.value = progressMap;
    }
  }

  Future<void> _saveToStorage() async {
    final ids = downloadedTracksNotifier.value.map((t) => t.id).toList();
    await _storage.write(key: 'offline_track_ids', value: jsonEncode(ids));
  }

  bool isTrackDownloaded(String trackId) {
    return downloadedTracksNotifier.value.any((t) => t.id == trackId);
  }

  Future<String?> getLocalTrackPath(String trackId) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$trackId.mp3');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }
}