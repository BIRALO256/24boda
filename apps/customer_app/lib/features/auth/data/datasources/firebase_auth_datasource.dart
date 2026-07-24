import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_models/core_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:utils/utils.dart';

/// All direct Firebase SDK calls for authentication live here.
///
/// This is the ONLY file in the entire customer app that imports
/// firebase_auth and touches the Firebase Auth SDK directly.
///
/// Why isolate Firebase calls in a datasource?
/// - If Firebase changes its API, you update one file
/// - Unit tests mock this class — no real Firebase needed
/// - The repository orchestrates logic, the datasource handles I/O
/// - Separation of concerns: datasource = raw data, repository = shaped data
class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ── Phone OTP ─────────────────────────────────────────────────────────────

  /// Sends a one-time password SMS via Firebase Auth.
  ///
  /// Handles both web (reCAPTCHA-based) and mobile (automatic) flows.
  /// Firebase manages the SMS sending, rate limiting, and token lifecycle.
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    if (kIsWeb) {
      // Web flow: Firebase uses reCAPTCHA for verification
      // The confirmationResult holds the verificationId equivalent
      try {
        final confirmationResult = await _auth.signInWithPhoneNumber(
          phoneNumber,
        );
        onCodeSent(confirmationResult.verificationId);
      } on FirebaseAuthException catch (e) {
        onError(_mapFirebaseError(e));
      }
    } else {
      // Mobile flow: Firebase sends SMS automatically
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          // Android only — auto-retrieval of OTP
          // We don't auto-sign-in here — we let the user complete
          // the OTP screen for a consistent cross-platform experience
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_mapFirebaseError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timed out — the OTP screen handles this gracefully
        },
      );
    }
  }

  /// Verifies the OTP code and signs the user in.
  ///
  /// Returns the Firebase [User] on success.
  /// Throws [FirebaseAuthException] on failure.
  Future<User> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otpCode,
    );

    final userCredential = await _auth.signInWithCredential(credential);

    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'null-user',
        message: 'Authentication succeeded but user is null.',
      );
    }

    return userCredential.user!;
  }

  // ── Firestore user document ───────────────────────────────────────────────

  /// Fetches the [UserProfile] document from Firestore.
  ///
  /// Returns null if the document doesn't exist yet (new user).
  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  /// Creates a new [UserProfile] document in Firestore.
  ///
  /// Called on first login only — when [getUserProfile] returns null.
  /// Uses [SetOptions(merge: true)] to prevent overwriting if the
  /// document already exists (race condition protection).
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

  /// Updates the FCM token on the user's Firestore document.
  /// Called on every login to keep notifications working.
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

  /// The currently signed-in Firebase user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of Firebase auth state changes.
  /// Emits [User] on sign-in, null on sign-out.
  Stream<User?> get firebaseAuthStateChanges => _auth.authStateChanges();

  /// Signs out the current user.
  Future<void> signOut() => _auth.signOut();

  // ── Error mapping ─────────────────────────────────────────────────────────

  /// Maps Firebase error codes to user-friendly messages.
  ///
  /// Firebase error codes are technical strings like 'invalid-phone-number'.
  /// Users should never see those. This maps them to plain English.
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
