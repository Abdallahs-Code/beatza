import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SubscriptionState {
  final bool isPro;
  final String? currentPriceId;
  SubscriptionState({required this.isPro, this.currentPriceId});
}

class SubscriptionStatusNotifier extends ValueNotifier<SubscriptionState> {
  SubscriptionStatusNotifier() : super(SubscriptionState(isPro: false, currentPriceId: null));

  bool get isPro => value.isPro;
  String? get currentPriceId => value.currentPriceId;

  bool _isOptimisticWait = false;
  Timer? _pollingTimer;

  Future<void> loadLocalStatus() async {
    await checkStatusFromApi();
  }

  Future<void> checkStatusFromApi() async {
    try {
      final token = await PaymentService._getToken();
      if (token == null) {
        if (!_isOptimisticWait) reset();
        return;
      }

      final responseBody = await PaymentService._sendPaymentRequest('GET', '/api/payment/v1/subscriptions');
      final data = jsonDecode(responseBody);

      if (data['success'] == true && data['data'] != null) {
        final subData = data['data'];

        final actualSub = (subData is List && subData.isNotEmpty)
            ? subData[0]
            : (subData['subscription'] ?? subData);

        final status = actualSub['status']?.toString().toLowerCase() ?? '';

        if (status == 'active' || status == 'trialing' || status == 'incomplete' || status == 'past_due') {

          String? priceId;

          if (actualSub['priceId'] != null && actualSub['priceId'].toString().isNotEmpty) {
            priceId = actualSub['priceId'].toString();
          } else if (actualSub['plan'] != null) {
            if (actualSub['plan'] is String) {
              priceId = actualSub['plan'];
            } else if (actualSub['plan'] is Map) {
              priceId = actualSub['plan']['id']?.toString();
            }
          }

          priceId ??= actualSub['items']?['data']?[0]?['price']?['id']?.toString();

          _isOptimisticWait = false;
          _pollingTimer?.cancel();
          value = SubscriptionState(isPro: true, currentPriceId: priceId);
          return;
        }
      }

      if (!_isOptimisticWait) {
        reset();
      }
    } catch (e) {
      if (!_isOptimisticWait) {
        reset();
      }
    }
  }

  void setOptimisticPro(String priceId) {
    _isOptimisticWait = true;
    value = SubscriptionState(isPro: true, currentPriceId: priceId);

    int attempts = 0;
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      await checkStatusFromApi();
      try { await PaymentService.refreshToken(); } catch(_) {}

      if (!_isOptimisticWait || attempts >= 5) {
        _isOptimisticWait = false;
        timer.cancel();
      }
    });
  }

  Future<void> refresh() async {
    await checkStatusFromApi();
  }

  void reset() {
    _isOptimisticWait = false;
    _pollingTimer?.cancel();
    value = SubscriptionState(isPro: false, currentPriceId: null);

    PaymentService._storage.delete(key: 'is_pro_local');
    PaymentService._storage.delete(key: 'price_id_local');
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
      final request = method == 'POST' ? await httpClient.postUrl(url)
          : method == 'PATCH' ? await httpClient.patchUrl(url)
          : method == 'DELETE' ? await httpClient.deleteUrl(url)
          : await httpClient.getUrl(url);

      request.headers.set('Authorization', 'Bearer $currentToken', preserveHeaderCase: true);
      request.headers.set('Content-Type', 'application/json', preserveHeaderCase: true);
      request.headers.set('User-Agent', 'Android', preserveHeaderCase: true);

      if (body != null && (method == 'POST' || method == 'PATCH' || method == 'DELETE')) {
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      var errorMsg = 'Unknown error';
      try {
        errorMsg = jsonDecode(responseBody)['message'] ?? errorMsg;
      } catch (_) {}
      throw Exception(errorMsg);
    }
  }

  static Future<Map<String, dynamic>> getPlans() async {
    final responseBody = await _sendPaymentRequest('GET', '/api/payment/v1/plans');
    return jsonDecode(responseBody)['data'];
  }

  static Future<void> registerStripeCustomer(String paymentMethodId) async {
    try {
      await _sendPaymentRequest('POST', '/api/payment/v1/user', body: {'paymentMethodId': paymentMethodId});
    } catch (e) {
      if (!e.toString().toLowerCase().contains('already has a stripe customer id')) {
        rethrow;
      }
    }
  }

  static Future<void> createSubscription(String priceId) async {
    try {
      await _sendPaymentRequest('POST', '/api/payment/v1/subscriptions', body: {'priceId': priceId});
    } catch (e) {
      if (e.toString().toLowerCase().contains('already has an active subscription')) {
        await updateSubscription(priceId);
      } else {
        rethrow;
      }
    }
  }

  static Future<void> updateSubscription(String priceId) async {
    await _sendPaymentRequest('PATCH', '/api/payment/v1/subscriptions', body: {'priceId': priceId});
  }

  static Future<void> cancelSubscription() async {
    await _sendPaymentRequest('DELETE', '/api/payment/v1/subscriptions', body: {'cancelAtPeriodEnd': false});
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

  static Future<Map<String, dynamic>?> getCurrentSubscriptionDetails() async {
    try {
      final responseBody = await _sendPaymentRequest('GET', '/api/payment/v1/subscriptions');
      final jsonResponse = jsonDecode(responseBody);

      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        return jsonResponse['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching subscription details: $e');
    }
    return null;
  }
}