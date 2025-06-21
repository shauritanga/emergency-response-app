import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utility class for network connectivity checks and handling
class NetworkUtils {
  static const String _testHost = 'google.com';
  static const int _testPort = 443;
  static const Duration _timeout = Duration(seconds: 5);

  /// Checks if the device has internet connectivity
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup(_testHost).timeout(_timeout);

      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    }
  }

  /// Checks connectivity by attempting to connect to a specific host
  static Future<bool> canConnectToHost(String host, int port) async {
    try {
      final socket = await Socket.connect(host, port, timeout: _timeout);
      socket.destroy();
      return true;
    } catch (e) {
      debugPrint('Failed to connect to $host:$port - $e');
      return false;
    }
  }

  /// Performs a more comprehensive connectivity check
  static Future<ConnectivityResult> checkConnectivity() async {
    try {
      // First, try a quick DNS lookup
      final dnsResult = await InternetAddress.lookup(
        _testHost,
      ).timeout(const Duration(seconds: 3));

      if (dnsResult.isEmpty) {
        return ConnectivityResult.none;
      }

      // Then try to establish a connection
      final canConnect = await canConnectToHost(_testHost, _testPort);

      if (canConnect) {
        return ConnectivityResult.connected;
      } else {
        return ConnectivityResult.limited;
      }
    } catch (e) {
      debugPrint('Connectivity check error: $e');

      // Analyze the error to provide more specific feedback
      if (e is SocketException) {
        if (e.osError?.errorCode == 7) {
          return ConnectivityResult.none; // No address associated with hostname
        } else if (e.osError?.errorCode == 101) {
          return ConnectivityResult.none; // Network is unreachable
        }
      } else if (e is TimeoutException) {
        return ConnectivityResult.limited; // Slow or limited connection
      }

      return ConnectivityResult.none;
    }
  }

  /// Retries a network operation with exponential backoff
  static Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (attempt >= maxRetries) {
          rethrow; // Re-throw the last error if all retries failed
        }

        debugPrint('Operation failed (attempt $attempt/$maxRetries): $e');
        debugPrint('Retrying in ${delay.inSeconds} seconds...');

        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Executes an operation with network connectivity check
  static Future<T> executeWithConnectivityCheck<T>(
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    final hasConnection = await hasInternetConnection();

    if (!hasConnection) {
      throw NetworkException(
        errorMessage ??
            'No internet connection. Please check your network and try again.',
      );
    }

    try {
      return await operation();
    } catch (e) {
      // If the operation fails, check if it's a network-related error
      if (e is SocketException ||
          e.toString().toLowerCase().contains('network') ||
          e.toString().toLowerCase().contains('connection')) {
        throw NetworkException(
          'Network error occurred. Please check your connection and try again.',
        );
      }
      rethrow;
    }
  }

  /// Gets a user-friendly network error message
  static String getNetworkErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return error.message;
    }

    if (error is SocketException) {
      switch (error.osError?.errorCode) {
        case 7:
          return 'Unable to connect to server. Please check your internet connection.';
        case 101:
          return 'Network is unreachable. Please check your connection.';
        case 111:
          return 'Connection refused. The service may be temporarily unavailable.';
        case 113:
          return 'No route to host. Please check your network settings.';
        default:
          return 'Network connection failed. Please try again.';
      }
    }

    if (error is TimeoutException) {
      return 'Connection timed out. Please check your internet connection and try again.';
    }

    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error occurred. Please check your connection and try again.';
    }

    return 'Connection failed. Please try again.';
  }
}

/// Enum representing different connectivity states
enum ConnectivityResult {
  connected, // Full internet connectivity
  limited, // Limited connectivity (can resolve DNS but can't connect)
  none, // No connectivity
}

/// Custom exception for network-related errors
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
