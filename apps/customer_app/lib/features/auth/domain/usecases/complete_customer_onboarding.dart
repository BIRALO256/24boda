import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:customer_app/features/auth/domain/repositories/auth_repository.dart';

final class CompleteCustomerOnboarding {
  const CompleteCustomerOnboarding(this._repository);

  final AuthRepository _repository;

  Future<PlatformUser> call({required String displayName}) =>
      _repository.completeCustomerOnboarding(displayName: displayName);
}

final completeCustomerOnboardingProvider = Provider<CompleteCustomerOnboarding>(
  (ref) {
    return CompleteCustomerOnboarding(ref.watch(authRepositoryProvider));
  },
);
