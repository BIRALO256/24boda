import 'package:customer_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:firebase_services/firebase_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only an explicit wrong-role reason identifies another app role', () {
    expect(
      isWrongRoleOnboardingError(
        const CustomerOnboardingException(
          code: 'permission-denied',
          message: 'Different app',
          reason: 'wrong-role',
        ),
      ),
      isTrue,
    );
    expect(
      isWrongRoleOnboardingError(
        const CustomerOnboardingException(
          code: 'permission-denied',
          message: 'App Check rejected the request',
        ),
      ),
      isFalse,
    );
  });
}
