import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rider_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rider_app/features/auth/domain/repositories/auth_repository.dart';

class SendOtp {
  const SendOtp(this._repository);
  final AuthRepository _repository;

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

final sendOtpProvider = Provider<SendOtp>((ref) {
  return SendOtp(ref.watch(authRepositoryProvider));
});
