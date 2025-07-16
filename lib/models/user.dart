import 'package:flutter/foundation.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoURL;
  final String role;
  final String status; // active, inactive, suspended, pending
  final String? department;
  final String? deviceToken;
  final Map<String, dynamic>? lastLocation;
  final Map<String, bool?>? notificationPreferences;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? specializations;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    this.phone,
    required this.role,
    this.status = 'active',
    this.department,
    this.deviceToken,
    this.lastLocation,
    this.notificationPreferences,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
    this.updatedAt,
    this.specializations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoURL': photoURL,
      'role': role,
      'status': status,
      'department': department,
      'deviceToken': deviceToken,
      'lastLocation': lastLocation,
      'notificationPreferences': notificationPreferences,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'specializations': specializations,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      photoURL: map['photoURL'] ?? '',
      role: map['role'] ?? 'citizen',
      status: map['status'] ?? 'active',
      department: map['department'],
      deviceToken: map['deviceToken'],
      lastLocation: map['lastLocation'],
      notificationPreferences: _parseNotificationPreferences(
        map['notificationPreferences'],
      ),
      isOnline: _parseBooleanField(map['isOnline']) ?? false,
      lastSeen: map['lastSeen']?.toDate(),
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      specializations:
          map['specializations'] != null
              ? List<String>.from(map['specializations'])
              : null,
    );
  }

  /// Safely parse notification preferences from Firebase data
  static Map<String, bool?>? _parseNotificationPreferences(dynamic data) {
    if (data == null) return null;

    try {
      if (data is Map<String, dynamic>) {
        final Map<String, bool?> preferences = {};

        data.forEach((key, value) {
          // Handle different data types that might be stored in Firebase
          if (value is bool) {
            preferences[key] = value;
          } else if (value is List) {
            // If it's a list, we'll ignore it or convert based on context
            // This handles the case where lists were accidentally stored
            preferences[key] = null;
          } else if (value is String) {
            // Handle string representations of booleans
            if (value.toLowerCase() == 'true') {
              preferences[key] = true;
            } else if (value.toLowerCase() == 'false') {
              preferences[key] = false;
            } else {
              preferences[key] = null;
            }
          } else {
            // For any other type, default to null
            preferences[key] = null;
          }
        });

        return preferences;
      }

      // If data is not a Map, return null
      return null;
    } catch (e) {
      // If parsing fails, return null and log the error
      debugPrint('Error parsing notification preferences: $e');
      return null;
    }
  }

  /// Safely parse boolean fields from Firebase data
  static bool? _parseBooleanField(dynamic value) {
    if (value == null) return null;

    if (value is bool) {
      return value;
    } else if (value is String) {
      if (value.toLowerCase() == 'true') {
        return true;
      } else if (value.toLowerCase() == 'false') {
        return false;
      }
    } else if (value is List) {
      // If it's a list, we can't convert it to boolean
      debugPrint('Warning: Expected boolean but got List: $value');
      return null;
    }

    // For any other type, return null
    debugPrint(
      'Warning: Could not parse boolean from: $value (${value.runtimeType})',
    );
    return null;
  }
}
