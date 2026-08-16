import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rider_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rider_app/features/auth/domain/repositories/auth_repository.dart';

class SignOut {
  const SignOut(this._repository);
  final AuthRepository _repository;

  Future<void> call() async => _repository.signOut();
}

final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});
