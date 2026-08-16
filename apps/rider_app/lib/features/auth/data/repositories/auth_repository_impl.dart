import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

import 'package:rider_app/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:rider_app/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] for the rider app.
///
/// THE KEY DIFFERENCE from the customer app:
/// After OTP verification, this implementation checks that
/// the user's role is 'rider'. If it's 'customer' or 'admin',
/// it signs them out immediately and throws [RiderRoleException].
///
/// This is the enforcement point — one check, enforced once,
/// in the data layer where it belongs. The UI just reacts to
/// the exception with a clear error message.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
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
    final firebaseUser = await _datasource.verifyOtp(
      verificationId: verificationId,
      otpCode: otpCode,
    );

    final profile = await _datasource.getUserProfile(firebaseUser.uid);

    // ── Role check — the critical gate ────────────────────────────────
    // If no profile exists, this is a new signup via the rider app.
    // We do NOT create a new profile here — riders are registered by
    // admins only. An unknown user is treated as unauthorized.
    if (profile == null) {
      await _datasource.signOut();
      throw const RiderRoleException();
    }

    // If profile exists but role is not rider — block access
    if (!profile.isRider) {
      await _datasource.signOut();
      throw const RiderRoleException();
    }

    // If account is inactive (banned/suspended) — block access
    if (!profile.isActive) {
      await _datasource.signOut();
      throw const RiderRoleException();
    }

    return profile;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final firebaseUser = _datasource.currentUser;
    if (firebaseUser == null) return null;

    final profile = await _datasource.getUserProfile(firebaseUser.uid);

    // Also enforce role check on session restore
    if (profile == null || !profile.isRider || !profile.isActive) {
      await _datasource.signOut();
      return null;
    }

    return profile;
  }

  @override
  Stream<UserProfile?> get authStateChanges {
    return _datasource.firebaseAuthStateChanges.asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final profile = await _datasource.getUserProfile(firebaseUser.uid);
      if (profile == null || !profile.isRider || !profile.isActive) {
        return null;
      }
      return profile;
    });
  }

  @override
  Future<void> signOut() => _datasource.signOut();
}

final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider));
});
