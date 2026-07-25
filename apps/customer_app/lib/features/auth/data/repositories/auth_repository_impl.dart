import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_app/features/auth/data/datasources/firebase_auth_datasource.dart';

/// Concrete implementation of [AuthRepository].
///
/// This class orchestrates the auth flow:
/// 1. Calls [FirebaseAuthDatasource] for raw Firebase operations
/// 2. Shapes the raw data into domain entities ([UserProfile])
/// 3. Handles business logic (first login vs returning user)
///
/// The domain layer knows nothing about this class — it only
/// knows about the [AuthRepository] interface. This is the
/// Dependency Inversion Principle in action.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    // Convert to E.164 format before sending to Firebase
    // e.g. "0700123456" → "+256700123456"
    final e164Phone = PhoneValidator.toE164(phoneNumber);

    await _datasource.sendOtp(
      phoneNumber: e164Phone,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  @override
  Future<UserProfile> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    // 1. Verify with Firebase — get the Firebase User
    final firebaseUser = await _datasource.verifyOtp(
      verificationId: verificationId,
      otpCode: otpCode,
    );

    // 2. Try to fetch existing Firestore profile
    UserProfile? profile = await _datasource.getUserProfile(firebaseUser.uid);

    // 3. First time login — create the Firestore document
    if (profile == null) {
      profile = await _datasource.createUserProfile(
        uid: firebaseUser.uid,
        phone: firebaseUser.phoneNumber ?? '',
      );
    }

    return profile;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final firebaseUser = _datasource.currentUser;
    if (firebaseUser == null) return null;
    return _datasource.getUserProfile(firebaseUser.uid);
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _datasource.firebaseAuthStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _datasource.getUserProfile(firebaseUser.uid);
    });
  }

  @override
  Future<void> signOut() => _datasource.signOut();
}

/// Riverpod provider for [FirebaseAuthDatasource].
/// Singleton — one instance shared across the app.
final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

/// Riverpod provider for [AuthRepository].
///
/// Exposes [AuthRepositoryImpl] as [AuthRepository] so all
/// consumers depend on the interface, not the implementation.
/// Swapping the implementation requires changing only this provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(firebaseAuthDatasourceProvider),
  );
});
