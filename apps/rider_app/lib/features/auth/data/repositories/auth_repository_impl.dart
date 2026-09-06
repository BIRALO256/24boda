import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

import 'package:rider_app/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:rider_app/features/auth/domain/repositories/auth_repository.dart';

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

    // Case 1 — No profile at all: never registered by admin
    if (profile == null) {
      await _datasource.signOut();
      throw const NotRegisteredRiderException();
    }

    // Case 2 — Profile exists but not a rider
    if (!profile.isRider) {
      await _datasource.signOut();
      throw WrongRoleException(profile.role);
    }

    // Case 3 — Rider account exists but is inactive/banned
    if (!profile.isActive) {
      await _datasource.signOut();
      throw const InactiveRiderException();
    }

    return profile;
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final firebaseUser = _datasource.currentUser;
    if (firebaseUser == null) return null;

    final profile = await _datasource.getUserProfile(firebaseUser.uid);

    // Debug — remove before production
    if (profile == null) {
      // ignore: avoid_print
      print('DEBUG: No Firestore profile found for UID: ${firebaseUser.uid}');
    } else if (!profile.isRider) {
      // ignore: avoid_print
      print('DEBUG: Profile found but role is ${profile.role.value}, not rider');
    } else if (!profile.isActive) {
      // ignore: avoid_print
      print('DEBUG: Rider profile found but isActive is false');
    } else {
      // ignore: avoid_print
      print('DEBUG: Valid rider profile found for ${profile.name}');
    }

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
