abstract final class FirestoreCollections {
  static const users = 'users';
  static const riderApplications = 'rider_applications';
  static const riders = 'riders';
  static const shipments = 'shipments';
  static const shipmentOffers = 'shipment_offers';
  static const quotes = 'quotes';
  static const payments = 'payments';
  static const ledgerEntries = 'ledger_entries';
  static const serviceZones = 'service_zones';
}

abstract final class FirestoreSubcollections {
  static const devices = 'devices';
  static const events = 'events';
}

abstract final class FirestorePaths {
  static String user(String uid) => _document(FirestoreCollections.users, uid);
  static String riderApplication(String id) =>
      _document(FirestoreCollections.riderApplications, id);
  static String rider(String uid) =>
      _document(FirestoreCollections.riders, uid);
  static String shipment(String id) =>
      _document(FirestoreCollections.shipments, id);
  static String shipmentOffer(String id) =>
      _document(FirestoreCollections.shipmentOffers, id);
  static String quote(String id) => _document(FirestoreCollections.quotes, id);
  static String payment(String id) =>
      _document(FirestoreCollections.payments, id);
  static String ledgerEntry(String id) =>
      _document(FirestoreCollections.ledgerEntries, id);
  static String userDevice(String uid, String deviceId) =>
      '${user(uid)}/${FirestoreSubcollections.devices}/${_segment(deviceId, 'deviceId')}';
  static String shipmentEvent(String shipmentId, String eventId) =>
      '${shipment(shipmentId)}/${FirestoreSubcollections.events}/${_segment(eventId, 'eventId')}';

  static String _document(String collection, String id) =>
      '$collection/${_segment(id, 'documentId')}';

  static String _segment(String value, String name) {
    final clean = value.trim();
    if (clean.isEmpty || clean.contains('/')) {
      throw ArgumentError.value(
        value,
        name,
        'Must be one non-empty path segment',
      );
    }
    return clean;
  }
}
