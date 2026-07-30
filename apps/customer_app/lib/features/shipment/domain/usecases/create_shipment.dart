import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/shipment/data/repositories/shipment_repository_impl.dart';
import 'package:customer_app/features/shipment/domain/repositories/shipment_repository.dart';

/// Use case: Create a new delivery shipment.
///
/// Validates inputs, calls the repository, returns the created Shipment.
/// All business rules around shipment creation live here — not in the UI.
class CreateShipment {
  const CreateShipment(this._repository);

  final ShipmentRepository _repository;

  Future<Shipment> call({
    required String customerId,
    required Location pickup,
    required Location dropoff,
    required String packageSize,
    required double distanceKm,
    required int estimatedDurationMinutes,
    required double estimatedFee,
    String? packageDescription,
    String? customerNote,
  }) {
    return _repository.createShipment(
      customerId: customerId,
      pickup: pickup,
      dropoff: dropoff,
      packageSize: packageSize,
      distanceKm: distanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      estimatedFee: estimatedFee,
      packageDescription: packageDescription,
      customerNote: customerNote,
    );
  }
}

final createShipmentProvider = Provider<CreateShipment>((ref) {
  return CreateShipment(ref.watch(shipmentRepositoryProvider));
});
