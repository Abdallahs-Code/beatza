import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/activity/services/activity_notifications_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';

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
  late ActivityNotificationsApiService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockAuth = MockAuthApiService();
    when(() => mockAuth.getStoredAccessToken()).thenAnswer((_) async => 'tok');

    service = ActivityNotificationsApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      authApiService: mockAuth,
    );
  });

  // ── GET /api/notifications/v1 ─────────────────────────────────────────────

  group('getNotifications', () {
    test('GET notifications/v1 200 returns page', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'notifications': [],
            'total': 0,
            'offset': 1,
            'limit': 20,
          }),
          200,
        ),
      );

      final page = await service.getNotifications();

      expect(page.notifications, isEmpty);
      verify(
        () => mockClient.get(
          any(
            that: predicate<Uri>(
              (u) =>
                  u.path == '/api/notifications/v1' &&
                  u.queryParameters['offset'] == '1' &&
                  u.queryParameters['limit'] == '20',
            ),
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('throws when no access token', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(
        () => service.getNotifications(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 401 unauthorized', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized Access'}), 401),
      );

      expect(
        () => service.getNotifications(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 500 server error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Internal server error'}), 500),
      );

      expect(
        () => service.getNotifications(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('network down'));

      expect(
        () => service.getNotifications(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── GET /api/notifications/v1/unread-count ────────────────────────────────

  group('getUnreadCount', () {
    test('GET unread-count 200 returns count', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'unreadCount': 5}), 200),
      );

      final n = await service.getUnreadCount();

      expect(n, 5);
      verify(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/notifications/v1/unread-count',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('returns 0 when unreadCount absent in 200 response', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode({}), 200),
      );

      final n = await service.getUnreadCount();

      expect(n, 0);
    });

    test('throws when no access token', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(
        () => service.getUnreadCount(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 401', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized Access'}), 401),
      );

      expect(
        () => service.getUnreadCount(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on network error', () async {
      when(
        () => mockClient.get(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      expect(
        () => service.getUnreadCount(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/notifications/v1/read-all ──────────────────────────────────

  group('markAllAsRead', () {
    test('PATCH read-all 200 returns updated unread count', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'unreadCount': 0}), 200),
      );

      final n = await service.markAllAsRead();

      expect(n, 0);
      verify(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/notifications/v1/read-all',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('throws when no access token', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(
        () => service.markAllAsRead(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 401', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.markAllAsRead(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 500 server error', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Server error'}), 500),
      );

      expect(
        () => service.markAllAsRead(),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/notifications/v1/{notificationId}/read ─────────────────────

  group('markSingleAsRead', () {
    test('PATCH {id}/read 200 succeeds', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async => http.Response('{}', 200),
      );

      await service.markSingleAsRead('n1');

      verify(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/notifications/v1/n1/read',
          ),
          headers: any(named: 'headers'),
        ),
      ).called(1);
    });

    test('throws when no access token', () async {
      when(() => mockAuth.getStoredAccessToken())
          .thenAnswer((_) async => null);

      expect(
        () => service.markSingleAsRead('n1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 401', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.markSingleAsRead('n1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 404 notification not found', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Notification not found'}), 404),
      );

      expect(
        () => service.markSingleAsRead('n1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on network error', () async {
      when(
        () => mockClient.patch(any(), headers: any(named: 'headers')),
      ).thenThrow(Exception('error'));

      expect(
        () => service.markSingleAsRead('n1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
