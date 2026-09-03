import 'package:flutter/material.dart';

enum AppointmentStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case AppointmentStatus.pending:
        return 'Pending Review';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case AppointmentStatus.pending:
        return const Color(0xFFF59E0B);
      case AppointmentStatus.confirmed:
        return const Color(0xFF0284C7);
      case AppointmentStatus.inProgress:
        return const Color(0xFF7C3AED);
      case AppointmentStatus.completed:
        return const Color(0xFF10B981);
      case AppointmentStatus.cancelled:
        return const Color(0xFFEF4444);
    }
  }

  static AppointmentStatus fromString(String? status) {
    if (status == null) return AppointmentStatus.pending;
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'inprogress':
      case 'in_progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      default:
        return AppointmentStatus.pending;
    }
  }
}

class AppointmentModel {
  final String id;
  final String patientId;
  final String patientName;
  final String patientPhone;
  final String village;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? ashaWorkerId;
  final String? ashaWorkerName;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String chiefComplaints;
  final String? diagnosis;
  final String? prescriptionNotes;
  final List<String> prescribedMedicines;
  final bool isTeleconsult;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.patientPhone,
    required this.village,
    required this.doctorId,
    required this.doctorName,
    this.doctorSpecialty = 'General Physician / ग्रामीण चिकित्सक',
    this.ashaWorkerId,
    this.ashaWorkerName,
    required this.scheduledAt,
    this.status = AppointmentStatus.pending,
    required this.chiefComplaints,
    this.diagnosis,
    this.prescriptionNotes,
    this.prescribedMedicines = const [],
    this.isTeleconsult = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'patientPhone': patientPhone,
      'village': village,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpecialty': doctorSpecialty,
      'ashaWorkerId': ashaWorkerId,
      'ashaWorkerName': ashaWorkerName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'status': status.name,
      'chiefComplaints': chiefComplaints,
      'diagnosis': diagnosis,
      'prescriptionNotes': prescriptionNotes,
      'prescribedMedicines': prescribedMedicines,
      'isTeleconsult': isTeleconsult,
    };
  }

  factory AppointmentModel.fromMap(Map<String, dynamic> map, String docId) {
    return AppointmentModel(
      id: map['id'] as String? ?? docId,
      patientId: map['patientId'] as String? ?? '',
      patientName: map['patientName'] as String? ?? 'Patient',
      patientPhone: map['patientPhone'] as String? ?? '',
      village: map['village'] as String? ?? '',
      doctorId: map['doctorId'] as String? ?? '',
      doctorName: map['doctorName'] as String? ?? 'Dr. Specialist',
      doctorSpecialty: map['doctorSpecialty'] as String? ?? 'General Physician',
      ashaWorkerId: map['ashaWorkerId'] as String?,
      ashaWorkerName: map['ashaWorkerName'] as String?,
      scheduledAt: map['scheduledAt'] != null
          ? DateTime.tryParse(map['scheduledAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: AppointmentStatus.fromString(map['status'] as String?),
      chiefComplaints: map['chiefComplaints'] as String? ?? '',
      diagnosis: map['diagnosis'] as String?,
      prescriptionNotes: map['prescriptionNotes'] as String?,
      prescribedMedicines: List<String>.from(map['prescribedMedicines'] ?? []),
      isTeleconsult: map['isTeleconsult'] as bool? ?? true,
    );
  }
}
