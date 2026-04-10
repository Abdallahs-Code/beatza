// Dart imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Package imports
import 'package:cross_team5/core/services/logger_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/qr_polling_service.dart';
import 'package:cross_team5/features/home/home.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  QrPollingService? _pollingService;
  bool _isPolling = false;
  String _pollingStatus = 'waiting';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place the Qr Code in the center of the box'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              // Handle scan logic
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                _handleScan(barcode.rawValue);
              }
            },
          ),
          // Inside Stack children[], after the MobileScanner:
          if (_isPolling)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_pollingStatus == 'waiting')
                        const CircularProgressIndicator(color: Colors.white)
                      else if (_pollingStatus == 'success')
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 60,
                        )
                      else if (_pollingStatus == 'error')
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        )
                      else if (_pollingStatus == 'timeout')
                        const Icon(
                          Icons.timer_off,
                          color: Colors.orange,
                          size: 60,
                        ),

                      const SizedBox(height: 20),
                      Text(
                        _getStatusMessage(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      if (_pollingStatus == 'waiting') ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Confirm login on your desktop',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],

                      if (_pollingStatus == 'error' ||
                          _pollingStatus == 'timeout') ...[
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _resetScanner,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          // Overlay UI
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScan(String? value) async {
    if (value == null || value.isEmpty || _isPolling) return;

    // Stop camera to save resources
    await controller.stop();

    setState(() {
      _isPolling = true;
      _pollingStatus = 'waiting';
    });

    try {
      final authApi = AuthApiService();

      _pollingService = QrPollingService(
        authApi: authApi,
        pollInterval: const Duration(seconds: 5),
        timeout: const Duration(minutes: 2),
      );

      // Start polling
      final result = await _pollingService!.startPolling(
        qrData: value,
        onStatusUpdate: (status) {
          if (mounted) {
            setState(() => _pollingStatus = status);
          }
        },
        onError: (error) {
          LoggerService.logger.e('Polling error: $error');
          if (mounted) {
            setState(() => _pollingStatus = 'error');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Connection error: $error')));
          }
        },
      );

      // SUCCESS: Handle login
      if (mounted && result['status'] == 'success') {
        await _handleLoginSuccess(result);
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _pollingStatus = 'timeout');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please scan a new QR code.'),
          ),
        );
      }
    } catch (e) {
      LoggerService.logger.e('Scan failed: $e');
      if (mounted) {
        setState(() => _pollingStatus = 'error');
      }
    } finally {
      // Only restart camera if we're NOT done (success/navigation happened)
      if (_isPolling && mounted && _pollingStatus != 'success') {
        await controller.start();
      }
    }
  }

  /// Handle successful authentication
  Future<void> _handleLoginSuccess(Map<String, dynamic> userData) async {
    // Save tokens securely
    final AuthApiService authApiService = AuthApiService();
    await authApiService.saveTokens(
      accessToken: userData['accessToken'],
      refreshToken: userData['refreshToken'],
    );
    await authApiService.refreshToken(); // for user ID storing

    // Navigate to home and clear stack
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        HomeRoutes.home, // Your home route constant
        (route) => false,
        arguments: {'loginMethod': 'qr'},
      );
    }
  }

  @override
  void dispose() {
    _pollingService?.dispose();
    controller.dispose();
    super.dispose();
  }

  String _getStatusMessage() {
    switch (_pollingStatus) {
      case 'waiting':
        return 'Waiting for confirmation...';
      case 'success':
        return 'Login successful!';
      case 'error':
        return 'Connection error';
      case 'timeout':
        return 'Session expired';
      default:
        return 'Verifying...';
    }
  }

  void _resetScanner() async {
    _pollingService?.stopPolling();
    setState(() {
      _isPolling = false;
      _pollingStatus = 'waiting';
    });
    await controller.start();
  }
}