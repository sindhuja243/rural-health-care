import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/patient_model.dart';
import '../models/appointment_model.dart';
import '../models/referral_model.dart';
import '../models/hospital_model.dart';
import 'firebase_service.dart';
import 'location_service.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initSampleData();
  }

  final FirebaseFirestore? _firestore =
      FirebaseService.isInitialized ? FirebaseFirestore.instance : null;

  // In-Memory fallback store for demo/offline test runs
  final Map<String, UserModel> _usersStore = {};
  final Map<String, PatientModel> _patientsStore = {};
  final Map<String, AppointmentModel> _appointmentsStore = {};
  final Map<String, ReferralModel> _referralsStore = {};
  final Map<String, HospitalModel> _hospitalsStore = {};

  // Initialize sample data for realistic healthcare presentation
  void _initSampleData() {
    final samplePatients = [
      PatientModel(
        id: 'pat_101',
        fullName: 'Ram Prasad',
        age: 58,
        gender: 'Male',
        village: 'Rampur',
        district: 'Vizianagaram',
        contactPhone: '+91 98765 43210',
        abhaId: '91-4523-8812-9901',
        bloodGroup: 'B+',
        emergencyContact: '+91 98765 43211',
        chronicConditions: ['Hypertension', 'Type-2 Diabetes'],
        latestVitals: PatientVitals(
          bloodPressure: '142/90',
          pulseRate: 78,
          spo2: 97,
          bloodSugar: 165.0,
          temperature: 98.4,
          recordedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        registeredByAshaId: 'asha_104',
        registeredByAshaName: 'Sunita Devi',
        registeredAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      PatientModel(
        id: 'pat_102',
        fullName: 'Meena Kumari',
        age: 26,
        gender: 'Female',
        village: 'Shivpur',
        district: 'Vizianagaram',
        contactPhone: '+91 98765 11223',
        abhaId: '91-8834-1192-3342',
        bloodGroup: 'O+',
        emergencyContact: '+91 98765 11224',
        chronicConditions: ['Anemia (Mild)', 'Pregnancy - 2nd Trimester'],
        latestVitals: PatientVitals(
          bloodPressure: '118/76',
          pulseRate: 82,
          spo2: 99,
          bloodSugar: 92.0,
          temperature: 98.6,
          recordedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        registeredByAshaId: 'asha_104',
        registeredByAshaName: 'Sunita Devi',
        registeredAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      PatientModel(
        id: 'pat_103',
        fullName: 'Gopal Yadav',
        age: 71,
        gender: 'Male',
        village: 'Kalyanpur',
        district: 'Vizianagaram',
        contactPhone: '+91 98765 99887',
        abhaId: '91-6677-2234-5541',
        bloodGroup: 'A+',
        emergencyContact: '+91 98765 99888',
        chronicConditions: ['COPD / Respiratory distress', 'Arthritis'],
        latestVitals: PatientVitals(
          bloodPressure: '135/88',
          pulseRate: 92,
          spo2: 93,
          bloodSugar: 120.0,
          temperature: 99.2,
          recordedAt: DateTime.now().subtract(const Duration(hours: 6)),
        ),
        registeredByAshaId: 'asha_104',
        registeredByAshaName: 'Sunita Devi',
        registeredAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ];

    for (var p in samplePatients) {
      _patientsStore[p.id] = p;
    }

    final sampleAppts = [
      AppointmentModel(
        id: 'apt_201',
        patientId: 'pat_101',
        patientName: 'Ram Prasad',
        patientPhone: '+91 98765 43210',
        village: 'Rampur',
        doctorId: 'doc_501',
        doctorName: 'Dr. Anand Sharma',
        doctorSpecialty: 'Cardiology & General Medicine',
        ashaWorkerId: 'asha_104',
        ashaWorkerName: 'Sunita Devi',
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        status: AppointmentStatus.confirmed,
        chiefComplaints: 'High blood pressure readings, occasional dizziness while working on farm',
        prescribedMedicines: ['Amlodipine 5mg', 'Metformin 500mg'],
        isTeleconsult: true,
      ),
      AppointmentModel(
        id: 'apt_202',
        patientId: 'pat_102',
        patientName: 'Meena Kumari',
        patientPhone: '+91 98765 11223',
        village: 'Shivpur',
        doctorId: 'doc_501',
        doctorName: 'Dr. Anand Sharma',
        doctorSpecialty: 'Maternal & Child Health',
        ashaWorkerId: 'asha_104',
        ashaWorkerName: 'Sunita Devi',
        scheduledAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
        status: AppointmentStatus.pending,
        chiefComplaints: 'Routine ANC checkup, Iron & Folic acid supplement review',
        isTeleconsult: true,
      ),
    ];

    for (var a in sampleAppts) {
      _appointmentsStore[a.id] = a;
    }

    final sampleRefs = [
      ReferralModel(
        id: 'ref_301',
        patientId: 'pat_103',
        patientName: 'Gopal Yadav',
        patientAge: 71,
        patientGender: 'Male',
        patientVillage: 'Kalyanpur',
        ashaWorkerId: 'asha_104',
        ashaWorkerName: 'Sunita Devi (ASHA)',
        targetFacility: 'District Hospital, Vizianagaram - Pulmonology Unit',
        urgency: ReferralUrgency.priority,
        reason: 'Persistent SpO2 drop to 93% and severe chest wheezing not resolving with local nebulizer.',
        vitalsSummary: 'SpO2: 93%, BP: 135/88, Pulse: 92 bpm, Temp: 99.2 F',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
    ];

    for (var r in sampleRefs) {
      _referralsStore[r.id] = r;
    }

    // Sample Hospitals near Vizianagaram, Andhra Pradesh (with realistic coordinates)
    final sampleHospitals = [
      HospitalModel(
        id: 'hosp_ggh_vzm',
        name: 'Government General Hospital (GGH) Vizianagaram',
        latitude: 18.1171,
        longitude: 83.4072,
        address: 'Cantonment Road, Near RTC Complex, Vizianagaram, AP 535003',
        specialists: [
          'General Medicine',
          'Emergency Medicine',
          'Cardiology',
          'Pediatrics',
          'Obstetrics & Gynecology',
          'Orthopedics'
        ],
        contactNumber: '+91 8922 222108',
      ),
      HospitalModel(
        id: 'hosp_tirumala_vzm',
        name: 'Tirumala Multi-Speciality Hospital',
        latitude: 18.1065,
        longitude: 83.3948,
        address: 'Opp. Collector Office, Mayuri Junction, Vizianagaram, AP 535002',
        specialists: [
          'Cardiology',
          'Pulmonology',
          'General Surgery',
          'Critical Care',
          'General Medicine'
        ],
        contactNumber: '+91 8922 277999',
      ),
      HospitalModel(
        id: 'hosp_mims_nellimarla',
        name: 'Maharajah Institute of Medical Sciences (MIMS Hospital)',
        latitude: 18.0645,
        longitude: 83.4735,
        address: 'Nellimarla, Near Highway Junction, Vizianagaram District, AP 535217',
        specialists: [
          'Cardiology',
          'Neurology',
          'Obstetrics & Gynecology',
          'Pediatrics',
          'Orthopedics',
          'Emergency Medicine'
        ],
        contactNumber: '+91 8922 244555',
      ),
      HospitalModel(
        id: 'hosp_chc_gajapathinagaram',
        name: 'Community Health Centre (CHC) Gajapathinagaram',
        latitude: 18.2785,
        longitude: 83.3325,
        address: 'Main Road, Gajapathinagaram, Vizianagaram District, AP 535270',
        specialists: [
          'General Medicine',
          'Pediatrics',
          'Maternal Health',
          'Emergency Care'
        ],
        contactNumber: '+91 8922 284108',
      ),
      HospitalModel(
        id: 'hosp_phc_denkada',
        name: 'Primary Health Centre (PHC) Denkada',
        latitude: 18.0480,
        longitude: 83.4410,
        address: 'Denkada Gramam, Near Mandal Office, Vizianagaram, AP 535005',
        specialists: [
          'General Medicine',
          'Primary Care',
          'Maternal & Child Health'
        ],
        contactNumber: '+91 8922 231102',
      ),
      HospitalModel(
        id: 'hosp_lifeline_trauma',
        name: 'Lifeline Emergency & Trauma Care Centre',
        latitude: 18.1130,
        longitude: 83.4012,
        address: 'Station Road, Near Railway Junction, Vizianagaram, AP 535001',
        specialists: [
          'Emergency Medicine',
          'Cardiology',
          'Trauma & Orthopedics'
        ],
        contactNumber: '+91 8922 225108',
      ),
    ];

    for (var h in sampleHospitals) {
      _hospitalsStore[h.id] = h;
    }
  }

  // ================= USERS COLLECTION =================

  /// Save user role and phone to Firestore `/users/{uid}` with strict 15s timeout & full error logging
  Future<void> saveUserRole({
    required String uid,
    required String phoneNumber,
    required UserRole role,
    String? displayName,
    String? village,
    String? district,
  }) async {
    final user = UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      role: role,
      displayName: displayName ?? _getDefaultNameForRole(role),
      village: village ?? 'Rampur Gram',
      district: district ?? 'Vizianagaram',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isProfileComplete: true,
    );

    _usersStore[uid] = user;

    debugPrint('====================================================');
    debugPrint('[FirestoreService] saveUserRole initiating write:');
    debugPrint('Target UID: "$uid"');
    debugPrint('Selected Role: "${role.id}" (${role.displayName})');
    debugPrint('Phone Number: "$phoneNumber"');
    debugPrint('Document Path: "users/$uid"');
    debugPrint('====================================================');

    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        await firestore
            .collection('users')
            .doc(uid)
            .set(user.toMap(), SetOptions(merge: true))
            .timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('[FirestoreService] Cloud Firestore write timed out (5s) for UID: $uid. Falling back gracefully to local session.');
              },
            );

        debugPrint('[FirestoreService] Successfully written user role (${role.id}) to Firestore for UID: $uid');
      } on FirebaseException catch (e) {
        debugPrint('====================================================');
        debugPrint('[FirestoreService FirebaseException] Code: [${e.code}]');
        debugPrint('Message: "${e.message}"');
        debugPrint('Using local offline user session.');
        debugPrint('====================================================');
      } catch (e) {
        debugPrint('====================================================');
        debugPrint('[FirestoreService Notice] $e');
        debugPrint('Using local offline user session.');
        debugPrint('====================================================');
      }
    }
  }

  String _getDefaultNameForRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'Ramesh Kumar (Patient)';
      case UserRole.ashaWorker:
        return 'Sunita Devi (ASHA Worker)';
      case UserRole.doctor:
        return 'Dr. Anand Sharma, MD';
      case UserRole.admin:
        return 'District Health Officer (Admin)';
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        final doc = await firestore
            .collection('users')
            .doc(uid)
            .get()
            .timeout(const Duration(seconds: 10));
        if (doc.exists && doc.data() != null) {
          return UserModel.fromMap(doc.data()!, doc.id);
        }
      } catch (e) {
        debugPrint('[FirestoreService] getUser notice: $e');
      }
    }
    return _usersStore[uid];
  }

  // ================= HOSPITALS COLLECTION =================

  /// Fetches all hospitals from Firestore `/hospitals` collection.
  /// If `userLocation` is provided, calculates distances and sorts nearest-first.
  Future<List<HospitalModel>> getHospitals({Position? userLocation}) async {
    List<HospitalModel> hospitals = [];
    final firestore = _firestore;

    if (FirebaseService.isInitialized && firestore != null) {
      try {
        final snapshot = await firestore
            .collection('hospitals')
            .get()
            .timeout(const Duration(seconds: 10));

        if (snapshot.docs.isNotEmpty) {
          hospitals = snapshot.docs
              .map((doc) => HospitalModel.fromMap(doc.data(), doc.id))
              .toList();
          debugPrint('[FirestoreService] Loaded ${hospitals.length} hospitals from Cloud Firestore.');
        } else {
          // If Firestore collection is empty, seed with Vizianagaram sample hospitals
          debugPrint('[FirestoreService] Empty hospitals collection in Firestore. Seeding sample hospitals...');
          await seedSampleHospitals();
          hospitals = _hospitalsStore.values.toList();
        }
      } catch (e) {
        debugPrint('[FirestoreService] getHospitals Firestore notice: $e');
        hospitals = _hospitalsStore.values.toList();
      }
    } else {
      hospitals = _hospitalsStore.values.toList();
    }

    if (hospitals.isEmpty) {
      hospitals = _hospitalsStore.values.toList();
    }

    // Calculate distance and sort if user location is available
    final loc = userLocation ?? LocationService().currentPosition;
    if (loc != null) {
      final updatedHospitals = hospitals.map((h) {
        final dist = LocationService().calculateDistanceInKm(
          hospitalLat: h.latitude,
          hospitalLon: h.longitude,
          userLat: loc.latitude,
          userLon: loc.longitude,
        );
        return h.copyWith(distanceInKm: dist);
      }).toList();

      // Sort nearest first (ascending)
      updatedHospitals.sort((a, b) {
        final distA = a.distanceInKm ?? 999999.0;
        final distB = b.distanceInKm ?? 999999.0;
        return distA.compareTo(distB);
      });

      return updatedHospitals;
    }

    return hospitals;
  }

  /// Seeds sample hospitals near Vizianagaram to Firestore `/hospitals`
  Future<void> seedSampleHospitals() async {
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        final batch = firestore.batch();
        for (var h in _hospitalsStore.values) {
          final docRef = firestore.collection('hospitals').doc(h.id);
          batch.set(docRef, h.toMap(), SetOptions(merge: true));
        }
        await batch.commit();
        debugPrint('[FirestoreService] Successfully seeded 6 Vizianagaram hospitals to Firestore.');
      } catch (e) {
        debugPrint('[FirestoreService] seedSampleHospitals notice: $e');
      }
    }
  }

  // ================= PATIENTS COLLECTION =================

  Future<void> addPatient(PatientModel patient) async {
    _patientsStore[patient.id] = patient;
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        await firestore
            .collection('patients')
            .doc(patient.id)
            .set(patient.toMap())
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('[FirestoreService] addPatient notice: $e');
      }
    }
  }

  Future<List<PatientModel>> getPatients() async {
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        final query = await firestore
            .collection('patients')
            .get()
            .timeout(const Duration(seconds: 15));
        if (query.docs.isNotEmpty) {
          return query.docs.map((d) => PatientModel.fromMap(d.data(), d.id)).toList();
        }
      } catch (e) {
        debugPrint('[FirestoreService] getPatients notice: $e');
      }
    }
    return _patientsStore.values.toList();
  }

  // ================= APPOINTMENTS COLLECTION =================

  Future<void> createAppointment(AppointmentModel appointment) async {
    _appointmentsStore[appointment.id] = appointment;
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        await firestore
            .collection('appointments')
            .doc(appointment.id)
            .set(appointment.toMap())
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('[FirestoreService] createAppointment notice: $e');
      }
    }
  }

  Future<List<AppointmentModel>> getAppointments() async {
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        final query = await firestore
            .collection('appointments')
            .get()
            .timeout(const Duration(seconds: 15));
        if (query.docs.isNotEmpty) {
          return query.docs.map((d) => AppointmentModel.fromMap(d.data(), d.id)).toList();
        }
      } catch (e) {
        debugPrint('[FirestoreService] getAppointments notice: $e');
      }
    }
    return _appointmentsStore.values.toList();
  }

  // ================= REFERRALS COLLECTION =================

  Future<void> createReferral(ReferralModel referral) async {
    _referralsStore[referral.id] = referral;
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        await firestore
            .collection('referrals')
            .doc(referral.id)
            .set(referral.toMap())
            .timeout(const Duration(seconds: 15));
      } catch (e) {
        debugPrint('[FirestoreService] createReferral notice: $e');
      }
    }
  }

  Future<List<ReferralModel>> getReferrals() async {
    final firestore = _firestore;
    if (FirebaseService.isInitialized && firestore != null) {
      try {
        final query = await firestore
            .collection('referrals')
            .get()
            .timeout(const Duration(seconds: 15));
        if (query.docs.isNotEmpty) {
          return query.docs.map((d) => ReferralModel.fromMap(d.data(), d.id)).toList();
        }
      } catch (e) {
        debugPrint('[FirestoreService] getReferrals notice: $e');
      }
    }
    return _referralsStore.values.toList();
  }

  // District Metrics for Admin Dashboard
  Future<Map<String, dynamic>> getDistrictMetrics() async {
    final patients = await getPatients();
    final appointments = await getAppointments();
    final referrals = await getReferrals();

    return {
      'totalPatients': patients.length + 1420,
      'activeAshaWorkers': 48,
      'teleconsultsCompleted': appointments.length + 328,
      'pendingReferrals': referrals.where((r) => r.status == 'pending').length + 12,
      'villagesCovered': 24,
      'phcUnitsOperational': 6,
    };
  }
}
