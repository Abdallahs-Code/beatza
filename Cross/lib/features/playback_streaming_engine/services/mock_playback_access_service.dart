import 'package:flutter/foundation.dart';

import '../models/playback_track_model.dart';

enum MockPlaybackUserTier {
  free,
  goPlus,
}

class MockPlaybackAccessService extends ChangeNotifier {
  static final MockPlaybackAccessService shared =
      MockPlaybackAccessService._shared();

  MockPlaybackUserTier _currentTier = MockPlaybackUserTier.free;
  String _currentCountry = 'Unknown';

  MockPlaybackAccessService._shared();

  MockPlaybackUserTier get currentTier => _currentTier;
  String get currentCountry => _currentCountry;

  void setMockUserTier(MockPlaybackUserTier tier) {
    if (_currentTier == tier) return;
    _currentTier = tier;
    notifyListeners();
  }

  void syncCountryFromProfileLocation(String rawLocation) {
    final String nextCountry = _normalizeCountry(rawLocation);
    if (_currentCountry == nextCountry) return;
    _currentCountry = nextCountry;
    notifyListeners();
  }

  List<PlaybackTrackModel> get accessibilityDemoTracks {
    return _demoTrackTemplates.map(_resolveDemoTrack).toList(growable: false);
  }

  PlaybackTrackModel _resolveDemoTrack(_DemoTrackTemplate template) {
    final Set<String> normalizedBlockedCountries = template.blockedCountries
        .map(_normalizeCountry)
        .toSet();

    if (normalizedBlockedCountries.contains(_currentCountry)) {
      return template.track.copyWith(
        accessState: PlaybackAccessState.blocked,
        blockedReason: 'Not available in $_currentCountry.',
        previewAudioUrl: template.track.previewAudioUrl ?? template.track.audioUrl,
        previewDuration: template.previewDuration,
      );
    }

    if (template.fullyBlockedEverywhere) {
      return template.track.copyWith(
        accessState: PlaybackAccessState.blocked,
        blockedReason: 'Not available in your country.',
        previewAudioUrl: template.track.previewAudioUrl ?? template.track.audioUrl,
        previewDuration: template.previewDuration,
      );
    }

    if (_currentTier == MockPlaybackUserTier.goPlus) {
      return template.track.copyWith(
        accessState: PlaybackAccessState.playable,
        blockedReason: null,
        previewAudioUrl: template.track.previewAudioUrl ?? template.track.audioUrl,
        previewDuration: template.previewDuration,
      );
    }

    if (template.goPlusOnly || template.freeGetsPreview) {
      return template.track.copyWith(
        accessState: PlaybackAccessState.preview,
        blockedReason: null,
        previewAudioUrl: template.track.previewAudioUrl ?? template.track.audioUrl,
        previewDuration: template.previewDuration,
      );
    }

    return template.track.copyWith(
      accessState: PlaybackAccessState.playable,
      blockedReason: null,
      previewAudioUrl: template.track.previewAudioUrl ?? template.track.audioUrl,
      previewDuration: template.previewDuration,
    );
  }

  String _normalizeCountry(String rawLocation) {
    final String normalized = rawLocation.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 'Unknown';
    }

    if (normalized.contains('egypt')) {
      return 'Egypt';
    }
    if (normalized.contains('saudi')) {
      return 'Saudi Arabia';
    }
    if (normalized.contains('united arab emirates') ||
        normalized.contains('uae') ||
        normalized.contains('dubai') ||
        normalized.contains('abu dhabi')) {
      return 'United Arab Emirates';
    }
    if (normalized.contains('qatar')) {
      return 'Qatar';
    }
    if (normalized.contains('kuwait')) {
      return 'Kuwait';
    }
    if (normalized.contains('bahrain')) {
      return 'Bahrain';
    }
    if (normalized.contains('oman')) {
      return 'Oman';
    }
    if (normalized.contains('jordan')) {
      return 'Jordan';
    }
    if (normalized.contains('lebanon')) {
      return 'Lebanon';
    }
    if (normalized.contains('united states') ||
        normalized.contains('usa') ||
        normalized.contains('new york') ||
        normalized.contains('los angeles')) {
      return 'United States';
    }
    if (normalized.contains('united kingdom') ||
        normalized.contains('uk') ||
        normalized.contains('england') ||
        normalized.contains('london')) {
      return 'United Kingdom';
    }
    if (normalized.contains('canada') || normalized.contains('toronto')) {
      return 'Canada';
    }
    if (normalized.contains('germany') || normalized.contains('berlin')) {
      return 'Germany';
    }

