import 'package:core_models/core_models.dart';
import 'package:customer_app/features/shipment/data/datasources/delivery_quote_datasource.dart';
import 'package:customer_app/features/shipment/data/repositories/delivery_quote_repository_impl.dart';
import 'package:customer_app/features/shipment/domain/models/delivery_quote.dart';
import 'package:customer_app/features/shipment/domain/repositories/delivery_quote_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps App Check separately from account authorization', () {
    final appCheck = mapDeliveryQuoteFailure(
      const DeliveryQuoteRemoteException(
        kind: DeliveryQuoteRemoteFailureKind.appCheck,
        code: 'attestation-failed',
        message: 'App attestation failed.',
      ),
    );
    final account = mapDeliveryQuoteFailure(
      const DeliveryQuoteRemoteException(
        kind: DeliveryQuoteRemoteFailureKind.callable,
        code: 'permission-denied',
        message: 'Active customer required.',
      ),
    );

    expect(appCheck.kind, DeliveryQuoteFailureKind.appCheckRejected);
    expect(account.kind, DeliveryQuoteFailureKind.customerUnavailable);
  });

  test('preserves actionable backend reason codes', () {
    const cases = {
      ('out-of-range', 'outside-service-zone'):
          DeliveryQuoteFailureKind.outsideServiceZone,
      ('not-found', 'no-route'): DeliveryQuoteFailureKind.noRoute,
      ('failed-precondition', 'quote-expired'):
          DeliveryQuoteFailureKind.quoteExpired,
      ('already-exists', null): DeliveryQuoteFailureKind.idempotencyConflict,
      ('resource-exhausted', null): DeliveryQuoteFailureKind.rateLimited,
      ('unavailable', null): DeliveryQuoteFailureKind.serviceUnavailable,
    };

    for (final MapEntry(key: key, value: expected) in cases.entries) {
      final failure = mapDeliveryQuoteFailure(
        DeliveryQuoteRemoteException(
          kind: DeliveryQuoteRemoteFailureKind.callable,
          code: key.$1,
          reason: key.$2,
          message: 'remote message',
        ),
      );
      expect(failure.kind, expected);
    }
  });

  test('repository never leaks its datasource exception', () async {
    final repository = DeliveryQuoteRepositoryImpl(_FailingDatasource());

    await expectLater(
      repository.createQuote(_request()),
      throwsA(
        isA<DeliveryQuoteFailure>().having(
          (failure) => failure.kind,
          'kind',
          DeliveryQuoteFailureKind.serviceUnavailable,
        ),
      ),
    );
  });
}

CreateDeliveryQuoteRequest _request() => CreateDeliveryQuoteRequest(
  idempotencyKey: 'quote_attempt_123456',
  pickup: LocationSnapshot(
    address: 'Makerere West Gate',
    coordinate: GeoCoordinate(latitude: 0.3348, longitude: 32.5674),
  ),
  dropoff: LocationSnapshot(
    address: 'Acacia Mall',
    coordinate: GeoCoordinate(latitude: 0.3387, longitude: 32.5879),
  ),
  packageSize: DeliveryQuotePackageSize.small,
);

final class _FailingDatasource implements DeliveryQuoteDatasource {
  @override
  Future<DeliveryQuote> createQuote(CreateDeliveryQuoteRequest request) {
    throw const DeliveryQuoteRemoteException(
      kind: DeliveryQuoteRemoteFailureKind.callable,
      code: 'unavailable',
      message: 'offline',
    );
  }
}
