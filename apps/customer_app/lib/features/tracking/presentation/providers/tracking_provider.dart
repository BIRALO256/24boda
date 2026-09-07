import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:utils/utils.dart';

// Re-export the shipment stream so tracking_screen only needs to
// import this one file for both rider location + shipment status.
export 'package:customer_app/features/shipment/domain/usecases/watch_shipment.dart'
    show shipmentStreamProvider;

/// Real-time stream of the rider's current location.
///
/// Reads directly from riders/{riderId}.currentLocation in Firestore.
/// Updates every time the rider's location changes (every ~5 seconds).
///
/// Why a separate provider from the shipment stream?
/// The shipment document is updated on status changes (infrequent).
/// The rider location updates every 5 seconds (frequent).
/// Keeping them separate means the status card doesn't rebuild
/// every 5 seconds — only when the status actually changes.
final riderLocationProvider = StreamProvider.autoDispose
    .family<Location?, String>((ref, riderId) {
      if (riderId.isEmpty) return Stream.value(null);

      return FirebaseFirestore.instance
          .collection(FirestoreCollections.riders)
          .doc(riderId)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) return null;
            final data = snapshot.data()!;
            final locationData = data[RiderFields.currentLocation];
            if (locationData == null) return null;
            return Location.fromMap(locationData as Map<String, dynamic>);
          });
    });
