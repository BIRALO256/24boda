import 'package:cloud_functions/cloud_functions.dart';

final class CustomerOnboardingException implements Exception {
  const CustomerOnboardingException({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'CustomerOnboardingException($code): $message';
}

final class CustomerOnboardingResult {
  const CustomerOnboardingResult({
    required this.uid,
    required this.created,
    required this.completed,
    required this.schemaVersion,
  });

  final String uid;
  final bool created;
  final bool completed;
  final int schemaVersion;

  factory CustomerOnboardingResult.fromMap(Map<Object?, Object?> map) {
    final uid = map['uid'];
    final created = map['created'];
    final completed = map['completed'];
    final schemaVersion = map['schemaVersion'];
    if (uid is! String ||
        uid.isEmpty ||
        created is! bool ||
        completed is! bool ||
        schemaVersion is! int) {
      throw const FormatException('Invalid customer onboarding response');
    }
    return CustomerOnboardingResult(
      uid: uid,
      created: created,
      completed: completed,
      schemaVersion: schemaVersion,
    );
  }
}

final class CustomerOnboardingService {
  CustomerOnboardingService({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<CustomerOnboardingResult> complete({String? displayName}) async {
    try {
      final callable = _functions.httpsCallable('completeCustomerOnboarding');
      final result = await callable.call<Object?>({
        'displayName': ?displayName,
      });
      final data = result.data;
      if (data is! Map) {
        throw const FormatException('Invalid customer onboarding response');
      }
      return CustomerOnboardingResult.fromMap(data);
    } on FirebaseFunctionsException catch (error) {
      throw CustomerOnboardingException(
        code: error.code,
        message: error.message ?? 'Customer onboarding failed',
      );
    }
  }
}
