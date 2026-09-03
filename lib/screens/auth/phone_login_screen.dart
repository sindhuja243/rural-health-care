import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'otp_verification_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  // Pre-fill with configured Firebase test number: 9999999999 (+919999999999)
  final _phoneController = TextEditingController(text: '9999999999');
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool _isSendingOtp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptLocationPermission();
    });
  }

  void _promptLocationPermission() {
    if (LocationService().hasPermission) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppTheme.primaryTealLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryTeal),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Location Access / స్థానం అనుమతి',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'మీ దగ్గరలోని ఆసుపత్రులను చూపించడానికి location కావాలి.\n\nWe need your location to show nearby hospitals and medical emergency centres.',
          style: TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Deny / తిరస్కరించు', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await LocationService().requestPermission();
            },
            child: const Text('Allow / అనుమతించు', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    if (_isSendingOtp) return;

    String phone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.isEmpty || phone.length < 10) {
      setState(() {
        _errorMessage =
            'Please enter a valid 10-digit mobile number / कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें';
      });
      return;
    }

    // Strict E.164 without spaces: +919999999999
    final formattedPhone = '+91$phone';

    setState(() {
      _errorMessage = null;
      _isSendingOtp = true;
    });

    debugPrint('===> [UI] User tapped "Get OTP" for number: $formattedPhone');

    await AuthService().sendOtp(
      phoneNumber: formattedPhone,
      onCodeSent: (verificationId, resendToken) {
        if (!mounted) return;
        setState(() => _isSendingOtp = false);

        debugPrint('===> [UI] onCodeSent received! Navigating to OtpVerificationScreen...');

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: phone,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          ),
        );
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isSendingOtp = false;
          _errorMessage = error;
        });

        debugPrint('===> [UI] onError caught: "$error"');

        // Visible SnackBar alert so it NEVER fails silently
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Firebase Auth Error:\n$error',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.dangerCoral,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'DISMISS',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo & Healthcare Emblem
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryTeal, AppTheme.secondarySky],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // App Title & Bilingual Subtitle
                  const Text(
                    'Gramin Seva Health',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ग्रामीण स्वास्थ्य सेवा पोर्टल\nRural Healthcare Access Platform',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Phone Number Card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryTealLight,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.phone_android_rounded,
                                  color: AppTheme.primaryTeal,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Login / लॉग इन',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Enter your 10-digit mobile number to receive an OTP SMS code:',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Visible Error Message Banner (e.code + e.message)
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerCoralLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.dangerCoral,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_rounded,
                                    color: AppTheme.dangerCoral,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SelectableText(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppTheme.dangerCoral,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Phone Number Input with +91 country prefix
                          CustomTextField(
                            controller: _phoneController,
                            label: 'Mobile Number / मोबाइल नंबर',
                            hint: '9999999999',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_rounded,
                            prefix: Container(
                              padding: const EdgeInsets.only(right: 8),
                              child: const Text(
                                '+91 ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryTeal,
                                ),
                              ),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Get OTP Submit Button with active loading spinner
                          CustomButton(
                            text: _isSendingOtp
                                ? 'Sending OTP... / प्रतीक्षा करें...'
                                : 'Get OTP / ओटीपी प्राप्त करें',
                            icon: _isSendingOtp ? null : Icons.send_rounded,
                            isLoading: _isSendingOtp,
                            onPressed: _isSendingOtp ? null : _sendOtp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer security & privacy note
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 14, color: AppTheme.textMuted),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Powered by Firebase Authentication & SMS verification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
