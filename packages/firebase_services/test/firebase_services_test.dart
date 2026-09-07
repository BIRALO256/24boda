import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_services/firebase_services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CustomerOnboardingResult', () {
    test('parses the strict callable response', () {
      final result = CustomerOnboardingResult.fromMap({
        'uid': 'customer_01',
        'created': true,
        'completed': false,
        'schemaVersion': 1,
      });

      expect(result.uid, 'customer_01');
      expect(result.created, isTrue);
      expect(result.completed, isFalse);
      expect(result.schemaVersion, 1);
    });

    test('rejects malformed callable responses', () {
      expect(
        () => CustomerOnboardingResult.fromMap({
          'uid': 'customer_01',
          'created': 'yes',
          'completed': false,
          'schemaVersion': 1,
        }),
        throwsFormatException,
      );
    });
  });

  group('FirebaseEnvironmentConfig', () {
    test('accepts a project matching the selected environment', () {
      final config = FirebaseEnvironmentConfig(
        environment: FirebaseEnvironment.staging,
        projectId: '24boda-staging',
      );
      expect(config.verifyProjectConvention, returnsNormally);
    });

    test('rejects accidental production/environment mismatch', () {
      final config = FirebaseEnvironmentConfig(
        environment: FirebaseEnvironment.production,
        projectId: '24boda-dev',
      );
      expect(config.verifyProjectConvention, throwsStateError);
    });
  });

  group('FirestorePaths', () {
    test('builds canonical document and subcollection paths', () {
      expect(FirestorePaths.user('user_01'), 'users/user_01');
      expect(
        FirestorePaths.userDevice('user_01', 'device_01'),
        'users/user_01/devices/device_01',
      );
      expect(
        FirestorePaths.shipmentEvent('shipment_01', 'event_01'),
        'shipments/shipment_01/events/event_01',
      );
    });

    test('rejects unsafe path segments', () {
      expect(() => FirestorePaths.user(''), throwsArgumentError);
      expect(() => FirestorePaths.user('../admin'), throwsArgumentError);
    });
  });

  group('FirestoreValueAdapter', () {
    test('normalizes nested Timestamp and GeoPoint values', () {
      final timestamp = Timestamp.fromDate(DateTime.utc(2026, 9, 6, 12));
      final result = FirestoreValueAdapter.forCoreModel({
        'createdAt': timestamp,
        'pickup': {'coordinate': const GeoPoint(0.3476, 32.5825)},
      });

      expect(result['createdAt'], DateTime.utc(2026, 9, 6, 12));
      expect(result['pickup'], {
        'coordinate': {'latitude': 0.3476, 'longitude': 32.5825},
      });
    });

    test('encodes canonical coordinates as native GeoPoint', () {
      final result = FirestoreValueAdapter.forFirestore({
        'pickup': {
          'coordinate': {'latitude': 0.3476, 'longitude': 32.5825},
        },
      });
      final pickup = result['pickup']! as Map<String, dynamic>;

      expect(pickup['coordinate'], const GeoPoint(0.3476, 32.5825));
    });

    test('rejects ISO string timestamps', () {
      expect(
        () => FirestoreValueAdapter.dateTime(
          '2026-09-06T12:00:00.000Z',
          'createdAt',
        ),
        throwsFormatException,
      );
    });

    test('requires native GeoPoint values at the Firestore boundary', () {
      expect(
        () => FirestoreValueAdapter.geoPoint({
          'latitude': 0.3476,
          'longitude': 32.5825,
        }, 'coordinate'),
        throwsFormatException,
      );
    });
  });

  group('FirebaseFailure', () {
    test('maps Firebase codes into stable application categories', () {
      final failure = FirebaseFailure.from(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Denied',
        ),
      );

      expect(failure.kind, FirebaseFailureKind.permissionDenied);
      expect(failure.code, 'permission-denied');
    });

    test('maps malformed contract data to invalid argument', () {
      final failure = FirebaseFailure.from(
        const FormatException('Malformed document'),
      );
      expect(failure.kind, FirebaseFailureKind.invalidArgument);
    });
  });
}
