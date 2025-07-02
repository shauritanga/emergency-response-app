import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'push_notification_service.dart';
import '../models/user.dart';
import '../utils/network_utils.dart';

/// Service for managing real-time chat functionality
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's conversations stream
  Stream<List<Conversation>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Conversation.fromMap(doc.data()))
                  .toList(),
        );
  }

  /// Get messages for a specific conversation
  Stream<List<ChatMessage>> getConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(50) // Load last 50 messages initially
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromMap(doc.data()))
                  .toList(),
        );
  }

  /// Send a message to a conversation
  Future<void> sendMessage(ChatMessage message) async {
    try {
      await NetworkUtils.executeWithConnectivityCheck(() async {
        final batch = _firestore.batch();

        // Add message to conversation's messages subcollection
        final messageRef = _firestore
            .collection('conversations')
            .doc(message.conversationId)
            .collection('messages')
            .doc(message.id);

        batch.set(messageRef, message.toMap());

        // Update conversation's last message info
        final conversationRef = _firestore
            .collection('conversations')
            .doc(message.conversationId);

        // Get current conversation to update unread counts
        final conversationDoc = await conversationRef.get();
        if (conversationDoc.exists) {
          final conversation = Conversation.fromMap(conversationDoc.data()!);

          // Update unread counts for all participants except sender
          final updatedUnreadCounts = Map<String, int>.from(
            conversation.unreadCounts,
          );
          for (final participantId in conversation.participantIds) {
            if (participantId != message.senderId) {
              updatedUnreadCounts[participantId] =
                  (updatedUnreadCounts[participantId] ?? 0) + 1;
            }
          }

          batch.update(conversationRef, {
            'lastMessage': message.content,
            'lastMessageSenderId': message.senderId,
            'lastMessageTime': message.toMap()['timestamp'],
            'unreadCounts': updatedUnreadCounts,
          });
        }

        await batch.commit();
        debugPrint('Message sent successfully: ${message.id}');

        // Send push notifications to other participants
        if (conversationDoc.exists) {
          final conversation = Conversation.fromMap(conversationDoc.data()!);
          final otherParticipants =
              conversation.participantIds
                  .where((id) => id != message.senderId)
                  .toList();

          if (otherParticipants.isNotEmpty) {
            await PushNotificationService.sendChatNotification(
              conversationId: message.conversationId,
              senderId: message.senderId,
              senderName: message.senderName,
              content: message.content,
              participantIds: otherParticipants,
              isEmergency:
                  message.type == MessageType.emergency ||
                  message.type == MessageType.evacuation,
            );
          }
        }
      });
    } catch (e) {
      debugPrint('Failed to send message: $e');
      rethrow;
    }
  }

  /// Create a new conversation
  Future<String> createConversation({
    required ConversationType type,
    required List<String> participantIds,
    required Map<String, String> participantNames,
    required Map<String, String> participantRoles,
    required String createdBy,
    String? emergencyId,
    String? title,
    String? description,
  }) async {
    try {
      return await NetworkUtils.executeWithConnectivityCheck(() async {
        final conversationId = _firestore.collection('conversations').doc().id;
        final now = DateTime.now();

        final conversation = Conversation(
          id: conversationId,
          type: type,
          participantIds: participantIds,
          participantNames: participantNames,
          participantRoles: participantRoles,
          emergencyId: emergencyId,
          title: title,
          description: description,
          lastMessageTime: now,
          createdAt: now,
          createdBy: createdBy,
        );

        await _firestore
            .collection('conversations')
            .doc(conversationId)
            .set(conversation.toMap());

        debugPrint('Conversation created: $conversationId');
        return conversationId;
      });
    } catch (e) {
      debugPrint('Failed to create conversation: $e');
      rethrow;
    }
  }

  /// Add participant to conversation
  Future<void> addParticipant({
    required String conversationId,
    required String userId,
    required String userName,
    required String userRole,
  }) async {
    try {
      await NetworkUtils.executeWithConnectivityCheck(() async {
        await _firestore.collection('conversations').doc(conversationId).update(
          {
            'participantIds': FieldValue.arrayUnion([userId]),
            'participantNames.$userId': userName,
            'participantRoles.$userId': userRole,
          },
        );

        // Send system message about user joining
        final systemMessage = ChatMessage(
          id: _firestore.collection('temp').doc().id,
          conversationId: conversationId,
          senderId: 'system',
          senderName: 'System',
          senderRole: 'system',
          content: '$userName joined the conversation',
          type: MessageType.system,
          timestamp: DateTime.now(),
        );

        await sendMessage(systemMessage);
        debugPrint('Participant added: $userId to $conversationId');
      });
    } catch (e) {
      debugPrint('Failed to add participant: $e');
      rethrow;
    }
  }

  /// Remove participant from conversation
  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
    required String userName,
  }) async {
    try {
      await NetworkUtils.executeWithConnectivityCheck(() async {
        await _firestore.collection('conversations').doc(conversationId).update(
          {
            'participantIds': FieldValue.arrayRemove([userId]),
            'participantNames.$userId': FieldValue.delete(),
            'participantRoles.$userId': FieldValue.delete(),
            'unreadCounts.$userId': FieldValue.delete(),
          },
        );

        // Send system message about user leaving
        final systemMessage = ChatMessage(
          id: _firestore.collection('temp').doc().id,
          conversationId: conversationId,
          senderId: 'system',
          senderName: 'System',
          senderRole: 'system',
          content: '$userName left the conversation',
          type: MessageType.system,
          timestamp: DateTime.now(),
        );

        await sendMessage(systemMessage);
        debugPrint('Participant removed: $userId from $conversationId');
      });
    } catch (e) {
      debugPrint('Failed to remove participant: $e');
      rethrow;
    }
  }

  /// Mark messages as read for a user
  Future<void> markAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await NetworkUtils.executeWithConnectivityCheck(() async {
        // Reset unread count for this user
        await _firestore.collection('conversations').doc(conversationId).update(
          {'unreadCounts.$userId': 0},
        );

        debugPrint(
          'Messages marked as read for user: $userId in $conversationId',
        );
      });
    } catch (e) {
      debugPrint('Failed to mark messages as read: $e');
      rethrow;
    }
  }

  /// Get conversation by ID
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      return await NetworkUtils.executeWithConnectivityCheck(() async {
        final doc =
            await _firestore
                .collection('conversations')
                .doc(conversationId)
                .get();

        if (doc.exists) {
          return Conversation.fromMap(doc.data()!);
        }
        return null;
      });
    } catch (e) {
      debugPrint('Failed to get conversation: $e');
      return null;
    }
  }

  /// Find or create direct conversation between two users
  Future<String> findOrCreateDirectConversation({
    required String user1Id,
    required String user2Id,
    required UserModel user1,
    required UserModel user2,
  }) async {
    try {
      return await NetworkUtils.executeWithConnectivityCheck(() async {
        // Check if conversation already exists
        final existingQuery =
            await _firestore
                .collection('conversations')
                .where('type', isEqualTo: ConversationType.direct.name)
                .where('participantIds', arrayContains: user1Id)
                .get();

        for (final doc in existingQuery.docs) {
          final conversation = Conversation.fromMap(doc.data());
          if (conversation.participantIds.contains(user2Id) &&
              conversation.participantIds.length == 2) {
            return conversation.id;
          }
        }

        // Create new conversation if none exists
        return await createConversation(
          type: ConversationType.direct,
          participantIds: [user1Id, user2Id],
          participantNames: {user1Id: user1.name, user2Id: user2.name},
          participantRoles: {user1Id: user1.role, user2Id: user2.role},
          createdBy: user1Id,
        );
      });
    } catch (e) {
      debugPrint('Failed to find or create direct conversation: $e');
      rethrow;
    }
  }

  /// Archive/deactivate a conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      await NetworkUtils.executeWithConnectivityCheck(() async {
        await _firestore.collection('conversations').doc(conversationId).update(
          {'isActive': false},
        );
        debugPrint('Conversation archived: $conversationId');
      });
    } catch (e) {
      debugPrint('Failed to archive conversation: $e');
      rethrow;
    }
  }

  /// Get total unread count for user across all conversations
  Future<int> getTotalUnreadCount(String userId) async {
    try {
      return await NetworkUtils.executeWithConnectivityCheck(() async {
        final snapshot =
            await _firestore
                .collection('conversations')
                .where('participantIds', arrayContains: userId)
                .where('isActive', isEqualTo: true)
                .get();

        int totalUnread = 0;
        for (final doc in snapshot.docs) {
          final conversation = Conversation.fromMap(doc.data());
          totalUnread += conversation.getUnreadCount(userId);
        }

        return totalUnread;
      });
    } catch (e) {
      debugPrint('Failed to get total unread count: $e');
      return 0;
    }
  }
}
