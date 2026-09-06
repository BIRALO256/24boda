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

      final shipment = DeliveryShipment.fromMap(canonicalShipmentFixture);
      expect(shipment.price.customerTotalUgx, 12500);
      expect(shipment.pickup.coordinate.latitude, 0.3136);
      expect(
        DeliveryShipment.fromMap(shipment.toMap()).status,
        shipment.status,
      );
    });

    test('canonical identity and rider application round-trip', () {
      final user = PlatformUser.fromMap(canonicalUserFixture);
      expect(user.phoneE164, '+256700000001');
      expect(PlatformUser.fromMap(user.toMap()).status, AccountStatus.active);

      final application = RiderApplication.fromMap(
        canonicalRiderApplicationFixture,
      );
      expect(application.status, RiderApplicationStatus.pendingVerification);
      expect(
        RiderApplication.fromMap(application.toMap()).phoneE164,
        application.phoneE164,
      );
    });
  });

  group('Operational contracts', () {
    test('shipment offers and events round-trip', () {
      final offeredAt = DateTime.utc(2026, 9, 6, 10);
      final offer = ShipmentOffer.fromMap({
        'id': 'offer_01',
        'shipmentId': 'shipment_01',
        'riderId': 'rider_01',
        'status': 'pending',
        'distanceToPickupMeters': 1250,
        'offeredAt': offeredAt,
        'expiresAt': offeredAt.add(const Duration(seconds: 20)),
        'respondedAt': null,
        'schemaVersion': 1,
      });
      expect(
        ShipmentOffer.fromMap(offer.toMap()).status,
        ShipmentOfferStatus.pending,
      );

      final event = ShipmentEvent.fromMap({
        'id': 'event_01',
        'type': 'shipment_offer_sent',
        'fromStatus': 'searching',
        'toStatus': 'offered',
        'actorId': null,
        'actorRole': 'system',
        'reasonCode': null,
        'location': null,
        'metadata': {'dispatchVersion': 1},
        'occurredAt': offeredAt,
        'schemaVersion': 1,
      });
      expect(
        ShipmentEvent.fromMap(event.toMap()).actorRole,
        EventActorRole.system,
      );
    });

    test('payment and ledger records preserve integer UGX', () {
      final now = DateTime.utc(2026, 9, 6, 11);
      final payment = PaymentRecord.fromMap({
        'id': 'payment_01',
        'shipmentId': 'shipment_01',
        'customerId': 'customer_01',
        'amountUgx': 12500,
        'currency': 'UGX',
        'method': 'mobile_money',
        'status': 'processing',
        'idempotencyKey': 'payment:shipment_01:attempt_01',
        'providerReference': null,
        'createdAt': now,
        'updatedAt': now,
        'schemaVersion': 1,
      });
      expect(PaymentRecord.fromMap(payment.toMap()).amountUgx, 12500);

      final entry = LedgerEntry.fromMap({
        'id': 'entry_01',
        'accountId': 'rider_01',
        'shipmentId': 'shipment_01',
        'paymentId': 'payment_01',
        'type': 'rider_earning',
        'direction': 'credit',
        'amountUgx': 10000,
        'currency': 'UGX',
        'idempotencyKey': 'ledger:shipment_01:rider_earning',
        'occurredAt': now,
        'schemaVersion': 1,
      });
      expect(
        LedgerEntry.fromMap(entry.toMap()).direction,
        LedgerDirection.credit,
      );
    });

    test('financial records reject invalid money data', () {
      expect(
        () => PaymentRecord.fromMap({
          'id': 'payment_01',
          'shipmentId': 'shipment_01',
          'customerId': 'customer_01',
          'amountUgx': 12.5,
          'currency': 'UGX',
          'method': 'cash',
          'status': 'created',
          'idempotencyKey': 'key',
          'createdAt': DateTime.now(),
          'updatedAt': DateTime.now(),
        }),
        throwsFormatException,
      );
    });
  });
}