    return rawLocation.trim().isEmpty ? 'Unknown' : rawLocation.trim();
  }

  static const String _demoAudioUrl =
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';

  static final List<_DemoTrackTemplate> _demoTrackTemplates =
      <_DemoTrackTemplate>[
    _DemoTrackTemplate(
      track: PlaybackTrackModel(
        id: 'demo_playable_all',
        title: 'Always Playable',
        artistName: 'Accessibility Demo',
        artworkUrl:
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?q=80&w=800&auto=format&fit=crop',
        audioUrl: _demoAudioUrl,
        sourceType: PlaybackSourceType.network,
        accessState: PlaybackAccessState.playable,
        duration: const Duration(minutes: 4, seconds: 12),
        genre: 'Demo',
        numPlays: 4200,
      ),
    ),
    _DemoTrackTemplate(
      track: PlaybackTrackModel(
        id: 'demo_preview_free',
        title: 'Preview for Free Users',
        artistName: 'Accessibility Demo',
        artworkUrl:
            'https://images.unsplash.com/photo-1501612780327-45045538702b?q=80&w=800&auto=format&fit=crop',
        audioUrl: _demoAudioUrl,
        sourceType: PlaybackSourceType.network,
        accessState: PlaybackAccessState.preview,
        duration: const Duration(minutes: 3, seconds: 48),
        genre: 'Demo',
        numPlays: 3100,
      ),
      freeGetsPreview: true,
      previewDuration: const Duration(seconds: 30),
    ),
    _DemoTrackTemplate(
      track: PlaybackTrackModel(
        id: 'demo_blocked_country',
        title: 'Blocked in Egypt & Saudi Arabia',
        artistName: 'Accessibility Demo',
        artworkUrl:
            'https://images.unsplash.com/photo-1494232410401-ad00d5433cfa?q=80&w=800&auto=format&fit=crop',
        audioUrl: _demoAudioUrl,
        sourceType: PlaybackSourceType.network,
        accessState: PlaybackAccessState.blocked,
        duration: const Duration(minutes: 4),
        genre: 'Demo',
        numPlays: 1800,
      ),
      blockedCountries: <String>{'Egypt', 'Saudi Arabia'},
    ),
    _DemoTrackTemplate(
      track: PlaybackTrackModel(
        id: 'demo_go_plus_full',
        title: 'Go+ Full / Free Preview',
        artistName: 'Accessibility Demo',
        artworkUrl:
            'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?q=80&w=800&auto=format&fit=crop',
        audioUrl: _demoAudioUrl,
        sourceType: PlaybackSourceType.network,
        accessState: PlaybackAccessState.preview,
        duration: const Duration(minutes: 5, seconds: 3),
        genre: 'Demo',
        numPlays: 9100,
      ),
      goPlusOnly: true,
      freeGetsPreview: true,
      previewDuration: const Duration(seconds: 30),
    ),
    _DemoTrackTemplate(
      track: PlaybackTrackModel(
        id: 'demo_fully_blocked',
        title: 'Fully Blocked Demo Track',
        artistName: 'Accessibility Demo',
        artworkUrl:
            'https://images.unsplash.com/photo-1511379938547-c1f69419868d?q=80&w=800&auto=format&fit=crop',
        audioUrl: _demoAudioUrl,
        sourceType: PlaybackSourceType.network,
        accessState: PlaybackAccessState.blocked,
        duration: const Duration(minutes: 3, seconds: 20),
        genre: 'Demo',
        numPlays: 700,
      ),
      fullyBlockedEverywhere: true,
    ),
  ];
}

class _DemoTrackTemplate {
  final PlaybackTrackModel track;
  final bool goPlusOnly;
  final bool freeGetsPreview;
  final bool fullyBlockedEverywhere;
  final Set<String> blockedCountries;
  final Duration previewDuration;

  const _DemoTrackTemplate({
    required this.track,
    this.goPlusOnly = false,
    this.freeGetsPreview = false,
    this.fullyBlockedEverywhere = false,
    this.blockedCountries = const <String>{},
    this.previewDuration = const Duration(seconds: 30),
  });
}