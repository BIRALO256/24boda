import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_models/core_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:utils/utils.dart';

/// All direct Firebase SDK calls for authentication live here.
///
/// Web vs Mobile auth difference — important to understand:
///
/// On MOBILE (Android/iOS):
/// - Firebase uses verifyPhoneNumber() — sends SMS silently
/// - Returns a verificationId via codeSent callback
/// - OTP verified with PhoneAuthProvider.credential + signInWithCredential
/// - No reCAPTCHA ever shown to the user
///
/// On WEB:
/// - Firebase uses signInWithPhoneNumber() with a RecaptchaVerifier
/// - RecaptchaVerifier must be created with an HTML element ID
/// - Returns a ConfirmationResult (not a verificationId string)
/// - OTP verified with confirmationResult.confirm(otp) directly
/// - We store the ConfirmationResult in memory between sendOtp and verifyOtp
///
/// Why the difference?
/// Mobile apps have Play Integrity API (Android) and APNs (iOS) for
/// silent device verification. Web has no equivalent — reCAPTCHA is
/// Google's way to prevent bot abuse on web Phone Auth.
class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Stores the web ConfirmationResult between sendOtp and verifyOtp calls.
  /// Only used on web — null on mobile.
  ConfirmationResult? _webConfirmationResult;

  // ── Phone OTP ─────────────────────────────────────────────────────────────

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    if (kIsWeb) {
      await _sendOtpWeb(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
      );
    } else {
      await _sendOtpMobile(
        phoneNumber: phoneNumber,
        onCodeSent: onCodeSent,
        onError: onError,
      );
    }
  }

  /// Web OTP flow.
  ///
  /// Uses an invisible reCAPTCHA verifier — the user never sees a challenge
  /// unless Google's risk engine flags the request as suspicious.
  /// The 'recaptcha-container' div ID must exist in web/index.html.
  Future<void> _sendOtpWeb({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    try {
      // Pass no RecaptchaVerifier — Firebase creates an invisible one automatically.
      // This is the recommended approach in firebase_auth 5.x for invisible reCAPTCHA.
      // The reCAPTCHA challenge only appears if Google flags the request as suspicious.
      _webConfirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
      onCodeSent('web-confirmation-result');
    } on FirebaseAuthException catch (e) {
      onError(_mapFirebaseError(e));
    } catch (e) {
      onError('Something went wrong. Please try again.');
    }
  }

  /// Mobile OTP flow (Android + iOS).
  Future<void> _sendOtpMobile({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) {
        // Android auto-retrieval — we don't auto-sign-in to keep
        // the flow consistent across platforms
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(_mapFirebaseError(e));
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  /// Verifies the OTP entered by the user.
  ///
  /// On web: uses the stored [_webConfirmationResult].
  /// On mobile: builds a PhoneAuthCredential from verificationId + otp.
  Future<User> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    UserCredential userCredential;

    if (kIsWeb) {
      if (_webConfirmationResult == null) {
        throw FirebaseAuthException(
          code: 'session-expired',
          message: 'Session expired. Please request a new code.',
        );
      }
      userCredential = await _webConfirmationResult!.confirm(otpCode);
      _webConfirmationResult = null; // clear after use
    } else {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Authentication succeeded but user is null.',
      );
    }

    return userCredential.user!;
  }

  // ── Firestore user document ───────────────────────────────────────────────

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  Future<UserProfile> createUserProfile({
    required String uid,
    required String phone,
  }) async {
    final now = DateTime.now();
    final profile = UserProfile(
      id: uid,
      phone: phone,
      role: UserRole.customer,
      name: '',
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .set(profile.toMap(), SetOptions(merge: true));

    return profile;
  }

  Future<void> updateFcmToken({
    required String uid,
    required String token,
  }) async {
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .update({
      UserFields.fcmToken: token,
      UserFields.updatedAt: DateTime.now().toIso8601String(),
    });
  }

  // ── Auth state ────────────────────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get firebaseAuthStateChanges => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  // ── Error mapping ─────────────────────────────────────────────────────────

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-phone-number' =>
        'That phone number is not valid. Please check and try again.',
      'too-many-requests' =>
        'Too many attempts. Please wait a few minutes before trying again.',
      'invalid-verification-code' =>
        'The code you entered is incorrect. Please try again.',
      'session-expired' =>
        'Your verification code has expired. Please request a new one.',
      'quota-exceeded' =>
        'SMS quota exceeded. Please try again later.',
      'network-request-failed' =>
        'No internet connection. Please check your network and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
