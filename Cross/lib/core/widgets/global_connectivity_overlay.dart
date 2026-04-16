import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cross_team5/core/services/connectivity_service.dart';

class GlobalConnectivityOverlay extends StatefulWidget {
  const GlobalConnectivityOverlay({super.key});

  @override
  State<GlobalConnectivityOverlay> createState() =>
      _GlobalConnectivityOverlayState();
}

class _GlobalConnectivityOverlayState
    extends State<GlobalConnectivityOverlay> {
  StreamSubscription<bool>? _subscription;
  bool _isConnected = true;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _isConnected = ConnectivityService.instance.isConnected;

    _subscription = ConnectivityService.instance.stream.listen((connected) {
      if (!mounted) return;
      setState(() {
        _isConnected = connected;
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
    });

    final hasInternet =
        await ConnectivityService.instance.hasInternetConnection();

    if (!mounted) return;

    setState(() {
      _isConnected = hasInternet;
      _isRetrying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.88),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No Internet Connection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please connect to the internet and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _isRetrying ? null : _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: _isRetrying
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}