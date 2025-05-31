import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/rendering.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initialize({
    String? userId,
    String? role,
    String? department,
  }) async {
    debugPrint('Initializing Notification Service');
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    debugPrint('Device Token: $token');
    debugPrint('User ID: $userId');
    if (token != null && userId != null) {
      // Store device token in Firestore
      await _firestore.collection('users').doc(userId).update({
        'deviceToken': token,
        'notificationPreferences': {
          'notifyProximity': role == 'citizen' ? true : null,
          'notifyEmergencies': role == 'responder' ? true : null,
        },
      });
    }

    // Subscribe to topics based on role and preferences
    if (role == 'citizen') {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final preferences = userDoc.data()?['notificationPreferences'] ?? {};
      if (preferences['notifyProximity'] == true) {
        await _messaging.subscribeToTopic('citizens');
      }
    } else if (role == 'responder' && department != null) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final preferences = userDoc.data()?['notificationPreferences'] ?? {};
      if (preferences['notifyEmergencies'] == true) {
        await _messaging.subscribeToTopic(department);
        debugPrint('Subscribed to topic: $department');
      }
    }

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground notification: ${message.notification?.title}');
      // Optionally show a local notification or update UI
    });

    // Handle notification taps (deep linking)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final emergencyId = message.data['emergencyId'];
      if (emergencyId != null) {
        // Deep link handling is managed in main.dart
      }
    });

    // Handle background notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  Future<void> updateNotificationPreferences(
    String userId,
    String role,
    Map<String, bool?> preferences,
  ) async {
    await _firestore.collection('users').doc(userId).update({
      'notificationPreferences': preferences,
    });

    // Update topic subscriptions
    if (role == 'citizen') {
      if (preferences['notifyProximity'] == true) {
        await subscribeToTopic('citizens');
      } else {
        await unsubscribeFromTopic('citizens');
      }
    } else if (role == 'responder') {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final department = userDoc.data()?['department'];
      if (department != null) {
        if (preferences['notifyEmergencies'] == true) {
          await subscribeToTopic(department);
        } else {
          await unsubscribeFromTopic(department);
        }
      }
    }
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background notification: ${message.notification?.title}');
}
