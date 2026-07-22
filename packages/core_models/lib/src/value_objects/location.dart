/// A geographic location with coordinates and a human-readable address.
///
/// Used as an embedded object on [Shipment] (pickup and dropoff)
/// and on [Rider] (current live location).
///
/// Why a value object and not a plain Map?
/// - Type safety — the compiler catches missing lat/lng at build time
/// - Immutability — a location cannot be partially mutated
/// - Reusability — used in 3+ places without duplication
/// - Testability — pure Dart, no dependencies, trivially testable
///
/// Why [lat]/[lng] as [double] and not a Firebase GeoPoint?
/// This is the domain layer — it must have zero Firebase dependency.
/// The data layer converts to/from GeoPoint during serialisation.
class Location {
  const Location({
    required this.lat,
    required this.lng,
    required this.address,
    this.contactPhone,
  });

  /// Latitude in decimal degrees. Range: -90.0 to 90.0.
  final double lat;

  /// Longitude in decimal degrees. Range: -180.0 to 180.0.
  final double lng;

  /// Human-readable address string.
  /// Example: "Kampala Road, Kampala, Uganda"
  final String address;

  /// Optional phone number of the person at this location.
  /// Used when the sender or recipient is someone other than the
  /// logged-in customer — e.g. "call this number when you arrive".
  final String? contactPhone;

  /// Returns a copy of this location with the given fields replaced.
  Location copyWith({
    double? lat,
    double? lng,
    String? address,
    String? contactPhone,
  }) {
    return Location(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }

  /// Serialise to a plain [Map] for Firestore storage.
  /// The data layer calls this — never call it from the presentation layer.
  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
      'address': address,
      if (contactPhone != null) 'contactPhone': contactPhone,
    };
  }

  /// Deserialise from a Firestore [Map].
  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      address: map['address'] as String,
      contactPhone: map['contactPhone'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.lat == lat &&
        other.lng == lng &&
        other.address == address &&
        other.contactPhone == contactPhone;
  }

  @override
  int get hashCode =>
      lat.hashCode ^ lng.hashCode ^ address.hashCode ^ contactPhone.hashCode;

  @override
  String toString() =>
      'Location(lat: $lat, lng: $lng, address: $address, contactPhone: $contactPhone)';
}
