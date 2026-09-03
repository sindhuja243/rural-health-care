import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'firestore_service.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initAuthListener();
  }

  FirebaseAuth? get _auth =>
      FirebaseService.isInitialized ? FirebaseAuth.instance : null;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  String? _verificationId;
  String? get verificationId => _verificationId;

  int? _resendToken;
  int? get resendToken => _resendToken;

  // Flutter Web ConfirmationResult instance
  ConfirmationResult? _webConfirmationResult;
  ConfirmationResult? get webConfirmationResult => _webConfirmationResult;

  void _initAuthListener() {
    final auth = _auth;
    if (auth != null) {
      auth.authStateChanges().listen((User? user) async {
        if (user != null) {
          final userDoc = await FirestoreService().getUser(user.uid);
          _currentUser = userDoc ??
              UserModel(
                uid: user.uid,
                phoneNumber: user.phoneNumber ?? '',
                role: UserRole.patient,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isProfileComplete: false,
              );
          notifyListeners();
        } else if (_currentUser != null) {
          _currentUser = null;
          notifyListeners();
        }
      });
    }
  }

  /// Sends real SMS OTP via Firebase Auth Phone Authentication with Web & Mobile support
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
    int? forceResendingToken,
  }) async {
    // Standardize to strict E.164 phone format (+919999999999 with no spaces)
    final cleanedDigits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final formattedPhone = phoneNumber.trim().startsWith('+')
        ? '+$cleanedDigits'
        : '+91$cleanedDigits';

    debugPrint('====================================================');
    debugPrint('[FirebaseAuth] Initiating Phone Authentication...');
    debugPrint('[FirebaseAuth] Platform: ${kIsWeb ? "Web (signInWithPhoneNumber)" : "Mobile (verifyPhoneNumber)"}');
    debugPrint('[FirebaseAuth] Exact Phone Number String: "$formattedPhone"');
    debugPrint('====================================================');

    final auth = _auth;
    if (auth == null) {
      const err = '[firebase-not-initialized] Firebase is not initialized yet.';
      debugPrint('[FirebaseAuth] $err');
      onError(err);
      return;
    }

    if (kIsWeb) {
      // ----------------- FLUTTER WEB IMPLEMENTATION -----------------
      try {
        debugPrint('[FirebaseAuth Web] Calling _auth.signInWithPhoneNumber("$formattedPhone")...');
        final confirmationResult = await auth
            .signInWithPhoneNumber(formattedPhone)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'Phone authentication request timed out (15s). Please verify your network connection and Firebase authorized domains.',
                );
              },
            );

        _webConfirmationResult = confirmationResult;
        _verificationId = confirmationResult.verificationId;
        debugPrint('[FirebaseAuth Web] ConfirmationResult received! verificationId: "${confirmationResult.verificationId}"');
        onCodeSent(confirmationResult.verificationId, 0);
      } on FirebaseAuthException catch (e, stack) {
        debugPrint('====================================================');
        debugPrint('[FirebaseAuth Web Exception] code: [${e.code}], message: "${e.message}"');
        debugPrint('Stack trace:\n$stack');
        debugPrint('====================================================');
        onError(_getReadableAuthErrorMessage(e));
      } on TimeoutException catch (e, stack) {
        debugPrint('[FirebaseAuth Web Timeout]: $e\n$stack');
        onError('Request timed out (15s). Please try again.');
      } catch (e, stack) {
        debugPrint('[FirebaseAuth Web] Unexpected error: $e\n$stack');
        onError('Web Phone Auth Error: $e');
      }
    } else {
      // ----------------- MOBILE (ANDROID/IOS) IMPLEMENTATION -----------------
      try {
        await auth.verifyPhoneNumber(
          phoneNumber: formattedPhone,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (PhoneAuthCredential credential) async {
            debugPrint('[FirebaseAuth Mobile] verificationCompleted (Instant): ${credential.smsCode}');
            try {
              final userCred = await auth.signInWithCredential(credential);
              final uid = userCred.user?.uid;
              if (uid != null) {
                final userDoc = await FirestoreService().getUser(uid);
                _currentUser = userDoc ??
                    UserModel(
                      uid: uid,
                      phoneNumber: formattedPhone,
                      role: UserRole.patient,
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      isProfileComplete: false,
                    );
                notifyListeners();
              }
            } catch (e, stack) {
              debugPrint('[FirebaseAuth Mobile] Auto-verification signIn error: $e\n$stack');
            }
          },
          verificationFailed: (FirebaseAuthException e) {
            debugPrint('[FirebaseAuth Mobile] verificationFailed: [${e.code}] ${e.message}');
            onError(_getReadableAuthErrorMessage(e));
          },
          codeSent: (String verId, int? resendToken) {
            debugPrint('[FirebaseAuth Mobile] codeSent: verId = "$verId", resendToken = $resendToken');
            _verificationId = verId;
            _resendToken = resendToken;
            onCodeSent(verId, resendToken);
          },
          codeAutoRetrievalTimeout: (String verId) {
            debugPrint('[FirebaseAuth Mobile] codeAutoRetrievalTimeout: "$verId"');
            _verificationId = verId;
          },
          forceResendingToken: forceResendingToken ?? _resendToken,
        );
      } on FirebaseAuthException catch (e, stack) {
        debugPrint('[FirebaseAuth Mobile] Synchronous exception: [${e.code}] ${e.message}\n$stack');
        onError(_getReadableAuthErrorMessage(e));
      } catch (e, stack) {
        debugPrint('[FirebaseAuth Mobile] Unexpected error: $e\n$stack');
        onError('Unable to send OTP: $e');
      }
    }
  }

  /// Verifies the 6-digit OTP code using ConfirmationResult on Web or PhoneAuthProvider.credential on Mobile (with 15s timeout)
  Future<String?> verifyOtp({
    required String verificationId,
    required String smsCode,
    required String phoneNumber,
  }) async {
    final code = smsCode.trim();

    debugPrint('====================================================');
    debugPrint('[FirebaseAuth] verifyOtp initiating...');
    debugPrint('Platform: ${kIsWeb ? "Web (confirmationResult.confirm)" : "Mobile (signInWithCredential)"}');
    debugPrint('VerificationId: "$verificationId"');
    debugPrint('SMS Code: "$code"');
    debugPrint('Phone Number: "$phoneNumber"');
    debugPrint('====================================================');

    final auth = _auth;
    if (auth == null) {
      return '[firebase-not-initialized] Firebase is not initialized.';
    }

    try {
      User? user;

      if (kIsWeb && _webConfirmationResult != null) {
        // Web: confirm via ConfirmationResult with 15s timeout
        final userCredential = await _webConfirmationResult!
            .confirm(code)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'OTP verification timed out (15s). Please check your internet connection or try resending the OTP.',
                );
              },
            );
        user = userCredential.user;
      } else {
        // Mobile / Standard: signInWithCredential with 15s timeout
        final credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code,
        );
        final userCredential = await auth
            .signInWithCredential(credential)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                throw TimeoutException(
                  'OTP verification timed out (15s). Please check your internet connection or try resending the OTP.',
                );
              },
            );
        user = userCredential.user;
      }

      if (user != null) {
        debugPrint('[FirebaseAuth] Successfully authenticated user UID: ${user.uid}');
        final existing = await FirestoreService().getUser(user.uid);
        if (existing != null) {
          _currentUser = existing;
        } else {
          _currentUser = UserModel(
            uid: user.uid,
            phoneNumber: user.phoneNumber ?? phoneNumber,
            role: UserRole.patient,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isProfileComplete: false,
          );
        }
        notifyListeners();
        return null; // Success (no error)
      } else {
        return '[auth/no-user] No user session returned after credential confirmation.';
      }
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('====================================================');
      debugPrint('[FirebaseAuth verifyOtp Exception] Code: [${e.code}]');
      debugPrint('Message: "${e.message}"');
      debugPrint('Stack trace:\n$stack');
      debugPrint('====================================================');
      return _getReadableAuthErrorMessage(e);
    } on TimeoutException catch (e, stack) {
      debugPrint('[FirebaseAuth verifyOtp Timeout]: $e\n$stack');
      return 'Request timed out after 15 seconds. Please try again.';
    } catch (e, stack) {
      debugPrint('====================================================');
      debugPrint('[FirebaseAuth verifyOtp Unexpected Error]: $e');
      debugPrint('Stack trace:\n$stack');
      debugPrint('====================================================');
      return 'Verification error: $e';
    }
  }

  /// Updates user role in Firestore upon Role Selection with explicit UID printing and 15s timeout
  Future<void> updateUserRole(UserRole role) async {
    final currentAuthUser = _auth?.currentUser;
    final currentUid = _currentUser?.uid ?? currentAuthUser?.uid ?? 'user_anonymous';
    final currentPhone = _currentUser?.phoneNumber ?? currentAuthUser?.phoneNumber ?? '+919999999999';

    debugPrint('====================================================');
    debugPrint('[AuthService] updateUserRole starting...');
    debugPrint('User UID to be saved: "$currentUid"');
    debugPrint('User Role to be saved: "${role.id}" (${role.displayName})');
    debugPrint('User Phone Number: "$currentPhone"');
    debugPrint('====================================================');

    final updated = (_currentUser ??
            UserModel(
              uid: currentUid,
              phoneNumber: currentPhone,
              role: role,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isProfileComplete: false,
            ))
        .copyWith(
      role: role,
      isProfileComplete: true,
      updatedAt: DateTime.now(),
    );

    // Save to Firestore with timeout & error propagation
    await FirestoreService().saveUserRole(
      uid: updated.uid,
      phoneNumber: updated.phoneNumber,
      role: role,
      displayName: updated.displayName,
      village: updated.village ?? 'Rampur Gram',
    );

    _currentUser = updated;
    notifyListeners();
  }

  /// Sign out current user from Firebase Auth
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (_) {}
    _currentUser = null;
    _verificationId = null;
    _resendToken = null;
    _webConfirmationResult = null;
    notifyListeners();
  }

  /// Maps Firebase Auth error codes to user-friendly bilingual messages
  String _getReadableAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'configuration-not-found':
        return '[configuration-not-found] Phone Authentication provider is not enabled in Firebase Console.\n\nTo fix in Firebase Console:\n1. Go to console.firebase.google.com -> Project "gramin-seva-health"\n2. Click Authentication -> Sign-in method\n3. Click "Phone" and toggle Enable\n4. Add test phone "+919999999999" with code "123456" and click Save.';
      case 'invalid-phone-number':
        return 'The entered mobile number is invalid. / अमान्य मोबाइल नंबर दर्ज किया गया है।';
      case 'invalid-verification-code':
        return 'Invalid 6-digit OTP entered. Please check and re-enter. / अमान्य ओटीपी कोड।';
      case 'session-expired':
        return 'The OTP has expired. Please request a new OTP. / ओटीपी सत्र समाप्त हो गया है।';
      case 'quota-exceeded':
      case 'too-many-requests':
        return 'SMS quota limit reached. Please wait a few minutes or use test number +919999999999 with code 123456.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet. / इंटरनेट कनेक्शन में समस्या है।';
      case 'app-not-authorized':
        return 'App not authorized. Ensure "localhost" is in Firebase Console > Authentication > Settings > Authorized domains.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';
      default:
        return '[${e.code}] ${e.message ?? "Authentication error. Please try again."}';
    }
  }
}
