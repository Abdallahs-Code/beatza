import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/engagement_social_interactions/services/engagement_api_service.dart';

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
  late EngagementApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockSecureStorage();
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'tok');
    service = EngagementApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      storage: mockStorage,
    );
  });

  // ── LIKES ────────────────────────────────────────────────────────────────

  group('toggleTrackLike', () {
    test('POST 200 success', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'liked': true, 'numOfLikes': 3}), 200),
      );

      final r = await service.toggleTrackLike(trackId: 't1');

      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse(
            'https://beatza.me/api/engagement/tracks/v1/t1/like',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.toggleTrackLike(trackId: '  ');
      expect(r.$1, 400);
      expect(r.$2, 'Invalid track ID');
      verifyNever(() => mockClient.post(any(), headers: any(named: 'headers')));
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.toggleTrackLike(trackId: 't1');
      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.toggleTrackLike(trackId: 't1');
      expect(r.$1, 404);
      expect(r.$2, 'Track not found');
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));
      final r = await service.toggleTrackLike(trackId: 't1');
      expect(r.$1, 500);
      expect(r.$2.toString(), contains('Network error'));
    });
  });

  group('checkTrackLikeStatus', () {
    test('GET 200 returns liked status', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'liked': true}), 200),
      );
      final r = await service.checkTrackLikeStatus(trackId: 't1');
      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/engagement/tracks/v1/t1/like',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.checkTrackLikeStatus(trackId: '');
      expect(r.$1, 400);
      expect(r.$2, 'Invalid track ID');
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.checkTrackLikeStatus(trackId: 't1');
      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.checkTrackLikeStatus(trackId: 't1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.checkTrackLikeStatus(trackId: 't1');
      expect(r.$1, 500);
      expect(r.$2.toString(), contains('Network error'));
    });
  });

  group('togglePlaylistLike', () {
    test('POST 200 success', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'liked': true, 'numOfLikes': 5}), 200),
      );
      final r = await service.togglePlaylistLike(playlistId: 'pl1');
      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse(
            'https://beatza.me/api/engagement/playlists/v1/pl1/like',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty playlist id', () async {
      final r = await service.togglePlaylistLike(playlistId: '');
      expect(r.$1, 400);
      expect(r.$2, 'Invalid playlist ID');
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.togglePlaylistLike(playlistId: 'pl1');
      expect(r.$1, 401);
    });

    test('returns 404 when playlist not found', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Playlist not found'}), 404),
      );
      final r = await service.togglePlaylistLike(playlistId: 'pl1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.togglePlaylistLike(playlistId: 'pl1');
      expect(r.$1, 500);
      expect(r.$2.toString(), contains('Network error'));
    });
  });

  group('getTrackLikers', () {
    test('GET public engagement 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
          (_) async => http.Response(jsonEncode({'users': []}), 200));
      final r = await service.getTrackLikers(trackId: 't1');
      expect(r.$1, 200);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.getTrackLikers(trackId: '');
      expect(r.$1, 400);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.getTrackLikers(trackId: 't1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.getTrackLikers(trackId: 't1');
      expect(r.$1, 500);
    });
  });

  group('getPlaylistLikers', () {
    test('GET public playlist likes 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
          (_) async => http.Response(jsonEncode({'users': []}), 200));
      final r = await service.getPlaylistLikers(playlistId: 'pl1');
      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) => u.path ==
                  '/api/public/engagement/playlists/v1/pl1/likes',
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty playlist id', () async {
      final r = await service.getPlaylistLikers(playlistId: '');
      expect(r.$1, 400);
    });

    test('returns 404 when playlist not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Playlist not found'}), 404),
      );
      final r = await service.getPlaylistLikers(playlistId: 'pl1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.getPlaylistLikers(playlistId: 'pl1');
      expect(r.$1, 500);
    });
  });

  // ── REPOSTS ──────────────────────────────────────────────────────────────

  group('getTrackReposters', () {
    test('GET public track reposters 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
          (_) async => http.Response(jsonEncode({'users': []}), 200));
      final r = await service.getTrackReposters(trackId: 't1');
      expect(r.$1, 200);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.getTrackReposters(trackId: '');
      expect(r.$1, 400);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.getTrackReposters(trackId: 't1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.getTrackReposters(trackId: 't1');
      expect(r.$1, 500);
    });
  });

  group('getPlaylistReposters', () {
    test('GET public playlist reposters 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
          (_) async => http.Response(jsonEncode({'users': []}), 200));
      final r = await service.getPlaylistReposters(playlistId: 'pl1');
      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) => u.path ==
                  '/api/public/engagement/playlists/v1/pl1/reposts',
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty playlist id', () async {
      final r = await service.getPlaylistReposters(playlistId: '');
      expect(r.$1, 400);
    });

    test('returns 404 when playlist not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Playlist not found'}), 404),
      );
      final r = await service.getPlaylistReposters(playlistId: 'pl1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.getPlaylistReposters(playlistId: 'pl1');
      expect(r.$1, 500);
    });
  });

  group('getTrackRepostStatus', () {
    test('GET authenticated repost 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'reposted': false}), 200),
      );
      final r = await service.getTrackRepostStatus(trackId: 't1');
      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/engagement/tracks/v1/t1/repost',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.getTrackRepostStatus(trackId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.getTrackRepostStatus(trackId: 't1');
      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.getTrackRepostStatus(trackId: 't1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.getTrackRepostStatus(trackId: 't1');
      expect(r.$1, 500);
    });
  });

  group('toggleTrackRepost', () {
    test('POST 200 success without caption', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'reposted': true, 'numberOfReposts': 5}), 200),
      );
      final r = await service.toggleTrackRepost(trackId: 't1');
      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse(
            'https://beatza.me/api/engagement/tracks/v1/t1/repost',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('POST 200 success with caption', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'reposted': true, 'numberOfReposts': 5}), 200),
      );
      final r = await service.toggleTrackRepost(
          trackId: 't1', caption: 'Love this track!');
      expect(r.$1, 200);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.toggleTrackRepost(trackId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.toggleTrackRepost(trackId: 't1');
      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.toggleTrackRepost(trackId: 't1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('error'));
      final r = await service.toggleTrackRepost(trackId: 't1');
      expect(r.$1, 500);
    });
  });

  group('togglePlaylistRepost', () {
    test('POST 200 success', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'reposted': false, 'numberOfReposts': 3}), 200),
      );
      final r = await service.togglePlaylistRepost(playlistId: 'pl1');
      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse(
            'https://beatza.me/api/engagement/playlists/v1/pl1/repost',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('returns 400 for empty playlist id', () async {
      final r = await service.togglePlaylistRepost(playlistId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.togglePlaylistRepost(playlistId: 'pl1');
      expect(r.$1, 401);
    });

    test('returns 404 when playlist not found', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Playlist not found'}), 404),
      );
      final r = await service.togglePlaylistRepost(playlistId: 'pl1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('error'));
      final r = await service.togglePlaylistRepost(playlistId: 'pl1');
      expect(r.$1, 500);
    });
  });

  group('updateTrackRepostCaption', () {
    test('PATCH 200 success', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'success': true, 'caption': 'Updated!'}), 200),
      );
      final r = await service.updateTrackRepostCaption(
          trackId: 't1', caption: 'Updated!');
      expect(r.$1, 200);
      verify(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/engagement/tracks/v1/t1/repost',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.updateTrackRepostCaption(
          trackId: '', caption: 'cap');
      expect(r.$1, 400);
      expect(r.$2, 'Invalid track ID');
    });

    test('returns 400 for empty caption', () async {
      final r = await service.updateTrackRepostCaption(
          trackId: 't1', caption: '   ');
      expect(r.$1, 400);
      expect(r.$2, 'Caption cannot be empty');
    });

    test('returns 400 when user has not reposted this track', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'error': 'You have not reposted this track'}), 400),
      );
      final r = await service.updateTrackRepostCaption(
          trackId: 't1', caption: 'cap');
      expect(r.$1, 400);
      expect(r.$2, 'You have not reposted this track');
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.updateTrackRepostCaption(
          trackId: 't1', caption: 'cap');
      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.updateTrackRepostCaption(
          trackId: 't1', caption: 'cap');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('error'));
      final r = await service.updateTrackRepostCaption(
          trackId: 't1', caption: 'cap');
      expect(r.$1, 500);
    });
  });

  // ── COMMENTS ─────────────────────────────────────────────────────────────

  group('getTrackComments', () {
    test('GET public comments 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'comments': []}), 200),
      );
      final r = await service.getTrackComments(trackId: 't1');
      expect(r.$1, 200);
    });

    test('returns 400 for empty track id', () async {
      final r = await service.getTrackComments(trackId: '');
      expect(r.$1, 400);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r = await service.getTrackComments(trackId: 't1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.getTrackComments(trackId: 't1');
      expect(r.$1, 500);
    });
  });

  group('getCommentReplies', () {
    test('GET public replies 200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'replies': []}), 200),
      );
      final r = await service.getCommentReplies(commentId: 'c1');
      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) =>
                  u.path ==
                  '/api/public/engagement/comments/v1/c1/replies',
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty comment id', () async {
      final r = await service.getCommentReplies(commentId: '');
      expect(r.$1, 400);
    });

    test('returns 404 when comment not found', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Comment not found'}), 404),
      );
      final r = await service.getCommentReplies(commentId: 'c1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.getCommentReplies(commentId: 'c1');
      expect(r.$1, 500);
    });
  });

  group('postComment', () {
    test('POST 201 success top-level comment', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'commentId': 'cmt1',
            'userId': 'u1',
            'displayName': 'User',
            'avatarUrl': null,
            'content': 'Nice!',
            'timestamp': 10,
            'numLikes': 0,
            'replyCount': 0,
            'isLikedByUser': false,
            'isOwnComment': true,
            'createdAt': '2024-01-01T00:00:00.000Z',
          }),
          201,
        ),
      );
      final r = await service.postComment(
          trackId: 't1', content: 'Nice!', timestamp: 10);
      expect(r.$1, 201);
      verify(
        () => mockClient.post(
          Uri.parse(
            'https://beatza.me/api/engagement/tracks/v1/t1/comments',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('returns 400 for empty track id', () async {
      final r =
          await service.postComment(trackId: '', content: 'Nice!', timestamp: 10);
      expect(r.$1, 400);
      expect(r.$2, 'Invalid track ID');
    });

    test('returns 400 for empty content', () async {
      final r =
          await service.postComment(trackId: 't1', content: '  ', timestamp: 10);
      expect(r.$1, 400);
      expect(r.$2, 'Comment cannot be empty');
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r =
          await service.postComment(trackId: 't1', content: 'Hi', timestamp: 5);
      expect(r.$1, 401);
    });

    test('returns 404 when track not found', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Track not found'}), 404),
      );
      final r =
          await service.postComment(trackId: 't1', content: 'Hi', timestamp: 5);
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('error'));
      final r =
          await service.postComment(trackId: 't1', content: 'Hi', timestamp: 5);
      expect(r.$1, 500);
    });
  });

  group('deleteComment', () {
    test('DELETE 200 success', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'message': 'Comment deleted successfully.'}), 200),
      );
      final r = await service.deleteComment(commentId: 'cmt1');
      expect(r.$1, 200);
      expect(r.$2, 'Comment deleted successfully.');
      verify(
        () => mockClient.delete(
          Uri.parse(
            'https://beatza.me/api/engagement/comments/v1/cmt1',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty comment id', () async {
      final r = await service.deleteComment(commentId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.deleteComment(commentId: 'cmt1');
      expect(r.$1, 401);
    });

    test('returns 403 when not enough permissions', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'message': 'Not enough permissions'}), 403),
      );
      final r = await service.deleteComment(commentId: 'cmt1');
      expect(r.$1, 403);
      expect(r.$2, 'Not enough permissions');
    });

    test('returns 404 when comment not found', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Comment not found'}), 404),
      );
      final r = await service.deleteComment(commentId: 'cmt1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.delete(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.deleteComment(commentId: 'cmt1');
      expect(r.$1, 500);
    });
  });

  group('toggleCommentLike', () {
    test('POST 200 success', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'liked': true, 'numLikes': 7}), 200),
      );
      final r = await service.toggleCommentLike(commentId: 'cmt1');
      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse(
            'https://beatza.me/api/engagement/comments/v1/cmt1/like',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 for empty comment id', () async {
      final r = await service.toggleCommentLike(commentId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);
      final r = await service.toggleCommentLike(commentId: 'cmt1');
      expect(r.$1, 401);
    });

    test('returns 404 when comment not found', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Comment not found'}), 404),
      );
      final r = await service.toggleCommentLike(commentId: 'cmt1');
      expect(r.$1, 404);
    });

    test('returns 500 on network error', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));
      final r = await service.toggleCommentLike(commentId: 'cmt1');
      expect(r.$1, 500);
    });
  });
}
