import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

import 'package:customer_app/features/shipment/data/datasources/shipment_datasource.dart';
import 'package:customer_app/features/shipment/domain/repositories/shipment_repository.dart';

class ShipmentRepositoryImpl implements ShipmentRepository {
  ShipmentRepositoryImpl(this._datasource);

  final ShipmentDatasource _datasource;

  @override
  Future<Shipment> createShipment({
    required String customerId,
    required Location pickup,
    required Location dropoff,
    required String packageSize,
    required double distanceKm,
    required int estimatedDurationMinutes,
    required double estimatedFee,
    String? packageDescription,
    String? customerNote,
  }) async {
    final now = DateTime.now();

    final shipment = Shipment(
      id: '', // Firestore will generate the real ID
      customerId: customerId,
      status: ShipmentStatus.searching,
      pickup: pickup,
      dropoff: dropoff,
      packageSize: packageSize,
      packageDescription: packageDescription,
      customerNote: customerNote,
      price: ShipmentPrice(
        estimatedFee: estimatedFee,
        currency: CurrencyFormatter.currencyCode,
      ),
      distanceKm: distanceKm,
      estimatedDurationMinutes: estimatedDurationMinutes,
      createdAt: now,
      updatedAt: now,
    );

    return _datasource.createShipment(shipment);
  }

  @override
  Stream<Shipment> watchShipment(String shipmentId) {
    return _datasource.watchShipment(shipmentId);
  }

  @override
  Future<void> cancelShipment(String shipmentId) {
    return _datasource.cancelShipment(shipmentId);
  }
}

final shipmentDatasourceProvider = Provider<ShipmentDatasource>((ref) {
  return ShipmentDatasource();
});

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepositoryImpl(ref.watch(shipmentDatasourceProvider));
});
