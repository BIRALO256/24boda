import 'package:core_models/core_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/contract_fixtures.dart';

void main() {
  group('Money', () {
    test('round-trips integer UGX without precision loss', () {
      final money = Money.fromMap({'amount': 12550, 'currency': 'UGX'});

      expect(money, Money.ugx(12550));
      expect(money.toMap(), {'amount': 12550, 'currency': 'UGX'});
    });

    test('rejects floating-point and negative amounts', () {
      expect(
        () => Money.fromMap({'amount': 12.5, 'currency': 'UGX'}),
        throwsFormatException,
      );
      expect(() => Money.ugx(-1), throwsArgumentError);
    });

    test('does not combine different currencies', () {
      expect(
        () => Money.ugx(100) + const Money(amount: 1, currency: 'USD'),
        throwsArgumentError,
      );
    });
  });

  group('GeoCoordinate', () {
    test('reads canonical and legacy coordinate keys', () {
      expect(
        GeoCoordinate.fromMap({'latitude': 0.3476, 'longitude': 32.5825}),
        GeoCoordinate(latitude: 0.3476, longitude: 32.5825),
      );
      expect(
        GeoCoordinate.fromMap({'lat': 0.3476, 'lng': 32.5825}),
        GeoCoordinate(latitude: 0.3476, longitude: 32.5825),
      );
    });

    test('rejects invalid world coordinates', () {
      expect(
        () => GeoCoordinate(latitude: 91, longitude: 32),
        throwsArgumentError,
      );
    });
  });

  group('ContractParsing', () {
    test('reads canonical DateTime and legacy ISO timestamp', () {
      final date = DateTime.utc(2026, 9, 6, 12);
      expect(ContractParsing.dateTime(date, 'createdAt'), date);
      expect(
        ContractParsing.dateTime(date.toIso8601String(), 'createdAt'),
        date,
      );
    });

    test('rejects future schema versions', () {
      expect(
        () => ContractParsing.schemaVersion({'schemaVersion': 2}),
        throwsFormatException,
      );
    });
  });

  group('Canonical enums', () {
    test('round-trip stable storage values', () {
      for (final value in DeliveryStatus.values) {
        expect(DeliveryStatus.fromValue(value.value), value);
      }
      for (final value in PaymentStatus.values) {
        expect(PaymentStatus.fromValue(value.value), value);
      }
    });

    test('reject unknown values rather than silently defaulting', () {
      expect(() => DeliveryStatus.fromValue('unknown'), throwsFormatException);
    });
  });

  group('Contract fixtures', () {
    test('canonical user fixture has a supported schema and stable enums', () {
      expect(ContractParsing.schemaVersion(canonicalUserFixture), 1);
      expect(
        UserRole.fromValue(canonicalUserFixture['role']! as String),
        UserRole.customer,
      );
      expect(
        AccountStatus.fromValue(canonicalUserFixture['status']! as String),
        AccountStatus.active,
      );
      expect(
        ContractParsing.dateTime(
          canonicalUserFixture['createdAt'],
          'createdAt',
        ),
        DateTime.utc(2026, 9, 6, 9),
      );
    });

    test('canonical shipment fixture uses integer money and stable enums', () {
      expect(ContractParsing.schemaVersion(canonicalShipmentFixture), 1);
      expect(
        DeliveryStatus.fromValue(canonicalShipmentFixture['status']! as String),
        DeliveryStatus.searching,
      );
      expect(
        PaymentMethod.fromValue(
          canonicalShipmentFixture['paymentMethod']! as String,
        ),
        PaymentMethod.cash,
      );

      final price = ContractParsing.map(
        canonicalShipmentFixture['price'],
        'price',
      );
      expect(
        ContractParsing.integer(
          price['customerTotalUgx'],
          'customerTotalUgx',
          minimum: 0,
        ),
        12500,
      );
    });
  });
}
