import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static bool _initialized = false;
  static String? _fcmToken;

  /// Initialize push notification service
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission for notifications
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission for notifications');
      } else {
        debugPrint(
          'User declined or has not accepted permission for notifications',
        );
        return;
      }

      // Note: Local notifications can be added later if needed

      // Get FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token refreshed: $token');
        // TODO: Update token in user profile
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

      // Handle app launch from terminated state
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleBackgroundMessageTap(initialMessage);
      }

      _initialized = true;
      debugPrint('Push notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  /// Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // For now, just log the message. In a full implementation,
    // you would show a local notification or update the UI
  }

  /// Handle background message tap
  static Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('Background message tapped: ${message.messageId}');

    // Navigate to appropriate screen based on message data
    final data = message.data;
    final type = data['type'];

    switch (type) {
      case 'chat_message':
        final conversationId = data['conversationId'];
        if (conversationId != null) {
          // TODO: Navigate to chat screen
          debugPrint('Navigate to chat: $conversationId');
        }
        break;
      case 'emergency_alert':
        final emergencyId = data['emergencyId'];
        if (emergencyId != null) {
          // TODO: Navigate to emergency details
          debugPrint('Navigate to emergency: $emergencyId');
        }
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  /// Send chat notification to participants
  static Future<void> sendChatNotification({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    required List<String> participantIds,
    bool isEmergency = false,
  }) async {
    try {
      // TODO: Implement server-side notification sending
      // This would typically be done through your backend service
      // For now, we'll just log the notification
      debugPrint('Sending chat notification:');
      debugPrint('  Conversation: $conversationId');
      debugPrint('  Sender: $senderName');
      debugPrint('  Content: $content');
      debugPrint('  Participants: ${participantIds.length}');
      debugPrint('  Emergency: $isEmergency');

      // In a real implementation, you would:
      // 1. Get FCM tokens for participant user IDs
      // 2. Send notifications via Firebase Admin SDK or your backend
      // 3. Handle different notification types and priorities
    } catch (e) {
      debugPrint('Error sending chat notification: $e');
    }
  }

  /// Send emergency alert notification
  static Future<void> sendEmergencyAlert({
    required String emergencyId,
    required String emergencyType,
    required String description,
    required List<String> responderIds,
  }) async {
    try {
      // TODO: Implement server-side emergency notification
      debugPrint('Sending emergency alert:');
      debugPrint('  Emergency: $emergencyId');
      debugPrint('  Type: $emergencyType');
      debugPrint('  Description: $description');
      debugPrint('  Responders: ${responderIds.length}');

      // In a real implementation, you would:
      // 1. Get FCM tokens for responder user IDs
      // 2. Send high-priority emergency notifications
      // 3. Include location and emergency details
      // 4. Trigger sound/vibration alerts
    } catch (e) {
      debugPrint('Error sending emergency alert: $e');
    }
  }

  /// Get current FCM token
  static String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Request notification permissions
  static Future<bool> requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Subscribe to topic for broadcast notifications
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  // Handle background message processing here
}
