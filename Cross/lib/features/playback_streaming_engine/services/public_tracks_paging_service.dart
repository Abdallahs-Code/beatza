import 'package:flutter/foundation.dart';

import '../models/playback_track_model.dart';
import 'public_tracks_api_service.dart';

class PublicTracksPagingService extends ChangeNotifier {
  static final PublicTracksPagingService shared =
      PublicTracksPagingService._shared();

  final PublicTracksApiService _apiService;

  final List<PlaybackTrackModel> _tracks = <PlaybackTrackModel>[];
  int _page = 0;
  int _limit = 2;
  bool _hasNext = true;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  PublicTracksPagingService._shared({PublicTracksApiService? apiService})
    : _apiService = apiService ?? PublicTracksApiService();

  List<PlaybackTrackModel> get tracks =>
      List<PlaybackTrackModel>.unmodifiable(_tracks);
  int get page => _page;
  int get limit => _limit;
  bool get hasNext => _hasNext;
  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasLoadedAnything => _tracks.isNotEmpty || _page > 0;

  Future<void> loadInitial({int limit = 2, bool forceRefresh = false}) async {
    if (_isInitialLoading) return;
    if (!forceRefresh && hasLoadedAnything) return;

    _limit = limit;
    _isInitialLoading = true;
    _errorMessage = null;
    if (forceRefresh) {
      _tracks.clear();
      _page = 0;
      _hasNext = true;
    }
    notifyListeners();

    try {
      final PublicTracksPageResult result = await _apiService
          .fetchPublicTracksPage(page: 1, limit: _limit);

      _tracks
        ..clear()
        ..addAll(_dedupe(result.tracks));
      _page = result.page;
      _hasNext = result.hasNext;
      _errorMessage = null;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadMore() async {
    if (_isInitialLoading || _isLoadingMore || !_hasNext) {
      return false;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final PublicTracksPageResult result = await _apiService
          .fetchPublicTracksPage(page: _page + 1, limit: _limit);

      final int beforeCount = _tracks.length;
      _tracks.addAll(_dedupe(result.tracks, existing: _tracks));
      _page = result.page;
      _hasNext = result.hasNext;
      _errorMessage = null;
      return _tracks.length > beforeCount;
    } catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> ensureNextTrackAvailableForPlayer() async {
    if (!_hasNext) {
      return false;
    }
    return loadMore();
  }

  List<PlaybackTrackModel> _dedupe(
    List<PlaybackTrackModel> incoming, {
    List<PlaybackTrackModel> existing = const <PlaybackTrackModel>[],
  }) {
    final Set<String> seenIds = <String>{
      ...existing.map((track) => track.id.trim()).where((id) => id.isNotEmpty),
    };
    final List<PlaybackTrackModel> unique = <PlaybackTrackModel>[];

    for (final PlaybackTrackModel track in incoming) {
      final String id = track.id.trim();
      if (id.isNotEmpty && seenIds.contains(id)) {
        continue;
      }
      if (id.isNotEmpty) {
        seenIds.add(id);
      }
      unique.add(track);
    }

    return unique;
  }
}
