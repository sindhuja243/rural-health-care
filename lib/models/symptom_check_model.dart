import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomCheckModel {
  final String id;
  final String symptomsText;
  final String severity; // 'low' or 'high'
  final String possibleCondition;
  final String? remedy;
  final DateTime timestamp;

  SymptomCheckModel({
    required this.id,
    required this.symptomsText,
    required this.severity,
    required this.possibleCondition,
    this.remedy,
    required this.timestamp,
  });

  bool get isHighSeverity => severity.toLowerCase() == 'high';
  bool get isLowSeverity => severity.toLowerCase() == 'low';

  Map<String, dynamic> toMap() {
    return {
      'symptomsText': symptomsText,
      'severity': severity,
      'possibleCondition': possibleCondition,
      'remedy': remedy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory SymptomCheckModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedTime = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTime = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    }

    return SymptomCheckModel(
      id: id,
      symptomsText: map['symptomsText'] ?? '',
      severity: (map['severity'] ?? 'low').toString().toLowerCase(),
      possibleCondition: map['possibleCondition'] ?? 'Medical Condition',
      remedy: map['remedy'],
      timestamp: parsedTime,
    );
  }
}
