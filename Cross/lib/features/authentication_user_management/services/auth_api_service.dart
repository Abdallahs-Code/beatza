import "dart:convert";

import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:http/http.dart" as http;

import "../../../core/services/api_services.dart";
import "../models/user.dart" as user_model;

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
    await _storage.delete(key: "access_token");
    await _storage.delete(key: "refresh_token");
    await _storage.delete(key: "token_time");
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
        final accessToken = data["data"]?["accessToken"];
        final refreshToken = data["data"]?["refreshToken"];

        if (accessToken != null && refreshToken != null) {
          await saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
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
      await _clearTokens();
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

        if (newAccessToken != null && newRefreshToken != null) {
          await saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
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
    try 
    {
      final response = await _client.post(
        Uri.parse("$_servicePath/cross/mobile"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
          "User-Agent": "Android",
        },
        body: jsonEncode({"qrCode": qrData}),
      );

      if (response.statusCode == 200)
      {
        return true;
      }
      return false;
    }
    catch(e)
    {
      print('Approve Qr code Func: $e');
      return false;
    }
    
  }

  Future<Map<String, dynamic>> checkQrStatus(String qrData) async {
    try {
      final response = await _client.post(
        Uri.parse('$_servicePath/cross/desktop/poll'),
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
        body: jsonEncode({'qrCode': qrData}),
      ).timeout(const Duration(seconds: 10));

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
              'message': data['message'] ?? 'QR code not scanned, waiting for approval.',
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
      print('checkQrStatus error: $e');
      rethrow;
    }
  }
}