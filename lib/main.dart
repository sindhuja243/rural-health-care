import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'widgets/responsive_phone_frame.dart';
import 'screens/auth/phone_login_screen.dart';
import 'screens/role_selection/role_selection_screen.dart';
import 'screens/dashboard/patient_dashboard.dart';
import 'screens/dashboard/asha_worker_dashboard.dart';
import 'screens/dashboard/doctor_dashboard.dart';
import 'screens/dashboard/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const RuralHealthcareApp());
}

class RuralHealthcareApp extends StatelessWidget {
  const RuralHealthcareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gramin Seva Health - Rural Healthcare',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return ResponsivePhoneFrame(child: child ?? const SizedBox.shrink());
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        final user = authService.currentUser;

        // If not logged in, show Phone + OTP login screen
        if (user == null) {
          return const PhoneLoginScreen();
        }

        // If logged in but hasn't selected a role or profile is incomplete
        if (!user.isProfileComplete) {
          return const RoleSelectionScreen();
        }

        // Route to the role's dashboard
        switch (user.role) {
          case UserRole.patient:
            return const PatientDashboard();
          case UserRole.ashaWorker:
            return const ASHAWorkerDashboard();
          case UserRole.doctor:
            return const DoctorDashboard();
          case UserRole.admin:
            return const AdminDashboard();
        }
      },
    );
  }
}
