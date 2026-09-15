import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/shipment/data/datasources/delivery_quote_datasource.dart';
import 'package:customer_app/features/shipment/domain/models/delivery_quote.dart';
import 'package:customer_app/features/shipment/domain/repositories/delivery_quote_repository.dart';

final class DeliveryQuoteRepositoryImpl implements DeliveryQuoteRepository {
  const DeliveryQuoteRepositoryImpl(this._datasource);

  final DeliveryQuoteDatasource _datasource;

  @override
  Future<DeliveryQuote> createQuote(CreateDeliveryQuoteRequest request) async {
    try {
      return await _datasource.createQuote(request);
    } on DeliveryQuoteRemoteException catch (error) {
      throw mapDeliveryQuoteFailure(error);
    }
  }
}

DeliveryQuoteFailure mapDeliveryQuoteFailure(
  DeliveryQuoteRemoteException error,
) {
  if (error.kind == DeliveryQuoteRemoteFailureKind.appCheck) {
    return DeliveryQuoteFailure(
      DeliveryQuoteFailureKind.appCheckRejected,
      'We could not verify this installation. Check your connection and try again.',
      cause: error,
    );
  }
  if (error.kind == DeliveryQuoteRemoteFailureKind.invalidResponse) {
    return DeliveryQuoteFailure(
      DeliveryQuoteFailureKind.invalidResponse,
      'We could not read the delivery price. Please try again.',
      cause: error,
    );
  }

  final kind = switch ((error.code, error.reason)) {
    ('unauthenticated', _) => DeliveryQuoteFailureKind.authenticationRequired,
    ('permission-denied', _) => DeliveryQuoteFailureKind.customerUnavailable,
    ('invalid-argument', _) => DeliveryQuoteFailureKind.invalidRequest,
    ('out-of-range', 'outside-service-zone') =>
      DeliveryQuoteFailureKind.outsideServiceZone,
    ('not-found', 'no-route') => DeliveryQuoteFailureKind.noRoute,
    ('failed-precondition', 'quote-expired') =>
      DeliveryQuoteFailureKind.quoteExpired,
    ('already-exists', _) => DeliveryQuoteFailureKind.idempotencyConflict,
    ('resource-exhausted', _) => DeliveryQuoteFailureKind.rateLimited,
    ('unavailable', _) ||
    ('deadline-exceeded', _) => DeliveryQuoteFailureKind.serviceUnavailable,
    _ => DeliveryQuoteFailureKind.unknown,
  };

  return DeliveryQuoteFailure(kind, _messageFor(kind), cause: error);
}

String _messageFor(DeliveryQuoteFailureKind kind) => switch (kind) {
  DeliveryQuoteFailureKind.authenticationRequired =>
    'Your session has expired. Sign in again to request a price.',
  DeliveryQuoteFailureKind.customerUnavailable =>
    'Your customer account is not currently able to request deliveries.',
  DeliveryQuoteFailureKind.invalidRequest =>
    'Check the pickup, destination and package details.',
  DeliveryQuoteFailureKind.outsideServiceZone =>
    '24Boda is not available at one of these locations yet.',
  DeliveryQuoteFailureKind.noRoute =>
    'We could not find a boda route between these locations.',
  DeliveryQuoteFailureKind.quoteExpired =>
    'This price has expired. Request a new price to continue.',
  DeliveryQuoteFailureKind.idempotencyConflict =>
    'These details changed during the request. Please request a new price.',
  DeliveryQuoteFailureKind.rateLimited =>
    'Too many price requests were made. Wait a moment and try again.',
  DeliveryQuoteFailureKind.serviceUnavailable =>
    'Delivery pricing is temporarily unavailable. Please try again.',
  DeliveryQuoteFailureKind.invalidResponse ||
  DeliveryQuoteFailureKind.appCheckRejected ||
  DeliveryQuoteFailureKind.unknown =>
    'We could not get a delivery price. Please try again.',
};

final deliveryQuoteDatasourceProvider = Provider<DeliveryQuoteDatasource>(
  (ref) => FirebaseDeliveryQuoteDatasource(),
);

final deliveryQuoteRepositoryProvider = Provider<DeliveryQuoteRepository>(
  (ref) =>
      DeliveryQuoteRepositoryImpl(ref.watch(deliveryQuoteDatasourceProvider)),
);
