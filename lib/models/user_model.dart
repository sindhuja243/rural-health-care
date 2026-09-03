import 'package:flutter/material.dart';

enum UserRole {
  patient,
  ashaWorker,
  doctor,
  admin;

  String get id {
    switch (this) {
      case UserRole.patient:
        return 'patient';
      case UserRole.ashaWorker:
        return 'asha_worker';
      case UserRole.doctor:
        return 'doctor';
      case UserRole.admin:
        return 'admin';
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.patient:
        return 'Patient / नागरिक';
      case UserRole.ashaWorker:
        return 'ASHA Worker / आशा कार्यकर्ता';
      case UserRole.doctor:
        return 'Doctor / डॉक्टर';
      case UserRole.admin:
        return 'Admin / प्रशासक';
    }
  }

  String get englishTitle {
    switch (this) {
      case UserRole.patient:
        return 'Patient';
      case UserRole.ashaWorker:
        return 'ASHA Worker';
      case UserRole.doctor:
        return 'Doctor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get subtitle {
    switch (this) {
      case UserRole.patient:
        return 'Book doctor consultations, access health cards & digital prescriptions';
      case UserRole.ashaWorker:
        return 'Register village patients, record vitals, surveys & emergency referrals';
      case UserRole.doctor:
        return 'Conduct tele-consultations, verify referrals & issue digital prescriptions';
      case UserRole.admin:
        return 'Monitor district health stats, worker coverage & healthcare resources';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.patient:
        return Icons.person_rounded;
      case UserRole.ashaWorker:
        return Icons.medical_services_rounded; // Medical bag / health worker
      case UserRole.doctor:
        return Icons.health_and_safety_rounded; // Stethoscope / Doctor
      case UserRole.admin:
        return Icons.dashboard_customize_rounded; // Admin Dashboard
    }
  }

  Color get color {
    switch (this) {
      case UserRole.patient:
        return const Color(0xFF0284C7); // Sky Blue
      case UserRole.ashaWorker:
        return const Color(0xFF0D9488); // Teal
      case UserRole.doctor:
        return const Color(0xFF7C3AED); // Royal Purple
      case UserRole.admin:
        return const Color(0xFFD97706); // Warm Amber
    }
  }

  static UserRole fromString(String? roleStr) {
    if (roleStr == null) return UserRole.patient;
    switch (roleStr.toLowerCase()) {
      case 'patient':
        return UserRole.patient;
      case 'asha_worker':
      case 'ashaworker':
      case 'asha':
        return UserRole.ashaWorker;
      case 'doctor':
        return UserRole.doctor;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }
}

class UserModel {
  final String uid;
  final String phoneNumber;
  final UserRole role;
  final String? displayName;
  final String? village;
  final String? district;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isProfileComplete;

  const UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.role,
    this.displayName,
    this.village,
    this.district,
    required this.createdAt,
    required this.updatedAt,
    this.isProfileComplete = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'role': role.id,
      'displayName': displayName ?? '',
      'village': village ?? '',
      'district': district ?? '',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isProfileComplete': isProfileComplete,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid'] as String? ?? documentId,
      phoneNumber: map['phoneNumber'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      displayName: map['displayName'] as String?,
      village: map['village'] as String?,
      district: map['district'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isProfileComplete: map['isProfileComplete'] as bool? ?? true,
    );
  }

  UserModel copyWith({
    String? uid,
    String? phoneNumber,
    UserRole? role,
    String? displayName,
    String? village,
    String? district,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isProfileComplete,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      village: village ?? this.village,
      district: district ?? this.district,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
    );
  }
}
