import 'package:cloud_firestore/cloud_firestore.dart';

class Emergency {
  final String id;
  final String userId;
  final String type; // Medical, Fire, Police
  final double latitude;
  final double longitude;
  final String description;
  final String status; // Pending, In Progress, Resolved
  final DateTime timestamp;
  final List<String> imageUrls; // URLs of uploaded images
  final List<String>
  responderIds; // IDs of responders who have worked on this emergency

  Emergency({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.status,
    required this.timestamp,
    this.imageUrls = const [],
    this.responderIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'status': status,
      'timestamp': timestamp,
      'imageUrls': imageUrls,
      'responderIds': responderIds,
    };
  }

  factory Emergency.fromMap(Map<String, dynamic> map) {
    return Emergency(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      description: map['description'],
      status: map['status'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      responderIds: List<String>.from(map['responderIds'] ?? []),
    );
  }
}
