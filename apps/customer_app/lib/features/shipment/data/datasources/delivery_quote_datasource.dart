import 'package:cloud_functions/cloud_functions.dart';
import 'package:core_models/core_models.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'package:customer_app/features/shipment/domain/models/delivery_quote.dart';

enum DeliveryQuoteRemoteFailureKind { appCheck, callable, invalidResponse }

final class DeliveryQuoteRemoteException implements Exception {
  const DeliveryQuoteRemoteException({
    required this.kind,
    required this.code,
    required this.message,
    this.reason,
    this.cause,
  });

  final DeliveryQuoteRemoteFailureKind kind;
  final String code;
  final String message;
  final String? reason;
  final Object? cause;
}

abstract interface class DeliveryQuoteDatasource {
  Future<DeliveryQuote> createQuote(CreateDeliveryQuoteRequest request);
}

final class FirebaseDeliveryQuoteDatasource implements DeliveryQuoteDatasource {
  FirebaseDeliveryQuoteDatasource({
    FirebaseFunctions? functions,
    FirebaseAppCheck? appCheck,
  }) : _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
       _appCheck = appCheck ?? FirebaseAppCheck.instance;

  final FirebaseFunctions _functions;
  final FirebaseAppCheck _appCheck;

  @override
  Future<DeliveryQuote> createQuote(CreateDeliveryQuoteRequest request) async {
    await _requireAppCheckToken();

    try {
      final callable = _functions.httpsCallable('createDeliveryQuote');
      final result = await callable.call<Object?>(request.toMap());
      return parseDeliveryQuoteResponse(result.data);
    } on FirebaseFunctionsException catch (error) {
      throw DeliveryQuoteRemoteException(
        kind: DeliveryQuoteRemoteFailureKind.callable,
        code: error.code,
        message: error.message ?? 'Delivery quote request failed.',
        reason: _reasonFrom(error.details),
        cause: error,
      );
    } on FormatException catch (error) {
      throw DeliveryQuoteRemoteException(
        kind: DeliveryQuoteRemoteFailureKind.invalidResponse,
        code: 'invalid-response',
        message: 'The quote service returned an invalid response.',
        cause: error,
      );
    }
  }

  Future<void> _requireAppCheckToken() async {
    try {
      final token = await _appCheck.getToken();
      if (token == null || token.isEmpty) {
        throw FirebaseException(
          plugin: 'firebase_app_check',
          code: 'missing-token',
          message: 'No App Check token was available.',
        );
      }
    } on FirebaseException catch (error) {
      throw DeliveryQuoteRemoteException(
        kind: DeliveryQuoteRemoteFailureKind.appCheck,
        code: error.code,
        message: error.message ?? 'App verification failed.',
        cause: error,
      );
    }
  }
}

String? _reasonFrom(Object? details) {
  if (details is! Map) return null;
  final reason = details['reason'];
  return reason is String ? reason : null;
}
