import 'package:core_models/core_models.dart';
import 'package:customer_app/features/shipment/domain/models/delivery_quote.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pickup = LocationSnapshot(
    address: 'Makerere West Gate, Kampala',
    coordinate: GeoCoordinate(latitude: 0.3348, longitude: 32.5674),
    landmark: 'Behind the main gate',
  );
  final dropoff = LocationSnapshot(
    address: 'Acacia Mall, Kampala',
    coordinate: GeoCoordinate(latitude: 0.3387, longitude: 32.5879),
    placeId: 'place_acacia',
  );

  test('serializes the exact backend quote request contract', () {
    final request = CreateDeliveryQuoteRequest(
      idempotencyKey: 'quote_attempt_123456',
      pickup: pickup,
      dropoff: dropoff,
      packageSize: DeliveryQuotePackageSize.medium,
    );

    expect(request.toMap(), {
      'idempotencyKey': 'quote_attempt_123456',
      'pickup': pickup.toMap(),
      'dropoff': dropoff.toMap(),
      'packageSize': 'medium',
    });
  });

  test('rejects invalid idempotency keys before making a request', () {
    expect(
      () => CreateDeliveryQuoteRequest(
        idempotencyKey: 'short',
        pickup: pickup,
        dropoff: dropoff,
        packageSize: DeliveryQuotePackageSize.small,
      ),
      throwsArgumentError,
    );
  });

  test('strictly parses integer UGX, route data, and UTC expiry', () {
    final quote = parseDeliveryQuoteResponse(_quoteMap(pickup, dropoff));

    expect(quote.price.customerTotalUgx, 6000);
    expect(quote.routeDistanceMeters, 3200);
    expect(quote.isExpiredAt(DateTime.parse('2026-09-15T10:05:00Z')), isTrue);
  });

  test('rejects malformed and forward-incompatible responses', () {
    final extra = _quoteMap(pickup, dropoff)..['clientPrice'] = 1;
    final future = _quoteMap(pickup, dropoff)..['schemaVersion'] = 2;
    final fractional = _quoteMap(pickup, dropoff)
      ..['routeDistanceMeters'] = 3200.5;

    expect(() => parseDeliveryQuoteResponse(extra), throwsFormatException);
    expect(() => parseDeliveryQuoteResponse(future), throwsFormatException);
    expect(() => parseDeliveryQuoteResponse(fractional), throwsFormatException);
  });
}

Map<String, Object?> _quoteMap(
  LocationSnapshot pickup,
  LocationSnapshot dropoff,
) => {
  'id': 'quote_123',
  'customerId': 'customer_123',
  'pickup': pickup.toMap(),
  'dropoff': dropoff.toMap(),
  'routeDistanceMeters': 3200,
  'routeDurationSeconds': 900,
  'price': {
    'subtotalUgx': 6000,
    'discountUgx': 0,
    'customerTotalUgx': 6000,
    'riderEarningUgx': 4800,
    'platformCommissionUgx': 1200,
    'taxUgx': 0,
    'surgeBasisPoints': 10000,
    'currency': 'UGX',
  },
  'pricingRuleVersion': 1,
  'serviceZoneId': 'kampala_launch_v1',
  'createdAt': '2026-09-15T10:00:00.000Z',
  'expiresAt': '2026-09-15T10:05:00.000Z',
  'schemaVersion': 1,
};
