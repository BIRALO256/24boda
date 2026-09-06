import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:core_models/core_models.dart';

import 'firestore_paths.dart';
import 'firestore_value_adapter.dart';

typedef ModelDecoder<T> = T Function(Map<String, dynamic> map);
typedef ModelEncoder<T> = Map<String, dynamic> Function(T value);

/// Dependency-injected, typed access to canonical Firestore documents.
///
/// This class contains no business commands. Sensitive writes belong in
/// Cloud Functions; repositories may use these references for authorized
/// reads and narrowly scoped client-owned updates.
final class PlatformFirestore {
  PlatformFirestore({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<PlatformUser> get users => _collection(
    FirestoreCollections.users,
    idField: 'uid',
    decode: PlatformUser.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<RiderApplication> get riderApplications => _collection(
    FirestoreCollections.riderApplications,
    decode: RiderApplication.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<RiderProfile> get riders => _collection(
    FirestoreCollections.riders,
    idField: 'uid',
    decode: RiderProfile.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<DeliveryQuote> get quotes => _collection(
    FirestoreCollections.quotes,
    decode: DeliveryQuote.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<DeliveryShipment> get shipments => _collection(
    FirestoreCollections.shipments,
    decode: DeliveryShipment.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<ShipmentOffer> get shipmentOffers => _collection(
    FirestoreCollections.shipmentOffers,
    decode: ShipmentOffer.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<PaymentRecord> get payments => _collection(
    FirestoreCollections.payments,
    decode: PaymentRecord.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<LedgerEntry> get ledgerEntries => _collection(
    FirestoreCollections.ledgerEntries,
    decode: LedgerEntry.fromMap,
    encode: (value) => value.toMap(),
  );

  CollectionReference<ShipmentEvent> shipmentEvents(String shipmentId) {
    final path =
        '${FirestorePaths.shipment(shipmentId)}/'
        '${FirestoreSubcollections.events}';
    return _collection(
      path,
      decode: ShipmentEvent.fromMap,
      encode: (value) => value.toMap(),
    );
  }

  CollectionReference<T> _collection<T>(
    String path, {
    required ModelDecoder<T> decode,
    required ModelEncoder<T> encode,
    String idField = 'id',
  }) {
    return _firestore
        .collection(path)
        .withConverter<T>(
          fromFirestore: (snapshot, _) {
            final source = snapshot.data();
            if (source == null) {
              throw StateError(
                'Document ${snapshot.reference.path} has no data',
              );
            }
            final normalized = FirestoreValueAdapter.forCoreModel(source);
            normalized[idField] ??= snapshot.id;
            return decode(normalized);
          },
          toFirestore: (value, _) =>
              FirestoreValueAdapter.forFirestore(encode(value)),
        );
  }
}
