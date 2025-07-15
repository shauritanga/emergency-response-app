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
      notificationPreferences:
          map['notificationPreferences'] != null
              ? Map<String, bool?>.from(map['notificationPreferences'])
              : null,
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen']?.toDate(),
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
      specializations:
          map['specializations'] != null
              ? List<String>.from(map['specializations'])
              : null,
    );
  }
}
