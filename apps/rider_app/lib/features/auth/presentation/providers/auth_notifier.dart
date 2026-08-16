import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rider_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rider_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:rider_app/features/auth/domain/usecases/send_otp.dart';
import 'package:rider_app/features/auth/domain/usecases/sign_out.dart';
import 'package:rider_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:rider_app/features/auth/presentation/providers/auth_state.dart';

class AuthNotifier extends AsyncNotifier<AuthState> {
  late SendOtp _sendOtp;
  late VerifyOtp _verifyOtp;
  late SignOut _signOut;

  @override
  Future<AuthState> build() async {
    _sendOtp = ref.watch(sendOtpProvider);
    _verifyOtp = ref.watch(verifyOtpProvider);
    _signOut = ref.watch(signOutProvider);

    ref.listen(authStateChangesProvider, (_, next) {
      next.whenData((user) {
        if (user != null) {
          state = AsyncData(AuthAuthenticated(user: user));
        } else {
          final current = state.valueOrNull;
          if (current is AuthInitial || current is AuthAuthenticated) {
            state = const AsyncData(AuthUnauthenticated());
          }
        }
      });
    });

    final repository = ref.watch(authRepositoryProvider);
    final currentUser = await repository.getCurrentUser();

    if (currentUser != null) {
      return AuthAuthenticated(user: currentUser);
    }

    return const AuthUnauthenticated();
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncData(AuthOtpSending());

    await _sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        state = AsyncData(AuthOtpSent(
          verificationId: verificationId,
          phoneNumber: phoneNumber,
        ));
      },
      onError: (message) {
        state = AsyncData(AuthError(message: message));
      },
    );
  }

  Future<void> verifyOtp({
    required String verificationId,
    required String otpCode,
  }) async {
    state = const AsyncData(AuthVerifying());

    try {
      final user = await _verifyOtp(
        verificationId: verificationId,
        otpCode: otpCode,
      );
      state = AsyncData(AuthAuthenticated(user: user));
    } on RiderRoleException {
      // Specific state for wrong role — shows a clear message
      state = const AsyncData(AuthWrongRole());
    } catch (e) {
      state = AsyncData(AuthError(message: _mapError(e)));
    }
  }

  Future<void> signOut() async {
    await _signOut();
    state = const AsyncData(AuthUnauthenticated());
  }

  void resetError() {
    state = const AsyncData(AuthUnauthenticated());
  }

  String _mapError(Object e) {
    final message = e.toString();
    if (message.contains('invalid-verification-code')) {
      return 'The code you entered is incorrect. Please try again.';
    }
    if (message.contains('session-expired')) {
      return 'Your verification code has expired. Please request a new one.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());

final authStateChangesProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  if (authState is AuthAuthenticated) return authState.user;
  return null;
});
