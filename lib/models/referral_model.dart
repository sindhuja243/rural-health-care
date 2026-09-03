import 'package:flutter/material.dart';

enum ReferralUrgency {
  routine,
  priority,
  emergency;

  String get label {
    switch (this) {
      case ReferralUrgency.routine:
        return 'Routine / सामान्य';
      case ReferralUrgency.priority:
        return 'Priority / प्राथमिकता';
      case ReferralUrgency.emergency:
        return 'Critical Emergency / आपातकालीन';
    }
  }

  Color get color {
    switch (this) {
      case ReferralUrgency.routine:
        return const Color(0xFF10B981);
      case ReferralUrgency.priority:
        return const Color(0xFFF59E0B);
      case ReferralUrgency.emergency:
        return const Color(0xFFEF4444);
    }
  }

  static ReferralUrgency fromString(String? urgency) {
    if (urgency == null) return ReferralUrgency.routine;
    switch (urgency.toLowerCase()) {
      case 'emergency':
      case 'critical':
        return ReferralUrgency.emergency;
      case 'priority':
      case 'high':
        return ReferralUrgency.priority;
      default:
        return ReferralUrgency.routine;
    }
  }
}

class ReferralModel {
  final String id;
  final String patientId;
  final String patientName;
  final int patientAge;
  final String patientGender;
  final String patientVillage;
  final String ashaWorkerId;
  final String ashaWorkerName;
  final String targetFacility; // e.g., 'Primary Health Centre (PHC)', 'District Civil Hospital'
  final ReferralUrgency urgency;
  final String reason;
  final String? vitalsSummary;
  final String status; // 'pending', 'accepted', 'completed', 'discharged'
  final DateTime createdAt;
  final String? clinicalNotes;

  const ReferralModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientAge,
    required this.patientGender,
    required this.patientVillage,
    required this.ashaWorkerId,
    required this.ashaWorkerName,
    required this.targetFacility,
    this.urgency = ReferralUrgency.routine,
    required this.reason,
    this.vitalsSummary,
    this.status = 'pending',
    required this.createdAt,
    this.clinicalNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientAge': patientAge,
      'patientGender': patientGender,
      'patientVillage': patientVillage,
      'ashaWorkerId': ashaWorkerId,
      'ashaWorkerName': ashaWorkerName,
      'targetFacility': targetFacility,
      'urgency': urgency.name,
      'reason': reason,
      'vitalsSummary': vitalsSummary,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'clinicalNotes': clinicalNotes,
    };
  }

  factory ReferralModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReferralModel(
      id: map['id'] as String? ?? docId,
      patientId: map['patientId'] as String? ?? '',
      patientName: map['patientName'] as String? ?? 'Patient',
      patientAge: map['patientAge'] as int? ?? 0,
      patientGender: map['patientGender'] as String? ?? 'Unspecified',
      patientVillage: map['patientVillage'] as String? ?? 'Village',
      ashaWorkerId: map['ashaWorkerId'] as String? ?? '',
      ashaWorkerName: map['ashaWorkerName'] as String? ?? 'ASHA Worker',
      targetFacility: map['targetFacility'] as String? ?? 'Primary Health Centre',
      urgency: ReferralUrgency.fromString(map['urgency'] as String?),
      reason: map['reason'] as String? ?? '',
      vitalsSummary: map['vitalsSummary'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      clinicalNotes: map['clinicalNotes'] as String?,
    );
  }
}
