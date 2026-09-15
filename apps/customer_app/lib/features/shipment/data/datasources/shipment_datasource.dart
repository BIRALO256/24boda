import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_models/core_models.dart';
import 'package:utils/utils.dart';

/// All direct Firestore calls for shipments live here.
///
/// This is the only file that imports cloud_firestore in the shipment feature.
/// Isolating Firestore here means:
/// - Swapping Firestore = change one file
/// - Unit tests mock this class — no real Firestore needed
/// - The repository orchestrates logic, the datasource handles raw I/O
class ShipmentDatasource {
  ShipmentDatasource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.shipments);

  /// Returns a real-time stream of a shipment document.
  Stream<Shipment> watchShipment(String shipmentId) {
    return _collection.doc(shipmentId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Shipment $shipmentId not found');
      }
      return Shipment.fromMap(snapshot.data()!);
    });
  }

  /// Updates shipment status to cancelled.
  Future<void> cancelShipment(String shipmentId) async {
    await _collection.doc(shipmentId).update({
      ShipmentFields.status: ShipmentStatus.cancelled.value,
      ShipmentFields.cancelledAt: DateTime.now().toIso8601String(),
      ShipmentFields.updatedAt: DateTime.now().toIso8601String(),
    });
  }
}
