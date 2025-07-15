import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency.dart';
import '../models/emergency_status.dart';
import '../models/user.dart';

class EnhancedEmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Update emergency status with validation and audit trail
  Future<bool> updateEmergencyStatus({
    required String emergencyId,
    required EmergencyStatus newStatus,
    String? reason,
    List<File>? evidenceFiles,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');
      final userData = UserModel.fromMap(userDoc.data()!);

      // Get current emergency data
      final emergencyDoc = await _firestore.collection('emergencies').doc(emergencyId).get();
      if (!emergencyDoc.exists) throw Exception('Emergency not found');
      final emergency = Emergency.fromMap(emergencyDoc.data()!);
      final currentStatus = EmergencyStatus.fromString(emergency.status);

      // Validate transition
      if (!StatusTransitionRules.canTransition(currentStatus, newStatus, userData.role)) {
        throw Exception('Status transition not allowed for your role');
      }

      // Check evidence requirements
      if (StatusTransitionRules.requiresEvidence(newStatus) && 
          (evidenceFiles == null || evidenceFiles.isEmpty)) {
        throw Exception('Evidence is required for this status change');
      }

      // Upload evidence files if provided
      List<String> evidenceUrls = [];
      if (evidenceFiles != null && evidenceFiles.isNotEmpty) {
        evidenceUrls = await _uploadEvidenceFiles(emergencyId, evidenceFiles);
      }

      // Create status change record
      final statusChange = StatusChange(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emergencyId: emergencyId,
        fromStatus: currentStatus,
        toStatus: newStatus,
        changedBy: user.uid,
        changedByRole: userData.role,
        timestamp: DateTime.now(),
        reason: reason,
        evidenceUrls: evidenceUrls,
        metadata: metadata ?? {},
      );

      // Use transaction to ensure consistency
      await _firestore.runTransaction((transaction) async {
        // Update emergency status
        transaction.update(
          _firestore.collection('emergencies').doc(emergencyId),
          {
            'status': newStatus.displayName,
            'lastUpdated': FieldValue.serverTimestamp(),
            'lastUpdatedBy': user.uid,
          },
        );

        // Add status change to audit trail
        transaction.set(
          _firestore
              .collection('emergencies')
              .doc(emergencyId)
              .collection('status_changes')
              .doc(statusChange.id),
          statusChange.toMap(),
        );

        // If marking as pending resolution, create verification requirement
        if (newStatus == EmergencyStatus.pendingResolution) {
          await _createVerificationRequirement(emergencyId, userData);
        }
      });

      // Send notifications based on status change
      await _sendStatusChangeNotifications(emergency, currentStatus, newStatus, userData);

      debugPrint('Emergency status updated: $emergencyId -> ${newStatus.displayName}');
      return true;
    } catch (e) {
      debugPrint('Error updating emergency status: $e');
      return false;
    }
  }

  /// Verify emergency resolution
  Future<bool> verifyResolution({
    required String emergencyId,
    required bool isConfirmed,
    String? notes,
    List<File>? evidenceFiles,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User data not found');
      final userData = UserModel.fromMap(userDoc.data()!);

      // Upload evidence if provided
      List<String> evidenceUrls = [];
      if (evidenceFiles != null && evidenceFiles.isNotEmpty) {
        evidenceUrls = await _uploadEvidenceFiles(emergencyId, evidenceFiles);
      }

      final verification = ResolutionVerification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        emergencyId: emergencyId,
        verifiedBy: user.uid,
        verifierRole: userData.role,
        timestamp: DateTime.now(),
        isConfirmed: isConfirmed,
        notes: notes,
        evidenceUrls: evidenceUrls,
      );

      await _firestore.runTransaction((transaction) async {
        // Add verification record
        transaction.set(
          _firestore
              .collection('emergencies')
              .doc(emergencyId)
              .collection('verifications')
              .doc(verification.id),
          verification.toMap(),
        );

        // Update emergency status based on verification
        final newStatus = isConfirmed 
            ? EmergencyStatus.resolved 
            : EmergencyStatus.disputed;

        transaction.update(
          _firestore.collection('emergencies').doc(emergencyId),
          {
            'status': newStatus.displayName,
            'lastUpdated': FieldValue.serverTimestamp(),
            'verificationStatus': isConfirmed ? 'confirmed' : 'disputed',
          },
        );
      });

      return true;
    } catch (e) {
      debugPrint('Error verifying resolution: $e');
      return false;
    }
  }

  /// Get emergency status history
  Future<List<StatusChange>> getStatusHistory(String emergencyId) async {
    try {
      final snapshot = await _firestore
          .collection('emergencies')
          .doc(emergencyId)
          .collection('status_changes')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => StatusChange.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting status history: $e');
      return [];
    }
  }

  /// Get resolution verifications
  Future<List<ResolutionVerification>> getVerifications(String emergencyId) async {
    try {
      final snapshot = await _firestore
          .collection('emergencies')
          .doc(emergencyId)
          .collection('verifications')
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ResolutionVerification.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting verifications: $e');
      return [];
    }
  }

  /// Check if user can change emergency status
  Future<bool> canUserChangeStatus(String emergencyId, EmergencyStatus newStatus) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;
      final userData = UserModel.fromMap(userDoc.data()!);

      final emergencyDoc = await _firestore.collection('emergencies').doc(emergencyId).get();
      if (!emergencyDoc.exists) return false;
      final emergency = Emergency.fromMap(emergencyDoc.data()!);
      final currentStatus = EmergencyStatus.fromString(emergency.status);

      return StatusTransitionRules.canTransition(currentStatus, newStatus, userData.role);
    } catch (e) {
      debugPrint('Error checking user permissions: $e');
      return false;
    }
  }

  /// Upload evidence files to Firebase Storage
  Future<List<String>> _uploadEvidenceFiles(String emergencyId, List<File> files) async {
    final List<String> urls = [];
    
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = 'evidence_${DateTime.now().millisecondsSinceEpoch}_$i';
      final ref = _storage.ref().child('emergencies/$emergencyId/evidence/$fileName');
      
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      urls.add(url);
    }
    
    return urls;
  }

  /// Create verification requirement for pending resolution
  Future<void> _createVerificationRequirement(String emergencyId, UserModel responder) async {
    // Implementation for creating verification requirements
    // This could involve notifying the citizen who reported the emergency
    // or requiring additional responder confirmation
  }

  /// Send notifications for status changes
  Future<void> _sendStatusChangeNotifications(
    Emergency emergency,
    EmergencyStatus fromStatus,
    EmergencyStatus toStatus,
    UserModel changedBy,
  ) async {
    // Implementation for sending notifications to relevant parties
    // based on the status change
  }
}
