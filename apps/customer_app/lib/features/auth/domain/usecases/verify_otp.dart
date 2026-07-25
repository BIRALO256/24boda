import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_app/features/auth/data/repositories/auth_repository_impl.dart';

/// Use case: Verify the OTP entered by the user.
///
/// On success, returns the authenticated [UserProfile].
/// On failure, throws an [AuthException] with a user-friendly message.
class VerifyOtp {
  const VerifyOtp(this._repository);

  final AuthRepository _repository;

  /// Executes the OTP verification.
  ///
  /// [verificationId] — received from [SendOtp] via onCodeSent callback
  /// [otpCode] — 6-digit code entered by the user
  Future<UserProfile> call({
    required String verificationId,
    required String otpCode,
  }) async {
    return _repository.verifyOtp(
      verificationId: verificationId,
      otpCode: otpCode,
    );
  }
}

/// Riverpod provider for [VerifyOtp].
final verifyOtpProvider = Provider<VerifyOtp>((ref) {
  return VerifyOtp(ref.watch(authRepositoryProvider));
});
