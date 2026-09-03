import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/patient_model.dart';
import '../../models/referral_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/healthcare_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stat_card.dart';

class ASHAWorkerDashboard extends StatefulWidget {
  const ASHAWorkerDashboard({super.key});

  @override
  State<ASHAWorkerDashboard> createState() => _ASHAWorkerDashboardState();
}

class _ASHAWorkerDashboardState extends State<ASHAWorkerDashboard> {
  List<PatientModel> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  void _loadPatients() async {
    final list = await FirestoreService().getPatients();
    if (mounted) {
      setState(() {
        _patients = list;
        _isLoading = false;
      });
    }
  }

  void _showRegisterPatientDialog() {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    final phoneController = TextEditingController();
    final villageController = TextEditingController(text: 'Rampur Gram');
    final bpController = TextEditingController(text: '120/80');
    final spo2Controller = TextEditingController(text: '98');
    String selectedGender = 'Female';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Register Village Patient\nनया ग्रामीण मरीज जोड़ें',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name / पूरा नाम',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Age / उम्र',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender / लिंग',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        items: ['Female', 'Male', 'Other']
                            .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedGender = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Contact Phone / संपर्क नंबर',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: villageController,
                  decoration: InputDecoration(
                    labelText: 'Village / गाँव',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Initial Vitals (प्राथमिक जांच):', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bpController,
                        decoration: InputDecoration(
                          labelText: 'BP (e.g. 120/80)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: spo2Controller,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'SpO2 %',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Save Patient to Firestore',
                  icon: Icons.cloud_upload_rounded,
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) return;

                    final newPatient = PatientModel(
                      id: 'pat_${DateTime.now().millisecondsSinceEpoch}',
                      fullName: nameController.text.trim(),
                      age: int.tryParse(ageController.text.trim()) ?? 30,
                      gender: selectedGender,
                      village: villageController.text.trim(),
                      contactPhone: phoneController.text.trim(),
                      abhaId: '91-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}',
                      registeredByAshaId: 'asha_104',
                      registeredByAshaName: 'Sunita Devi',
                      registeredAt: DateTime.now(),
                      latestVitals: PatientVitals(
                        bloodPressure: bpController.text,
                        spo2: int.tryParse(spo2Controller.text) ?? 98,
                        recordedAt: DateTime.now(),
                      ),
                    );

                    await FirestoreService().addPatient(newPatient);
                    if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                    _loadPatients();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ ${newPatient.fullName} registered under Rampur ASHA!'),
                          backgroundColor: AppTheme.successMint,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateReferralDialog(PatientModel patient) {
    final reasonController = TextEditingController();
    String facility = 'Primary Health Centre (PHC) Rampur';
    ReferralUrgency urgency = ReferralUrgency.priority;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Refer Patient: ${patient.fullName}\nविशेषज्ञ को रेफर करें',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: facility,
                decoration: InputDecoration(
                  labelText: 'Target Facility / अस्पताल',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: [
                  'Primary Health Centre (PHC) Rampur',
                  'Community Health Centre (CHC) Shivpur',
                  'District Civil Hospital - Varanasi',
                  'Maternal Care & Delivery Unit',
                ].map((f) => DropdownMenuItem(value: f, child: Text(f, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => facility = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ReferralUrgency>(
                initialValue: urgency,
                decoration: InputDecoration(
                  labelText: 'Urgency Level / प्राथमिकता',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: ReferralUrgency.values
                    .map((u) => DropdownMenuItem(value: u, child: Text(u.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() => urgency = val);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Reason for Referral / लक्षण व कारण',
                  hintText: 'e.g. Chronic cough with weight loss, high risk ANC...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Submit Emergency Referral',
                icon: Icons.send_rounded,
                backgroundColor: urgency.color,
                onPressed: () async {
                  final newRef = ReferralModel(
                    id: 'ref_${DateTime.now().millisecondsSinceEpoch}',
                    patientId: patient.id,
                    patientName: patient.fullName,
                    patientAge: patient.age,
                    patientGender: patient.gender,
                    patientVillage: patient.village,
                    ashaWorkerId: 'asha_104',
                    ashaWorkerName: 'Sunita Devi (ASHA)',
                    targetFacility: facility,
                    urgency: urgency,
                    reason: reasonController.text.isNotEmpty
                        ? reasonController.text
                        : 'Referred by ASHA worker for clinical evaluation',
                    vitalsSummary: 'BP: ${patient.latestVitals?.bloodPressure ?? "120/80"}, SpO2: ${patient.latestVitals?.spo2 ?? 98}%',
                    createdAt: DateTime.now(),
                  );

                  await FirestoreService().createReferral(newRef);
                  if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🚨 Referral created for ${patient.fullName} at $facility'),
                        backgroundColor: AppTheme.successMint,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const HealthcareAppBar(
        title: 'ASHA Worker Portal',
        subtitle: 'Sunita Devi • Sector 4 Rampur',
        role: UserRole.ashaWorker,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ASHA Sync & Coverage Status Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryTeal, Color(0xFF0F766E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'आशा कार्यकर्ता डैशबोर्ड',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.cloud_done_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text('Cloud Synced', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Rampur Gram • 320 Households Assigned',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryTeal,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _showRegisterPatientDialog,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('+ Register New Village Patient', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Registered',
                      value: '${_patients.length + 84}',
                      subtitle: 'Village Patients',
                      icon: Icons.people_alt_rounded,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'High-Risk',
                      value: '14',
                      subtitle: 'ANC & Chronic',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.warningAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Patient Registry Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Village Patient Registry / मरीज सूची',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: _showRegisterPatientDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Patient'),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else
                ..._patients.map((p) => _buildPatientCard(p)),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard(PatientModel patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryTealLight,
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName.substring(0, 1) : 'P',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primaryTeal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.fullName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${patient.age} yrs • ${patient.gender} • ${patient.village}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(0, 36),
                  side: const BorderSide(color: AppTheme.dangerCoral),
                ),
                onPressed: () => _showCreateReferralDialog(patient),
                child: const Text('Refer', style: TextStyle(color: AppTheme.dangerCoral, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (patient.latestVitals != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('BP: ${patient.latestVitals!.bloodPressure ?? "120/80"}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('SpO2: ${patient.latestVitals!.spo2 ?? 98}%', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Sugar: ${patient.latestVitals!.bloodSugar?.toInt() ?? 110} mg', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
