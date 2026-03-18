import "dart:convert";

import "package:http/http.dart" as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart' as user_model;
import '../../../core/services/api_services.dart';


import '../../../core/services/logger_service.dart';


class AuthApiService 
{
  final ApiServices _apiServices = ApiServices();
  String? _servicePath; 
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Methods
  AuthApiService() 
  {
    _servicePath = "${_apiServices.baseUrl}/api/auth/v1";
  }
  
  bool _isValidEmail(String email) 
  {
    // Standard email regex pattern
    final regex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
      multiLine: false,
    );
    return regex.hasMatch(email);
  }

  // bool _isValidPass(String password) 
  // {
  //   // Min 8 chars, 1 Upper, 1 Lower, 1 Digit
  //   final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d_]{8,}$');
  //   return regex.hasMatch(password);
  // }

  Future<void> _clearTokens() async 
  {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_time');
  }

  Future<(int , dynamic)> login({required user_model.User user}) async
  {
    // early returns 
    if (!_isValidEmail(user.email)) 
    {
      return (400, "Invalid email format");
    }
    // if (!_isValidPass(user.password)) 
    // {
    //   return (400, "Password must be 8+ chars with upper, lower, and number");
    // }
    
    try 
    {
      final response = await http.post(
        Uri.parse('$_servicePath/login'),
        headers: {'Content-Type': 'application/json', 
        'User-Agent': 'Android'},
        body: jsonEncode({
          "email": user.email,
          "password": user.password
        })
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        final accessToken = data['data']?['accessToken'];
        final refreshToken = data['data']?['refreshToken'];
        LoggerService.logger.i("Access Token: $accessToken \nRefresh Token: $refreshToken");

        if (accessToken != null && refreshToken != null) 
        {
          await _storage.write(key: 'access_token', value: accessToken);
          await _storage.write(key: 'refresh_token', value: refreshToken);
          await _storage.write(key: 'token_time', value: DateTime.now().toString());
          return (200, data['message'] ?? "Login successful");
        } 
        else 
        {
          return (response.statusCode , data['message'] ?? "Login failed: Tokens missing");
        }
      } 
      return (response.statusCode, data['message'] ?? "Login failed");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  Future<(int , dynamic)> signup({required user_model.User user}) async
  {
    // early returns 
    if (!_isValidEmail(user.email)) 
    {
      return (400, "Invalid email format");
    }
    // if (!_isValidPass(user.password)) 
    // {
    //   return (400, "Weak password");
    // }

    try 
    {
      final response = await http.post(
        Uri.parse('$_servicePath/sign-up'),
        headers: {'Content-Type': 'application/json', 
        'User-Agent': 'Android'},
        body: jsonEncode({
          "email": user.email,
          "password": user.password,
          "displayName": user.displayName,
          "dateOfBirth": user.dateOfBirth,
          "gender": user.gender
        })
      );

      final data = jsonDecode(response.body);
      return (response.statusCode, data['message'] ?? "Signup request processed");
    } 
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

  Future<void> logout() async 
  {
    // check user status
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) 
    { // User is not logged in, no need to call the API
      LoggerService.logger.i("No user is currently logged in");
      return;
    }
    LoggerService.logger.i("Attempting to log out user with access token: $accessToken");

    try 
    {
      final response = await http.get(
        Uri.parse('$_servicePath/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'User-Agent': 'Android'
        }
      );

      switch (response.statusCode) 
      {
        case 200:
          LoggerService.logger.i("Logout successful");
          break;
        case 401:
          LoggerService.logger.i("Unauthorized: Invalid or expired token");
          break;
        default:
          throw Exception("Failed to logout: ${response.statusCode}");
      }
    }
    catch (e) 
    {
      LoggerService.logger.e("Error occurred while logging out: $e");
    }
    finally 
    {
      await _clearTokens();
    }
  }

  Future<(int , dynamic)> refreshToken() async 
  {
    final refreshToken = await _storage.read(key: 'refresh_token');
    LoggerService.logger.i("Refresh Token: $refreshToken");

    if (refreshToken == null) 
    {
      return (401, "No refresh token found");
    }

    try
    {
      final response = await http.get(
        Uri.parse('$_servicePath/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
          'User-Agent': 'Android'
        }
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) 
      {
        final newAccessToken = data['data']?['accessToken'];
        final newRefreshToken = data['data']?['refreshToken'];
        LoggerService.logger.i("Access Token: $newAccessToken\nRefresh Token: $newRefreshToken");

        if (newAccessToken != null && newRefreshToken != null) 
        {
          await _storage.write(key: 'access_token', value: newAccessToken);
          await _storage.write(key: 'refresh_token', value: newRefreshToken);
          await _storage.write(key: 'token_time', value: DateTime.now().toString());
          return (200, "Token refreshed successfully");
        } 
        else 
        {
          return (response.statusCode , data['message'] ?? "Token refresh failed: Tokens missing");
        }
      } 
      return (response.statusCode, data['message'] ?? "Token refresh failed");
    }
    catch (err) 
    {
      return (500, "Network error: $err");
    }
  }

}