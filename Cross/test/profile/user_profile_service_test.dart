import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:cross_team5/core/services/api_services.dart';
import 'package:cross_team5/features/user_profile_social_identity/models/user_profile_model.dart';
import 'package:cross_team5/features/user_profile_social_identity/services/user_profile_service.dart';

import '../helpers/load_test_env.dart';

class MockHttpClient extends Mock implements http.Client {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => 'https://beatza.me';
}

void main() {
  late MockHttpClient mockClient;
  late UserProfileService service;

  setUpAll(() async {
    await loadTestEnv();
    registerFallbackValue(Uri.parse('https://beatza.me'));
  });

  setUp(() {
    mockClient = MockHttpClient();
    service = UserProfileService(
      apiServices: FakeApiServices(),
      client: mockClient,
    );
  });

  // ── GET /api/public/profile/v1/{userId} ───────────────────────────────────

  group('getUserProfile', () {
    test('200 returns parsed profile', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'userId': 'u1', 'displayName': 'Tester'}),
          200,
        ),
      );

      final profile = await service.getUserProfile('u1', 'token');

      expect(profile.userId, 'u1');
      expect(profile.displayName, 'Tester');

      verify(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer token',
            'User-Agent': 'Android',
          },
        ),
      ).called(1);
    });

    test('401 throws ApiException', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.getUserProfile('u1', 'token'),
        throwsA(isA<ApiException>()),
      );
    });

    test('403 throws ApiException', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Forbidden'}), 403),
      );

      expect(
        () => service.getUserProfile('u1', 'token'),
        throwsA(isA<ApiException>()),
      );
    });

    test('404 throws ApiException with 404 status', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'User not found'}), 404),
      );

      ApiException? caught;
      try {
        await service.getUserProfile('u1', 'token');
      } on ApiException catch (e) {
        caught = e;
      }
      expect(caught?.statusCode, 404);
    });

    test('500 throws ApiException', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      expect(
        () => service.getUserProfile('u1', 'token'),
        throwsA(isA<ApiException>()),
      );
    });

    test('network error throws ApiException with statusCode 500', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenThrow(Exception('network down'));

      ApiException? caught;
      try {
        await service.getUserProfile('u1', 'token');
      } on ApiException catch (e) {
        caught = e;
      }
      expect(caught?.statusCode, 500);
      expect(caught?.message, contains('Network error'));
    });

    test('HTML response throws ApiException', () async {
      when(
        () => mockClient.get(
          Uri.parse('https://beatza.me/api/public/profile/v1/u1'),
          headers: any(named: 'headers'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          '<!DOCTYPE html><html><body>Not Found</body></html>',
          404,
        ),
      );

      expect(
        () => service.getUserProfile('u1', 'token'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ── PATCH /api/profile/v1 ────────────────────────────────────────────────

  group('updateUserProfile', () {
    test('200 with profile data in body returns updated profile', () async {
      final model = UserProfileModel(userId: 'u1', displayName: 'Updated');

      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({'userId': 'u1', 'displayName': 'Updated'}),
          200,
        ),
      );

      final out = await service.updateUserProfile(model, 'tok');

      expect(out.displayName, 'Updated');
      verify(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer tok',
            'User-Agent': 'Android',
          },
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test('400 throws ApiException', () async {
      final model = UserProfileModel(userId: 'u1', displayName: '');

      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Validation error'}), 400),
      );

      expect(
        () => service.updateUserProfile(model, 'tok'),
        throwsA(isA<ApiException>()),
      );
    });

    test('401 throws ApiException', () async {
      final model = UserProfileModel(userId: 'u1', displayName: 'X');

      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({'message': 'Unauthorized'}), 401),
      );

      expect(
        () => service.updateUserProfile(model, 'tok'),
        throwsA(isA<ApiException>()),
      );
    });

    test('500 throws ApiException', () async {
      final model = UserProfileModel(userId: 'u1', displayName: 'X');

      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => http.Response('Server Error', 500));

      expect(
        () => service.updateUserProfile(model, 'tok'),
        throwsA(isA<ApiException>()),
      );
    });

    test('network error throws ApiException with statusCode 500', () async {
      final model = UserProfileModel(userId: 'u1', displayName: 'X');

      when(
        () => mockClient.patch(
          Uri.parse('https://beatza.me/api/profile/v1'),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(Exception('timeout'));

      ApiException? caught;
      try {
        await service.updateUserProfile(model, 'tok');
      } on ApiException catch (e) {
        caught = e;
      }
      expect(caught?.statusCode, 500);
    });
  });
}
