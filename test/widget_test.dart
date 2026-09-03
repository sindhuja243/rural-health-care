import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rural_healthcare_app/main.dart';
import 'package:rural_healthcare_app/models/user_model.dart';
import 'package:rural_healthcare_app/models/patient_model.dart';
import 'package:rural_healthcare_app/models/appointment_model.dart';
import 'package:rural_healthcare_app/models/referral_model.dart';
import 'package:rural_healthcare_app/models/symptom_check_model.dart';
import 'package:rural_healthcare_app/models/hospital_model.dart';
import 'package:rural_healthcare_app/screens/auth/phone_login_screen.dart';
import 'package:rural_healthcare_app/screens/auth/otp_verification_screen.dart';
import 'package:rural_healthcare_app/screens/role_selection/role_selection_screen.dart';
import 'package:rural_healthcare_app/screens/symptom_checker/symptom_checker_screen.dart';
import 'package:rural_healthcare_app/screens/hospital/find_hospital_screen.dart';
import 'package:rural_healthcare_app/widgets/role_card.dart';

void main() {
  group('Rural Healthcare Data Models Test', () {
    test('UserModel serialization and role mapping', () {
      final user = UserModel(
        uid: 'user_test_123',
        phoneNumber: '+91 98765 43210',
        role: UserRole.ashaWorker,
        displayName: 'Sunita Devi',
        village: 'Rampur',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final map = user.toMap();
      expect(map['uid'], 'user_test_123');
      expect(map['role'], 'asha_worker');

      final fromMap = UserModel.fromMap(map, 'user_test_123');
      expect(fromMap.role, UserRole.ashaWorker);
      expect(fromMap.displayName, 'Sunita Devi');
    });

    test('PatientModel and Vitals mapping', () {
      final patient = PatientModel(
        id: 'pat_test_1',
        fullName: 'Ram Prasad',
        age: 58,
        gender: 'Male',
        village: 'Rampur',
        contactPhone: '+91 98765 43210',
        latestVitals: const PatientVitals(
          bloodPressure: '140/90',
          spo2: 97,
        ),
        registeredAt: DateTime(2026, 1, 1),
      );

      final map = patient.toMap();
      expect(map['fullName'], 'Ram Prasad');
      expect(map['latestVitals']['bloodPressure'], '140/90');

      final fromMap = PatientModel.fromMap(map, 'pat_test_1');
      expect(fromMap.fullName, 'Ram Prasad');
      expect(fromMap.latestVitals?.spo2, 97);
    });

    test('AppointmentModel mapping', () {
      final appt = AppointmentModel(
        id: 'apt_test_1',
        patientId: 'pat_101',
        patientName: 'Ram Prasad',
        patientPhone: '+91 98765 43210',
        village: 'Rampur',
        doctorId: 'doc_501',
        doctorName: 'Dr. Anand Sharma',
        scheduledAt: DateTime(2026, 9, 3, 10, 0),
        status: AppointmentStatus.confirmed,
        chiefComplaints: 'Fever and headache',
      );

      final map = appt.toMap();
      expect(map['status'], 'confirmed');
      expect(map['doctorName'], 'Dr. Anand Sharma');
    });

    test('ReferralModel mapping', () {
      final ref = ReferralModel(
        id: 'ref_test_1',
        patientId: 'pat_101',
        patientName: 'Gopal Yadav',
        patientAge: 71,
        patientGender: 'Male',
        patientVillage: 'Kalyanpur',
        ashaWorkerId: 'asha_104',
        ashaWorkerName: 'Sunita Devi',
        targetFacility: 'District Hospital',
        urgency: ReferralUrgency.emergency,
        reason: 'Low SpO2 and shortness of breath',
        createdAt: DateTime(2026, 9, 3),
      );

      final map = ref.toMap();
      expect(map['urgency'], 'emergency');
      expect(map['targetFacility'], 'District Hospital');
    });

    test('SymptomCheckModel mapping and severity predicates', () {
      final lowCheck = SymptomCheckModel(
        id: 'chk_101',
        symptomsText: 'Mild cold and cough / జలుబు',
        severity: 'low',
        possibleCondition: 'Common Cold',
        remedy: 'Drink ginger tulsi tea / తులసి టీ',
        timestamp: DateTime(2026, 9, 3),
      );

      expect(lowCheck.isLowSeverity, isTrue);
      expect(lowCheck.isHighSeverity, isFalse);

      final map = lowCheck.toMap();
      expect(map['severity'], 'low');
      expect(map['possibleCondition'], 'Common Cold');
    });

    test('HospitalModel serialization and distance mapping', () {
      final hospital = HospitalModel(
        id: 'hosp_ggh',
        name: 'Government General Hospital Vizianagaram',
        latitude: 18.1171,
        longitude: 83.4072,
        address: 'Cantonment Road, Vizianagaram',
        specialists: ['Cardiology', 'General Medicine', 'Pediatrics'],
        contactNumber: '+91 8922 222108',
        distanceInKm: 2.4,
      );

      expect(hospital.name, 'Government General Hospital Vizianagaram');
      expect(hospital.specialists.contains('Cardiology'), isTrue);
      expect(hospital.distanceInKm, 2.4);

      final map = hospital.toMap();
      expect(map['latitude'], 18.1171);
      expect(map['longitude'], 83.4072);

      final fromMap = HospitalModel.fromMap(map, 'hosp_ggh');
      expect(fromMap.name, 'Government General Hospital Vizianagaram');
      expect(fromMap.specialists.length, 3);
    });
  });

  group('UI Widgets Rendering Test', () {
    testWidgets('App renders PhoneLoginScreen on startup without bypass buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const RuralHealthcareApp());
      await tester.pumpAndSettle();

      expect(find.text('Gramin Seva Health'), findsOneWidget);
      expect(find.byType(PhoneLoginScreen), findsOneWidget);
      expect(find.text('Get OTP / ओटीपी प्राप्त करें'), findsOneWidget);
      expect(find.textContaining('Hackathon Mode'), findsNothing);
      expect(find.textContaining('Quick Demo Access'), findsNothing);
    });

    testWidgets('OtpVerificationScreen renders 6 input boxes and cooldown timer', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OtpVerificationScreen(
            phoneNumber: '9876543210',
            verificationId: 'test-verification-id',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Enter 6-Digit OTP'), findsOneWidget);
      expect(find.textContaining('9876543210'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6));
      expect(find.text('Verify & Proceed / सत्यापन करें'), findsOneWidget);
      expect(find.textContaining('Resend OTP in'), findsOneWidget);
    });

    testWidgets('RoleSelectionScreen displays all 4 healthcare roles', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RoleSelectionScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RoleCard), findsNWidgets(4));
      expect(find.textContaining('Patient'), findsWidgets);
      expect(find.textContaining('ASHA Worker'), findsWidgets);
      expect(find.textContaining('Doctor'), findsWidgets);
      expect(find.textContaining('Admin'), findsWidgets);
    });

    testWidgets('SymptomCheckerScreen renders input, examples and analyze button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SymptomCheckerScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI Symptom Checker / లక్షణాల తనిఖీ'), findsOneWidget);
      expect(find.text('Describe Symptoms / మీ లక్షణాలు చెప్పండి'), findsOneWidget);
      expect(find.text('Analyze Symptoms / లక్షణాలను విశ్లేషించండి'), findsOneWidget);
      expect(find.textContaining('Mild Cold & Cough'), findsOneWidget);
      expect(find.textContaining('Severe Chest Pain'), findsOneWidget);
    });

    testWidgets('FindHospitalScreen renders hospital list and search bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FindHospitalScreen(conditionHint: 'Potential Cardiac / Respiratory Distress'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Find Hospital / ఆసుపత్రులు'), findsOneWidget);
      expect(find.textContaining('All Hospitals'), findsOneWidget);
      expect(find.textContaining('Government General Hospital'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
