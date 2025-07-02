import 'package:cloud_firestore/cloud_firestore.dart';

/// Legacy message model for system notifications
class Message {
  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      body: map['body'],
      timestamp: DateTime.parse(map['timestamp']),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

/// Enhanced chat message model for real-time messaging
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;
  final String? emergencyId;
  final Map<String, dynamic>? metadata;
  final List<String> readBy;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    required this.type,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.emergencyId,
    this.metadata,
    this.readBy = const [],
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderRole: map['senderRole'] ?? '',
      content: map['content'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${map['type']}',
        orElse: () => MessageType.text,
      ),
      timestamp:
          map['timestamp'] is Timestamp
              ? (map['timestamp'] as Timestamp).toDate()
              : DateTime.parse(map['timestamp']),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${map['status']}',
        orElse: () => MessageStatus.sent,
      ),
      emergencyId: map['emergencyId'],
      metadata:
          map['metadata'] != null
              ? Map<String, dynamic>.from(map['metadata'])
              : null,
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'content': content,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'emergencyId': emergencyId,
      'metadata': metadata,
      'readBy': readBy,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderRole,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
    String? emergencyId,
    Map<String, dynamic>? metadata,
    List<String>? readBy,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      emergencyId: emergencyId ?? this.emergencyId,
      metadata: metadata ?? this.metadata,
      readBy: readBy ?? this.readBy,
    );
  }

  bool isReadBy(String userId) => readBy.contains(userId);
}

/// Message types for different content
enum MessageType {
  text,
  image,
  location,
  system,
  emergency,
  status,
  voice, // Voice messages
  evacuation, // Evacuation notices
  statusUpdate, // Emergency status updates
}

/// Message delivery status
enum MessageStatus { sending, sent, delivered, read, failed }
