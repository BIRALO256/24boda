import 'package:core_models/core_models.dart';

/// Abstract contract for authentication operations.
///
/// Why an abstract interface and not directly calling Firebase?
/// Clean Architecture rule: the domain layer must not know about
/// Firebase, Firestore, or any external service. It only defines
/// WHAT needs to happen — not HOW.
///
/// The HOW lives in the data layer ([AuthRepositoryImpl]).
/// This means:
/// - You can swap Firebase for any other auth provider by changing
///   one file in the data layer. Zero changes to domain or UI.
/// - You can unit test use cases with a fake implementation of this
///   interface — no Firebase emulator needed.
/// - Every auth operation in the app goes through this contract.
///   Nothing calls Firebase directly from UI or providers.
abstract interface class AuthRepository {
  /// Sends a one-time password via SMS to the given phone number.
  ///
  /// [phoneNumber] must be in E.164 format: +256XXXXXXXXX
  ///
  /// On success, the [onCodeSent] callback is called with the
  /// [verificationId] needed to verify the OTP in [verifyOtp].
  ///
  /// On failure, throws an [AuthException].
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  });

  /// Verifies the OTP entered by the user.
  ///
  /// [verificationId] is received from [sendOtp] via [onCodeSent].
  /// [otpCode] is the 6-digit code the user entered.
  ///
  /// On success:
  /// - Firebase Auth signs the user in
  /// - If first time user, creates [users/{uid}] document in Firestore
  /// - Returns the [UserProfile] of the authenticated user
  ///
  /// On failure, throws an [AuthException].
  Future<UserProfile> verifyOtp({
    required String verificationId,
    required String otpCode,
  });

  /// Returns the currently authenticated user's profile,
  /// or null if not authenticated.
  Future<UserProfile?> getCurrentUser();

  /// Stream of auth state changes.
  ///
  /// Emits [UserProfile] when user logs in.
  /// Emits null when user logs out or is not authenticated.
  ///
  /// The go_router auth guard and [AuthNotifier] both listen to this
  /// stream to reactively update the UI when auth state changes.
  Stream<UserProfile?> get authStateChanges;

  /// Signs out the current user.
  Future<void> signOut();
}
