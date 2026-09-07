import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/shipment/data/repositories/shipment_repository_impl.dart';
import 'package:customer_app/features/shipment/domain/repositories/shipment_repository.dart';

/// Use case: Watch a shipment for real-time status changes.
///
/// Returns a `Stream<Shipment>` that emits every time the Firestore
/// document changes. The searching_rider_screen and tracking_screen
/// use this to react instantly when a rider accepts or delivers.
class WatchShipment {
  const WatchShipment(this._repository);

  final ShipmentRepository _repository;

  Stream<Shipment> call(String shipmentId) {
    return _repository.watchShipment(shipmentId);
  }
}

final watchShipmentProvider = Provider<WatchShipment>((ref) {
  return WatchShipment(ref.watch(shipmentRepositoryProvider));
});

/// Family provider — watch a specific shipment by ID.
/// Usage: ref.watch(shipmentStreamProvider('shipmentId'))
final shipmentStreamProvider = StreamProvider.autoDispose
    .family<Shipment, String>((ref, shipmentId) {
      return ref.watch(watchShipmentProvider).call(shipmentId);
    });
