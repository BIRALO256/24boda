import 'package:core_models/core_models.dart';

/// Auth state machine for the rider app.
/// Identical structure to the customer app.
/// The role enforcement happens in the data layer —
/// by the time state reaches here, it's already verified rider-only.
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

/// Shown when a non-rider account tries to log into the rider app.
/// Has a dedicated state so the UI can show a specific message —
/// not a generic error — explaining which app to use instead.
final class AuthWrongRole extends AuthState {
  const AuthWrongRole();
}

final class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;
}
