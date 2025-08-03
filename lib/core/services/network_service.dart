import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class NetworkService {
  Future<bool> get isConnected;
  Stream<bool> get connectivityStream;
  Future<bool> hasInternetConnection();
}

class NetworkServiceImpl implements NetworkService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _connectivityController;

  NetworkServiceImpl() {
    _initializeConnectivityStream();
  }

  void _initializeConnectivityStream() {
    _connectivityController = StreamController<bool>.broadcast();

    _connectivity.onConnectivityChanged.listen((result) {
      _checkConnectivity();
    });

    // Initial connectivity check
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final bool connected = await hasInternetConnection();
    _connectivityController?.add(connected);
  }

  @override
  Future<bool> get isConnected async {
    return await hasInternetConnection();
  }

  @override
  Stream<bool> get connectivityStream {
    return _connectivityController?.stream ?? Stream.value(false);
  }

  @override
  Future<bool> hasInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult =
          await _connectivity.checkConnectivity();

      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }

      // Additional check: try to reach a reliable server
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivityController?.close();
  }
}
