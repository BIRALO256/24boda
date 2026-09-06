import 'package:firebase_core/firebase_core.dart';

enum FirebaseFailureKind {
  unauthenticated,
  permissionDenied,
  notFound,
  alreadyExists,
  invalidArgument,
  unavailable,
  deadlineExceeded,
  quotaExceeded,
  cancelled,
  unknown,
}

final class FirebaseFailure implements Exception {
  const FirebaseFailure({
    required this.kind,
    required this.message,
    this.code,
    this.cause,
  });

  final FirebaseFailureKind kind;
  final String message;
  final String? code;
  final Object? cause;

  factory FirebaseFailure.from(Object error) {
    if (error is FirebaseFailure) return error;
    if (error is FirebaseException) {
      return FirebaseFailure(
        kind: _kind(error.code),
        message: error.message ?? 'Firebase operation failed.',
        code: error.code,
        cause: error,
      );
    }
    if (error is FormatException) {
      return FirebaseFailure(
        kind: FirebaseFailureKind.invalidArgument,
        message: error.message,
        cause: error,
      );
    }
    return FirebaseFailure(
      kind: FirebaseFailureKind.unknown,
      message: 'An unexpected Firebase operation failed.',
      cause: error,
    );
  }

  static FirebaseFailureKind _kind(String code) => switch (code) {
    'unauthenticated' ||
    'user-token-expired' => FirebaseFailureKind.unauthenticated,
    'permission-denied' => FirebaseFailureKind.permissionDenied,
    'not-found' || 'user-not-found' => FirebaseFailureKind.notFound,
    'already-exists' ||
    'email-already-in-use' => FirebaseFailureKind.alreadyExists,
    'invalid-argument' ||
    'invalid-phone-number' => FirebaseFailureKind.invalidArgument,
    'unavailable' ||
    'network-request-failed' => FirebaseFailureKind.unavailable,
    'deadline-exceeded' => FirebaseFailureKind.deadlineExceeded,
    'resource-exhausted' ||
    'quota-exceeded' ||
    'too-many-requests' => FirebaseFailureKind.quotaExceeded,
    'cancelled' => FirebaseFailureKind.cancelled,
    _ => FirebaseFailureKind.unknown,
  };
}
