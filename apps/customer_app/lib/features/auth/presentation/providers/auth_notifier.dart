import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:customer_app/features/auth/domain/usecases/complete_customer_onboarding.dart';
import 'package:customer_app/features/auth/domain/usecases/send_otp.dart';
import 'package:customer_app/features/auth/domain/usecases/sign_out.dart';
import 'package:customer_app/features/auth/domain/usecases/verify_otp.dart';
import 'package:customer_app/features/auth/presentation/providers/auth_state.dart';

/// Manages the authentication state machine.
///
/// [AuthNotifier] is the single source of truth for auth state
/// in the presentation layer. It:
/// 1. Restores existing sessions on app launch
/// 2. Drives the phone → OTP → home navigation flow
/// 3. Handles all error states with user-friendly messages
///
/// Screens never call Firebase directly — they call methods
/// on this notifier and react to [AuthState] changes.
///
/// Why [AsyncNotifier] vs [StateNotifier]?
/// [AsyncNotifier] has built-in support for async initialisation.
/// The [build] method runs once on first access and restores
/// the existing auth session — perfect for splash screen logic.
class AuthNotifier extends AsyncNotifier<AuthState> {
  late SendOtp _sendOtp;
  late VerifyOtp _verifyOtp;
  late SignOut _signOut;
  late CompleteCustomerOnboarding _completeCustomerOnboarding;

  @override
  Future<AuthState> build() async {
    _sendOtp = ref.watch(sendOtpProvider);
    _verifyOtp = ref.watch(verifyOtpProvider);
    _signOut = ref.watch(signOutProvider);
    _completeCustomerOnboarding = ref.watch(completeCustomerOnboardingProvider);

    // Listen to Firebase auth state changes reactively.
    // When the user signs in or out from anywhere, this stream fires
    // and we update the state automatically — no manual coordination needed.
    ref.listen(authStateChangesProvider, (_, next) {
      next.whenData((user) {
        if (user != null) {
          state = AsyncData(AuthAuthenticated(user: user));
        } else {
          // Only set unauthenticated if we're not in the middle of a flow
          final current = state.valueOrNull;
          if (current is AuthInitial || current is AuthAuthenticated) {
            state = const AsyncData(AuthUnauthenticated());
          }
        }
      });
    });

    // Check if there's an existing session on app launch
    final repository = ref.watch(authRepositoryProvider);
    final currentUser = await repository.getCurrentUser();

    if (currentUser != null) {
      return AuthAuthenticated(user: currentUser);
    }

    return const AuthUnauthenticated();
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Sends OTP to the given phone number.
  ///
  /// Transitions: unauthenticated → otpSending → otpSent (or error)
  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncData(AuthOtpSending());

    await _sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        state = AsyncData(
          AuthOtpSent(verificationId: verificationId, phoneNumber: phoneNumber),
        );
      },
      onError: (message) {
        state = AsyncData(AuthError(message: message));
      },
    );
  }

  /// Verifies the OTP entered by the user.
  ///
  /// Transitions: otpSent → verifying → authenticated (or error)
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
    } on CustomerAppRiderException {
      state = const AsyncData(AuthWrongRoleRider());
    } catch (e) {
      state = AsyncData(AuthError(message: _mapError(e)));
    }
  }

  /// Signs out the current user.
  ///
  /// Transitions: authenticated → unauthenticated
  Future<void> signOut() async {
    await _signOut();
    state = const AsyncData(AuthUnauthenticated());
  }

  Future<void> completeCustomerOnboarding(String displayName) async {
    final previous = state.valueOrNull;
    try {
      final user = await _completeCustomerOnboarding(displayName: displayName);
      state = AsyncData(AuthAuthenticated(user: user));
    } catch (_) {
      if (previous != null) state = AsyncData(previous);
      rethrow;
    }
  }

  /// Resets error state back to unauthenticated so the user
  /// can try again without restarting the app.
  void resetError() {
    state = const AsyncData(AuthUnauthenticated());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _mapError(Object e) {
    final message = e.toString();
    if (message.contains('invalid-verification-code')) {
      return 'The code you entered is incorrect. Please try again.';
    }
    if (message.contains('session-expired')) {
      return 'Your verification code has expired. Please request a new one.';
    }
    if (message.contains('network')) {
      return 'No internet connection. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Provider for [AuthNotifier].
///
/// [keepAlive: true] ensures auth state persists for the entire
/// app lifecycle — it is never disposed while the app is running.
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

/// Convenience provider that streams auth state changes from Firebase.
/// Used by [AuthNotifier] to reactively respond to sign-in/sign-out.
final authStateChangesProvider = StreamProvider<PlatformUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Convenience provider — returns the current user or null.
/// Used in screens that need to read the user without reacting to changes.
final currentUserProvider = Provider<PlatformUser?>((ref) {
  final authState = ref.watch(authNotifierProvider).valueOrNull;
  if (authState is AuthAuthenticated) return authState.user;
  return null;
});
