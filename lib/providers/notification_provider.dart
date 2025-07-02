import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../models/user.dart';
import '../services/enhanced_notification_service.dart';

/// Provider for managing notification state and listeners
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  StreamSubscription<QuerySnapshot>? _emergencySubscription;
  StreamSubscription<QuerySnapshot>? _chatSubscription;
  String? _currentUserId;

  /// Initialize notification listeners for a user
  Future<void> initializeForUser(String userId) async {
    _currentUserId = userId;

    // Initialize the enhanced notification service
    await EnhancedNotificationService.initialize(userId: userId);

    // Set up emergency listeners
    await _setupEmergencyListeners(userId);

    // Set up chat listeners
    await _setupChatListeners(userId);

    // Subscribe to emergency topics based on user role
    await _subscribeToTopics(userId);

    state = state.copyWith(isInitialized: true);
  }

  /// Set up emergency listeners
  Future<void> _setupEmergencyListeners(String userId) async {
    try {
      // Listen for new emergencies
      _emergencySubscription = FirebaseFirestore.instance
          .collection('emergencies')
          .where(
            'timestamp',
            isGreaterThan: DateTime.now().subtract(const Duration(minutes: 1)),
          )
          .snapshots()
          .listen((snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final emergency = Emergency.fromMap(change.doc.data()!);
                _handleNewEmergency(emergency, userId);
              } else if (change.type == DocumentChangeType.modified) {
                final emergency = Emergency.fromMap(change.doc.data()!);
                _handleEmergencyUpdate(emergency, userId);
              }
            }
          });
    } catch (e) {
      debugPrint('Error setting up emergency listeners: $e');
    }
  }

  /// Set up chat listeners for real-time message notifications
  Future<void> _setupChatListeners(String userId) async {
    try {
      // Listen for new messages in conversations where user is a participant
      _chatSubscription = FirebaseFirestore.instance
          .collection('messages')
          .where(
            'timestamp',
            isGreaterThan: DateTime.now().subtract(const Duration(minutes: 1)),
          )
          .snapshots()
          .listen((snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                _handleNewMessage(change.doc.data()!, userId);
              }
            }
          });
    } catch (e) {
      debugPrint('Error setting up chat listeners: $e');
    }
  }

  /// Handle new emergency
  void _handleNewEmergency(Emergency emergency, String userId) {
    // Don't notify the user who reported the emergency
    if (emergency.userId == userId) return;

    // Update state with new emergency
    final newEmergencies = [...state.recentEmergencies, emergency];
    state = state.copyWith(
      recentEmergencies: newEmergencies.take(10).toList(), // Keep last 10
      lastEmergencyNotification: DateTime.now(),
    );
  }

  /// Handle emergency updates
  void _handleEmergencyUpdate(Emergency emergency, String userId) {
    // Update state with emergency update
    final updatedEmergencies =
        state.recentEmergencies.map((e) {
          return e.id == emergency.id ? emergency : e;
        }).toList();

    state = state.copyWith(
      recentEmergencies: updatedEmergencies,
      lastEmergencyUpdate: DateTime.now(),
    );
  }

  /// Handle new chat messages
  void _handleNewMessage(Map<String, dynamic> messageData, String userId) {
    final senderId = messageData['senderId'] as String?;

    // Don't notify for own messages
    if (senderId == userId) return;

    // Update unread message count
    state = state.copyWith(
      unreadMessageCount: state.unreadMessageCount + 1,
      lastMessageNotification: DateTime.now(),
    );
  }

  /// Subscribe to FCM topics based on user role
  Future<void> _subscribeToTopics(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();

      if (userDoc.exists) {
        final user = UserModel.fromMap(userDoc.data()!);
        await EnhancedNotificationService.subscribeToEmergencyTopics(
          user.role,
          user.department,
        );
      }
    } catch (e) {
      debugPrint('Error subscribing to topics: $e');
    }
  }

  /// Legacy method for backward compatibility
  Future<void> initialize({
    required String userId,
    required String role,
    String? department,
  }) async {
    await initializeForUser(userId);
  }

  /// Legacy method for updating notification preferences
  Future<void> updateNotificationPreferences(
    String userId,
    String role,
    Map<String, dynamic> preferences,
  ) async {
    try {
      _currentUserId = userId; // Update current user ID

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'notificationPreferences': preferences,
      });

      final prefs = NotificationPreferences.fromMap(preferences);
      state = state.copyWith(preferences: prefs);
    } catch (e) {
      debugPrint('Error updating notification preferences: $e');
    }
  }

  /// Legacy method for subscribing to topics
  Future<void> subscribeToTopic(String topic) async {
    try {
      await EnhancedNotificationService.subscribeToEmergencyTopics(
        'citizen',
        null,
      );
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await EnhancedNotificationService.areNotificationsEnabled();
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    return await EnhancedNotificationService.requestPermissions();
  }

  @override
  void dispose() {
    _emergencySubscription?.cancel();
    _chatSubscription?.cancel();
    super.dispose();
  }
}

