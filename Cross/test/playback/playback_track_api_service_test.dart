import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/playback_streaming_engine/models/playback_track_model.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/playback_track_api_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'https://beatza.me';
}

void main() {
  late MockHttpClient mockClient;
  late MockSecureStorage mockStorage;
  late PlaybackTrackApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockSecureStorage();
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'tok');
    service = PlaybackTrackApiService(
      client: mockClient,
      storage: mockStorage,
      apiServices: FakeApiServices(),
    );
  });

  // ── GET /api/public/tracks/v2/{trackId} ──────────────────────────────────

  group('getTracksById', () {
    test('200 with data as object returns single-element list', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              '_id': 't1',
              'basicInfo': {
                'title': 'T',
                'permalink': 't',
                'mainArtists': ['A'],
              },
              'audio': {'audioLink': 'https://x.test/a.mp3'},
              'durationInSeconds': 100,
              'isAvailableForUser': true,
              'geoBlocking': {
                'mode': 'worldwide',
                'regions': [],
                'countries': [],
              },
            },
          }),
          200,
        ),
      );

      final list = await service.getTracksById('t1');

      expect(list.length, 1);
      expect(list.first.id, 't1');
    });

    test('200 with data as list parses all tracks', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                '_id': 't1',
                'basicInfo': {
                  'title': 'A',
                  'permalink': 'a',
                  'mainArtists': ['X'],
                },
                'durationInSeconds': 100,
              },
              {
                '_id': 't2',
                'basicInfo': {
                  'title': 'B',
                  'permalink': 'b',
                  'mainArtists': ['Y'],
                },
                'durationInSeconds': 200,
              },
            ],
          }),
          200,
        ),
      );

      final list = await service.getTracksById('t1');

      expect(list.length, 2);
    });

    test('403 returns blocked track — does not throw', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Forbidden'}), 403),
      );

      final list = await service.getTracksById('t1');

      expect(list.length, 1);
      expect(list.first.id, 't1');
      expect(list.first.accessState, PlaybackAccessState.blocked);
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.getTracksById('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('404 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );

      expect(
        () => service.getTracksById('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => service.getTracksById('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when access token is absent', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      expect(
        () => service.getTracksById('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      expect(
        () => service.getTracksById('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('200 with no data field throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'message': 'ok'}), 200),
      );

      expect(
        () => service.getTracksById('t1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── GET /api/public/tracks/v2/stats/{trackId} ────────────────────────────

  group('getTrackStats', () {
    test('200 returns parsed stats', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/stats/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {'topFans': [], 'firstFans': []},
          }),
          200,
        ),
      );

      final stats = await service.getTrackStats('t1');

      expect(stats.topFans, isEmpty);
      expect(stats.firstFans, isEmpty);
    });

    test('403 returns private stats — does not throw', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/stats/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Stats are private'}), 403),
      );

      final stats = await service.getTrackStats('t1');

      expect(stats.topFans, isEmpty);
      expect(stats.firstFans, isEmpty);
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/stats/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.getTrackStats('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('404 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/stats/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );

      expect(
        () => service.getTrackStats('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/stats/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => service.getTrackStats('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when access token is absent', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      expect(
        () => service.getTrackStats('t1'),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/stats/t1'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network error'));

      expect(
        () => service.getTrackStats('t1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
