
import 'dart:async';


import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';

class QrPollingService {
  final AuthApiService _authApi;
  Timer? _pollingTimer;

  final Duration pollInterval;
  final Duration timeout;

  QrPollingService({
    required AuthApiService authApi,
    this.pollInterval = const Duration(seconds: 5),
    this.timeout = const Duration(minutes: 2),
  }) : _authApi = authApi;

  Future<Map<String, dynamic>> startPolling({
    required String qrData,
    void Function(String status)? onStatusUpdate,
    void Function(Object error)? onError,
  }) {
    final completer = Completer<Map<String, dynamic>>();
    final stopwatch = Stopwatch()..start();

    _pollingTimer = Timer.periodic(pollInterval, (timer) async {
      try {
        
        if (stopwatch.elapsed > timeout) {
          timer.cancel();
          stopwatch.stop();
          completer.completeError(TimeoutException('QR polling timed out'));
          return;
        }

        
        final response = await _authApi.checkQrStatus(qrData);
        final status = response['status'] as String;
        
        

        
        onStatusUpdate?.call(status);

        switch (status) {
          case 'success':
            timer.cancel();
            stopwatch.stop();
            completer.complete(response); 
            break;

          case 'waiting':
            
            break;

          default:
            timer.cancel();
            stopwatch.stop();
            completer.completeError(Exception('Unknown status: $status'));
            break;
        }
      } catch (e) {
        
        onError?.call(e);

        
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('session expired') ||
            errorMessage.contains('bad request') ||
            errorMessage.contains('internal server error')) {
          
          timer.cancel();
          stopwatch.stop();
          completer.completeError(e);
        }
        
      }
    });

    return completer.future;
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  bool get isPolling => _pollingTimer?.isActive ?? false;

  void dispose() {
    stopPolling();
  }
}
