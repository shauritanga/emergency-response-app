import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class ModernFCMService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
  static const _projectId = 'emergency-response-app-dit';

  static ServiceAccountCredentials? _credentials;
  static http.Client? _client;

  /// Initialize the FCM service with service account credentials
  static Future<void> initialize() async {
    try {
      // Load service account JSON from assets
      final String jsonString = await rootBundle.loadString(
        'assets/emergency-response-app-dit-9c011cf8bcb8.json',
      );
      final Map<String, dynamic> serviceAccountJson = jsonDecode(jsonString);

      // Create service account credentials
      _credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

      // Create authenticated HTTP client
      _client = await clientViaServiceAccount(_credentials!, _scopes);

      debugPrint('✅ Modern FCM Service initialized successfully');
      debugPrint('📱 Project ID: $_projectId');
    } catch (e) {
      debugPrint('❌ Failed to initialize Modern FCM Service: $e');
      rethrow;
    }
  }

  /// Send FCM notification to a single token
  static Future<bool> sendNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      if (_client == null) {
        await initialize();
      }

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final message = {
        "message": {
          "token": token,
          "notification": {"title": title, "body": body},
          "data": data ?? {},
          "android": {
            "priority": "high",
            "notification": {
              "channel_id": "emergency_alerts",
              "priority": "high",
              "default_sound": true,
              "default_vibrate_timings": true,
            },
          },
          "apns": {
            "payload": {
              "aps": {
                "alert": {"title": title, "body": body},
                "sound": "default",
                "badge": 1,
              },
            },
          },
        },
      };

      final response = await _client!.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint(
          '✅ FCM notification sent successfully to token: ${token.substring(0, 10)}...',
        );
        return true;
      } else {
        debugPrint(
          '❌ Failed to send FCM notification: ${response.statusCode} - ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending FCM notification: $e');
      return false;
    }
  }

  /// Send FCM notification to multiple tokens (multicast)
  static Future<Map<String, bool>> sendMulticastNotification({
    required List<String> tokens,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final results = <String, bool>{};

    // FCM v1 API doesn't support true multicast, so we send individually
    // but we can optimize by using the same client
    for (final token in tokens) {
      final success = await sendNotification(
        token: token,
        title: title,
        body: body,
        data: data,
      );
      results[token] = success;
    }

    final successCount = results.values.where((success) => success).length;
    debugPrint(
      '📊 Multicast results: $successCount/${tokens.length} successful',
    );

    return results;
  }

  /// Send emergency notification
  static Future<bool> sendEmergencyNotification({
    required String token,
    required String emergencyType,
    required String description,
    required String emergencyId,
  }) async {
    return await sendNotification(
      token: token,
      title: '$emergencyType Emergency',
      body: description,
      data: {
        'type': 'emergency',
        'emergencyId': emergencyId,
        'emergencyType': emergencyType,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  /// Send chat notification
  static Future<bool> sendChatNotification({
    required String token,
    required String senderName,
    required String message,
    required String conversationId,
  }) async {
    return await sendNotification(
      token: token,
      title: 'New message from $senderName',
      body: message,
      data: {
        'type': 'chat',
        'conversationId': conversationId,
        'senderName': senderName,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  /// Send system notification
  static Future<bool> sendSystemNotification({
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    return await sendNotification(
      token: token,
      title: title,
      body: body,
      data: {
        'type': 'system',
        ...?data,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  /// Test FCM connection
  static Future<bool> testConnection() async {
    try {
      await initialize();
      debugPrint('✅ FCM connection test successful');
      return true;
    } catch (e) {
      debugPrint('❌ FCM connection test failed: $e');
      return false;
    }
  }

  /// Dispose resources
  static void dispose() {
    _client?.close();
    _client = null;
    _credentials = null;
    debugPrint('🧹 Modern FCM Service disposed');
  }
}
