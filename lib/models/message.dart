import 'package:cloud_firestore/cloud_firestore.dart';

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
