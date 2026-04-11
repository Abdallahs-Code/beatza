// Dart imports
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/models/user.dart'
    as user_model;
import 'package:cross_team5/core/services/api_services.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

class FakeApiServices extends Fake implements ApiServices {
  @override
  String get baseUrl => "https://beatza.me";
}

void main() {
  late MockHttpClient mockClient;
  late MockSecureStorage mockStorage;
  late AuthApiService authApiService;

  final validUser = user_model.User(
    "test@example.com",
    "Password123",
    "Test User",
    "2000-01-01",
    "Male",
  );

  setUpAll(() {
    registerFallbackValue(Uri.parse("https://beatza.me"));
  });

  setUp(() {
    mockClient = MockHttpClient();
    mockStorage = MockSecureStorage();

    authApiService = AuthApiService(
      apiServices: FakeApiServices(),
      client: mockClient,
      storage: mockStorage,
    );
  });

  group("login", () {
    test("returns 400 for invalid email", () async {
      final invalidUser = user_model.User(
        "bad-email",
        "Password123",
        "Test User",
        "2000-01-01",
        "Male",
      );

      final result = await authApiService.login(user: invalidUser);

      expect(result.$1, 400);
      expect(result.$2, "Invalid email format");

      verifyNever(
        () => mockClient.post(
          any(),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      );
    });

    test("returns 200 and stores tokens on successful login", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/login"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "message": "Login successful",
            "data": {
              "accessToken": "access_123",
              "refreshToken": "refresh_123",
            },
          }),
          200,
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      final result = await authApiService.login(user: validUser);

      expect(result.$1, 200);
      expect(result.$2, "Login successful");

      verify(
        () => mockStorage.write(key: "access_token", value: "access_123"),
      ).called(1);
      verify(
        () => mockStorage.write(key: "refresh_token", value: "refresh_123"),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: "token_time",
          value: any(named: "value"),
        ),
      ).called(1);
    });

    test("sends correct headers and body in login request", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/login"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "message": "Login successful",
            "data": {
              "accessToken": "access_123",
              "refreshToken": "refresh_123",
            },
          }),
          200,
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      await authApiService.login(user: validUser);

      verify(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/login"),
          headers: {
            "Content-Type": "application/json",
            "User-Agent": "Android",
          },
          body: jsonEncode({
            "email": validUser.email,
            "password": validUser.password,
          }),
        ),
      ).called(1);
    });

    test("returns error when login succeeds but tokens are missing", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/login"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({"message": "Tokens missing", "data": {}}),
          200,
        ),
      );

      final result = await authApiService.login(user: validUser);

      expect(result.$1, 200);
      expect(result.$2, "Tokens missing");
    });

    test("returns backend error message on failed login", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/login"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({"message": "Invalid credentials"}), 401),
      );

      final result = await authApiService.login(user: validUser);

      expect(result.$1, 401);
      expect(result.$2, "Invalid credentials");
    });

    test("returns 500 on network error", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/login"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenThrow(Exception("network down"));

      final result = await authApiService.login(user: validUser);

      expect(result.$1, 500);
      expect(result.$2.toString(), contains("Network error"));
    });

    test("handles malformed JSON response", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/login"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer((_) async => http.Response("INVALID_JSON", 200));

      final result = await authApiService.login(user: validUser);

      expect(result.$1, 500);
      expect(result.$2.toString(), contains("Network error"));
    });
  });

  group("signup", () {
    test("returns 400 for invalid email", () async {
      final invalidUser = user_model.User(
        "bad-email",
        "Password123",
        "Test User",
        "2000-01-01",
        "Male",
      );

      final result = await authApiService.signup(user: invalidUser);

      expect(result.$1, 400);
      expect(result.$2, "Invalid email format");
    });

    test("returns success response on valid signup", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/sign-up"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({"message": "Signup successful"}), 201),
      );

      final result = await authApiService.signup(user: validUser);

      expect(result.$1, 201);
      expect(result.$2, "Signup successful");
    });

    test("sends correct signup request body", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/sign-up"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({"message": "Signup successful"}), 201),
      );

      await authApiService.signup(user: validUser);

      verify(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/sign-up"),
          headers: {
            "Content-Type": "application/json",
            "User-Agent": "Android",
          },
          body: jsonEncode({
            "email": validUser.email,
            "password": validUser.password,
            "displayName": validUser.displayName,
            "dateOfBirth": validUser.dateOfBirth,
            "gender": validUser.gender,
          }),
        ),
      ).called(1);
    });

    test("returns 500 on signup network error", () async {
      when(
        () => mockClient.post(
          Uri.parse("https://beatza.me/api/auth/v1/sign-up"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenThrow(Exception("signup failed"));

      final result = await authApiService.signup(user: validUser);

      expect(result.$1, 500);
      expect(result.$2.toString(), contains("Network error"));
    });
  });

  group("logout", () {
    test("does nothing if no access token exists", () async {
      when(
        () => mockStorage.read(key: "access_token"),
      ).thenAnswer((_) async => null);

      await authApiService.logout();

      verify(() => mockStorage.read(key: "access_token")).called(1);
      verifyNever(() => mockClient.get(any(), headers: any(named: "headers")));
    });

    test("calls logout endpoint and clears tokens on success", () async {
      when(
        () => mockStorage.read(key: "access_token"),
      ).thenAnswer((_) async => "access_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/logout"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer((_) async => http.Response("{}", 200));

      when(
        () => mockStorage.delete(key: any(named: "key")),
      ).thenAnswer((_) async {});

      await authApiService.logout();

      verify(() => mockStorage.delete(key: "access_token")).called(1);
      verify(() => mockStorage.delete(key: "refresh_token")).called(1);
      verify(() => mockStorage.delete(key: "token_time")).called(1);
    });

    test("handles 401 logout response gracefully", () async {
      when(
        () => mockStorage.read(key: "access_token"),
      ).thenAnswer((_) async => "access_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/logout"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer((_) async => http.Response("{}", 401));

      when(
        () => mockStorage.delete(key: any(named: "key")),
      ).thenAnswer((_) async {});

      await authApiService.logout();

      verify(() => mockStorage.delete(key: "access_token")).called(1);
      verify(() => mockStorage.delete(key: "refresh_token")).called(1);
      verify(() => mockStorage.delete(key: "token_time")).called(1);
    });

    test("handles unexpected logout status code", () async {
      when(
        () => mockStorage.read(key: "access_token"),
      ).thenAnswer((_) async => "access_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/logout"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer((_) async => http.Response("{}", 500));

      when(
        () => mockStorage.delete(key: any(named: "key")),
      ).thenAnswer((_) async {});

      await authApiService.logout();

      verify(() => mockStorage.delete(key: "access_token")).called(1);
      verify(() => mockStorage.delete(key: "refresh_token")).called(1);
      verify(() => mockStorage.delete(key: "token_time")).called(1);
    });

    test("clears tokens even if logout request fails", () async {
      when(
        () => mockStorage.read(key: "access_token"),
      ).thenAnswer((_) async => "access_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/logout"),
          headers: any(named: "headers"),
        ),
      ).thenThrow(Exception("server exploded"));

      when(
        () => mockStorage.delete(key: any(named: "key")),
      ).thenAnswer((_) async {});

      await authApiService.logout();

      verify(() => mockStorage.delete(key: "access_token")).called(1);
      verify(() => mockStorage.delete(key: "refresh_token")).called(1);
      verify(() => mockStorage.delete(key: "token_time")).called(1);
    });
  });

  group("refreshToken", () {
    test("returns 401 if no refresh token exists", () async {
      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => null);

      final result = await authApiService.refreshToken();

      expect(result.$1, 401);
      expect(result.$2, "No refresh token found");
    });

    test("stores new tokens on successful refresh", () async {
      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "refresh_old");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "data": {
              "accessToken": "access_new",
              "refreshToken": "refresh_new",
            },
          }),
          200,
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      final result = await authApiService.refreshToken();

      expect(result.$1, 200);
      expect(result.$2, "Token refreshed successfully");

      verify(
        () => mockStorage.write(key: "access_token", value: "access_new"),
      ).called(1);
      verify(
        () => mockStorage.write(key: "refresh_token", value: "refresh_new"),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: "token_time",
          value: any(named: "value"),
        ),
      ).called(1);
    });

    test("returns backend message if refreshed tokens are missing", () async {
      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "refresh_old");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({"message": "Tokens missing", "data": {}}),
          200,
        ),
      );

      final result = await authApiService.refreshToken();

      expect(result.$1, 200);
      expect(result.$2, "Tokens missing");
    });

    test("returns backend message on non-200 refresh response", () async {
      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "refresh_old");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async =>
            http.Response(jsonEncode({"message": "Unauthorized"}), 401),
      );

      final result = await authApiService.refreshToken();

      expect(result.$1, 401);
      expect(result.$2, "Unauthorized");
    });

    test("returns 500 on refresh network error", () async {
      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "refresh_old");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenThrow(Exception("refresh failed"));

      final result = await authApiService.refreshToken();

      expect(result.$1, 500);
      expect(result.$2.toString(), contains("Network error"));
    });
  });

  group("Google Auth - New user", () {
    test("returns 400 if incompleteToken is empty", () async {
      final result = await authApiService.completeGoogleSignup(
        incompleteToken: "",
        dateOfBirth: "2000-01-01",
        gender: "Male",
      );

      expect(result.$1, 400);
      expect(result.$2, "Incomplete token is required");
    });

    test("returns 400 if dateOfBirth is empty", () async {
      final result = await authApiService.completeGoogleSignup(
        incompleteToken: "incomplete_token_123",
        dateOfBirth: "",
        gender: "Male",
      );

      expect(result.$1, 400);
      expect(result.$2, "Date of birth is required");
    });

    test("returns 400 if gender is empty", () async {
      final result = await authApiService.completeGoogleSignup(
        incompleteToken: "incomplete_token_123",
        dateOfBirth: "2000-01-01",
        gender: "",
      );

      expect(result.$1, 400);
      expect(result.$2, "Gender is required");
    });

    test("returns 200 and stores tokens on successful signup completion",
        () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/complete?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "message": "Authenticated successfully",
            "data": {
              "accessToken": "google_access_123",
              "refreshToken": "google_refresh_123",
            },
          }),
          200,
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "google_refresh_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "data": {
              "accessToken": "google_access_new",
              "refreshToken": "google_refresh_new",
              "user": {"id": "user_1"},
            },
          }),
          200,
        ),
      );

      final result = await authApiService.completeGoogleSignup(
        incompleteToken: "incomplete_token_123",
        dateOfBirth: "2000-01-01",
        gender: "Male",
      );

      expect(result.$1, 200);

      verify(
        () => mockStorage.write(
            key: "access_token", value: "google_access_123"),
      ).called(1);
      verify(
        () => mockStorage.write(
            key: "refresh_token", value: "google_refresh_123"),
      ).called(1);
    });

    test("sends correct request body", () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/complete?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "message": "Authenticated successfully",
            "data": {
              "accessToken": "google_access_123",
              "refreshToken": "google_refresh_123",
            },
          }),
          200,
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "google_refresh_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "data": {
              "accessToken": "google_access_new",
              "refreshToken": "google_refresh_new",
            },
          }),
          200,
        ),
      );

      await authApiService.completeGoogleSignup(
        incompleteToken: "incomplete_token_123",
        dateOfBirth: "2000-01-01",
        gender: "Male",
      );

      verify(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/complete?client=Android"),
          headers: {
            "Content-Type": "application/json",
            "User-Agent": "Android",
          },
          body: jsonEncode({
            "incompleteToken": "incomplete_token_123",
            "dateOfBirth": "2000-01-01",
            "gender": "Male",
          }),
        ),
      ).called(1);
    });

    test("returns backend error on non-200 response", () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/complete?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({"message": "Invalid token"}),
          400,
        ),
      );

      final result = await authApiService.completeGoogleSignup(
        incompleteToken: "bad_token",
        dateOfBirth: "2000-01-01",
        gender: "Male",
      );

      expect(result.$1, 400);
      expect(result.$2, "Invalid token");
    });

    test("returns 500 on network error", () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/complete?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenThrow(Exception("network down"));

      final result = await authApiService.completeGoogleSignup(
        incompleteToken: "incomplete_token_123",
        dateOfBirth: "2000-01-01",
        gender: "Male",
      );

      expect(result.$1, 500);
      expect(result.$2.toString(), contains("Network error"));
    });
  });

  group("Google Auth - Returning Google user", () {
    // This group tests the scenario where a user who previously signed up with Google is signing back in.

    test("saveTokens stores tokens correctly for returning Google user",
        () async {
      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      await authApiService.saveTokens(
        accessToken: "google_returning_access",
        refreshToken: "google_returning_refresh",
      );

      verify(
        () => mockStorage.write(
            key: "access_token", value: "google_returning_access"),
      ).called(1);
      verify(
        () => mockStorage.write(
            key: "refresh_token", value: "google_returning_refresh"),
      ).called(1);
      verify(
        () => mockStorage.write(
          key: "token_time",
          value: any(named: "value"),
        ),
      ).called(1);
    });

    test("refreshToken succeeds after saving returning Google user tokens",
        () async {
      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "google_returning_refresh");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "data": {
              "accessToken": "google_refreshed_access",
              "refreshToken": "google_refreshed_refresh",
              "user": {"id": "google_user_42"},
            },
          }),
          200,
        ),
      );

      // Simulate the returning Google user flow:
      // 1. Save tokens from OAuth callback
      await authApiService.saveTokens(
        accessToken: "google_returning_access",
        refreshToken: "google_returning_refresh",
      );

      // 2. Refresh token to get user data
      final result = await authApiService.refreshToken();

      expect(result.$1, 200);
      expect(result.$2, "Token refreshed successfully");

      verify(
        () => mockStorage.write(key: "user_id", value: "google_user_42"),
      ).called(1);
    });
  });

  group("Google Auth - Existing email user signing in with Google",
      () {
    test("returns 400 if pendingToken is empty", () async {
      final result = await authApiService.verifyGoogleCode(
        pendingToken: "",
        code: "123456",
      );

      expect(result.$1, 400);
      expect(result.$2, "Pending token is required");
    });

    test("returns 400 if code is empty", () async {
      final result = await authApiService.verifyGoogleCode(
        pendingToken: "pending_token_123",
        code: "",
      );

      expect(result.$1, 400);
      expect(result.$2, "Verification code is required");
    });

    test(
        "returns 200 and stores tokens on successful code verification",
        () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/verify-code?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "message": "Authenticated successfully",
            "data": {
              "accessToken": "verified_access_123",
              "refreshToken": "verified_refresh_123",
            },
          }),
          200,
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "verified_refresh_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "data": {
              "accessToken": "verified_access_new",
              "refreshToken": "verified_refresh_new",
              "user": {"id": "existing_user_99"},
            },
          }),
          200,
        ),
      );

      final result = await authApiService.verifyGoogleCode(
        pendingToken: "pending_token_123",
        code: "123456",
      );

      expect(result.$1, 200);
      expect(result.$2, "Authenticated successfully");

      verify(
        () => mockStorage.write(
            key: "access_token", value: "verified_access_123"),
      ).called(1);
      verify(
        () => mockStorage.write(
            key: "refresh_token", value: "verified_refresh_123"),
      ).called(1);
    });

    test("sends correct request body for verify-code", () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/verify-code?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "message": "Authenticated successfully",
            "data": {
              "accessToken": "verified_access_123",
              "refreshToken": "verified_refresh_123",
            },
          }),
          200,
        ),
      );

      when(
        () => mockStorage.write(
          key: any(named: "key"),
          value: any(named: "value"),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockStorage.read(key: "refresh_token"),
      ).thenAnswer((_) async => "verified_refresh_123");

      when(
        () => mockClient.get(
          Uri.parse("https://beatza.me/api/auth/v1/refresh-token"),
          headers: any(named: "headers"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            "data": {
              "accessToken": "verified_access_new",
              "refreshToken": "verified_refresh_new",
            },
          }),
          200,
        ),
      );

      await authApiService.verifyGoogleCode(
        pendingToken: "pending_token_123",
        code: "123456",
      );

      verify(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/verify-code?client=Android"),
          headers: {
            "Content-Type": "application/json",
            "User-Agent": "Android",
          },
          body: jsonEncode({
            "pendingToken": "pending_token_123",
            "code": "123456",
          }),
        ),
      ).called(1);
    });

    test("returns backend error on invalid code", () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/verify-code?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({"message": "Invalid verification code"}),
          400,
        ),
      );

      final result = await authApiService.verifyGoogleCode(
        pendingToken: "pending_token_123",
        code: "000000",
      );

      expect(result.$1, 400);
      expect(result.$2, "Invalid verification code");
    });

    test("returns backend error on expired pending token", () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/verify-code?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenAnswer(
        (_) async => http.Response(
          jsonEncode({"message": "Token expired"}),
          401,
        ),
      );

      final result = await authApiService.verifyGoogleCode(
        pendingToken: "expired_token",
        code: "123456",
      );

      expect(result.$1, 401);
      expect(result.$2, "Token expired");
    });

    test("returns 500 on network error", () async {
      when(
        () => mockClient.post(
          Uri.parse(
              "https://beatza.me/api/auth/v1/google/verify-code?client=Android"),
          headers: any(named: "headers"),
          body: any(named: "body"),
        ),
      ).thenThrow(Exception("connection refused"));

      final result = await authApiService.verifyGoogleCode(
        pendingToken: "pending_token_123",
        code: "123456",
      );

      expect(result.$1, 500);
      expect(result.$2.toString(), contains("Network error"));
    });
  });
}