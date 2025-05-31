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

  Emergency({
    required this.id,
    required this.userId,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.description,
    required this.status,
    required this.timestamp,
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
    );
  }
}
