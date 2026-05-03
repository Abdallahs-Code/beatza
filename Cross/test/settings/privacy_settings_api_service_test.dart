import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/library/models/privacy_settings_model.dart';
import 'package:cross_team5/features/library/services/privacy_settings_api_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'https://beatza.me';
}

void main() {
  late MockHttpClient mockClient;
  late PrivacySettingsApiService service;

  setUpAll(() async {
    await loadTestEnv();
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = PrivacySettingsApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
    );
  });

  // ── GET /api/profile/v1/settings/privacy ─────────────────────────────────

  group('getSettings', () {
    test('200 returns parsed settings', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'allowMessagesAnyone': true,
            'showActivityDiscovery': true,
            'showFirstTopFan': false,
            'showTrackTopFans': true,
          }),
          200,
        ),
      );

      final s = await service.getSettings('t');

      expect(s.allowMessagesAnyone, true);
      expect(s.showFirstTopFan, false);
    });

    test('401 throws', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
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
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
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
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
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
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      expect(
        () => service.getSettings('t'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ── PATCH /api/profile/v1/settings/privacy ───────────────────────────────

  group('updateSettings', () {
    final p = PrivacySettings(
      allowMessagesAnyone: true,
      showActivityDiscovery: false,
      showFirstTopFan: true,
      showTrackTopFans: true,
    );

    test('200 returns updated settings', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(jsonEncode(p.toJson()), 200),
      );

      final out = await service.updateSettings('t', p);

      expect(out.showActivityDiscovery, false);
    });

    test('400 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Bad Request'}), 400),
      );

      expect(
        () => service.updateSettings('t', p),
        throwsA(isA<Exception>()),
      );
    });

    test('401 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.updateSettings('t', p),
        throwsA(isA<Exception>()),
      );
    });

    test('500 throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.updateSettings('t', p),
        throwsA(isA<Exception>()),
      );
    });

    test('network error throws', () async {
      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1/settings/privacy'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('timeout'));

      expect(
        () => service.updateSettings('t', p),
        throwsA(isA<Exception>()),
      );
    });
  });
}
