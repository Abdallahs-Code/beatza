import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_api_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockAuthApiService extends Mock implements AuthApiService {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'https://beatza.me';
}

void main() {
  late MockHttpClient mockClient;
  late MockAuthApiService mockAuth;
  late MessagingApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockAuth = MockAuthApiService();
    when(() => mockAuth.getStoredAccessToken()).thenAnswer((_) async => 'tok');

    service = MessagingApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      authApiService: mockAuth,
    );
  });

  // ── GET /api/messages/v1/chats ────────────────────────────────────────────

  group('getChats', () {
    test('GET messages/v1/chats 200 returns empty list', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'data': []}),
          200,
        ),
      );

      final chats = await service.getChats();

      expect(chats, isEmpty);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/messages/v1/chats?limit=20'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('throws when unauthorized (no token)', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(() => service.getChats(), throwsA(isA<Exception>()));
    });

    test('throws when server returns non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(() => service.getChats(), throwsA(isA<Exception>()));
    });

    test('throws on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      expect(() => service.getChats(), throwsA(isA<Exception>()));
    });
  });

  // ── GET /api/messages/v1/chat/message/{chatId} ────────────────────────────

  group('getChatMessages', () {
    test('GET 200 returns messages and block flags', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'messages': [],
              'isReceiverBlocked': false,
              'isBlockedByReceiver': false,
            },
          }),
          200,
        ),
      );

      final result =
          await service.getChatMessages(chatId: 'chat1');

      expect(result.messages, isEmpty);
      expect(result.isReceiverBlocked, false);
      expect(result.isBlockedByReceiver, false);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) => u.path == '/api/messages/v1/chat/message/chat1',
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('throws when unauthorized (no token)', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(
        () => service.getChatMessages(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when server returns non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      expect(
        () => service.getChatMessages(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── POST /api/messages/v1/send ────────────────────────────────────────────

  group('sendMessage', () {
    test('POST 200 returns ChatModel', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'chat': 'chat1',
              'participants': ['u1', 'u2'],
            },
          }),
          200,
        ),
      );

      final chat = await service.sendMessage(
          receiverId: 'u2', content: 'Hello');

      expect(chat, isNotNull);
      verify(
        () => mockClient.post(
          Uri.parse('https://beatza.me/api/messages/v1/send'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('throws when unauthorized (no token)', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(
        () => service.sendMessage(receiverId: 'u2', content: 'Hello'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when server returns non-200', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Forbidden'}), 403),
      );

      expect(
        () => service.sendMessage(receiverId: 'u2', content: 'Hello'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/messages/v1/archive ────────────────────────────────────────

  group('archiveChat', () {
    test('PATCH 200 succeeds', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await service.archiveChat(chatId: 'chat1');

      verify(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/messages/v1/archive'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('throws when unauthorized (no token)', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(
        () => service.archiveChat(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when server returns non-200', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      expect(
        () => service.archiveChat(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/messages/v1/chat/read ─────────────────────────────────────

  group('markChatAsRead', () {
    test('PATCH 200 succeeds', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await service.markChatAsRead(chatId: 'chat1');

      verify(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/messages/v1/chat/read'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('PATCH 204 also succeeds', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('', 204));

      await service.markChatAsRead(chatId: 'chat1');
    });

    test('throws on 400 bad request', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Validation failed'}), 400),
      );

      expect(
        () => service.markChatAsRead(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 401 unauthorized', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('{}', 401),
      );

      expect(
        () => service.markChatAsRead(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 404 endpoint not found', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response('{}', 404),
      );

      expect(
        () => service.markChatAsRead(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/messages/v1/chat/unread ───────────────────────────────────

  group('markChatAsUnread', () {
    test('PATCH 200 succeeds', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 200));

      await service.markChatAsUnread(chatId: 'chat1');

      verify(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/messages/v1/chat/unread'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('PATCH 204 also succeeds', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('', 204));

      await service.markChatAsUnread(chatId: 'chat1');
    });

    test('throws on 400 bad request', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Validation failed'}), 400),
      );

      expect(
        () => service.markChatAsUnread(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 401 unauthorized', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 401));

      expect(
        () => service.markChatAsUnread(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 403 forbidden', () async {
      when(
        () => mockClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('{}', 403));

      expect(
        () => service.markChatAsUnread(chatId: 'chat1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── GET /api/tracks/v2/liked/{userId} ────────────────────────────────────

  group('getLikedTracks', () {
    test('GET 200 returns track list', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                '_id': 't1',
                'basicInfo': {
                  'title': 'T',
                  'permalink': 't',
                  'mainArtists': ['A'],
                },
                'audio': {'audioLink': 'https://x.test/a.mp3'},
                'durationInSeconds': 90,
                'isAvailableForUser': true,
                'geoBlocking': {
                  'mode': 'worldwide',
                  'regions': [],
                  'countries': [],
                },
              },
            ],
          }),
          200,
        ),
      );

      final tracks = await service.getLikedTracks(userId: 'u1');

      expect(tracks, isNotEmpty);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/tracks/v2/liked/u1'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns empty list on 404', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final tracks = await service.getLikedTracks(userId: 'u1');

      expect(tracks, isEmpty);
    });

    test('returns empty list on 500 (known backend bug)', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({'message': 'Server error'}), 500),
      );

      final tracks = await service.getLikedTracks(userId: 'u1');

      expect(tracks, isEmpty);
    });
  });

  // ── GET /api/tracks/v2/posted/{userId} ───────────────────────────────────

  group('getUserPostedTracks', () {
    test('GET 200 returns track list', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': [
              {
                '_id': 't1',
                'basicInfo': {
                  'title': 'T',
                  'permalink': 't',
                  'mainArtists': ['A'],
                },
                'audio': {'audioLink': 'https://x.test/a.mp3'},
                'durationInSeconds': 60,
                'isAvailableForUser': true,
                'geoBlocking': {
                  'mode': 'worldwide',
                  'regions': [],
                  'countries': [],
                },
              },
            ],
          }),
          200,
        ),
      );

      final tracks = await service.getUserPostedTracks(userId: 'u1');

      expect(tracks, isNotEmpty);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/tracks/v2/posted/u1'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns empty list on 404', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      final tracks = await service.getUserPostedTracks(userId: 'u1');

      expect(tracks, isEmpty);
    });
  });

  // ── GET /api/public/tracks/v2/permalink/{profileLink}/{permalink} ─────────

  group('getTrackByPermalink', () {
    test('returns null when profileLink is empty', () async {
      final track = await service.getTrackByPermalink(
          profileLink: '', permalink: 'my-track');

      expect(track, isNull);
      verifyNever(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      );
    });

    test('returns null when permalink is empty', () async {
      final track = await service.getTrackByPermalink(
          profileLink: 'artist', permalink: '');

      expect(track, isNull);
    });

    test('returns null on 404', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final track = await service.getTrackByPermalink(
          profileLink: 'artist', permalink: 'track');

      expect(track, isNull);
    });
  });

  // ── GET /api/tracks/v2/{trackId} ─────────────────────────────────────────

  group('getTrackById', () {
    test('returns null when trackId is empty', () async {
      final track = await service.getTrackById(trackId: '');

      expect(track, isNull);
      verifyNever(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      );
    });

    test('returns null on non-200', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Not found'}), 404),
      );

      final track = await service.getTrackById(trackId: 't1');

      expect(track, isNull);
    });
  });

  // ── GET /api/profile/v1/{userId} ─────────────────────────────────────────

  group('getProfileBlockingMe', () {
    test('GET profile/v1/{userId} returns false when not blocked', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'amIBlocked': false}), 200),
      );

      final blocked = await service.getProfileBlockingMe(userId: 'u9');

      expect(blocked, false);
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/u9'),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns true when user is blocked', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'amIBlocked': true}), 200),
      );

      final blocked = await service.getProfileBlockingMe(userId: 'u9');

      expect(blocked, true);
    });

    test('returns false when userId is empty', () async {
      final blocked = await service.getProfileBlockingMe(userId: '');

      expect(blocked, false);
      verifyNever(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      );
    });

    test('returns false on 401', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('{}', 401),
      );

      final blocked = await service.getProfileBlockingMe(userId: 'u9');

      expect(blocked, false);
    });

    test('returns false on 404', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('{}', 404),
      );

      final blocked = await service.getProfileBlockingMe(userId: 'u9');

      expect(blocked, false);
    });

    test('returns false on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      final blocked = await service.getProfileBlockingMe(userId: 'u9');

      expect(blocked, false);
    });
  });
}
