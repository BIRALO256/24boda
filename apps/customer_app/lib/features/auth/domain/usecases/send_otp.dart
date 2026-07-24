import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_app/features/auth/data/repositories/auth_repository_impl.dart';

/// Use case: Send OTP to a phone number.
///
/// A use case is a single business action.
/// It takes inputs, calls the repository, and returns a result.
///
/// Why a dedicated class and not just calling the repository directly?
/// 1. Single Responsibility — this class does one thing only
/// 2. Testable in isolation — mock the repository, test the logic
/// 3. Business rules live here — e.g. rate limiting, validation
///    before hitting the network
/// 4. The presentation layer depends on use cases, not repositories —
///    one more layer of protection against leaking data layer details
class SendOtp {
  const SendOtp(this._repository);

  final AuthRepository _repository;

  /// Executes the send OTP operation.
  ///
  /// [phoneNumber] — Uganda phone number, will be validated and
  /// converted to E.164 format before sending.
  Future<void> call({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await _repository.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }
}

/// Riverpod provider for [SendOtp].
/// Depends on [authRepositoryProvider] from the data layer.
final sendOtpProvider = Provider<SendOtp>((ref) {
  return SendOtp(ref.watch(authRepositoryProvider));
});
