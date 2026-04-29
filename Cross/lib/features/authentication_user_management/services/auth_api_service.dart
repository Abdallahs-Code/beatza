// Dart imports
import "dart:convert";
import "dart:io";

import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:http/http.dart" as http;
import "package:cross_team5/core/services/api_services.dart";
import "package:cross_team5/features/authentication_user_management/models/user.dart"
as user_model;
import 'package:cross_team5/features/playback_streaming_engine/services/playback_streaming_engine_service.dart';
import 'package:cross_team5/features/activity/controllers/activity_notifications_controller.dart';
import 'package:cross_team5/features/messaging_track_sharing/services/messaging_notification_service.dart';
import 'package:cross_team5/features/premium_subscription/services/payment_service.dart';

class AuthApiService {
  final ApiServices _apiServices;
  final http.Client _client;
  final FlutterSecureStorage _storage;
  late final String _servicePath;

  AuthApiService({
    ApiServices? apiServices,
    http.Client? client,
    FlutterSecureStorage? storage,
  }) : _apiServices = apiServices ?? ApiServices(),
        _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage() {
    _servicePath = "${_apiServices.baseUrl}/api/auth/v1";
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
      caseSensitive: false,
      multiLine: false,
    );
    return regex.hasMatch(email);
  }

  Future<void> _clearTokens() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final accessToken = await _storage.read(key: 'access_token');
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (accessToken != null && fcmToken != null) {
          await _client.delete(
            Uri.parse('${_apiServices.baseUrl}/api/notifications/v1/fcm-token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
              'User-Agent': 'Android',
            },
            body: jsonEncode({'token': fcmToken}),
          ).timeout(const Duration(seconds: 5));
        }
      } catch (_) {}
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_time');
    await _storage.delete(key: 'user_id');
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: "access_token", value: accessToken);
    await _storage.write(key: "refresh_token", value: refreshToken);
    await _storage.write(
      key: "token_time",
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: "access_token");
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: "refresh_token");
  }

  Future<(int, dynamic)> login({required user_model.User user}) async {
    if (!_isValidEmail(user.email)) {
      return (400, "Invalid email format");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/login"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({"email": user.email, "password": user.password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final accessToken = data['data']?['accessToken'];
        final refreshToken = data['data']?['refreshToken'];
        final userId = data['data']?['user']?['id']?.toString();

        if (accessToken != null && refreshToken != null) {
          await saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
          if (userId != null && userId.trim().isNotEmpty) {
            await _storage.write(key: 'user_id', value: userId);
          }

          await ActivityNotificationsController.shared.initialize();
          await MessagingNotificationService.shared.initialize();
          await PaymentService.subscriptionSuccessNotifier.refresh();

          return (200, data["message"] ?? "Login successful");
        } else {
          return (
          response.statusCode,
          data["message"] ?? "Login failed: Tokens missing",
          );
        }
      }

      return (response.statusCode, data["message"] ?? "Login failed");
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> signup({required user_model.User user}) async {
    if (!_isValidEmail(user.email)) {
      return (400, "Invalid email format");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/sign-up"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({
          "email": user.email,
          "password": user.password,
          "displayName": user.displayName,
          "dateOfBirth": user.dateOfBirth,
          "gender": user.gender,
        }),
      );

      final data = jsonDecode(response.body);
      return (
      response.statusCode,
      data["message"] ?? "Signup request processed",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<void> logout() async {
    final accessToken = await _storage.read(key: "access_token");

    if (accessToken == null) {
      return;
    }

    try {
      final response = await _client.get(
        Uri.parse("$_servicePath/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "User-Agent": "Android",
        },
      );

      switch (response.statusCode) {
        case 200:
          break;
        case 401:
          break;
        default:
          throw Exception("Failed to logout: ${response.statusCode}");
      }
    } catch (_) {
    } finally {
      ActivityNotificationsController.shared.resetForLogout();
      MessagingNotificationService.shared.reset();
      await _clearTokens();
      await PlaybackStreamingEngineService.shared.clearSessionState();
      PaymentService.subscriptionSuccessNotifier.reset();
    }
  }

  Future<(int, dynamic)> refreshToken() async {
    final refreshToken = await _storage.read(key: "refresh_token");

    if (refreshToken == null) {
      return (401, "No refresh token found");
    }

    try {
      final response = await _client.get(
        Uri.parse("$_servicePath/refresh-token"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $refreshToken",
          "User-Agent": "Android",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final newAccessToken = data["data"]?["accessToken"];
        final newRefreshToken = data["data"]?["refreshToken"];
        final userId = data['data']?['user']?['id']?.toString();

        if (newAccessToken != null && newRefreshToken != null) {
          await saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
          if (userId != null && userId.trim().isNotEmpty) {
            await _storage.write(key: 'user_id', value: userId);
          }
          await ActivityNotificationsController.shared.initialize();
          await MessagingNotificationService.shared.initialize();
          return (200, "Token refreshed successfully");
        } else {
          return (
          response.statusCode,
          data["message"] ?? "Token refresh failed: Tokens missing",
          );
        }
      }

      return (response.statusCode, data["message"] ?? "Token refresh failed");
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<String?> getStoredAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<String?> getStoredUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String> getQrCodeToken() async {
    try {
      final response = await _client.get(
        Uri.parse("$_servicePath/cross/desktop"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["pendingToken"]?["qrCode"] ?? "";
      } else {
        throw Exception("Failed to get QR code token: ${response.statusCode}");
      }
    } catch (err) {
      throw Exception("Network error: $err");
    }
  }

  Future<bool> approveQrCode(String qrData) async {
    final accessToken = await _storage.read(key: "access_token");
    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/cross/mobile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "User-Agent": "Android",
        },
        body: jsonEncode({"qrCode": qrData}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> checkQrStatus(String qrData) async {
    try {
      final response = await _client
          .post(
        Uri.parse('$_servicePath/cross/desktop/poll'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
        body: jsonEncode({'qrCode': qrData}),
      )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      switch (response.statusCode) {
        case 200:
          if (data.containsKey('data')) {
            return {
              'status': 'success',
              'message': data['message'] ?? 'Authenticated successfully',
              'data': data['data'],
            };
          } else {
            return {
              'status': 'waiting',
              'message':
              data['message'] ??
                  'QR code not scanned, waiting for approval.',
            };
          }

        case 400:
          throw Exception(data['message'] ?? 'Bad request');

        case 401:
          throw Exception(data['message'] ?? 'Session expired');

        case 500:
          throw Exception(data['message'] ?? 'Internal server error');

        default:
          throw Exception('Failed to check QR status: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkUserExists({required String email}) async {
    if (!_isValidEmail(email)) {
      throw Exception("Invalid email format");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/find-email"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({"email": email.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data["data"]?["exists"] == true;
      }

      throw Exception(data["message"] ?? "Failed to check email");
    } catch (err) {
      throw Exception("Network error: $err");
    }
  }

  Future<(int, dynamic)> forgotPassword({required String email}) async {
    if (!_isValidEmail(email)) {
      return (400, "Invalid email format");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/forgot-password"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({"email": email.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (
        200,
        data["message"] ?? "Password reset email sent successfully",
        );
      }

      return (
      response.statusCode,
      data["message"] ?? "Failed to send password reset email",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> resendVerificationEmail({
    required String email,
  }) async {
    if (!_isValidEmail(email)) {
      return (400, "Invalid email format");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/resend-verification-email"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({"email": email.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (
        200,
        data["message"] ?? "Email existence check completed successfully",
        );
      }

      return (
      response.statusCode,
      data["message"] ?? "Failed to resend verification email",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> verifyGoogleCode({
    required String pendingToken,
    required String code,
  }) async {
    if (pendingToken.trim().isEmpty) {
      return (400, "Pending token is required");
    }

    if (code.trim().isEmpty) {
      return (400, "Verification code is required");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/google/verify-code?client=Android"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({"pendingToken": pendingToken, "code": code.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final responseData = data["data"];
        final accessToken = responseData?["accessToken"];
        final refreshTokenValue = responseData?["refreshToken"];

        if (accessToken != null && refreshTokenValue != null) {
          await saveTokens(
            accessToken: accessToken,
            refreshToken: refreshTokenValue,
          );

          await ActivityNotificationsController.shared.initialize();
          await MessagingNotificationService.shared.initialize();

          await refreshToken();
          await PaymentService.subscriptionSuccessNotifier.refresh();
        }

        return (200, data["message"] ?? "Authenticated successfully");
      }

      return (
      response.statusCode,
      data["message"] ?? "Google code verification failed",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> completeGoogleSignup({
    required String incompleteToken,
    required String dateOfBirth,
    required String gender,
    String? displayName,
  }) async {
    if (incompleteToken.trim().isEmpty) {
      return (400, "Incomplete token is required");
    }

    if (dateOfBirth.trim().isEmpty) {
      return (400, "Date of birth is required");
    }

    if (gender.trim().isEmpty) {
      return (400, "Gender is required");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/google/complete?client=Android"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({
          "incompleteToken": incompleteToken,
          "dateOfBirth": dateOfBirth,
          "gender": gender,
          if (displayName != null && displayName.trim().isNotEmpty)
            "displayName": displayName.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final responseData = data["data"];
        final accessToken = responseData?["accessToken"];
        final refreshTokenValue = responseData?["refreshToken"];

        if (accessToken != null && refreshTokenValue != null) {
          await saveTokens(
            accessToken: accessToken,
            refreshToken: refreshTokenValue,
          );
          await ActivityNotificationsController.shared.initialize();
          await MessagingNotificationService.shared.initialize();

          await refreshToken();
          await PaymentService.subscriptionSuccessNotifier.refresh();
          return (200, responseData ?? "Authenticated successfully");
        }

        return (200, data["message"] ?? "Authenticated successfully");
      }

      return (
      response.statusCode,
      data["message"] ?? "Google signup completion failed",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> deleteAccount() async {
    final accessToken = await _storage.read(key: "access_token");

    if (accessToken == null || accessToken.trim().isEmpty) {
      return (401, "No access token found");
    }

    try {
      final response = await _client.delete(
        Uri.parse("$_servicePath/delete-account"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "User-Agent": "Android",
        },
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        await _clearTokens();
        await PlaybackStreamingEngineService.shared.clearSessionState();
        PaymentService.subscriptionSuccessNotifier.reset();
        return (
        response.statusCode,
        data?["message"] ?? "Account deleted successfully",
        );
      }

      return (
      response.statusCode,
      data?["message"] ?? "Failed to delete account",
      );
    } catch (err) {
      return (500, "Network error: $err");
    }
  }

  Future<(int, dynamic)> resendGoogleVerificationCode({
    required String pendingToken,
  }) async {
    if (pendingToken.trim().isEmpty) {
      return (400, "Pending token is required");
    }

    try {
      final response = await _client.post(
        Uri.parse("$_servicePath/google/resend-code"),
        headers: {"Content-Type": "application/json", "User-Agent": "Android"},
        body: jsonEncode({"pendingToken": pendingToken.trim()}),
      );

      dynamic message = "Failed to resend Google verification code";

      if (response.body.trim().isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          message = data["message"] ?? message;
        } catch (_) {
          message = response.body;
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return (
        response.statusCode,
        message == "Failed to resend Google verification code"
            ? "Verification code resent"
            : message,
        );
      }

      return (response.statusCode, message);
    } catch (err) {
      return (500, "Network error: $err");
    }
  }
}