/// Notification state class
class NotificationState {
  final bool isInitialized;
  final List<Emergency> recentEmergencies;
  final int unreadMessageCount;
  final DateTime? lastEmergencyNotification;
  final DateTime? lastEmergencyUpdate;
  final DateTime? lastMessageNotification;
  final NotificationPreferences preferences;

  const NotificationState({
    this.isInitialized = false,
    this.recentEmergencies = const [],
    this.unreadMessageCount = 0,
    this.lastEmergencyNotification,
    this.lastEmergencyUpdate,
    this.lastMessageNotification,
    this.preferences = const NotificationPreferences(),
  });

  NotificationState copyWith({
    bool? isInitialized,
    List<Emergency>? recentEmergencies,
    int? unreadMessageCount,
    DateTime? lastEmergencyNotification,
    DateTime? lastEmergencyUpdate,
    DateTime? lastMessageNotification,
    NotificationPreferences? preferences,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      recentEmergencies: recentEmergencies ?? this.recentEmergencies,
      unreadMessageCount: unreadMessageCount ?? this.unreadMessageCount,
      lastEmergencyNotification:
          lastEmergencyNotification ?? this.lastEmergencyNotification,
      lastEmergencyUpdate: lastEmergencyUpdate ?? this.lastEmergencyUpdate,
      lastMessageNotification:
          lastMessageNotification ?? this.lastMessageNotification,
      preferences: preferences ?? this.preferences,
    );
  }
}

/// Notification preferences class
class NotificationPreferences {
  final bool emergencyAlerts;
  final bool chatMessages;
  final bool nearbyAlerts;
  final double radius; // in kilometers
  final bool soundEnabled;
  final bool vibrationEnabled;
  final List<String> enabledEmergencyTypes;

  const NotificationPreferences({
    this.emergencyAlerts = true,
    this.chatMessages = true,
    this.nearbyAlerts = true,
    this.radius = 5.0,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.enabledEmergencyTypes = const ['Medical', 'Fire', 'Police'],
  });

  Map<String, dynamic> toMap() {
    return {
      'emergencyAlerts': emergencyAlerts,
      'chatMessages': chatMessages,
      'nearbyAlerts': nearbyAlerts,
      'radius': radius,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'enabledEmergencyTypes': enabledEmergencyTypes,
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      emergencyAlerts: map['emergencyAlerts'] ?? true,
      chatMessages: map['chatMessages'] ?? true,
      nearbyAlerts: map['nearbyAlerts'] ?? true,
      radius: (map['radius'] as num?)?.toDouble() ?? 5.0,
      soundEnabled: map['soundEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      enabledEmergencyTypes: List<String>.from(
        map['enabledEmergencyTypes'] ?? ['Medical', 'Fire', 'Police'],
      ),
    );
  }

  NotificationPreferences copyWith({
    bool? emergencyAlerts,
    bool? chatMessages,
    bool? nearbyAlerts,
    double? radius,
    bool? soundEnabled,
    bool? vibrationEnabled,
    List<String>? enabledEmergencyTypes,
  }) {
    return NotificationPreferences(
      emergencyAlerts: emergencyAlerts ?? this.emergencyAlerts,
      chatMessages: chatMessages ?? this.chatMessages,
      nearbyAlerts: nearbyAlerts ?? this.nearbyAlerts,
      radius: radius ?? this.radius,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      enabledEmergencyTypes:
          enabledEmergencyTypes ?? this.enabledEmergencyTypes,
    );
  }
}

/// Provider for notification state
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      return NotificationNotifier();
    });

/// Legacy provider for backward compatibility
final notificationServiceProvider = Provider<NotificationNotifier>((ref) {
  return ref.watch(notificationProvider.notifier);
});
