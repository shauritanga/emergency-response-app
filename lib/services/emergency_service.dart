import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import 'chat_service.dart';
import 'enhanced_notification_service.dart';

class EmergencyService {
  final CollectionReference _emergencies = FirebaseFirestore.instance
      .collection('emergencies');
  final ChatService _chatService = ChatService();

  Future<void> reportEmergency(Emergency emergency) async {
    await _emergencies.doc(emergency.id).set(emergency.toMap());

    // Create emergency chat room
    await _createEmergencyChat(emergency);
  }

  /// Get a specific emergency by ID
  Future<Emergency?> getEmergency(String emergencyId) async {
    try {
      final doc = await _emergencies.doc(emergencyId).get();
      if (doc.exists) {
        return Emergency.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting emergency: $e');
      return null;
    }
  }

  /// Public method to create emergency chat
  Future<void> createEmergencyChat(Emergency emergency) async {
    await _createEmergencyChat(emergency);
  }

  /// Creates an emergency-specific chat room
  Future<void> _createEmergencyChat(Emergency emergency) async {
    try {
      // Get user data for the emergency reporter
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(emergency.userId)
              .get();

      if (!userDoc.exists) {
        debugPrint('User not found for emergency chat creation');
        return;
      }

      final userData = UserModel.fromMap(userDoc.data()!);

      // Find relevant responders based on emergency type
      final responders = await _findRelevantResponders(emergency.type);

      // Create participant lists
      final participantIds = [emergency.userId, ...responders.map((r) => r.id)];
      final participantNames = {
        emergency.userId: userData.name,
        ...{for (var r in responders) r.id: r.name},
      };
      final participantRoles = {
        emergency.userId: userData.role,
        ...{for (var r in responders) r.id: r.role},
      };

      // Create emergency conversation
      final conversationId = await _chatService.createConversation(
        type: ConversationType.emergency,
        participantIds: participantIds,
        participantNames: participantNames,
        participantRoles: participantRoles,
        createdBy: emergency.userId,
        emergencyId: emergency.id,
        title:
            'Emergency #${emergency.id.length > 8 ? emergency.id.substring(0, 8) : emergency.id}',
        description: '${emergency.type} emergency - ${emergency.description}',
      );

      // Emergency system messages are disabled for cleaner chat interface
      // Users can see emergency details in the emergency status screen instead
      // final systemMessage = ChatMessage(
      //   id: DateTime.now().millisecondsSinceEpoch.toString(),
      //   conversationId: conversationId,
      //   senderId: 'emergency_system',
      //   senderName: 'Emergency System',
      //   senderRole: 'admin',
      //   content:
      //       '🚨 Emergency reported: ${emergency.type}\n'
      //       'Location: ${emergency.latitude}, ${emergency.longitude}\n'
      //       'Description: ${emergency.description}\n\n'
      //       'Emergency responders have been notified.',
      //   type: MessageType.emergency,
      //   timestamp: DateTime.now(),
      //   emergencyId: emergency.id,
      // );

      // await _chatService.sendMessage(systemMessage);

      debugPrint(
        'Emergency chat created: $conversationId for emergency: ${emergency.id}',
      );
    } catch (e) {
      debugPrint('Failed to create emergency chat: $e');
      // Don't rethrow - emergency reporting should still succeed even if chat fails
    }
  }

  /// Find relevant responders for an emergency type
  Future<List<UserModel>> _findRelevantResponders(String emergencyType) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: 'responder')
              .where('department', isEqualTo: emergencyType)
              .limit(5) // Limit to 5 responders initially
              .get();

      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
    } catch (e) {
      debugPrint('Failed to find relevant responders: $e');
      return [];
    }
  }

  Future<void> notifyEmergency(Emergency emergency) async {
    try {
      // Use enhanced notification service instead of cloud functions
      await EnhancedNotificationService.triggerEmergencyNotifications(
        emergency,
      );

      debugPrint(
        'Emergency notifications triggered successfully for: ${emergency.id}',
      );
    } catch (e) {
      debugPrint('Error triggering emergency notifications: $e');
      rethrow;
    }
  }

  Future<void> updateEmergencyStatus(String emergencyId, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _emergencies.doc(emergencyId).update({
        'status': status,
        'responderIds': FieldValue.arrayUnion([user.uid]),
      });

      // Add responder to emergency chat if accepting the emergency
      if (status == 'In Progress') {
        await _addResponderToEmergencyChat(emergencyId, user.uid);
      }
    } else {
      throw Exception('User not authenticated');
    }
  }

  /// Add a responder to an existing emergency chat
  Future<void> _addResponderToEmergencyChat(
    String emergencyId,
    String responderId,
  ) async {
    try {
      // Find the emergency conversation
      final conversationsSnapshot =
          await FirebaseFirestore.instance
              .collection('conversations')
              .where('emergencyId', isEqualTo: emergencyId)
              .where('type', isEqualTo: ConversationType.emergency.name)
              .limit(1)
              .get();

      if (conversationsSnapshot.docs.isEmpty) {
        debugPrint(
          'No emergency conversation found for emergency: $emergencyId',
        );
        return;
      }

      final conversationDoc = conversationsSnapshot.docs.first;
      final conversation = Conversation.fromMap(conversationDoc.data());

      // Check if responder is already a participant
      if (conversation.hasParticipant(responderId)) {
        debugPrint('Responder already in emergency chat: $responderId');
        return;
      }

      // Get responder data
      final responderDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(responderId)
              .get();

      if (!responderDoc.exists) {
        debugPrint('Responder not found: $responderId');
        return;
      }

      final responderData = UserModel.fromMap(responderDoc.data()!);

      // Add responder to conversation
      await _chatService.addParticipant(
        conversationId: conversation.id,
        userId: responderId,
        userName: responderData.name,
        userRole: responderData.role,
      );

      debugPrint('Added responder to emergency chat: $responderId');
    } catch (e) {
      debugPrint('Failed to add responder to emergency chat: $e');
      // Don't rethrow - emergency status update should still succeed
    }
  }

  // Future<void> updateEmergencyStatus(String emergencyId, String status) async {
  //   await _emergencies.doc(emergencyId).update({'status': status});
  // }

  Stream<List<Emergency>> getUserEmergencies(String userId) {
    return _emergencies
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Emergency.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  Stream<List<Emergency>> getResponderEmergencies(String department) {
    return _emergencies
        .where('type', isEqualTo: department)
        .where('status', whereIn: ['Pending', 'In Progress'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Emergency.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  Stream<List<Emergency>> getResponderHistory(String userId) {
    return _emergencies
        .where('responderIds', arrayContains: userId)
        .where('status', isEqualTo: 'Resolved')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Emergency.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  /// Get mock emergency history for development/offline testing
  static List<Emergency> getMockResponderHistory(String userId) {
    final now = DateTime.now();
    return [
      Emergency(
        id: 'mock_emergency_1',
        userId: 'citizen_123',
        type: 'Fire',
        description: 'Apartment building fire on 5th floor',
        latitude: 40.713,
        longitude: -74.006,
        status: 'Resolved',
        timestamp: now.subtract(const Duration(hours: 2)),
        responderIds: [userId],
        imageUrls: [
          'https://images.unsplash.com/photo-1574870111867-089730e5a72b?w=400',
        ],
      ),
      Emergency(
        id: 'mock_emergency_2',
        userId: 'citizen_456',
        type: 'Medical',
        description: 'Cardiac arrest patient',
        latitude: 40.748,
        longitude: -73.986,
        status: 'Resolved',
        timestamp: now.subtract(const Duration(days: 1)),
        responderIds: [userId],
        imageUrls: [
          'https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400',
        ],
      ),
      Emergency(
        id: 'mock_emergency_3',
        userId: 'citizen_789',
        type: 'Police',
        description: 'Armed robbery in progress',
        latitude: 40.758,
        longitude: -73.979,
        status: 'Resolved',
        timestamp: now.subtract(const Duration(days: 3)),
        responderIds: [userId],
        imageUrls: [
          'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=400',
        ],
      ),
    ];
  }
}

final emergencyProvider = StateProvider<Emergency?>((ref) => null);
final emergencyIdProvider = StateProvider<String>((ref) => '');
final emergencyStatusProvider = StateProvider<String>((ref) => '');
final emergencyTypeProvider = StateProvider<String>((ref) => '');
