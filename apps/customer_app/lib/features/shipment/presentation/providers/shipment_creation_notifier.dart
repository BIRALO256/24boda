import 'dart:convert';
import 'dart:math';

import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/shipment/data/repositories/delivery_quote_repository_impl.dart';
import 'package:customer_app/features/shipment/domain/models/delivery_quote.dart';
import 'package:customer_app/features/shipment/domain/repositories/delivery_quote_repository.dart';
import 'package:customer_app/features/shipment/presentation/providers/shipment_creation_state.dart';

class ShipmentCreationNotifier
    extends AutoDisposeNotifier<ShipmentCreationState> {
  String? _attemptFingerprint;
  String? _idempotencyKey;

  @override
  ShipmentCreationState build() => const ShipmentCreationIdle();

  void onAddressPicked({
    required LocationSnapshot dropoff,
    required LocationSnapshot pickup,
  }) {
    _clearAttempt();
    state = ShipmentCreationAddressPicked(dropoff: dropoff, pickup: pickup);
  }

  Future<DeliveryQuoteFailure?> requestQuote({
    required PackageSize packageSize,
    String? packageDescription,
    String? customerNote,
  }) async {
    final draft = switch (state) {
      ShipmentCreationAddressPicked state => state,
      ShipmentCreationQuoteFailed(:final draft) => draft,
      _ => null,
    };
    if (draft == null) return null;

    final quoteSize = DeliveryQuotePackageSize.values.byName(packageSize.name);
    final fingerprint = jsonEncode({
      'pickup': draft.pickup.toMap(),
      'dropoff': draft.dropoff.toMap(),
      'packageSize': quoteSize.value,
    });
    if (_attemptFingerprint != fingerprint || _idempotencyKey == null) {
      _attemptFingerprint = fingerprint;
      _idempotencyKey = _newIdempotencyKey();
    }

    state = ShipmentCreationQuoteLoading(draft: draft);
    try {
      final quote = await ref
          .read(deliveryQuoteRepositoryProvider)
          .createQuote(
            CreateDeliveryQuoteRequest(
              idempotencyKey: _idempotencyKey!,
              pickup: draft.pickup,
              dropoff: draft.dropoff,
              packageSize: quoteSize,
            ),
          );
      state = ShipmentCreationQuoteAvailable(
        quote: quote,
        packageSize: packageSize,
        packageDescription: packageDescription,
        customerNote: customerNote,
      );
      return null;
    } on DeliveryQuoteFailure catch (failure) {
      state = ShipmentCreationQuoteFailed(draft: draft, failure: failure);
      return failure;
    }
  }

  void reset() {
    _clearAttempt();
    state = const ShipmentCreationIdle();
  }

  void _clearAttempt() {
    _attemptFingerprint = null;
    _idempotencyKey = null;
  }
}

String _newIdempotencyKey() {
  final random = Random.secure();
  final bytes = List<int>.generate(18, (_) => random.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}

final shipmentCreationProvider =
    AutoDisposeNotifierProvider<
      ShipmentCreationNotifier,
      ShipmentCreationState
    >(ShipmentCreationNotifier.new);
