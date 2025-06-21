import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'chat_service.dart';

class EmergencyService {
  final CollectionReference _emergencies = FirebaseFirestore.instance
      .collection('emergencies');
  final ChatService _chatService = ChatService();

  Future<void> reportEmergency(Emergency emergency) async {
    await _emergencies.doc(emergency.id).set(emergency.toMap());

    // Create emergency chat room
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
        title: 'Emergency #${emergency.id.substring(0, 8)}',
        description: '${emergency.type} emergency - ${emergency.description}',
      );

      // Send initial system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: conversationId,
        senderId: 'system',
        senderName: 'Emergency System',
        senderRole: 'system',
        content:
            '🚨 Emergency reported: ${emergency.type}\n'
            'Location: ${emergency.latitude}, ${emergency.longitude}\n'
            'Description: ${emergency.description}\n\n'
            'Emergency responders have been notified.',
        type: MessageType.emergency,
        timestamp: DateTime.now(),
        emergencyId: emergency.id,
      );

      await _chatService.sendMessage(systemMessage);

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
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('notifyEmergency');

      final result = await callable.call({
        'emergencyId': emergency.id,
        'type': emergency.type,
        'latitude': emergency.latitude,
        'longitude': emergency.longitude,
        'description': emergency.description,
      });

      debugPrint('Notification sent successfully: ${result.data}');
    } catch (e) {
      debugPrint('Error triggering notification: $e');
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
        .where('status', whereIn: ['In Progress', 'Resolved'])
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
}

final emergencyProvider = StateProvider<Emergency?>((ref) => null);
final emergencyIdProvider = StateProvider<String>((ref) => '');
final emergencyStatusProvider = StateProvider<String>((ref) => '');
final emergencyTypeProvider = StateProvider<String>((ref) => '');
