import 'package:core_models/core_models.dart';

abstract interface class AuthRepository {
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  });

  Future<UserProfile> verifyOtp({
    required String verificationId,
    required String otpCode,
  });

  Future<UserProfile?> getCurrentUser();
  Stream<UserProfile?> get authStateChanges;
  Future<void> signOut();
}

/// Thrown when the phone number has no Firestore profile at all.
/// This means the person was never registered by an admin.
/// Message tells them to contact 24Boda to get onboarded.
class NotRegisteredRiderException implements Exception {
  const NotRegisteredRiderException();
}

/// Thrown when the phone number is registered but as a customer or admin —
/// not as a rider. Message tells them to use the customer app instead.
class WrongRoleException implements Exception {
  const WrongRoleException(this.role);
  final UserRole role;
}

/// Thrown when the rider account exists but is inactive/banned.
class InactiveRiderException implements Exception {
  const InactiveRiderException();
}
