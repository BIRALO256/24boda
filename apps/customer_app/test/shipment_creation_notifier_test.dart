import 'package:core_models/core_models.dart';
import 'package:customer_app/features/shipment/data/repositories/delivery_quote_repository_impl.dart';
import 'package:customer_app/features/shipment/domain/models/delivery_quote.dart';
import 'package:customer_app/features/shipment/domain/repositories/delivery_quote_repository.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_notifier.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:utils/utils.dart';

void main() {
  test(
    'a retry of the same logical quote reuses its idempotency key',
    () async {
      final repository = _FakeQuoteRepository()
        ..failures.add(
          const DeliveryQuoteFailure(
            DeliveryQuoteFailureKind.serviceUnavailable,
            'Try again.',
          ),
        );
      final container = _container(repository);
      addTearDown(container.dispose);

      final notifier = container.read(shipmentCreationProvider.notifier);
      notifier.onAddressPicked(pickup: _pickup, dropoff: _dropoff);

      final firstFailure = await notifier.requestQuote(
        packageSize: PackageSize.small,
      );
      final secondFailure = await notifier.requestQuote(
        packageSize: PackageSize.small,
      );

      expect(firstFailure?.kind, DeliveryQuoteFailureKind.serviceUnavailable);
      expect(secondFailure, isNull);
      expect(repository.requests, hasLength(2));
      expect(
        repository.requests.first.idempotencyKey,
        repository.requests.last.idempotencyKey,
      );
      expect(
        container.read(shipmentCreationProvider),
        isA<ShipmentCreationQuoteAvailable>(),
      );
    },
  );

  test('changing an address starts a new idempotent attempt', () async {
    final repository = _FakeQuoteRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    final notifier = container.read(shipmentCreationProvider.notifier);
    notifier.onAddressPicked(pickup: _pickup, dropoff: _dropoff);
    await notifier.requestQuote(packageSize: PackageSize.small);
    final firstKey = repository.requests.single.idempotencyKey;

    notifier.onAddressPicked(
      pickup: _pickup,
      dropoff: LocationSnapshot(
        address: 'Wandegeya, Kampala',
        coordinate: GeoCoordinate(latitude: 0.3302, longitude: 32.5741),
      ),
    );
    await notifier.requestQuote(packageSize: PackageSize.small);

    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.idempotencyKey, isNot(firstKey));
  });
}

ProviderContainer _container(DeliveryQuoteRepository repository) {
  final container = ProviderContainer(
    overrides: [deliveryQuoteRepositoryProvider.overrideWithValue(repository)],
  );
  container.listen(shipmentCreationProvider, (_, _) {});
  return container;
}

final _pickup = LocationSnapshot(
  address: 'Makerere West Gate, Kampala',
  coordinate: GeoCoordinate(latitude: 0.3331, longitude: 32.5663),
);

final _dropoff = LocationSnapshot(
  address: 'Acacia Mall, Kampala',
  coordinate: GeoCoordinate(latitude: 0.3389, longitude: 32.5862),
);

final class _FakeQuoteRepository implements DeliveryQuoteRepository {
  final requests = <CreateDeliveryQuoteRequest>[];
  final failures = <DeliveryQuoteFailure>[];

  @override
  Future<DeliveryQuote> createQuote(CreateDeliveryQuoteRequest request) async {
    requests.add(request);
    if (failures.isNotEmpty) throw failures.removeAt(0);
    final createdAt = DateTime.utc(2026, 9, 15, 10);
    return DeliveryQuote(
      id: 'quote-1',
      customerId: 'customer-1',
      pickup: request.pickup,
      dropoff: request.dropoff,
      routeDistanceMeters: 4200,
      routeDurationSeconds: 900,
      price: PriceSnapshot(
        subtotalUgx: 7000,
        discountUgx: 0,
        customerTotalUgx: 7000,
        riderEarningUgx: 5600,
        platformCommissionUgx: 1400,
        taxUgx: 0,
        surgeBasisPoints: 0,
      ),
      pricingRuleVersion: 1,
      serviceZoneId: 'kampala',
      createdAt: createdAt,
      expiresAt: createdAt.add(const Duration(minutes: 5)),
    );
  }
}
