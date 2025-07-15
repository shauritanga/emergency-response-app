import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class UserTrackingService {
  static final UserTrackingService _instance = UserTrackingService._internal();
  factory UserTrackingService() => _instance;
  UserTrackingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _heartbeatTimer;
  bool _isTracking = false;

  /// Start tracking user activity
  void startTracking() {
    if (_isTracking) return;
    
    final user = _auth.currentUser;
    if (user == null) return;

    _isTracking = true;
    debugPrint('🔄 Starting user activity tracking for: ${user.uid}');

    // Set user as online immediately
    _updateOnlineStatus(true);

    // Start heartbeat timer to update lastSeen every 30 seconds
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateLastSeen();
    });
  }

  /// Stop tracking user activity
  void stopTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    debugPrint('⏹️ Stopping user activity tracking');

    // Cancel heartbeat timer
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;

    // Set user as offline
    _updateOnlineStatus(false);
  }

  /// Update user's online status
  Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Updated online status: $isOnline for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error updating online status: $e');
    }
  }

  /// Update user's last seen timestamp
  Future<void> _updateLastSeen() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('🕐 Updated lastSeen for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error updating lastSeen: $e');
    }
  }

  /// Update user location
  Future<void> updateUserLocation({
    required double latitude,
    required double longitude,
    String? address,
    String? city,
    String? state,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'city': city,
        'state': state,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).update({
        'lastLocation': locationData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📍 Updated user location: $latitude, $longitude');
    } catch (e) {
      debugPrint('❌ Error updating user location: $e');
    }
  }

  /// Update user status (active, inactive, suspended, pending)
  Future<void> updateUserStatus(String status) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📊 Updated user status: $status for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error updating user status: $e');
    }
  }

  /// Update user specializations (for responders)
  Future<void> updateUserSpecializations(List<String> specializations) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'specializations': specializations,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('🎯 Updated user specializations: $specializations');
    } catch (e) {
      debugPrint('❌ Error updating user specializations: $e');
    }
  }

  /// Update device token for push notifications
  Future<void> updateDeviceToken(String? deviceToken) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'deviceToken': deviceToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📱 Updated device token for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error updating device token: $e');
    }
  }

  /// Mark user as active (called when app becomes active)
  void onAppResumed() {
    if (_auth.currentUser != null) {
      startTracking();
    }
  }

  /// Mark user as inactive (called when app goes to background)
  void onAppPaused() {
    stopTracking();
  }

  /// Clean up resources
  void dispose() {
    stopTracking();
  }
}
