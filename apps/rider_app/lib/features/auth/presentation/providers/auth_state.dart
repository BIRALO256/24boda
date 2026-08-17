import 'package:core_models/core_models.dart';

sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthOtpSending extends AuthState {
  const AuthOtpSending();
}

final class AuthOtpSent extends AuthState {
  const AuthOtpSent({
    required this.verificationId,
    required this.phoneNumber,
  });
  final String verificationId;
  final String phoneNumber;
}

final class AuthVerifying extends AuthState {
  const AuthVerifying();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});
  final UserProfile user;
}

/// Phone number has no account — never registered by admin.
/// UI shows: "This number isn't registered. Contact 24Boda to get onboarded."
final class AuthNotRegistered extends AuthState {
  const AuthNotRegistered();
}

/// Phone number is registered but as a customer — not a rider.
/// UI shows: "This number is registered as a customer. Use the 24Boda customer app."
final class AuthWrongRoleCustomer extends AuthState {
  const AuthWrongRoleCustomer();
}

/// Rider account exists but has been deactivated.
/// UI shows: "Your account has been suspended. Contact 24Boda support."
final class AuthAccountInactive extends AuthState {
  const AuthAccountInactive();
}

final class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;
}
