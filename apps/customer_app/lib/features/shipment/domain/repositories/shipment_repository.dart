import 'package:core_models/core_models.dart';

/// Abstract contract for all shipment operations.
///
/// Domain layer defines WHAT. Data layer defines HOW.
/// The presentation layer and use cases depend only on this interface —
/// never on Firebase, Firestore, or any external service directly.
abstract interface class ShipmentRepository {
  /// Returns a real-time stream of a single shipment document.
  ///
  /// Emits a new [Shipment] every time the document changes in Firestore.
  /// Used on the searching/tracking screens to react instantly when
  /// a rider accepts, picks up, or delivers the package.
  ///
  /// Why a stream and not a one-time fetch?
  /// The shipment status changes without any user action — a rider
  /// somewhere accepts the job. The only way to know instantly is
  /// to listen to Firestore changes in real time.
  Stream<Shipment> watchShipment(String shipmentId);

  /// Cancels a shipment before a rider accepts.
  ///
  /// Sets status to [ShipmentStatus.cancelled].
  /// Can only be called when status is [ShipmentStatus.searching].
  Future<void> cancelShipment(String shipmentId);
}
