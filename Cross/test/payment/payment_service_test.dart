import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockHttpClient mockHttp;
  late MockSecureStorage mockStorage;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockHttp = MockHttpClient();
    mockStorage = MockSecureStorage();
    PaymentService.storageOverride = mockStorage;
    PaymentService.refreshTokenHttpClient = mockHttp;
  });

  tearDown(() {
    PaymentService.storageOverride = null;
    PaymentService.refreshTokenHttpClient = http.Client();
  });

  // ── GET /api/auth/v1/refresh-token ────────────────────────────────────────

  group('refreshToken', () {
    test('200 updates access and refresh tokens in storage', () async {
      when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'ref_old');
      when(
        () => mockHttp.get(
          Uri.parse('https://beatza.me/api/auth/v1/refresh-token'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'data': {
              'accessToken': 'acc_new',
              'refreshToken': 'ref_new',
            },
          }),
          200,
        ),
      );
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await PaymentService.refreshToken();

      verify(
        () => mockStorage.write(key: 'access_token', value: 'acc_new'),
      ).called(1);
      verify(
        () => mockStorage.write(key: 'refresh_token', value: 'ref_new'),
      ).called(1);
    });

    test('throws when refresh token missing', () async {
      when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => null);

      expect(PaymentService.refreshToken, throwsException);
    });

    test('throws when server returns non-200', () async {
      when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'ref_old');
      when(
        () => mockHttp.get(
          Uri.parse('https://beatza.me/api/auth/v1/refresh-token'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(() => PaymentService.refreshToken(), throwsException);
    });

    test('throws on network error during refresh', () async {
      when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'ref_old');
      when(
        () => mockHttp.get(
          Uri.parse('https://beatza.me/api/auth/v1/refresh-token'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      expect(() => PaymentService.refreshToken(), throwsException);
    });

    test('200 but missing tokens in response body does not write to storage',
        () async {
      when(() => mockStorage.read(key: 'refresh_token'))
          .thenAnswer((_) async => 'ref_old');
      when(
        () => mockHttp.get(
          Uri.parse('https://beatza.me/api/auth/v1/refresh-token'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'data': {}}),
          200,
        ),
      );
      when(
        () => mockStorage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});

      await PaymentService.refreshToken();

      verifyNever(
        () => mockStorage.write(key: 'access_token', value: any(named: 'value')),
      );
    });
  });

  // ── GET /api/payment/v1/plans (getPlans uses dart:io HttpClient) ──────────
  // Only testable at the storage boundary — can verify that missing access
  // token causes an early throw before any HTTP call is made.

  group('getPlans', () {
    test('throws when access token missing', () async {
      when(() => mockStorage.read(key: 'access_token'))
          .thenAnswer((_) async => null);

      expect(PaymentService.getPlans, throwsException);
    });
  });
}
