import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/emergency.dart';

class EmergencyService {
  final CollectionReference _emergencies = FirebaseFirestore.instance
      .collection('emergencies');

  Future<void> reportEmergency(Emergency emergency) async {
    await _emergencies.doc(emergency.id).set(emergency.toMap());
  }

  Future<void> notifyEmergency(Emergency emergency) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('notifyEmergency');

      await callable.call([
        {
          'emergencyId': emergency.id,
          'type': emergency.type,
          'latitude': emergency.latitude,
          'longitude': emergency.longitude,
          'description': emergency.description,
        },
      ]);
    } catch (e) {
      debugPrint('Error triggering notification: $e');
      rethrow;
    }
  }

  Future<void> updateEmergencyStatus(String emergencyId, String status) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _emergencies.doc(emergencyId).update({
        'status': status,
        'responderIds': FieldValue.arrayUnion([user.uid]),
      });
    } else {
      throw Exception('User not authenticated');
    }
  }

  // Future<void> updateEmergencyStatus(String emergencyId, String status) async {
  //   await _emergencies.doc(emergencyId).update({'status': status});
  // }

  Stream<List<Emergency>> getUserEmergencies(String userId) {
    return _emergencies
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Emergency.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  Stream<List<Emergency>> getResponderEmergencies(String department) {
    return _emergencies
        .where('type', isEqualTo: department)
        .where('status', whereIn: ['Pending', 'In Progress'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Emergency.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  Stream<List<Emergency>> getResponderHistory(String userId) {
    return _emergencies
        .where('responderIds', arrayContains: userId)
        .where('status', whereIn: ['In Progress', 'Resolved'])
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Emergency.fromMap(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }
}

final emergencyProvider = StateProvider<Emergency?>((ref) => null);
final emergencyIdProvider = StateProvider<String>((ref) => '');
final emergencyStatusProvider = StateProvider<String>((ref) => '');
final emergencyTypeProvider = StateProvider<String>((ref) => '');
