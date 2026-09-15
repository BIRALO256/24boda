import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/shipment/data/datasources/shipment_datasource.dart';
import 'package:customer_app/features/shipment/domain/repositories/shipment_repository.dart';

class ShipmentRepositoryImpl implements ShipmentRepository {
  ShipmentRepositoryImpl(this._datasource);

  final ShipmentDatasource _datasource;

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
