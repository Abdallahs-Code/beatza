// Dart imports
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Package imports
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:cross_team5/core/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  bool _isProcessing = false;
  String _status = 'idle'; // idle, approving, success, error

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              // Only handle first valid scan
              if (_isProcessing) return;

              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue);
                  break; // Handle only first code
                }
              }
            },
          ),

          // Scanning frame overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.whiteSmoke, width: 4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          // Processing status overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Status icon
                      if (_status == 'approving')
                        CircularProgressIndicator(color: AppColors.whiteSmoke)
                      else if (_status == 'success')
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 80,
                        )
                      else if (_status == 'error')
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 80,
                        ),

                      const SizedBox(height: 20),

                      // Status message
                      Text(
                        _status == 'approving'
                            ? 'Approving login...'
                            : _status == 'success'
                            ? '✓ Login approved!'
                            : 'Approval failed',
                        style: TextStyle(
                          color: AppColors.whiteSmoke,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Subtext for success
                      if (_status == 'success') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Return to desktop to continue',
                          style: TextStyle(color: AppColors.white70),
                        ),
                      ],

                      // Retry button for error
                      if (_status == 'error') ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _resetScanner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whiteSmoke,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Handle QR scan: Mobile just APPROVES, doesn't poll or save tokens
  Future<void> _handleScan(String? qrCode) async {
    if (qrCode == null || qrCode.isEmpty || _isProcessing) return;

    // Stop camera to save resources
    await controller.stop();

    setState(() {
      _isProcessing = true;
      _status = 'approving';
    });

    try {
      final authApi = AuthApiService();

      // Mobile calls approve endpoint only - no polling
      final bool success = await authApi.approveQrCode(qrCode);

      if (success && mounted) {
        setState(() => _status = 'success');

        // Show success briefly, then return
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); // Return to Library screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Desktop login approved! ✓'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        setState(() => _status = 'error');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Reset scanner to allow re-scanning after error
  Future<void> _resetScanner() async {
    setState(() {
      _isProcessing = false;
      _status = 'idle';
    });
    await controller.start();
  }

  @override
  void dispose() {
    controller.dispose(); // Clean up camera
    super.dispose();
  }
}
