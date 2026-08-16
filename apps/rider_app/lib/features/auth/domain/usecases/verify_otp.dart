import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rider_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rider_app/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtp {
  const VerifyOtp(this._repository);
  final AuthRepository _repository;

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

final verifyOtpProvider = Provider<VerifyOtp>((ref) {
  return VerifyOtp(ref.watch(authRepositoryProvider));
});
