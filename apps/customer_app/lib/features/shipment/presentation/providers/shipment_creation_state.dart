import 'package:core_models/core_models.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/shipment/domain/repositories/delivery_quote_repository.dart';

sealed class ShipmentCreationState {
  const ShipmentCreationState();
}

final class ShipmentCreationIdle extends ShipmentCreationState {
  const ShipmentCreationIdle();
}

final class ShipmentCreationAddressPicked extends ShipmentCreationState {
  const ShipmentCreationAddressPicked({
    required this.dropoff,
    required this.pickup,
  });

  final LocationSnapshot dropoff;
  final LocationSnapshot pickup;
}

final class ShipmentCreationQuoteLoading extends ShipmentCreationState {
  const ShipmentCreationQuoteLoading({required this.draft});

  final ShipmentCreationAddressPicked draft;
}

final class ShipmentCreationQuoteAvailable extends ShipmentCreationState {
  const ShipmentCreationQuoteAvailable({
    required this.quote,
    required this.packageSize,
    this.packageDescription,
    this.customerNote,
  });

  final DeliveryQuote quote;
  final PackageSize packageSize;
  final String? packageDescription;
  final String? customerNote;
}

final class ShipmentCreationQuoteFailed extends ShipmentCreationState {
  const ShipmentCreationQuoteFailed({
    required this.draft,
    required this.failure,
  });

  final ShipmentCreationAddressPicked draft;
  final DeliveryQuoteFailure failure;
}
