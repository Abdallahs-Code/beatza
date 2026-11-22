import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/playback_streaming_engine/services/public_tracks_api_service.dart';

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
  late PublicTracksApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockSecureStorage();
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'tok');
    service = PublicTracksApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      storage: mockStorage,
    );
  });

  // ── GET /api/tracks/v2 ───────────────────────────────────────────────────

  group('fetchPublicTracksPage', () {
    test('200 returns parsed page result', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'tracks': [],
              'paginationInfo': {
                'page': 1,
                'totalPages': 1,
                'hasNext': false,
                'totalNumTracks': 0,
              },
            },
          }),
          200,
        ),
      );

      final page = await service.fetchPublicTracksPage(page: 1, limit: 10);

      expect(page.tracks, isEmpty);
      expect(page.hasNext, false);
      expect(page.page, 1);
    });

    test('200 with track data parses tracks', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'tracks': [
                {
                  '_id': 't1',
                  'basicInfo': {
                    'title': 'Track',
                    'permalink': 'track',
                    'mainArtists': ['Artist'],
                  },
                  'durationInSeconds': 120,
                },
              ],
              'paginationInfo': {
                'page': 1,
                'totalPages': 2,
                'hasNext': true,
                'totalNumTracks': 15,
              },
            },
          }),
          200,
        ),
      );

      final page = await service.fetchPublicTracksPage();

      expect(page.tracks.length, 1);
      expect(page.hasNext, true);
      expect(page.totalNumTracks, 15);
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.fetchPublicTracksPage(),
        throwsA(isA<Exception>()),
      );
    });

    test('403 throws', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Forbidden'}), 403),
      );

      expect(
        () => service.fetchPublicTracksPage(),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.fetchPublicTracksPage(),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      expect(
        () => service.fetchPublicTracksPage(),
        throwsA(isA<Exception>()),
      );
    });

    test('200 with unexpected top-level format throws', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode([1, 2, 3]), 200),
      );

      expect(
        () => service.fetchPublicTracksPage(),
        throwsA(isA<Exception>()),
      );
    });

    test('200 with missing data object throws', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'ok'}), 200),
      );

      expect(
        () => service.fetchPublicTracksPage(),
        throwsA(isA<Exception>()),
      );
    });

    test('200 with data object missing tracks list throws', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'data': {'paginationInfo': {}}}),
          200,
        ),
      );

      expect(
        () => service.fetchPublicTracksPage(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── GET /api/public/tracks/v2/{trackId} (getTrackArtistId) ───────────────

  group('getTrackArtistId', () {
    test('returns null for empty trackId', () async {
      final id = await service.getTrackArtistId('  ');
      expect(id, isNull);
    });

    test('200 returns artist id from posterId field', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              '_id': 't1',
              'posterId': 'artist99',
              'basicInfo': {
                'title': 'T',
                'permalink': 't',
                'mainArtists': ['A'],
              },
            },
          }),
          200,
        ),
      );

      final id = await service.getTrackArtistId('t1');

      expect(id, 'artist99');
    });

    test('non-200 returns null', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final id = await service.getTrackArtistId('t1');

      expect(id, isNull);
    });

    test('network error returns null', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final id = await service.getTrackArtistId('t1');

      expect(id, isNull);
    });

    test('200 with no recognisable artist fields returns null', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              '_id': 't1',
              'basicInfo': {'title': 'T', 'permalink': 't', 'mainArtists': []},
            },
          }),
          200,
        ),
      );

      final id = await service.getTrackArtistId('t1');

      expect(id, isNull);
    });
  });
}
