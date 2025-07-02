import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/emergency.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User Management
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is included
        return UserModel.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users: $e');
      rethrow;
    }
  }

  static Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('User role updated: $userId -> $newRole');
    } catch (e) {
      debugPrint('Error updating user role: $e');
      rethrow;
    }
  }

  static Future<void> updateUserDepartment(
    String userId,
    String? department,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'department': department,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('User department updated: $userId -> $department');
    } catch (e) {
      debugPrint('Error updating user department: $e');
      rethrow;
    }
  }

  static Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
        'deactivatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('User deactivated: $userId');
    } catch (e) {
      debugPrint('Error deactivating user: $e');
      rethrow;
    }
  }

  static Future<void> activateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
        'deactivatedAt': null,
      });
      debugPrint('User activated: $userId');
    } catch (e) {
      debugPrint('Error activating user: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      // First, check if user has any active emergencies
      final emergencies =
          await _firestore
              .collection('emergencies')
              .where('userId', isEqualTo: userId)
              .where('status', whereIn: ['Pending', 'In Progress'])
              .get();

      if (emergencies.docs.isNotEmpty) {
        throw Exception('Cannot delete user with active emergencies');
      }

      await _firestore.collection('users').doc(userId).delete();
      debugPrint('User deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  // Emergency Management
  static Future<List<Emergency>> getAllEmergencies() async {
    try {
      final snapshot =
          await _firestore
              .collection('emergencies')
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Emergency.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching emergencies: $e');
      rethrow;
    }
  }

  static Future<List<Emergency>> getEmergenciesByStatus(String status) async {
    try {
      final snapshot =
          await _firestore
              .collection('emergencies')
              .where('status', isEqualTo: status)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Emergency.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching emergencies by status: $e');
      rethrow;
    }
  }

  static Future<List<Emergency>> getEmergenciesByType(String type) async {
    try {
      final snapshot =
          await _firestore
              .collection('emergencies')
              .where('type', isEqualTo: type)
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Emergency.fromMap(data);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching emergencies by type: $e');
      rethrow;
    }
  }

  static Future<void> updateEmergencyStatus(
    String emergencyId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection('emergencies').doc(emergencyId).update({
        'status': newStatus,
        'adminUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Emergency status updated: $emergencyId -> $newStatus');
    } catch (e) {
      debugPrint('Error updating emergency status: $e');
      rethrow;
    }
  }

  static Future<void> assignResponderToEmergency(
    String emergencyId,
    String responderId,
  ) async {
    try {
      await _firestore.collection('emergencies').doc(emergencyId).update({
        'assignedResponderId': responderId,
        'assignedAt': FieldValue.serverTimestamp(),
      });
      debugPrint(
        'Responder assigned to emergency: $responderId -> $emergencyId',
      );
    } catch (e) {
      debugPrint('Error assigning responder: $e');
      rethrow;
    }
  }

  static Future<void> deleteEmergency(String emergencyId) async {
    try {
      await _firestore.collection('emergencies').doc(emergencyId).delete();
      debugPrint('Emergency deleted: $emergencyId');
    } catch (e) {
      debugPrint('Error deleting emergency: $e');
      rethrow;
    }
  }

  // Analytics and Statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final now = DateTime.now();
      final last24Hours = now.subtract(const Duration(hours: 24));
      final last7Days = now.subtract(const Duration(days: 7));
      final last30Days = now.subtract(const Duration(days: 30));

      // Get user counts
      final totalUsers = await _firestore.collection('users').count().get();
      final activeUsers =
          await _firestore
              .collection('users')
              .where('isActive', isEqualTo: true)
              .count()
              .get();
      final responders =
          await _firestore
              .collection('users')
              .where('role', isEqualTo: 'responder')
              .count()
              .get();

      // Get emergency counts
      final totalEmergencies =
          await _firestore.collection('emergencies').count().get();
      final pendingEmergencies =
          await _firestore
              .collection('emergencies')
              .where('status', isEqualTo: 'Pending')
              .count()
              .get();
      final inProgressEmergencies =
          await _firestore
              .collection('emergencies')
              .where('status', isEqualTo: 'In Progress')
              .count()
              .get();

      // Get recent emergencies (last 24 hours)
      final recentEmergencies =
          await _firestore
              .collection('emergencies')
              .where(
                'timestamp',
                isGreaterThan: Timestamp.fromDate(last24Hours),
              )
              .count()
              .get();

      // Get emergency types distribution
      final medicalEmergencies =
          await _firestore
              .collection('emergencies')
              .where('type', isEqualTo: 'Medical')
              .count()
              .get();
      final fireEmergencies =
          await _firestore
              .collection('emergencies')
              .where('type', isEqualTo: 'Fire')
              .count()
              .get();
      final policeEmergencies =
          await _firestore
              .collection('emergencies')
              .where('type', isEqualTo: 'Police')
              .count()
              .get();

      return {
        'totalUsers': totalUsers.count,
        'activeUsers': activeUsers.count,
        'responders': responders.count,
        'totalEmergencies': totalEmergencies.count,
        'pendingEmergencies': pendingEmergencies.count,
        'inProgressEmergencies': inProgressEmergencies.count,
        'recentEmergencies': recentEmergencies.count,
        'emergencyTypes': {
          'medical': medicalEmergencies.count,
          'fire': fireEmergencies.count,
          'police': policeEmergencies.count,
        },
      };
    } catch (e) {
      debugPrint('Error fetching dashboard stats: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getEmergencyTrends() async {
    try {
      final now = DateTime.now();
      final last7Days = now.subtract(const Duration(days: 7));

      final snapshot =
          await _firestore
              .collection('emergencies')
              .where('timestamp', isGreaterThan: Timestamp.fromDate(last7Days))
              .orderBy('timestamp', descending: true)
              .get();

      final emergencies =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'type': data['type'],
              'status': data['status'],
              'timestamp': (data['timestamp'] as Timestamp).toDate(),
            };
          }).toList();

      // Group by date
      final Map<String, int> dailyCounts = {};
      for (final emergency in emergencies) {
        final date = emergency['timestamp'].toString().split(' ')[0];
        dailyCounts[date] = (dailyCounts[date] ?? 0) + 1;
      }

      return dailyCounts.entries
          .map((entry) => {'date': entry.key, 'count': entry.value})
          .toList();
    } catch (e) {
      debugPrint('Error fetching emergency trends: $e');
      rethrow;
    }
  }

  // System Settings
  static Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final doc =
          await _firestore.collection('system_settings').doc('main').get();
      if (doc.exists) {
        return doc.data()!;
      }
      return {};
    } catch (e) {
      debugPrint('Error fetching system settings: $e');
      rethrow;
    }
  }

  static Future<void> updateSystemSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore.collection('system_settings').doc('main').set(settings);
      debugPrint('System settings updated');
    } catch (e) {
      debugPrint('Error updating system settings: $e');
      rethrow;
    }
  }

  // Bulk Operations
  static Future<void> bulkUpdateUserRoles(
    Map<String, String> userRoleUpdates,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final entry in userRoleUpdates.entries) {
        final userRef = _firestore.collection('users').doc(entry.key);
        batch.update(userRef, {
          'role': entry.value,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint(
        'Bulk user role update completed: ${userRoleUpdates.length} users',
      );
    } catch (e) {
      debugPrint('Error in bulk user role update: $e');
      rethrow;
    }
  }

  static Future<void> bulkUpdateEmergencyStatuses(
    Map<String, String> emergencyStatusUpdates,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final entry in emergencyStatusUpdates.entries) {
        final emergencyRef = _firestore
            .collection('emergencies')
            .doc(entry.key);
        batch.update(emergencyRef, {
          'status': entry.value,
          'adminUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint(
        'Bulk emergency status update completed: ${emergencyStatusUpdates.length} emergencies',
      );
    } catch (e) {
      debugPrint('Error in bulk emergency status update: $e');
      rethrow;
    }
  }

  // Search and Filter
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple prefix search on name and email
      final users = await getAllUsers();
      return users.where((user) {
        final searchLower = query.toLowerCase();
        return user.name.toLowerCase().contains(searchLower) ||
            user.email.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  static Future<List<Emergency>> searchEmergencies(String query) async {
    try {
      final emergencies = await getAllEmergencies();
      return emergencies.where((emergency) {
        final searchLower = query.toLowerCase();
        return emergency.type.toLowerCase().contains(searchLower) ||
            emergency.description.toLowerCase().contains(searchLower) ||
            emergency.status.toLowerCase().contains(searchLower);
      }).toList();
    } catch (e) {
      debugPrint('Error searching emergencies: $e');
      rethrow;
    }
  }
}
