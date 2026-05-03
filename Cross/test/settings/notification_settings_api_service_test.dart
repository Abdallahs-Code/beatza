import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/library/models/notification_settings_model.dart';
import 'package:cross_team5/features/library/services/notification_settings_api_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'https://beatza.me';
}

void main() {
  late MockHttpClient mockClient;
  late NotificationSettingsApiService service;

  setUpAll(() async {
    await loadTestEnv();
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = NotificationSettingsApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
    );
  });

  final allOff = NotificationSettings(
    newFollower: 'off',
    repostOfYourPost: 'off',
    newPostByFollowedUser: 'off',
    likesAndPlaysOnYourPost: 'off',
    commentOnYourPost: 'off',
    recommendedContent: 'off',
    updatesFromSoundcloud: 'off',
    soundcloudFeatureUpdatesEducation: 'off',
    surveysAndFeedback: 'off',
    promotionalPartnershipContent: 'off',
    soundcloudNewsletter: 'off',
    newMessageEmail: false,
    newMessageDevices: 'off',
  );

  // ── GET /api/profile/v1/settings/notifications ───────────────────────────

  group('getSettings', () {
    test('200 returns parsed settings', () async {
      when(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response(jsonEncode({}), 200));

      final s = await service.getSettings('t');

      expect(s.newFollower, 'off');
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.getSettings('t'),
        throwsA(isA<Exception>()),
      );
    });

    test('403 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Forbidden'}), 403),
      );

      expect(
        () => service.getSettings('t'),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.getSettings('t'),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.get(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      expect(
        () => service.getSettings('t'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/profile/v1/settings/notifications ─────────────────────────

  group('updateSettings', () {
    test('200 returns updated settings', () async {
      when(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(allOff.toJson()), 200),
      );

      final out = await service.updateSettings('t', allOff);

      expect(out.newMessageDevices, 'off');
    });

    test('400 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Bad Request'}), 400),
      );

      expect(
        () => service.updateSettings('t', allOff),
        throwsA(isA<Exception>()),
      );
    });

    test('401 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.updateSettings('t', allOff),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.updateSettings('t', allOff),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse(
            'https://beatza.me/api/profile/v1/settings/notifications',
          ),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('timeout'));

      expect(
        () => service.updateSettings('t', allOff),
        throwsA(isA<Exception>()),
      );
    });
  });
}
