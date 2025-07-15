import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced emergency status with validation and audit trail
enum EmergencyStatus {
  pending('Pending'),
  acknowledged('Acknowledged'), // Responder has seen it
  responding('Responding'), // Responder is en route
  onScene('On Scene'), // Responder is at location
  inProgress('In Progress'), // Working on resolution
  pendingResolution('Pending Resolution'), // Waiting for verification
  resolved('Resolved'), // Fully resolved and verified
  disputed('Disputed'), // Citizen disputes resolution
  escalated('Escalated'); // Requires admin intervention

  const EmergencyStatus(this.displayName);
  final String displayName;

  static EmergencyStatus fromString(String status) {
    return EmergencyStatus.values.firstWhere(
      (e) => e.displayName == status,
      orElse: () => EmergencyStatus.pending,
    );
  }
}

/// Status change record for audit trail
class StatusChange {
  final String id;
  final String emergencyId;
  final EmergencyStatus fromStatus;
  final EmergencyStatus toStatus;
  final String changedBy;
  final String changedByRole;
  final DateTime timestamp;
  final String? reason;
  final List<String> evidenceUrls;
  final Map<String, dynamic> metadata;

  StatusChange({
    required this.id,
    required this.emergencyId,
    required this.fromStatus,
    required this.toStatus,
    required this.changedBy,
    required this.changedByRole,
    required this.timestamp,
    this.reason,
    this.evidenceUrls = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emergencyId': emergencyId,
      'fromStatus': fromStatus.displayName,
      'toStatus': toStatus.displayName,
      'changedBy': changedBy,
      'changedByRole': changedByRole,
      'timestamp': timestamp,
      'reason': reason,
      'evidenceUrls': evidenceUrls,
      'metadata': metadata,
    };
  }

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      id: map['id'],
      emergencyId: map['emergencyId'],
      fromStatus: EmergencyStatus.fromString(map['fromStatus']),
      toStatus: EmergencyStatus.fromString(map['toStatus']),
      changedBy: map['changedBy'],
      changedByRole: map['changedByRole'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      reason: map['reason'],
      evidenceUrls: List<String>.from(map['evidenceUrls'] ?? []),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Resolution verification record
class ResolutionVerification {
  final String id;
  final String emergencyId;
  final String verifiedBy;
  final String verifierRole;
  final DateTime timestamp;
  final bool isConfirmed;
  final String? notes;
  final List<String> evidenceUrls;

  ResolutionVerification({
    required this.id,
    required this.emergencyId,
    required this.verifiedBy,
    required this.verifierRole,
    required this.timestamp,
    required this.isConfirmed,
    this.notes,
    this.evidenceUrls = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emergencyId': emergencyId,
      'verifiedBy': verifiedBy,
      'verifierRole': verifierRole,
      'timestamp': timestamp,
      'isConfirmed': isConfirmed,
      'notes': notes,
      'evidenceUrls': evidenceUrls,
    };
  }

  factory ResolutionVerification.fromMap(Map<String, dynamic> map) {
    return ResolutionVerification(
      id: map['id'],
      emergencyId: map['emergencyId'],
      verifiedBy: map['verifiedBy'],
      verifierRole: map['verifierRole'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isConfirmed: map['isConfirmed'],
      notes: map['notes'],
      evidenceUrls: List<String>.from(map['evidenceUrls'] ?? []),
    );
  }
}

/// Status transition validation rules
class StatusTransitionRules {
  static const Map<EmergencyStatus, List<EmergencyStatus>> allowedTransitions = {
    EmergencyStatus.pending: [
      EmergencyStatus.acknowledged,
      EmergencyStatus.escalated,
    ],
    EmergencyStatus.acknowledged: [
      EmergencyStatus.responding,
      EmergencyStatus.escalated,
    ],
    EmergencyStatus.responding: [
      EmergencyStatus.onScene,
      EmergencyStatus.escalated,
    ],
    EmergencyStatus.onScene: [
      EmergencyStatus.inProgress,
      EmergencyStatus.escalated,
    ],
    EmergencyStatus.inProgress: [
      EmergencyStatus.pendingResolution,
      EmergencyStatus.escalated,
    ],
    EmergencyStatus.pendingResolution: [
      EmergencyStatus.resolved,
      EmergencyStatus.disputed,
      EmergencyStatus.inProgress, // Back to work
    ],
    EmergencyStatus.disputed: [
      EmergencyStatus.inProgress,
      EmergencyStatus.escalated,
    ],
    EmergencyStatus.escalated: [
      EmergencyStatus.inProgress,
      EmergencyStatus.resolved,
    ],
  };

  static const Map<String, List<EmergencyStatus>> rolePermissions = {
    'citizen': [
      // Citizens can only dispute resolution
      EmergencyStatus.disputed,
    ],
    'responder': [
      EmergencyStatus.acknowledged,
      EmergencyStatus.responding,
      EmergencyStatus.onScene,
      EmergencyStatus.inProgress,
      EmergencyStatus.pendingResolution,
    ],
    'admin': [
      // Admins can change to any status
      ...EmergencyStatus.values,
    ],
  };

  static bool canTransition(
    EmergencyStatus from,
    EmergencyStatus to,
    String userRole,
  ) {
    // Check if transition is allowed
    final allowedFromCurrent = allowedTransitions[from] ?? [];
    if (!allowedFromCurrent.contains(to)) return false;

    // Check if user role has permission
    final roleAllowed = rolePermissions[userRole] ?? [];
    return roleAllowed.contains(to);
  }

  static bool requiresEvidence(EmergencyStatus status) {
    return [
      EmergencyStatus.pendingResolution,
      EmergencyStatus.resolved,
    ].contains(status);
  }

  static bool requiresVerification(EmergencyStatus status) {
    return status == EmergencyStatus.resolved;
  }
}
