import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/emergency.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import 'dart:math';

/// Helper class for emergency-related chat operations
class EmergencyChatHelper {
  static final ChatService _chatService = ChatService();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find emergency conversation for a specific emergency ID
  static Future<Conversation?> findEmergencyConversation(
    String emergencyId,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('conversations')
              .where('emergencyId', isEqualTo: emergencyId)
              .where('type', isEqualTo: ConversationType.emergency.name)
              .limit(1)
              .get();

      if (snapshot.docs.isNotEmpty) {
        return Conversation.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      debugPrint('Failed to find emergency conversation: $e');
      return null;
    }
  }

  /// Create a direct chat between citizen and responder for an emergency
  static Future<String?> createEmergencyDirectChat({
    required String emergencyId,
    required String citizenId,
    required String responderId,
    required UserModel citizen,
    required UserModel responder,
  }) async {
    try {
      // Check if direct chat already exists for this emergency
      final existingConversations =
          await _firestore
              .collection('conversations')
              .where('type', isEqualTo: ConversationType.direct.name)
              .where('emergencyId', isEqualTo: emergencyId)
              .where('participantIds', arrayContains: citizenId)
              .get();

      for (final doc in existingConversations.docs) {
        final conversation = Conversation.fromMap(doc.data());
        if (conversation.participantIds.contains(responderId)) {
          return conversation.id; // Return existing conversation
        }
      }

      // Create new direct conversation
      final conversationId = await _chatService.createConversation(
        type: ConversationType.direct,
        participantIds: [citizenId, responderId],
        participantNames: {
          citizenId: citizen.name,
          responderId: responder.name,
        },
        participantRoles: {
          citizenId: citizen.role,
          responderId: responder.role,
        },
        createdBy: citizenId,
        emergencyId: emergencyId,
        title: 'Emergency Support Chat',
        description:
            'Direct chat for emergency #${emergencyId.substring(0, 8)}',
      );

      debugPrint('Created emergency direct chat: $conversationId');
      return conversationId;
    } catch (e) {
      debugPrint('Failed to create emergency direct chat: $e');
      return null;
    }
  }

