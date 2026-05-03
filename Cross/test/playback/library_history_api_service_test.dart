import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/library/services/library_history_api_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'https://beatza.me';
}

void main() {
  late MockHttpClient mockClient;
  late LibraryHistoryApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = LibraryHistoryApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
    );
  });

  // ── GET /api/playback/v1/history/tracks ───────────────────────────────────

  group('getUserHistoryTracks', () {
    test('GET playback/v1/history/tracks 200 returns parsed tracks', () async {
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
                  'title': 'Track',
                  'permalink': 'tr',
                  'mainArtists': ['Art'],
                },
                'durationInSeconds': 90,
              },
            ],
          }),
          200,
        ),
      );

      final tracks = await service.getUserHistoryTracks('tok');

      expect(tracks.length, 1);
      expect(tracks.first.id, 't1');
    });

    test('deduplicates repeated tracks keeping first occurrence', () async {
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
                  'mainArtists': ['X'],
                },
                'durationInSeconds': 60,
              },
              {
                '_id': 't1',
                'basicInfo': {
                  'title': 'A',
                  'permalink': 'a',
                  'mainArtists': ['X'],
                },
                'durationInSeconds': 60,
              },
            ],
          }),
          200,
        ),
      );

      final tracks = await service.getUserHistoryTracks('tok');

      expect(tracks.length, 1);
    });

    test('404 with "no history" message returns empty list', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'message': 'no history found'}),
          404,
        ),
      );

      final tracks = await service.getUserHistoryTracks('tok');

      expect(tracks, isEmpty);
    });

    test('404 with unrelated message throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'message': 'Track endpoint not found'}),
          404,
        ),
      );

      expect(
        () => service.getUserHistoryTracks('tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'message': 'Unauthorized'}),
          401,
        ),
      );

      expect(
        () => service.getUserHistoryTracks('tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/playback/v1/history/tracks'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Internal Server Error', 500),
      );

      expect(
        () => service.getUserHistoryTracks('tok'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── DELETE /api/playback/v1/history/ ─────────────────────────────────────

  group('deleteUserHistory', () {
    test('DELETE playback/v1/history/ 204 succeeds', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/playback/v1/history/'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('', 204));

      await service.deleteUserHistory('tok');

      verify(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/playback/v1/history/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer tok',
            'User-Agent': 'Android',
          },
        ),
      ).called(1);
    });

    test('200 also succeeds', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/playback/v1/history/'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await service.deleteUserHistory('tok');
    });

    test('401 throws', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/playback/v1/history/'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.deleteUserHistory('tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.delete(
          Uri.parse('https://beatza.me/api/playback/v1/history/'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      expect(
        () => service.deleteUserHistory('tok'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── GET /api/public/tracks/v2/liked/{userId} ─────────────────────────────

  group('getUserLikedTracks', () {
    test('GET public tracks/v2/liked/{userId} 200 returns track list', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/liked/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'data': []}), 200),
      );

      final list = await service.getUserLikedTracks('u1', 'tok');

      expect(list, isEmpty);
    });

    test('200 with track data in list parses correctly', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/liked/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                '_id': 't1',
                'basicInfo': {
                  'title': 'Song',
                  'permalink': 'song',
                  'mainArtists': ['Artist'],
                },
                'durationInSeconds': 180,
              },
            ],
          }),
          200,
        ),
      );

      final list = await service.getUserLikedTracks('u1', 'tok');

      expect(list.length, 1);
      expect(list.first.id, 't1');
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/liked/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.getUserLikedTracks('u1', 'tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('404 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/liked/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      expect(
        () => service.getUserLikedTracks('u1', 'tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/tracks/v2/liked/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response('Server Error', 500),
      );

      expect(
        () => service.getUserLikedTracks('u1', 'tok'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
