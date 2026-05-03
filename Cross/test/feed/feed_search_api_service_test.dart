import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/feed_search_discovery/services/feed_search_api_service.dart';

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
  late FeedSearchApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockSecureStorage();
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'atok');
    when(() => mockStorage.read(key: 'user_id'))
        .thenAnswer((_) async => 'u1');
    service = FeedSearchApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      storage: mockStorage,
    );
  });

  // ── GET /api/feed/v1/feed ────────────────────────────────────────────────

  group('getUserFeed', () {
    test('GET feed 200 with query params', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getUserFeed(offset: 0, limit: 10);

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) =>
                  u.toString().startsWith(
                    'https://beatza.me/api/feed/v1/feed?',
                  ) &&
                  u.queryParameters['offset'] == '0' &&
                  u.queryParameters['limit'] == '10',
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token stored', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getUserFeed();

      expect(r.$1, 401);
    });

    test('returns backend status code on non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getUserFeed();

      expect(r.$1, 401);
      expect(r.$2, 'Unauthorized');
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.getUserFeed();

      expect(r.$1, 500);
      expect(r.$2.toString(), contains('Network error'));
    });
  });

  // ── GET /api/public/feed/v1/trending-tracks/{userId} ─────────────────────

  group('getTrendingTracks', () {
    test('GET public trending by stored user id 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getTrendingTracks();

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) =>
                  u.path == '/api/public/feed/v1/trending-tracks/u1' &&
                  u.queryParameters['offset'] == '0' &&
                  u.queryParameters['limit'] == '20',
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getTrendingTracks();

      expect(r.$1, 401);
    });

    test('returns 401 when no user id stored', () async {
      when(() => mockStorage.read(key: 'user_id'))
          .thenAnswer((_) async => null);

      final r = await service.getTrendingTracks();

      expect(r.$1, 401);
    });

    test('returns backend status on non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not Found'}), 404),
      );

      final r = await service.getTrendingTracks();

      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getTrendingTracks();

      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/profile/v1/{userId} ──────────────────────────────────

  group('getUserById', () {
    test('GET public profile by id 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'data': {'displayName': 'X'}}),
          200,
        ),
      );

      final r = await service.getUserById('u9');

      expect(r.$1, 200);
      expect((r.$2 as Map)['displayName'], 'X');
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getUserById('u9');

      expect(r.$1, 401);
    });

    test('returns 404 when user not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final r = await service.getUserById('u9');

      expect(r.$1, 404);
      expect(r.$2, 'User not found');
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getUserById('u9');

      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/tracks/v2/{id} ───────────────────────────────────────

  group('getTrackById', () {
    test('GET public track v2 by id 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {'_id': 't1', 'basicInfo': {'title': 'Hi'}},
          }),
          200,
        ),
      );

      final r = await service.getTrackById('t1');

      expect(r.$1, 200);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getTrackById('t1');

      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );

      final r = await service.getTrackById('t1');

      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getTrackById('t1');

      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/tracks/v2/permalink/{profileLink}/{permalink} ─────────

  group('getTrackByPermalink', () {
    test('GET public permalink 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'data': {'_id': 't1', 'basicInfo': {'title': 'T'}}}),
          200,
        ),
      );

      final r = await service.getTrackByPermalink(
          profileLink: 'artist', permalink: 'my-track');

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/public/tracks/v2/permalink/artist/my-track',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getTrackByPermalink(
          profileLink: 'artist', permalink: 'my-track');

      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );

      final r = await service.getTrackByPermalink(
          profileLink: 'artist', permalink: 'my-track');

      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getTrackByPermalink(
          profileLink: 'artist', permalink: 'my-track');

      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/feed/v1/search ───────────────────────────────────────

  group('globalSearch', () {
    test('GET public search with q 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {'results': []},
          }),
          200,
        ),
      );

      final r = await service.globalSearch(query: 'beat');

      expect(r.$1, 200);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.globalSearch(query: 'beat');

      expect(r.$1, 401);
    });

    test('returns backend status on non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Bad request'}), 400),
      );

      final r = await service.globalSearch(query: 'beat');

      expect(r.$1, 400);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.globalSearch(query: 'beat');

      expect(r.$1, 500);
    });
  });

  // ── GET /api/public/feed/v1/search/suggestions ───────────────────────────

  group('getSearchSuggestions', () {
    test('GET public search suggestions 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getSearchSuggestions('be');

      expect(r.$1, 200);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getSearchSuggestions('be');

      expect(r.$1, 401);
    });

    test('returns backend status on non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Bad request'}), 400),
      );

      final r = await service.getSearchSuggestions('be');

      expect(r.$1, 400);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getSearchSuggestions('be');

      expect(r.$1, 500);
    });
  });

  // ── GET /api/feed/v1/search/history ──────────────────────────────────────

  group('getSearchHistory', () {
    test('GET feed search history 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getSearchHistory();

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/feed/v1/search/history'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getSearchHistory();

      expect(r.$1, 401);
    });

    test('returns backend status on non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      final r = await service.getSearchHistory();

      expect(r.$1, 401);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getSearchHistory();

      expect(r.$1, 500);
    });
  });

  // ── POST /api/feed/v1/search/add-to-history ───────────────────────────────

  group('addToSearchHistory', () {
    test('POST add-to-history 201', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 201));

      final r = await service.addToSearchHistory(id: 't1', type: 'track');

      expect(r.$1, 201);
      verify(
        () => mockClient.post(
          Uri.parse(
            'https://beatza.me/api/feed/v1/search/add-to-history',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.addToSearchHistory(id: 't1', type: 'track');

      expect(r.$1, 401);
    });

    test('returns 400 on bad request', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Bad request'}), 400),
      );

      final r = await service.addToSearchHistory(id: 't1', type: 'track');

      expect(r.$1, 400);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('error'));

      final r = await service.addToSearchHistory(id: 't1', type: 'track');

      expect(r.$1, 500);
    });
  });

  // ── DELETE /api/feed/v1/search/history/{historyId} ────────────────────────

  group('deleteSearchHistoryItem', () {
    test('DELETE search history item 204', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('', 204));

      final r = await service.deleteSearchHistoryItem('h1');

      expect(r.$1, 204);
      verify(
        () => mockClient.delete(
          Uri.parse(
            'https://beatza.me/api/feed/v1/search/history/h1',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.deleteSearchHistoryItem('h1');

      expect(r.$1, 401);
    });

    test('returns 404 when history item not found', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final r = await service.deleteSearchHistoryItem('h1');

      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.deleteSearchHistoryItem('h1');

      expect(r.$1, 500);
    });
  });

  // ── GET /api/tracks/v2/ ──────────────────────────────────────────────────

  group('getPublicTracks', () {
    test('GET tracks v2 list 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'tracks': [],
              'paginationInfo': {'page': 1, 'hasNext': false},
            },
          }),
          200,
        ),
      );

      final r = await service.getPublicTracks();

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) =>
                  u.path == '/api/tracks/v2/' &&
                  u.queryParameters.containsKey('page'),
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getPublicTracks();

      expect(r.$1, 401);
    });

    test('returns backend status on non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Server error'}), 500),
      );

      final r = await service.getPublicTracks();

      expect(r.$1, 500);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getPublicTracks();

      expect(r.$1, 500);
    });
  });
}
