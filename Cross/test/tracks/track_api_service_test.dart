import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/audio_upload_track_management/services/track_api_service.dart';

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
  late TrackApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockSecureStorage();
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'tok');
    service = TrackApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      storage: mockStorage,
    );
  });

  // ── DELETE /api/tracks/v1/{trackId} ──────────────────────────────────────

  group('deleteTrack', () {
    test('200 returns success message', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/tracks/v1/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track Deleted Sucessfully'}), 200),
      );

      final r = await service.deleteTrack(trackId: 'trk1');

      expect(r.$1, 200);
      expect(r.$2, 'Track Deleted Sucessfully');
    });

    test('returns 400 when track id is empty', () async {
      final r = await service.deleteTrack(trackId: '  ');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.deleteTrack(trackId: 'trk1');
      expect(r.$1, 401);
    });

    test('401 from server propagates', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/tracks/v1/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.deleteTrack(trackId: 'trk1');
      expect(r.$1, 401);
    });

    test('403 from server propagates', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/tracks/v1/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Forbidden'}), 403),
      );

      final r = await service.deleteTrack(trackId: 'trk1');
      expect(r.$1, 403);
    });

    test('404 propagates', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/tracks/v1/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );

      final r = await service.deleteTrack(trackId: 'trk1');
      expect(r.$1, 404);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/tracks/v1/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      final r = await service.deleteTrack(trackId: 'trk1');
      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/tracks/v2/{trackId} ──────────────────────────────────

  group('getTrackById', () {
    test('200 returns parsed track', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              '_id': 'trk1',
              'basicInfo': {
                'title': 'Song',
                'permalink': 'song',
                'mainArtists': ['Artist'],
              },
            },
          }),
          200,
        ),
      );

      final r = await service.getTrackById(trackId: 'trk1');

      expect(r.$1, 200);
    });

    test('returns 400 when id is empty', () async {
      final r = await service.getTrackById(trackId: '  ');
      expect(r.$1, 400);
    });

    test('401 propagates', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getTrackById(trackId: 'trk1');
      expect(r.$1, 401);
    });

    test('404 propagates', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final r = await service.getTrackById(trackId: 'trk1');
      expect(r.$1, 404);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      final r = await service.getTrackById(trackId: 'trk1');
      expect(r.$1, 500);
    });
  });

  // ── PATCH /api/tracks/v2/listen ──────────────────────────────────────────

  group('incrementPlayCount', () {
    test('200 returns success', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/tracks/v2/listen'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'message': 'ok'}), 200),
      );

      final r = await service.incrementPlayCount(
        trackId: 'trk1',
        listenedDuration: 120,
        sessionIdPlay: '550e8400-e29b-41d4-a716-446655440000',
      );

      expect(r.$1, 200);
    });

    test('returns 400 when trackId is empty', () async {
      final r = await service.incrementPlayCount(
        trackId: '',
        listenedDuration: 0,
      );
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.incrementPlayCount(
        trackId: 'trk1',
        listenedDuration: 60,
      );
      expect(r.$1, 401);
    });

    test('401 from server propagates', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/tracks/v2/listen'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.incrementPlayCount(
        trackId: 'trk1',
        listenedDuration: 60,
      );
      expect(r.$1, 401);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/tracks/v2/listen'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('timeout'));

      final r = await service.incrementPlayCount(
        trackId: 'trk1',
        listenedDuration: 60,
      );
      expect(r.$1, 500);
    });
  });

  // ── POST /api/tracks/v1/played/{trackId} ─────────────────────────────────

  group('addToHistory', () {
    test('200 returns success', () async {
      when(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/tracks/v1/played/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'message': 'added'}), 200),
      );

      final r = await service.addToHistory(trackId: 'trk1');

      expect(r.$1, 200);
    });

    test('returns 400 when trackId is empty', () async {
      final r = await service.addToHistory(trackId: '  ');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.addToHistory(trackId: 'trk1');
      expect(r.$1, 401);
    });

    test('401 from server propagates', () async {
      when(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/tracks/v1/played/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.addToHistory(trackId: 'trk1');
      expect(r.$1, 401);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/tracks/v1/played/trk1'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      final r = await service.addToHistory(trackId: 'trk1');
      expect(r.$1, 500);
    });
  });

  // ── GET /api/playback/v1/history/tracks ──────────────────────────────────

  group('getListeningHistory', () {
    test('200 returns track list', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
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
                  'mainArtists': ['B'],
                },
                'durationInSeconds': 60,
              },
            ],
          }),
          200,
        ),
      );

      final r = await service.getListeningHistory();

      expect(r.$1, 200);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getListeningHistory();
      expect(r.$1, 401);
    });

    test('401 from server propagates', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getListeningHistory();
      expect(r.$1, 401);
    });

    test('500 propagates', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.getListeningHistory();
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      final r = await service.getListeningHistory();
      expect(r.$1, 500);
    });
  });

  // ── GET /api/tracks/v2 ───────────────────────────────────────────────────

  group('getAllTracksPaginated', () {
    test('200 returns paginated data', () async {
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
              },
            },
          }),
          200,
        ),
      );

      final r = await service.getAllTracksPaginated(page: 1, limit: 20);

      expect(r.$1, 200);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getAllTracksPaginated();
      expect(r.$1, 401);
    });

    test('401 from server propagates', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getAllTracksPaginated();
      expect(r.$1, 401);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.getAllTracksPaginated();
      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/tracks/v2/posted/{userId} ────────────────────────────

  group('getUserPostedTracks', () {
    test('200 returns track list', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'data': []}), 200),
      );

      final r = await service.getUserPostedTracks(userId: 'u1');

      expect(r.$1, 200);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.getUserPostedTracks(userId: '  ');
      expect(r.$1, 400);
    });

    test('404 propagates', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final r = await service.getUserPostedTracks(userId: 'u1');
      expect(r.$1, 404);
    });

    test('401 propagates', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getUserPostedTracks(userId: 'u1');
      expect(r.$1, 401);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.getUserPostedTracks(userId: 'u1');
      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/tracks/v2/liked/{userId} ─────────────────────────────

  group('getUserLikedTracks', () {
    test('200 returns track list', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'data': []}), 200),
      );

      final r = await service.getUserLikedTracks(userId: 'u1');

      expect(r.$1, 200);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.getUserLikedTracks(userId: '  ');
      expect(r.$1, 400);
    });

    test('401 propagates', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getUserLikedTracks(userId: 'u1');
      expect(r.$1, 401);
    });

    test('404 propagates', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final r = await service.getUserLikedTracks(userId: 'u1');
      expect(r.$1, 404);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getUserLikedTracks(userId: 'u1');
      expect(r.$1, 500);
    });
  });

  // ── GET /api/feed ─────────────────────────────────────────────────────────

  group('getUserFeed', () {
    test('200 returns feed tracks', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'data': []}), 200),
      );

      final r = await service.getUserFeed();

      expect(r.$1, 200);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getUserFeed();
      expect(r.$1, 401);
    });

    test('401 from server propagates', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getUserFeed();
      expect(r.$1, 401);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.getUserFeed();
      expect(r.$1, 500);
    });
  });

  // ── GET /api/trending ────────────────────────────────────────────────────

  group('getTrendingTracks', () {
    test('200 returns trending tracks', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'data': []}), 200),
      );

      final r = await service.getTrendingTracks();

      expect(r.$1, 200);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getTrendingTracks();
      expect(r.$1, 401);
    });

    test('500 propagates', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.getTrendingTracks();
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getTrendingTracks();
      expect(r.$1, 500);
    });
  });

  // ── PATCH /api/tracks/v1/mobile-pro-preview/{trackId} ────────────────────

  group('updateMobileProPreview', () {
    test('200 returns isChanged flag', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'message': 'updated',
            'data': {'isChanged': true},
          }),
          200,
        ),
      );

      final r = await service.updateMobileProPreview(
        trackId: 'trk1',
        mobileProPreview: true,
      );

      expect(r.$1, 200);
      expect((r.$2 as Map)['isChanged'], true);

      verify(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/tracks/v1/mobile-pro-preview/trk1',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('returns 400 when trackId is empty', () async {
      final r = await service.updateMobileProPreview(
        trackId: '  ',
        mobileProPreview: true,
      );
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.updateMobileProPreview(
        trackId: 'trk1',
        mobileProPreview: false,
      );
      expect(r.$1, 401);
    });

    test('401 from server propagates', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.updateMobileProPreview(
        trackId: 'trk1',
        mobileProPreview: true,
      );
      expect(r.$1, 401);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers'), body: any(named: 'body')),
      ).thenThrow(Exception('network down'));

      final r = await service.updateMobileProPreview(
        trackId: 'trk1',
        mobileProPreview: true,
      );
      expect(r.$1, 500);
    });
  });
}
