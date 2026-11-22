
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


import 'package:cross_team5/features/authentication_user_management/services/auth_api_service.dart';
import 'package:provider/provider.dart';
import 'package:cross_team5/core/services/theme_service.dart';
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
  String _status = 'idle'; 

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeService>();
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
          
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              
              if (_isProcessing) return;

              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScan(barcode.rawValue);
                  break; 
                }
              }
            },
          ),

          
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

          
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: AppColors.pureBlack.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      
                      if (_status == 'approving')
                        CircularProgressIndicator(color: AppColors.whiteSmoke)
                      else if (_status == 'success')
                        Icon(
                          Icons.check_circle,
                          color: AppColors.successGreen,
                          size: 80,
                        )
                      else if (_status == 'error')
                        Icon(
                          Icons.error_outline,
                          color: AppColors.anger,
                          size: 80,
                        ),

                      const SizedBox(height: 20),

                      
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

                      
                      if (_status == 'success') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Return to desktop to continue',
                          style: TextStyle(color: AppColors.white70),
                        ),
                      ],

                      
                      if (_status == 'error') ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _resetScanner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.whiteSmoke,
                            foregroundColor: AppColors.pureBlack,
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

  
  Future<void> _handleScan(String? qrCode) async {
    if (qrCode == null || qrCode.isEmpty || _isProcessing) return;

    
    await controller.stop();

    setState(() {
      _isProcessing = true;
      _status = 'approving';
    });

    try {
      final authApi = AuthApiService();

      
      final bool success = await authApi.approveQrCode(qrCode);

      if (success && mounted) {
        setState(() => _status = 'success');

        
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Desktop login approved! ✓'),
              backgroundColor: AppColors.successGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted) {
        setState(() => _status = 'error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to approve. Please try again.'),
            backgroundColor: AppColors.anger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: $e'),
            backgroundColor: AppColors.anger,
          ),
        );
      }
    }
  }

  
  Future<void> _resetScanner() async {
    setState(() {
      _isProcessing = false;
      _status = 'idle';
    });
    await controller.start();
  }

  @override
  void dispose() {
    controller.dispose(); 
    super.dispose();
  }
}
