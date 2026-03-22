// Dart imports
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Package imports
import 'package:cross_team5/core/services/logger_service.dart';
import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Place the Qr Code in the center of the box')),
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
    if (value == null || value.isEmpty) 
    {
      return;
    }

    await controller.stop();

    try {
      final bool success = await AuthApiService().approveQrCode(value);

      if (success) 
      {
        if (mounted)
        { 
          Navigator.pop(context); // return to the last screen (library)
        }
      } 
      else 
      {
        await controller.start(); // Resume camera for retry
      }
    } catch (e) {
      LoggerService.logger.i('Scan error: $e');
      await controller.start(); // Resume camera
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}