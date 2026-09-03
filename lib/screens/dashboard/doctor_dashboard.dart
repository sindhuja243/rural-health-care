import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/appointment_model.dart';
import '../../models/referral_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/healthcare_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stat_card.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  List<AppointmentModel> _appointments = [];
  List<ReferralModel> _referrals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final appts = await FirestoreService().getAppointments();
    final refs = await FirestoreService().getReferrals();
    if (mounted) {
      setState(() {
        _appointments = appts;
        _referrals = refs;
        _isLoading = false;
      });
    }
  }

  void _showPrescriptionDialog(AppointmentModel appt) {
    final rxController = TextEditingController(text: 'Tab. Paracetamol 650mg TDS x 3 days\nTab. Cetirizine 10mg HS x 5 days');
    final diagnosisController = TextEditingController(text: 'Acute Upper Respiratory Tract Infection (URTI)');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.doctorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppTheme.doctorColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'E-Prescription: ${appt.patientName}\nगाँव: ${appt.village}',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: diagnosisController,
              decoration: InputDecoration(
                labelText: 'Clinical Diagnosis / निदान',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rxController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Prescribed Medicines & Dosage / दवाइयां व खुराक',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Sign & Send Digital Prescription',
              icon: Icons.check_circle_rounded,
              backgroundColor: AppTheme.doctorColor,
              onPressed: () {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📄 Digital Prescription sent to ${appt.patientName} & local PHC pharmacy!'),
                    backgroundColor: AppTheme.successMint,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: const HealthcareAppBar(
        title: 'Doctor Portal / चिकित्सक',
        subtitle: 'Dr. Anand Sharma, MD • Telemedicine Unit',
        role: UserRole.doctor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Tele-Clinic Status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.doctorColor.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Active Tele-Clinic Session',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Connected to 6 Rural PHC Sub-centers',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.successMint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('ONLINE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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
                      title: 'Queue',
                      value: '${_appointments.length}',
                      subtitle: 'Patients Waiting',
                      icon: Icons.video_call_rounded,
                      color: AppTheme.doctorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Urgent',
                      value: '${_referrals.length}',
                      subtitle: 'ASHA Referrals',
                      icon: Icons.emergency_rounded,
                      color: AppTheme.dangerCoral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tele-consultation Queue
              const Text(
                'Rural Patient Teleconsult Queue',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
              else
                ..._appointments.map((appt) => _buildConsultCard(appt)),

              const SizedBox(height: 24),

              // Urgent ASHA Referrals Section
              const Text(
                'Priority Referrals from ASHA Workers',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 10),

              ..._referrals.map((ref) => _buildReferralCard(ref)),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultCard(AppointmentModel appt) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.doctorColor.withValues(alpha: 0.12),
                    child: const Icon(Icons.person, color: AppTheme.doctorColor),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appt.patientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('${appt.village} • Ph: ${appt.patientPhone}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successMintLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Ready', style: TextStyle(color: AppTheme.successMint, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Symptoms: ${appt.chiefComplaints}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    foregroundColor: AppTheme.doctorColor,
                    side: const BorderSide(color: AppTheme.doctorColor),
                  ),
                  icon: const Icon(Icons.medication_rounded, size: 18),
                  label: const Text('E-Prescription'),
                  onPressed: () => _showPrescriptionDialog(appt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    minimumSize: const Size(0, 42),
                  ),
                  icon: const Icon(Icons.videocam_rounded, size: 18),
                  label: const Text('Start Call'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('📞 Connecting secure WebRTC video stream to ${appt.patientName}...')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(ReferralModel ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ref.urgency.color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ref.patientName} (${ref.patientAge}y, ${ref.patientGender})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ref.urgency.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ref.urgency.label.split('/')[0],
                  style: TextStyle(color: ref.urgency.color, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('By: ${ref.ashaWorkerName} • Village: ${ref.patientVillage}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text(ref.reason, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          if (ref.vitalsSummary != null) ...[
            const SizedBox(height: 6),
            Text('Vitals: ${ref.vitalsSummary!}', style: const TextStyle(fontSize: 12, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}
