import 'package:core_models/core_models.dart';

/// Abstract contract for rider authentication operations.
///
/// Identical interface to the customer app's AuthRepository.
/// The key difference is in the implementation — the data layer
/// verifies that the authenticated user has role == 'rider'.
/// A customer trying to log into the rider app is blocked here.
abstract interface class AuthRepository {
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  });

  /// Verifies OTP and returns the rider's [UserProfile].
  ///
  /// Throws [RiderRoleException] if the authenticated user
  /// has role != 'rider' — this is the enforcement point that
  /// prevents customers from accessing the rider app.
  Future<UserProfile> verifyOtp({
    required String verificationId,
    required String otpCode,
  });

  Future<UserProfile?> getCurrentUser();

  Stream<UserProfile?> get authStateChanges;

  Future<void> signOut();
}

/// Thrown when a non-rider account tries to log into the rider app.
class RiderRoleException implements Exception {
  const RiderRoleException();

  @override
  String toString() =>
      'This phone number is registered as a customer account. '
      'Please use the 24Boda customer app.';
}
