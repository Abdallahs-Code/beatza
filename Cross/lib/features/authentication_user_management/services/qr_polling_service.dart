import 'dart:async';
import '../services/auth_api_service.dart';

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
        // Check timeout
        if (stopwatch.elapsed > timeout) {
          timer.cancel();
          stopwatch.stop();
          completer.completeError(TimeoutException('QR polling timed out'));
          return;
        }

        // Call the auth service to check status
        final response = await _authApi.checkQrStatus(qrData);
        final status = response['status'] as String;
        final message = response['message'] as String;
        
        // Notify UI of status change
        onStatusUpdate?.call(status);

        switch (status) {
          case 'success':
            timer.cancel();
            stopwatch.stop();
            completer.complete(response); // Contains user data
            break;
          
          case 'waiting':
            // keep polling
            break;
          
          default:
            timer.cancel();
            stopwatch.stop();
            completer.completeError(Exception('Unknown status: $status'));
            break;
        }
      } catch (e) {
        // Network error or HTTP error (400, 401, 500)
        onError?.call(e);
        
        // Check if it's a fatal error (not just network glitch)
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('session expired') || 
            errorMessage.contains('bad request') ||
            errorMessage.contains('internal server error')) {
          // Fatal error - stop polling
          timer.cancel();
          stopwatch.stop();
          completer.completeError(e);
        }
        // Otherwise, continue polling on transient network errors
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