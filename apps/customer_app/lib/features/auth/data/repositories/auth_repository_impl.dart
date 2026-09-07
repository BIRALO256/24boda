import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_services/firebase_services.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:customer_app/features/auth/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final FirebaseAuthDatasource _datasource;

  @override
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) => _datasource.sendOtp(
    phoneNumber: PhoneValidator.toE164(phoneNumber),
    onCodeSent: onCodeSent,
    onError: onError,
  );

  @override
  Future<PlatformUser> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    await _datasource.verifyOtp(
      verificationId: verificationId,
      otpCode: otpCode,
    );
    return _completeCustomerProfile();
  }

  @override
  Future<PlatformUser?> getCurrentUser() async {
    if (_datasource.currentUser == null) return null;
    return _completeCustomerProfile();
  }

  @override
  Stream<PlatformUser?> get authStateChanges =>
      _datasource.firebaseAuthStateChanges.asyncMap((firebaseUser) async {
        if (firebaseUser == null) return null;
        return _datasource.getUserProfile(firebaseUser.uid);
      });

  @override
  Future<PlatformUser> completeCustomerOnboarding({
    required String displayName,
  }) => _datasource.completeCustomerOnboarding(displayName: displayName);

  @override
  Future<void> signOut() => _datasource.signOut();

  Future<PlatformUser> _completeCustomerProfile() async {
    try {
      return await _datasource.completeCustomerOnboarding();
    } on CustomerOnboardingException catch (error) {
      if (error.code == 'permission-denied') {
        await _datasource.signOut();
        throw const CustomerAppRiderException();
      }
      rethrow;
    }
  }
}

final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>((ref) {
  return FirebaseAuthDatasource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDatasourceProvider));
});

final class CustomerAppRiderException implements Exception {
  const CustomerAppRiderException();
}
