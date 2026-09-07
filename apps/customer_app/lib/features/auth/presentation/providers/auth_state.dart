import 'package:core_models/core_models.dart';

/// All possible states of the authentication flow.
///
/// This is a sealed class — the compiler guarantees that every
/// switch/pattern match covers all cases. No runtime surprises.
///
/// Why a sealed class over an enum?
/// Some states carry data (e.g. [AuthAuthenticated] carries a [PlatformUser],
/// [AuthError] carries a message). Enums can't carry typed data.
/// Sealed classes give us type-safe data + exhaustive matching.
///
/// State machine:
/// ```
/// initial
///   └── unauthenticated   (no session found)
///   └── authenticated     (existing session restored)
///
/// unauthenticated
///   └── otpSending        (user submitted phone number)
///       └── otpSent       (Firebase sent the SMS)
///           └── verifying (user submitted 6-digit code)
///               └── authenticated
///               └── error
///   └── error             (phone submission failed)
/// ```
sealed class AuthState {
  const AuthState();
}

/// App just launched. Firebase is initialised but we haven't
/// checked the auth state yet. Splash screen shows during this state.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// No authenticated session. Show the phone number entry screen.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Firebase is in the process of sending the OTP SMS.
/// Show a loading indicator on the phone screen.
final class AuthOtpSending extends AuthState {
  const AuthOtpSending();
}

/// OTP SMS was sent successfully.
/// Navigate to the OTP entry screen.
/// [verificationId] is needed to verify the code.
/// [phoneNumber] is displayed masked on the OTP screen.
final class AuthOtpSent extends AuthState {
  const AuthOtpSent({required this.verificationId, required this.phoneNumber});

  final String verificationId;
  final String phoneNumber;
}

/// User submitted the OTP. Firebase is verifying it.
/// Show a loading indicator on the OTP screen.
final class AuthVerifying extends AuthState {
  const AuthVerifying();
}

/// User is authenticated. Navigate to the home screen.
/// [user] contains the full [PlatformUser] loaded from Firestore.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final PlatformUser user;
}

/// Something went wrong. Show an error message.
/// [message] is already user-friendly (mapped in the datasource).
final class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;
}

/// Phone number is registered as a rider trying to access the customer app.
/// UI shows: "This number is registered as a rider. Use the 24Boda Rider app."
final class AuthWrongRoleRider extends AuthState {
  const AuthWrongRoleRider();
}
