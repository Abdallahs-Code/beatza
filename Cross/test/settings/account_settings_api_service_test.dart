import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/library/models/account_settings_model.dart';
import 'package:cross_team5/features/library/services/account_settings_api_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'https://beatza.me';
}

void main() {
  late MockHttpClient mockClient;
  late AccountSettingsApiService service;

  setUpAll(() async {
    await loadTestEnv();
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = AccountSettingsApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
    );
  });

  // ── GET /api/profile/v1/settings/account ─────────────────────────────────

  group('getSettings', () {
    test('200 returns parsed settings', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'theme': 'Dark',
              'dateOfBirth': '1990-01-01',
              'gender': 'Male',
            },
          }),
          200,
        ),
      );

      final s = await service.getSettings('tok');

      expect(s.theme, 'Dark');
      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer tok',
            'User-Agent': 'Android',
          },
        ),
      ).called(1);
    });

    test('200 without wrapping data key also parses', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'theme': 'Light', 'dateOfBirth': '', 'gender': ''}),
          200,
        ),
      );

      final s = await service.getSettings('tok');

      expect(s.theme, 'Light');
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.getSettings('tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('403 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Forbidden'}), 403),
      );

      expect(
        () => service.getSettings('tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.getSettings('tok'),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      expect(
        () => service.getSettings('tok'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/profile/v1/settings/account ───────────────────────────────

  group('updateSettings', () {
    final settings = AccountSettings(
      theme: 'Light',
      dateOfBirth: '1990-01-01',
      gender: 'Female',
    );

    test('200 returns updated settings', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'theme': 'Light',
              'dateOfBirth': '1990-01-01',
              'gender': 'Female',
            },
          }),
          200,
        ),
      );

      final out = await service.updateSettings('tok', settings);

      expect(out.theme, 'Light');
    });

    test('400 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Bad Request'}), 400),
      );

      expect(
        () => service.updateSettings('tok', settings),
        throwsA(isA<Exception>()),
      );
    });

    test('401 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.updateSettings('tok', settings),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.updateSettings('tok', settings),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/account'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('timeout'));

      expect(
        () => service.updateSettings('tok', settings),
        throwsA(isA<Exception>()),
      );
    });
  });
}
