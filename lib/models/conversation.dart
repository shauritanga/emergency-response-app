import 'package:cloud_firestore/cloud_firestore.dart';

/// Conversation model for managing chat conversations
class Conversation {
  final String id;
  final ConversationType type;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String> participantRoles;
  final String? emergencyId;
  final String? title;
  final String? description;
  final String lastMessage;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  Conversation({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    required this.participantRoles,
    this.emergencyId,
    this.title,
    this.description,
    this.lastMessage = '',
    this.lastMessageSenderId = '',
    required this.lastMessageTime,
    this.unreadCounts = const {},
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.metadata,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] ?? '',
      type: ConversationType.values.firstWhere(
        (e) => e.toString() == 'ConversationType.${map['type']}',
        orElse: () => ConversationType.direct,
      ),
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantRoles: Map<String, String>.from(map['participantRoles'] ?? {}),
      emergencyId: map['emergencyId'],
      title: map['title'],
      description: map['description'],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : DateTime.parse(map['lastMessageTime']),
      unreadCounts: Map<String, int>.from(map['unreadCounts'] ?? {}),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
      metadata: map['metadata'] != null 
          ? Map<String, dynamic>.from(map['metadata']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantRoles': participantRoles,
      'emergencyId': emergencyId,
      'title': title,
      'description': description,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  Conversation copyWith({
    String? id,
    ConversationType? type,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String>? participantRoles,
    String? emergencyId,
    String? title,
    String? description,
    String? lastMessage,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantRoles: participantRoles ?? this.participantRoles,
      emergencyId: emergencyId ?? this.emergencyId,
      title: title ?? this.title,
      description: description ?? this.description,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get unread count for a specific user
  int getUnreadCount(String userId) => unreadCounts[userId] ?? 0;

  /// Check if user is a participant
  bool hasParticipant(String userId) => participantIds.contains(userId);

  /// Get conversation title for display
  String getDisplayTitle(String currentUserId) {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }

    switch (type) {
      case ConversationType.emergency:
        return emergencyId != null 
            ? 'Emergency #${emergencyId!.substring(0, 8)}'
            : 'Emergency Chat';
      case ConversationType.group:
        return 'Group Chat (${participantIds.length} members)';
      case ConversationType.direct:
        // For direct chat, show the other participant's name
        final otherParticipants = participantIds.where((id) => id != currentUserId);
        if (otherParticipants.isNotEmpty) {
          final otherUserId = otherParticipants.first;
          return participantNames[otherUserId] ?? 'Unknown User';
        }
        return 'Direct Chat';
      case ConversationType.broadcast:
        return 'Emergency Broadcast';
    }
  }

  /// Get conversation subtitle for display
  String getDisplaySubtitle() {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }

    switch (type) {
      case ConversationType.emergency:
        return 'Emergency coordination chat';
      case ConversationType.group:
        final roles = participantRoles.values.toSet().join(', ');
        return roles.isNotEmpty ? roles : 'Group conversation';
      case ConversationType.direct:
        return 'Direct conversation';
      case ConversationType.broadcast:
        return 'Emergency broadcast channel';
    }
  }

  /// Check if conversation is emergency-related
  bool get isEmergencyRelated => 
      type == ConversationType.emergency || emergencyId != null;

  /// Get participant count
  int get participantCount => participantIds.length;

  /// Check if conversation has unread messages for user
  bool hasUnreadMessages(String userId) => getUnreadCount(userId) > 0;
}

/// Types of conversations
enum ConversationType {
  direct,     // 1-on-1 conversation
  group,      // Group conversation
  emergency,  // Emergency-specific chat
  broadcast,  // One-way broadcast from responders
}

/// Conversation participant info
class ConversationParticipant {
  final String userId;
  final String name;
  final String role;
  final DateTime joinedAt;
  final bool isActive;
  final DateTime? lastSeen;

  ConversationParticipant({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
    this.lastSeen,
  });

  factory ConversationParticipant.fromMap(Map<String, dynamic> map) {
    return ConversationParticipant(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      joinedAt: map['joinedAt'] is Timestamp
          ? (map['joinedAt'] as Timestamp).toDate()
          : DateTime.parse(map['joinedAt']),
      isActive: map['isActive'] ?? true,
      lastSeen: map['lastSeen'] != null
          ? (map['lastSeen'] is Timestamp
              ? (map['lastSeen'] as Timestamp).toDate()
              : DateTime.parse(map['lastSeen']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'isActive': isActive,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    };
  }
}
