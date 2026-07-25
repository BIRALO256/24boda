import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:customer_app/features/auth/data/repositories/auth_repository_impl.dart';

/// Use case: Sign out the current user.
///
/// Simple but still a use case — consistency matters.
/// Every auth operation flows through a use case, not directly
/// from the UI to the repository. This keeps the architecture
/// predictable at scale.
class SignOut {
  const SignOut(this._repository);

  final AuthRepository _repository;

  /// Signs out the current user from Firebase Auth.
  /// The [authStateChanges] stream automatically emits null
  /// after this completes, which triggers the go_router auth
  /// guard to redirect to the phone screen.
  Future<void> call() async {
    await _repository.signOut();
  }
}

/// Riverpod provider for [SignOut].
final signOutProvider = Provider<SignOut>((ref) {
  return SignOut(ref.watch(authRepositoryProvider));
});
