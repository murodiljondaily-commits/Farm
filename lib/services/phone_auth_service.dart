import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class PhoneAuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static bool get isSignedIn => _auth.currentUser != null;
  static String? get uid => currentUser?.uid;
  static String? get phoneNumber => currentUser?.phoneNumber;
  static String? get displayName => currentUser?.displayName;

  static Future<void> sendOtp({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onAutoVerified,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String) onAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    debugPrint('[PhoneAuth] Sending OTP to $phoneNumber');
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: (credential) {
        debugPrint('[PhoneAuth] Auto-verified');
        onAutoVerified(credential);
      },
      verificationFailed: (e) {
        debugPrint('[PhoneAuth] Verification failed: ${e.code} ${e.message}');
        onVerificationFailed(e);
      },
      codeSent: (verificationId, resendToken) {
        debugPrint('[PhoneAuth] Code sent, verificationId=$verificationId');
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        debugPrint('[PhoneAuth] Auto-retrieval timeout');
        onAutoRetrievalTimeout(verificationId);
      },
    );
  }

  static Future<User?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(credential);
    debugPrint('[PhoneAuth] Signed in: uid=${userCred.user?.uid}');
    return userCred.user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
