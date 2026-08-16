import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_models/core_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:utils/utils.dart';

/// All direct Firebase SDK calls for rider authentication.
/// Identical to the customer app datasource — the role check
/// lives in the repository, not here.
class FirebaseAuthDatasource {
  FirebaseAuthDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  ConfirmationResult? _webConfirmationResult;

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    if (kIsWeb) {
      try {
        _webConfirmationResult =
            await _auth.signInWithPhoneNumber(phoneNumber);
        onCodeSent('web-confirmation-result');
      } on FirebaseAuthException catch (e) {
        onError(_mapFirebaseError(e));
      } catch (_) {
        onError('Something went wrong. Please try again.');
      }
    } else {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          onError(_mapFirebaseError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (_) {},
      );
    }
  }

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
      _webConfirmationResult = null;
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

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.users)
        .doc(uid)
        .get();

    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!);
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get firebaseAuthStateChanges => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

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
      'network-request-failed' =>
        'No internet connection. Please check your network and try again.',
      _ => 'Something went wrong. Please try again.',
    };
  }
}
