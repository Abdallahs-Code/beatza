import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/followers_social_graph/services/social_api_service.dart';

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
  late SocialApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockSecureStorage();
    when(() => mockStorage.read(key: 'access_token'))
        .thenAnswer((_) async => 'tok');
    service = SocialApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      storage: mockStorage,
    );
  });

  // ── GET /api/social/v1/followers/{userId} ─────────────────────────────────

  group('getFollowers', () {
    test('200 returns follower list', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getFollowers(userId: 'u1');

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/social/v1/followers/u1'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.getFollowers(userId: '  ');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getFollowers(userId: 'u1');
      expect(r.$1, 401);
    });

    test('404 propagates status and message', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final r = await service.getFollowers(userId: 'u1');
      expect(r.$1, 404);
    });

    test('500 propagates status', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.getFollowers(userId: 'u1');
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.getFollowers(userId: 'u1');
      expect(r.$1, 500);
    });
  });

  // ── GET /api/social/v1/following/{userId} ─────────────────────────────────

  group('getFollowing', () {
    test('200 returns following list', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getFollowing(userId: 'u1');

      expect(r.$1, 200);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.getFollowing(userId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getFollowing(userId: 'u1');
      expect(r.$1, 401);
    });

    test('404 propagates status', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final r = await service.getFollowing(userId: 'u1');
      expect(r.$1, 404);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getFollowing(userId: 'u1');
      expect(r.$1, 500);
    });
  });

  // ── GET /api/social/v1/suggested ─────────────────────────────────────────

  group('getSuggestedUsers', () {
    test('200 returns suggested users', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getSuggestedUsers();

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/social/v1/suggested'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getSuggestedUsers();
      expect(r.$1, 401);
    });

    test('500 propagates status', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.getSuggestedUsers();
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getSuggestedUsers();
      expect(r.$1, 500);
    });
  });

  // ── GET /api/social/v1/blocked ───────────────────────────────────────────

  group('getBlockedUsers', () {
    test('200 returns blocked users', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode([]), 200));

      final r = await service.getBlockedUsers();

      expect(r.$1, 200);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/social/v1/blocked'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.getBlockedUsers();
      expect(r.$1, 401);
    });

    test('500 propagates status', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.getBlockedUsers();
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final r = await service.getBlockedUsers();
      expect(r.$1, 500);
    });
  });

  // ── POST /api/social/v1/follow/{userId} ──────────────────────────────────

  group('followUser', () {
    test('200 returns success', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final r = await service.followUser(targetUserId: 'u2');

      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/social/v1/follow/u2'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.followUser(targetUserId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.followUser(targetUserId: 'u2');
      expect(r.$1, 401);
    });

    test('404 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final r = await service.followUser(targetUserId: 'u2');
      expect(r.$1, 404);
    });

    test('500 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.followUser(targetUserId: 'u2');
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.followUser(targetUserId: 'u2');
      expect(r.$1, 500);
    });
  });

  // ── POST /api/social/v1/unfollow/{userId} ────────────────────────────────

  group('unfollowUser', () {
    test('200 returns success', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final r = await service.unfollowUser(targetUserId: 'u2');

      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/social/v1/unfollow/u2'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.unfollowUser(targetUserId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.unfollowUser(targetUserId: 'u2');
      expect(r.$1, 401);
    });

    test('404 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final r = await service.unfollowUser(targetUserId: 'u2');
      expect(r.$1, 404);
    });

    test('500 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.unfollowUser(targetUserId: 'u2');
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.unfollowUser(targetUserId: 'u2');
      expect(r.$1, 500);
    });
  });

  // ── POST /api/social/v1/block/{userId} ───────────────────────────────────

  group('blockUser', () {
    test('200 returns success', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final r = await service.blockUser(targetUserId: 'u3');

      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/social/v1/block/u3'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.blockUser(targetUserId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.blockUser(targetUserId: 'u3');
      expect(r.$1, 401);
    });

    test('404 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final r = await service.blockUser(targetUserId: 'u3');
      expect(r.$1, 404);
    });

    test('500 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.blockUser(targetUserId: 'u3');
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.blockUser(targetUserId: 'u3');
      expect(r.$1, 500);
    });
  });

  // ── POST /api/social/v1/unblock/{userId} ─────────────────────────────────

  group('unblockUser', () {
    test('200 returns success', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response(jsonEncode({'ok': true}), 200));

      final r = await service.unblockUser(targetUserId: 'u3');

      expect(r.$1, 200);
      verify(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/social/v1/unblock/u3'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 400 when userId is empty', () async {
      final r = await service.unblockUser(targetUserId: '');
      expect(r.$1, 400);
    });

    test('returns 401 when no access token', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      final r = await service.unblockUser(targetUserId: 'u3');
      expect(r.$1, 401);
    });

    test('404 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final r = await service.unblockUser(targetUserId: 'u3');
      expect(r.$1, 404);
    });

    test('500 propagates status', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      final r = await service.unblockUser(targetUserId: 'u3');
      expect(r.$1, 500);
    });

    test('network error returns 500', () async {
      when(
        () => mockClient.post(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      final r = await service.unblockUser(targetUserId: 'u3');
      expect(r.$1, 500);
    });
  });
}
