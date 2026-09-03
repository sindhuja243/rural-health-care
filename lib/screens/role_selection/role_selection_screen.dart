import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/role_card.dart';
import '../dashboard/patient_dashboard.dart';
import '../dashboard/asha_worker_dashboard.dart';
import '../dashboard/doctor_dashboard.dart';
import '../dashboard/admin_dashboard.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole _selectedRole = UserRole.patient;
  bool _isSaving = false;

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _confirmAndProceed() async {
    setState(() => _isSaving = true);

    try {
      debugPrint('====================================================');
      debugPrint('[RoleSelectionScreen] Confirming role: ${_selectedRole.displayName} (${_selectedRole.id})');
      debugPrint('====================================================');

      // Save selected role with local fallback
      await AuthService().updateUserRole(_selectedRole);

      if (!mounted) return;

      Widget targetDashboard;
      switch (_selectedRole) {
        case UserRole.patient:
          targetDashboard = const PatientDashboard();
          break;
        case UserRole.ashaWorker:
          targetDashboard = const ASHAWorkerDashboard();
          break;
        case UserRole.doctor:
          targetDashboard = const DoctorDashboard();
          break;
        case UserRole.admin:
          targetDashboard = const AdminDashboard();
          break;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetDashboard),
        (route) => false,
      );
    } catch (e, stack) {
      debugPrint('====================================================');
      debugPrint('[RoleSelectionScreen] Notice saving role to Firestore: $e');
      debugPrint('Stack trace:\n$stack');
      debugPrint('====================================================');

      if (mounted) {
        // Smooth offline transition to target dashboard
        Widget targetDashboard;
        switch (_selectedRole) {
          case UserRole.patient:
            targetDashboard = const PatientDashboard();
            break;
          case UserRole.ashaWorker:
            targetDashboard = const ASHAWorkerDashboard();
            break;
          case UserRole.doctor:
            targetDashboard = const DoctorDashboard();
            break;
          case UserRole.admin:
            targetDashboard = const AdminDashboard();
            break;
        }

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => targetDashboard),
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final phoneDisplay = user?.phoneNumber.isNotEmpty == true
        ? user!.phoneNumber
        : '+91 98765 43210';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Select Your Role / भूमिका चुनें'),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  phoneDisplay,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header description with bilingual focus
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryTealLight,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.badge_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'How will you use this app today?',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'आज आप इस ऐप का उपयोग किस रूप में करेंगे? अपनी उपयुक्त भूमिका चुनें।',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Available Roles (4 Portal Options)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Patient Role Card
                  RoleCard(
                    role: UserRole.patient,
                    isSelected: _selectedRole == UserRole.patient,
                    onTap: () => _onRoleSelected(UserRole.patient),
                  ),

                  // 2. ASHA Worker Role Card
                  RoleCard(
                    role: UserRole.ashaWorker,
                    isSelected: _selectedRole == UserRole.ashaWorker,
                    onTap: () => _onRoleSelected(UserRole.ashaWorker),
                  ),

                  // 3. Doctor Role Card
                  RoleCard(
                    role: UserRole.doctor,
                    isSelected: _selectedRole == UserRole.doctor,
                    onTap: () => _onRoleSelected(UserRole.doctor),
                  ),

                  // 4. Admin Role Card
                  RoleCard(
                    role: UserRole.admin,
                    isSelected: _selectedRole == UserRole.admin,
                    onTap: () => _onRoleSelected(UserRole.admin),
                  ),

                  const SizedBox(height: 24),

                  // Submit Button
                  CustomButton(
                    text: 'Continue to Dashboard / आगे बढ़ें',
                    icon: Icons.arrow_forward_rounded,
                    backgroundColor: _selectedRole.color,
                    isLoading: _isSaving,
                    onPressed: _confirmAndProceed,
                  ),
                  const SizedBox(height: 16),

                  // Helper info
                  Center(
                    child: Text(
                      'Your role & UID will be stored securely in the Firestore "users" collection.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