  /// Get all emergency-related conversations for a user
  static Stream<List<Conversation>> getEmergencyConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Conversation.fromMap(doc.data()))
              .where((conv) => conv.isEmergencyRelated)
              .toList()
            ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        });
  }

  /// Create a broadcast channel for emergency updates
  static Future<String?> createEmergencyBroadcast({
    required String emergencyId,
    required String broadcasterId,
    required UserModel broadcaster,
    required List<UserModel> recipients,
  }) async {
    try {
      final participantIds = [broadcasterId, ...recipients.map((r) => r.id)];
      final participantNames = {
        broadcasterId: broadcaster.name,
        ...{for (var r in recipients) r.id: r.name},
      };
      final participantRoles = {
        broadcasterId: broadcaster.role,
        ...{for (var r in recipients) r.id: r.role},
      };

      final conversationId = await _chatService.createConversation(
        type: ConversationType.broadcast,
        participantIds: participantIds,
        participantNames: participantNames,
        participantRoles: participantRoles,
        createdBy: broadcasterId,
        emergencyId: emergencyId,
        title: 'Emergency Broadcast',
        description:
            'Official updates for emergency #${emergencyId.substring(0, 8)}',
      );

      debugPrint('Created emergency broadcast: $conversationId');
      return conversationId;
    } catch (e) {
      debugPrint('Failed to create emergency broadcast: $e');
      return null;
    }
  }

  /// Add nearby citizens to emergency conversation
  static Future<void> addNearbyCitizensToEmergency({
    required String emergencyId,
    required double latitude,
    required double longitude,
    double radiusKm = 1.0, // 1km radius by default
  }) async {
    try {
      // Find the emergency conversation
      final emergencyConversation = await findEmergencyConversation(
        emergencyId,
      );
      if (emergencyConversation == null) {
        debugPrint('Emergency conversation not found: $emergencyId');
        return;
      }

      // Find nearby citizens
      final usersSnapshot = await _firestore.collection('users').get();
      final nearbyCitizens = <UserModel>[];

      for (final userDoc in usersSnapshot.docs) {
        final user = UserModel.fromMap(userDoc.data());

        // Skip if not a citizen or already a participant
        if (user.role != 'citizen' ||
            emergencyConversation.hasParticipant(user.id)) {
          continue;
        }

        // Check if user has location data
        if (user.lastLocation != null) {
          final userLat = user.lastLocation!['latitude'] as double?;
          final userLon = user.lastLocation!['longitude'] as double?;

          if (userLat != null && userLon != null) {
            final distance = _calculateDistance(
              latitude,
              longitude,
              userLat,
              userLon,
            );
            if (distance <= radiusKm) {
              nearbyCitizens.add(user);
            }
          }
        }
      }

      // Add nearby citizens to the conversation
      for (final citizen in nearbyCitizens.take(10)) {
        // Limit to 10 citizens
        await _chatService.addParticipant(
          conversationId: emergencyConversation.id,
          userId: citizen.id,
          userName: citizen.name,
          userRole: citizen.role,
        );
      }

      debugPrint(
        'Added ${nearbyCitizens.length} nearby citizens to emergency chat',
      );
    } catch (e) {
      debugPrint('Failed to add nearby citizens to emergency: $e');
    }
  }

  /// Calculate distance between two points in kilometers
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
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  /// Get emergency status updates for a conversation
  static Stream<List<String>> getEmergencyStatusUpdates(String emergencyId) {
    return _firestore
        .collection('emergencies')
        .doc(emergencyId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists) {
            final emergency = Emergency.fromMap(snapshot.data()!);
            return [
              'Status: ${emergency.status}',
              'Type: ${emergency.type}',
              'Reported: ${emergency.timestamp.toString()}',
            ];
          }
          return <String>[];
        });
  }

  /// Check if user can access emergency conversation
  static Future<bool> canUserAccessEmergencyChat({
    required String userId,
    required String emergencyId,
  }) async {
    try {
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return false;

      final user = UserModel.fromMap(userDoc.data()!);

      // Get emergency data
      final emergencyDoc =
          await _firestore.collection('emergencies').doc(emergencyId).get();
      if (!emergencyDoc.exists) return false;

      final emergency = Emergency.fromMap(emergencyDoc.data()!);

      // Citizens can access if they reported the emergency
      if (user.role == 'citizen' && emergency.userId == userId) {
        return true;
      }

      // Responders can access if it's their department
      if (user.role == 'responder' && user.department == emergency.type) {
        return true;
      }

      // Admins can access all emergency chats
      if (user.role == 'admin') {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Failed to check emergency chat access: $e');
      return false;
    }
  }

  /// Send emergency status update to all related conversations
  static Future<void> broadcastEmergencyUpdate({
    required String emergencyId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String statusUpdate,
  }) async {
    try {
      // Find all conversations related to this emergency
      final conversationsSnapshot =
          await _firestore
              .collection('conversations')
              .where('emergencyId', isEqualTo: emergencyId)
              .get();

      for (final doc in conversationsSnapshot.docs) {
        final conversation = Conversation.fromMap(doc.data());

        // Send status update message to each conversation
        final message = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_${conversation.id}',
          conversationId: conversation.id,
          senderId: senderId,
          senderName: senderName,
          senderRole: senderRole,
          content: '📢 EMERGENCY UPDATE: $statusUpdate',
          type: MessageType.emergency,
          timestamp: DateTime.now(),
          emergencyId: emergencyId,
        );

        await _chatService.sendMessage(message);
      }

      debugPrint(
        'Broadcasted emergency update to ${conversationsSnapshot.docs.length} conversations',
      );
    } catch (e) {
      debugPrint('Failed to broadcast emergency update: $e');
    }
  }

  /// Create emergency evacuation instructions
  static Future<void> sendEvacuationInstructions({
    required String emergencyId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String evacuationRoute,
    required String assemblyPoint,
  }) async {
    try {
      final emergencyConversation = await findEmergencyConversation(
        emergencyId,
      );
      if (emergencyConversation == null) return;

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: emergencyConversation.id,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content:
            '🚨 EVACUATION INSTRUCTIONS:\n\n'
            '📍 Route: $evacuationRoute\n'
            '🏁 Assembly Point: $assemblyPoint\n\n'
            'Please evacuate immediately and proceed to the assembly point. '
            'Stay calm and help others if possible.',
        type: MessageType.emergency,
        timestamp: DateTime.now(),
        emergencyId: emergencyId,
        metadata: {
          'evacuationRoute': evacuationRoute,
          'assemblyPoint': assemblyPoint,
          'instructionType': 'evacuation',
        },
      );

      await _chatService.sendMessage(message);
      debugPrint('Sent evacuation instructions for emergency: $emergencyId');
    } catch (e) {
      debugPrint('Failed to send evacuation instructions: $e');
    }
  }

  /// Send shelter-in-place instructions
  static Future<void> sendShelterInstructions({
    required String emergencyId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String reason,
    required Duration estimatedDuration,
  }) async {
    try {
      final emergencyConversation = await findEmergencyConversation(
        emergencyId,
      );
      if (emergencyConversation == null) return;

      final message = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        conversationId: emergencyConversation.id,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content:
            '🏠 SHELTER IN PLACE:\n\n'
            '⚠️ Reason: $reason\n'
            '⏱️ Estimated Duration: ${estimatedDuration.inHours}h ${estimatedDuration.inMinutes % 60}m\n\n'
            'Stay indoors, close all windows and doors. '
            'Do not leave your current location until further notice.',
        type: MessageType.emergency,
        timestamp: DateTime.now(),
        emergencyId: emergencyId,
        metadata: {
          'reason': reason,
          'estimatedDuration': estimatedDuration.inMinutes,
          'instructionType': 'shelter',
        },
      );

      await _chatService.sendMessage(message);
      debugPrint('Sent shelter instructions for emergency: $emergencyId');
    } catch (e) {
      debugPrint('Failed to send shelter instructions: $e');
    }
  }

  /// Get emergency chat statistics
  static Future<EmergencyChatStats> getEmergencyChatStats(
    String emergencyId,
  ) async {
    try {
      final conversationsSnapshot =
          await _firestore
              .collection('conversations')
              .where('emergencyId', isEqualTo: emergencyId)
              .get();

      int totalParticipants = 0;
      int totalMessages = 0;
      int activeConversations = 0;
      DateTime? lastActivity;

      for (final doc in conversationsSnapshot.docs) {
        final conversation = Conversation.fromMap(doc.data());

        if (conversation.isActive) {
          activeConversations++;
          totalParticipants += conversation.participantCount;

          if (lastActivity == null ||
              conversation.lastMessageTime.isAfter(lastActivity)) {
            lastActivity = conversation.lastMessageTime;
          }
        }

        // Count messages in this conversation
        final messagesSnapshot =
            await _firestore
                .collection('conversations')
                .doc(conversation.id)
                .collection('messages')
                .get();

        totalMessages += messagesSnapshot.docs.length;
      }

      return EmergencyChatStats(
        emergencyId: emergencyId,
        totalConversations: conversationsSnapshot.docs.length,
        activeConversations: activeConversations,
        totalParticipants: totalParticipants,
        totalMessages: totalMessages,
        lastActivity: lastActivity,
      );
    } catch (e) {
      debugPrint('Failed to get emergency chat stats: $e');
      return EmergencyChatStats(emergencyId: emergencyId);
    }
  }

  /// Archive all conversations for a resolved emergency
  static Future<void> archiveEmergencyConversations(String emergencyId) async {
    try {
      final conversationsSnapshot =
          await _firestore
              .collection('conversations')
              .where('emergencyId', isEqualTo: emergencyId)
              .get();

      final batch = _firestore.batch();

      for (final doc in conversationsSnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();
      debugPrint(
        'Archived ${conversationsSnapshot.docs.length} conversations for emergency: $emergencyId',
      );
    } catch (e) {
      debugPrint('Failed to archive emergency conversations: $e');
    }
  }
}

/// Statistics for emergency chat activity
class EmergencyChatStats {
  final String emergencyId;
  final int totalConversations;
  final int activeConversations;
  final int totalParticipants;
  final int totalMessages;
  final DateTime? lastActivity;

  EmergencyChatStats({
    required this.emergencyId,
    this.totalConversations = 0,
    this.activeConversations = 0,
    this.totalParticipants = 0,
    this.totalMessages = 0,
    this.lastActivity,
  });

  Map<String, dynamic> toMap() {
    return {
      'emergencyId': emergencyId,
      'totalConversations': totalConversations,
      'activeConversations': activeConversations,
      'totalParticipants': totalParticipants,
      'totalMessages': totalMessages,
      'lastActivity': lastActivity?.toIso8601String(),
    };
  }
}
