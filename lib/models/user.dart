class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? photoURL;
  final String role;
  final String? department;
  final String? deviceToken;
  final Map<String, dynamic>? lastLocation;
  final Map<String, bool?>? notificationPreferences;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoURL,
    this.phone,
    required this.role,
    this.department,
    this.deviceToken,
    this.lastLocation,
    this.notificationPreferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photoURL': photoURL,
      'role': role,
      'department': department,
      'deviceToken': deviceToken,
      'lastLocation': lastLocation,
      'notificationPreferences': notificationPreferences,
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
      department: map['department'],
      deviceToken: map['deviceToken'],
      lastLocation: map['lastLocation'],
      notificationPreferences:
          map['notificationPreferences'] != null
              ? Map<String, bool?>.from(map['notificationPreferences'])
              : null,
    );
  }
}
