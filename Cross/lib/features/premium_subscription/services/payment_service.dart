import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubscriptionStatusNotifier extends ValueNotifier<bool> {
  SubscriptionStatusNotifier() : super(false);

  Future<void> loadLocalStatus() async {
    final localStatus = await PaymentService._storage.read(key: 'is_pro');
    value = localStatus == 'true';
  }
  Future<void> checkStatusFromApi() async {
    try {
      final token = await PaymentService._getToken();
      if (token == null) return;

      final url = Uri.parse('${PaymentService.baseUrl}/api/payment/v1/subscriptions');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'User-Agent': 'Android',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null && data['data']['status'] == 'active') {
          value = true;
          await PaymentService._storage.write(key: 'is_pro', value: 'true');
        } else {
          value = false;
          await PaymentService._storage.delete(key: 'is_pro');
        }
      }
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
    }
  }

  Future<void> markAsProLocally() async {
    value = true;
    await PaymentService._storage.write(key: 'is_pro', value: 'true');
  }

  Future<void> refresh() async {
    await checkStatusFromApi();
  }

  Future<void> reset() async {
    value = false;
    await PaymentService._storage.delete(key: 'is_pro');
  }
}

class PaymentService {
  static const String baseUrl = "https://beatza.me";
  static const _storage = FlutterSecureStorage();

  static final SubscriptionStatusNotifier subscriptionSuccessNotifier = SubscriptionStatusNotifier();

  static Future<String?> _getToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String> _sendPaymentRequest(String method, String endpoint, {Map<String, dynamic>? body}) async {
    String? token = await _getToken();
    if (token == null) throw Exception('No access token found');

    final url = Uri.parse('$baseUrl$endpoint');

    Future<HttpClientResponse> makeRequest(String currentToken) async {
      final httpClient = HttpClient();
      final request = method == 'POST' ? await httpClient.postUrl(url) : await httpClient.getUrl(url);

      request.headers.set('Authorization', 'Bearer $currentToken', preserveHeaderCase: true);
      request.headers.set('Content-Type', 'application/json', preserveHeaderCase: true);
      request.headers.set('User-Agent', 'Android', preserveHeaderCase: true);

      if (body != null && method == 'POST') {
        request.write(jsonEncode(body));
      }
      return await request.close();
    }

    var response = await makeRequest(token);

    if (response.statusCode == 401) {
      await refreshToken();
      token = await _getToken();
      response = await makeRequest(token!);
    }

    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode == 400 && endpoint.contains('/user')) {
      final errorMsg = jsonDecode(responseBody)['message'] ?? '';
      if (errorMsg.toString().toLowerCase().contains('already has a stripe customer id')) {
        return responseBody;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      final errorMsg = jsonDecode(responseBody)['message'] ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }

  static Future<Map<String, dynamic>> getPlans() async {
    final responseBody = await _sendPaymentRequest('GET', '/api/payment/v1/plans');
    return jsonDecode(responseBody)['data'];
  }

  static Future<void> registerStripeCustomer(String paymentMethodId) async {
    await _sendPaymentRequest('POST', '/api/payment/v1/user', body: {'paymentMethodId': paymentMethodId});
  }

  static Future<void> createSubscription(String priceId) async {
    await _sendPaymentRequest('POST', '/api/payment/v1/subscriptions', body: {'priceId': priceId});
  }

  static Future<void> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (refreshToken == null) {
      throw Exception('Session expired. Please login again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/v1/refresh-token'),
      headers: {
        'Authorization': 'Bearer $refreshToken',
        'Content-Type': 'application/json',
        'User-Agent': 'Android',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newAccessToken = data["data"]?["accessToken"];
      final newRefreshToken = data["data"]?["refreshToken"];

      if (newAccessToken != null && newRefreshToken != null) {
        await _storage.write(key: 'access_token', value: newAccessToken);
        await _storage.write(key: 'refresh_token', value: newRefreshToken);
      }
    } else {
      throw Exception('Failed to refresh authentication token.');
    }
  }
}