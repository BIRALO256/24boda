import 'package:core_models/core_models.dart';

import 'package:customer_app/features/shipment/domain/models/delivery_quote.dart';

enum DeliveryQuoteFailureKind {
  authenticationRequired,
  appCheckRejected,
  customerUnavailable,
  invalidRequest,
  outsideServiceZone,
  noRoute,
  quoteExpired,
  idempotencyConflict,
  rateLimited,
  serviceUnavailable,
  invalidResponse,
  unknown,
}

final class DeliveryQuoteFailure implements Exception {
  const DeliveryQuoteFailure(this.kind, this.message, {this.cause});

  final DeliveryQuoteFailureKind kind;
  final String message;
  final Object? cause;

  bool get canRetry => switch (kind) {
    DeliveryQuoteFailureKind.rateLimited ||
    DeliveryQuoteFailureKind.serviceUnavailable => true,
    _ => false,
  };

  @override
  String toString() => 'DeliveryQuoteFailure($kind): $message';
}

abstract interface class DeliveryQuoteRepository {
  Future<DeliveryQuote> createQuote(CreateDeliveryQuoteRequest request);
}
