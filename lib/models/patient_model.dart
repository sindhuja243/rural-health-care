class PatientVitals {
  final String? bloodPressure; // e.g., 120/80
  final int? pulseRate; // e.g., 72 bpm
  final int? spo2; // e.g., 98 %
  final double? bloodSugar; // e.g., 110 mg/dL
  final double? temperature; // e.g., 98.6 F
  final DateTime? recordedAt;

  const PatientVitals({
    this.bloodPressure,
    this.pulseRate,
    this.spo2,
    this.bloodSugar,
    this.temperature,
    this.recordedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'bloodPressure': bloodPressure,
      'pulseRate': pulseRate,
      'spo2': spo2,
      'bloodSugar': bloodSugar,
      'temperature': temperature,
      'recordedAt': recordedAt?.toIso8601String(),
    };
  }

  factory PatientVitals.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PatientVitals();
    return PatientVitals(
      bloodPressure: map['bloodPressure'] as String?,
      pulseRate: map['pulseRate'] as int?,
      spo2: map['spo2'] as int?,
      bloodSugar: (map['bloodSugar'] as num?)?.toDouble(),
      temperature: (map['temperature'] as num?)?.toDouble(),
      recordedAt: map['recordedAt'] != null
          ? DateTime.tryParse(map['recordedAt'] as String)
          : null,
    );
  }
}

class PatientModel {
  final String id;
  final String fullName;
  final int age;
  final String gender; // Male, Female, Other
  final String village;
  final String district;
  final String contactPhone;
  final String? abhaId; // Ayushman Bharat Health Account / ID
  final String? bloodGroup;
  final String? emergencyContact;
  final List<String> chronicConditions;
  final PatientVitals? latestVitals;
  final String? registeredByAshaId;
  final String? registeredByAshaName;
  final DateTime registeredAt;

  const PatientModel({
    required this.id,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.village,
    this.district = 'Rampur',
    required this.contactPhone,
    this.abhaId,
    this.bloodGroup,
    this.emergencyContact,
    this.chronicConditions = const [],
    this.latestVitals,
    this.registeredByAshaId,
    this.registeredByAshaName,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'age': age,
      'gender': gender,
      'village': village,
      'district': district,
      'contactPhone': contactPhone,
      'abhaId': abhaId,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'chronicConditions': chronicConditions,
      'latestVitals': latestVitals?.toMap(),
      'registeredByAshaId': registeredByAshaId,
      'registeredByAshaName': registeredByAshaName,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }

  factory PatientModel.fromMap(Map<String, dynamic> map, String docId) {
    return PatientModel(
      id: map['id'] as String? ?? docId,
      fullName: map['fullName'] as String? ?? 'Unknown Patient',
      age: map['age'] as int? ?? 0,
      gender: map['gender'] as String? ?? 'Unspecified',
      village: map['village'] as String? ?? 'Rural Village',
      district: map['district'] as String? ?? 'Rampur',
      contactPhone: map['contactPhone'] as String? ?? '',
      abhaId: map['abhaId'] as String?,
      bloodGroup: map['bloodGroup'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      latestVitals: map['latestVitals'] != null
          ? PatientVitals.fromMap(map['latestVitals'] as Map<String, dynamic>?)
          : null,
      registeredByAshaId: map['registeredByAshaId'] as String?,
      registeredByAshaName: map['registeredByAshaName'] as String?,
      registeredAt: map['registeredAt'] != null
          ? DateTime.tryParse(map['registeredAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
