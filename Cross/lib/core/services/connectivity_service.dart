import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final Connectivity _connectivity = Connectivity();

  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();

  Stream<bool> get stream => _controller.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<void> initialize() async {
    final initial = await hasInternetConnection();
    _update(initial);

    _subscription = _connectivity.onConnectivityChanged.listen((_) async {
      final current = await hasInternetConnection();
      _update(current);
    });
  }

  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (results.contains(ConnectivityResult.none)) {
        return false;
      }

      final lookup = await InternetAddress.lookup('google.com');
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _update(bool value) {
    if (_isConnected == value) return;
    _isConnected = value;
    _controller.add(value);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}