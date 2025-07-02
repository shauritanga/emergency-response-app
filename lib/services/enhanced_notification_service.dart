import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../models/emergency.dart';
import '../models/user.dart';
import 'modern_fcm_service.dart';

class EnhancedNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static bool _initialized = false;
  static String? _fcmToken;
  static String? _currentUserId;

  /// Initialize the enhanced notification service
  static Future<void> initialize({String? userId}) async {
    if (_initialized) return;

    _currentUserId = userId;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize FCM
      await _initializeFCM();

      // Set up Firestore listeners
      if (userId != null) {
        await _setupFirestoreListeners(userId);
      }

      _initialized = true;
      debugPrint('Enhanced notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing enhanced notifications: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  /// Create notification channels for different types
  static Future<void> _createNotificationChannels() async {
    // Emergency channel - high priority
    const emergencyChannel = AndroidNotificationChannel(
      'emergency_alerts',
      'Emergency Alerts',
      description: 'Critical emergency notifications',
      importance: Importance.max,
      enableVibration: true,
      enableLights: true,
      ledColor: Colors.red,
      sound: RawResourceAndroidNotificationSound('emergency_alert'),
    );

    // Chat channel - normal priority
    const chatChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: 'Chat and messaging notifications',
      importance: Importance.high,
      enableVibration: true,
    );

    // Nearby alerts channel - medium priority
    const nearbyChannel = AndroidNotificationChannel(
      'nearby_alerts',
      'Nearby Alerts',
      description: 'Notifications for nearby emergencies',
      importance: Importance.high,
      enableVibration: true,
    );

    final plugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (plugin != null) {
      await plugin.createNotificationChannel(emergencyChannel);
      await plugin.createNotificationChannel(chatChannel);
      await plugin.createNotificationChannel(nearbyChannel);
    }
  }

  /// Initialize FCM
  static Future<void> _initializeFCM() async {
    // Request permissions
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      debugPrint('User declined notification permissions');
      return;
    }

    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Update user's FCM token in Firestore
    if (_currentUserId != null && _fcmToken != null) {
      await _updateUserFCMToken(_currentUserId!, _fcmToken!);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      if (_currentUserId != null) {
        await _updateUserFCMToken(_currentUserId!, token);
      }
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
  }

  /// Update user's FCM token in Firestore
  static Future<void> _updateUserFCMToken(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('Updated FCM token for user: $userId');
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  /// Set up Firestore listeners for real-time notifications
  static Future<void> _setupFirestoreListeners(String userId) async {
    // Listen for new emergencies
    _firestore
        .collection('emergencies')
        .where('timestamp', isGreaterThan: DateTime.now())
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final emergency = Emergency.fromMap(change.doc.data()!);
              _handleNewEmergency(emergency, userId);
            }
          }
        });

    // Listen for emergency updates
    _firestore.collection('emergencies').snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final emergency = Emergency.fromMap(change.doc.data()!);
          _handleEmergencyUpdate(emergency, userId);
        }
      }
    });
  }

  /// Handle new emergency - determine if user should be notified
  static Future<void> _handleNewEmergency(
    Emergency emergency,
    String userId,
  ) async {
    try {
      // Don't notify the user who reported the emergency
      if (emergency.userId == userId) return;

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final user = UserModel.fromMap(userDoc.data()!);

      // Check if user should be notified based on role and preferences
      final shouldNotify = await _shouldNotifyUser(user, emergency);

      if (shouldNotify) {
        await _sendEmergencyNotification(user, emergency);
      }
    } catch (e) {
      debugPrint('Error handling new emergency: $e');
    }
  }

  /// Handle emergency updates
  static Future<void> _handleEmergencyUpdate(
    Emergency emergency,
    String userId,
  ) async {
    try {
      // Get current user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final user = UserModel.fromMap(userDoc.data()!);

      // Only notify responders about status updates
      if (user.role == 'responder' && user.department == emergency.type) {
        await _sendEmergencyUpdateNotification(user, emergency);
      }
    } catch (e) {
      debugPrint('Error handling emergency update: $e');
    }
  }

  /// Determine if user should be notified about an emergency
  static Future<bool> _shouldNotifyUser(
    UserModel user,
    Emergency emergency,
  ) async {
    // Responders: notify if department matches emergency type
    if (user.role == 'responder') {
      return user.department == emergency.type;
    }

    // Citizens: notify if within proximity radius
    if (user.role == 'citizen' && user.lastLocation != null) {
      final userLat = user.lastLocation!['latitude'] as double?;
      final userLon = user.lastLocation!['longitude'] as double?;

      if (userLat != null && userLon != null) {
        final distance = _calculateDistance(
          emergency.latitude,
          emergency.longitude,
          userLat,
          userLon,
        );

        // Get user's notification radius preference (default 5km)
        final notificationRadius =
            (user.notificationPreferences?['radius'] as num?)?.toDouble() ??
            5.0;
        return distance <= notificationRadius &&
            distance > 0.05; // Exclude very close to avoid self-notification
      }
    }

    return false;
  }

  /// Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Send emergency notification to user
  static Future<void> _sendEmergencyNotification(
    UserModel user,
    Emergency emergency,
  ) async {
    try {
      final isResponder = user.role == 'responder';
      final title =
          isResponder
              ? '🚨 ${emergency.type} Emergency Alert'
              : '⚠️ Emergency Nearby (${emergency.type})';

      final body =
          isResponder
              ? 'New ${emergency.type} emergency reported. Immediate response required.'
              : 'An emergency was reported near your location: ${emergency.description}';

      // Send local notification
      await _showLocalNotification(
        id: emergency.id.hashCode,
        title: title,
        body: body,
        channelId: isResponder ? 'emergency_alerts' : 'nearby_alerts',
        payload: jsonEncode({
          'type': 'emergency',
          'emergencyId': emergency.id,
          'emergencyType': emergency.type,
        }),
      );

      debugPrint('Sent emergency notification to ${user.role}: ${user.name}');
    } catch (e) {
      debugPrint('Error sending emergency notification: $e');
    }
  }

  /// Send emergency update notification
  static Future<void> _sendEmergencyUpdateNotification(
    UserModel user,
    Emergency emergency,
  ) async {
    try {
      await _showLocalNotification(
        id: '${emergency.id}_update'.hashCode,
        title: '📋 Emergency Update',
        body:
            'Status update for ${emergency.type} emergency: ${emergency.status}',
        channelId: 'emergency_alerts',
        payload: jsonEncode({
          'type': 'emergency_update',
          'emergencyId': emergency.id,
          'emergencyType': emergency.type,
        }),
      );
    } catch (e) {
      debugPrint('Error sending emergency update notification: $e');
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    required String channelId,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'emergency_alerts',
        'Emergency Alerts',
        channelDescription: 'Critical emergency notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        enableLights: true,
        ledColor: Colors.red,
        autoCancel: false,
        ongoing: false,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Handle foreground FCM messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? 'Notification',
        body: notification.body ?? '',
        channelId: message.data['channel'] ?? 'emergency_alerts',
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Handle background message tap
  static Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('Background message tapped: ${message.messageId}');
    // Navigation will be handled by the main app
  }

  /// Handle local notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final type = data['type'];

        // Store navigation data for the main app to handle
        _pendingNavigation = {'type': type, 'data': data};
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  static Map<String, dynamic>? _pendingNavigation;

  /// Get and clear pending navigation
  static Map<String, dynamic>? getPendingNavigation() {
    final navigation = _pendingNavigation;
    _pendingNavigation = null;
    return navigation;
  }

  /// Send chat notification to specific users
  static Future<void> sendChatNotification({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String content,
    required List<String> participantIds,
    bool isEmergency = false,
  }) async {
    try {
      // Get FCM tokens for participants
      final tokens = await _getFCMTokensForUsers(participantIds);

      if (tokens.isEmpty) {
        debugPrint('No FCM tokens found for chat participants');
        return;
      }

      // Create notification data
      final data = {
        'type': 'chat_message',
        'conversationId': conversationId,
        'senderId': senderId,
        'senderName': senderName,
        'isEmergency': isEmergency.toString(),
        'channel': 'chat_messages',
      };

      final title = isEmergency ? '🚨 Emergency Chat' : '💬 New Message';
      final body = '$senderName: $content';

      // Use multicast for better performance when sending to multiple users
      if (tokens.length > 1) {
        await _sendFCMMulticast(
          tokens: tokens,
          title: title,
          body: body,
          data: data,
        );
      } else {
        // Use single token send for one recipient
        await _sendFCMMessage(
          token: tokens.first,
          title: title,
          body: body,
          data: data,
        );
      }

      debugPrint('Sent chat notification to ${tokens.length} participants');
    } catch (e) {
      debugPrint('Error sending chat notification: $e');
    }
  }

  /// Get FCM tokens for list of user IDs
  static Future<List<String>> _getFCMTokensForUsers(
    List<String> userIds,
  ) async {
    try {
      final tokens = <String>[];

      for (final userId in userIds) {
        // Skip current user to avoid self-notification
        if (userId == _currentUserId) continue;

        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final fcmToken = userDoc.data()?['fcmToken'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            tokens.add(fcmToken);
          }
        }
      }

      return tokens;
    } catch (e) {
      debugPrint('Error getting FCM tokens: $e');
      return [];
    }
  }

  /// Send FCM message to specific token with retry mechanism
  static Future<void> _sendFCMMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      await ModernFCMService.sendNotification(
        token: token,
        title: title,
        body: body,
        data: data,
      );
      debugPrint(
        'FCM sent successfully to token: ${token.substring(0, 10)}...',
      );
    } catch (e) {
      debugPrint('FCM send failed: $e');
      // Fallback to local notification
      await _showLocalNotification(
        id: token.hashCode,
        title: title,
        body: body,
        channelId: data['channel'] ?? 'emergency_alerts',
        payload: jsonEncode(data),
      );
    }
  }

  /// Send FCM message to multiple tokens (multicast)
  static Future<void> _sendFCMMulticast({
    required List<String> tokens,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    if (tokens.isEmpty) return;

    try {
      await ModernFCMService.sendMulticastNotification(
        tokens: tokens,
        title: title,
        body: body,
        data: data,
      );
      debugPrint('FCM multicast sent successfully to ${tokens.length} tokens');
    } catch (e) {
      debugPrint('FCM multicast failed: $e');
      // Fallback to local notifications for all tokens
      for (final token in tokens) {
        await _showLocalNotification(
          id: token.hashCode,
          title: title,
          body: body,
          channelId: data['channel'] ?? 'emergency_alerts',
          payload: jsonEncode(data),
        );
      }
    }
  }

  /// Trigger emergency notifications for new emergency
  static Future<void> triggerEmergencyNotifications(Emergency emergency) async {
    try {
      debugPrint('Triggering emergency notifications for: ${emergency.id}');

      // The Firestore listener will automatically handle this
      // when the emergency document is created

      // Additionally, we can send immediate notifications to online users
      await _notifyOnlineUsers(emergency);
    } catch (e) {
      debugPrint('Error triggering emergency notifications: $e');
    }
  }

  /// Notify currently online users immediately
  static Future<void> _notifyOnlineUsers(Emergency emergency) async {
    try {
      // Get all users and check who should be notified
      final usersSnapshot = await _firestore.collection('users').get();

      final responderTokens = <String>[];
      final nearbyCitizenTokens = <String>[];

      for (final userDoc in usersSnapshot.docs) {
        final user = UserModel.fromMap(userDoc.data());

        // Skip the user who reported the emergency
        if (user.id == emergency.userId) continue;

        final shouldNotify = await _shouldNotifyUser(user, emergency);
        if (shouldNotify) {
          final fcmToken = userDoc.data()['fcmToken'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            if (user.role == 'responder') {
              responderTokens.add(fcmToken);
            } else {
              nearbyCitizenTokens.add(fcmToken);
            }
          }
        }
      }

      // Send notifications to responders
      if (responderTokens.isNotEmpty) {
        final responderData = {
          'type': 'emergency',
          'emergencyId': emergency.id,
          'emergencyType': emergency.type,
          'channel': 'emergency_alerts',
        };

        await _sendFCMMulticast(
          tokens: responderTokens,
          title: '🚨 ${emergency.type} Emergency Alert',
          body:
              'New ${emergency.type} emergency reported. Immediate response required.',
          data: responderData,
        );
      }

      // Send notifications to nearby citizens
      if (nearbyCitizenTokens.isNotEmpty) {
        final citizenData = {
          'type': 'emergency',
          'emergencyId': emergency.id,
          'emergencyType': emergency.type,
          'channel': 'nearby_alerts',
        };

        await _sendFCMMulticast(
          tokens: nearbyCitizenTokens,
          title: '⚠️ Emergency Nearby (${emergency.type})',
          body:
              'An emergency was reported near your location: ${emergency.description}',
          data: citizenData,
        );
      }

      debugPrint(
        'Sent emergency notifications to ${responderTokens.length} responders and ${nearbyCitizenTokens.length} nearby citizens',
      );
    } catch (e) {
      debugPrint('Error notifying online users: $e');
    }
  }

  /// Subscribe user to emergency type topics
  static Future<void> subscribeToEmergencyTopics(
    String userRole,
    String? department,
  ) async {
    try {
      if (userRole == 'responder' && department != null) {
        await _firebaseMessaging.subscribeToTopic(department.toLowerCase());
        debugPrint(
          'Subscribed responder to topic: ${department.toLowerCase()}',
        );
      }

      // Subscribe all users to general emergency alerts
      await _firebaseMessaging.subscribeToTopic('emergency_alerts');
      debugPrint('Subscribed to emergency_alerts topic');
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }

  /// Unsubscribe from topics
  static Future<void> unsubscribeFromTopics(
    String userRole,
    String? department,
  ) async {
    try {
      if (userRole == 'responder' && department != null) {
        await _firebaseMessaging.unsubscribeFromTopic(department.toLowerCase());
      }

      await _firebaseMessaging.unsubscribeFromTopic('emergency_alerts');
    } catch (e) {
      debugPrint('Error unsubscribing from topics: $e');
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
}
