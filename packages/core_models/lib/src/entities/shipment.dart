import 'package:core_models/src/enums/shipment_status.dart';
import 'package:core_models/src/value_objects/location.dart';

// PackageSize is defined in utils but re-exported here as a string field
// on the Shipment entity. The domain layer stores it as a string to avoid
// a dependency on the utils package from core_models.

/// The core business object of the 24Boda platform.
///
/// Every delivery job is a [Shipment]. It holds the full lifecycle
/// of a delivery from booking to completion or cancellation.
///
/// Maps to the [shipments/{shipmentId}] Firestore collection.
///
/// Field design principles applied here:
/// 1. Required at creation: anything needed to start matching a rider
/// 2. Optional at creation, required later: riderId (set when rider accepts)
/// 3. Optional always: packageDescription, photos, ratings, notes
/// 4. Timestamps are optional except createdAt and updatedAt — they are
///    set progressively as the shipment moves through its lifecycle
///
/// Why [price] as an embedded object and not flat fields?
/// Because price has internal structure (estimated, final, breakdown).
/// Embedding it keeps the root document clean and makes the pricing
/// logic portable without polluting the [Shipment] field list.
class Shipment {
  const Shipment({
    required this.id,
    required this.customerId,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.price,
    required this.distanceKm,
    required this.estimatedDurationMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.riderId,
    this.packageSize,
    this.packageDescription,
    this.packagePhotoUrl,
    this.customerNote,
    this.customerRating,
    this.riderRating,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
  });

  // ── Identity ──────────────────────────────────────────────────────────────

  /// Auto-generated Firestore document ID.
  final String id;

  /// Firebase Auth UID of the customer who placed this order.
  /// Set at creation, never changes.
  final String customerId;

  /// Firebase Auth UID of the rider assigned to this shipment.
  /// Null until a rider accepts. Set when status → [ShipmentStatus.accepted].
  final String? riderId;

  // ── Status ────────────────────────────────────────────────────────────────

  /// Current lifecycle state of this shipment.
  /// This is the single source of truth for what both apps display.
  final ShipmentStatus status;

  // ── Locations ─────────────────────────────────────────────────────────────

  /// Where the rider picks up the package.
  final Location pickup;

  /// Where the rider delivers the package.
  final Location dropoff;

  // ── Package details ────────────────────────────────────────────────────────

  /// Package size category — affects pricing.
  /// Stored as a string ('small', 'medium', 'large', 'fragile').
  /// Null until the customer selects it during booking.
  final String? packageSize;

  /// Optional description of what's being sent.
  /// Shown to the rider so they know what to expect to handle.
  /// Example: "Small envelope", "Laptop bag", "Food order"
  final String? packageDescription;

  /// Optional Firebase Storage URL of a photo of the package.
  /// Useful for proof of condition and dispute resolution.
  final String? packagePhotoUrl;

  /// Optional note from the customer to the rider.
  /// Example: "Call me when you arrive", "Gate code is 1234"
  final String? customerNote;

  // ── Pricing ───────────────────────────────────────────────────────────────

  /// The full pricing breakdown for this shipment.
  final ShipmentPrice price;

  // ── Distance & time ───────────────────────────────────────────────────────

  /// Straight-line distance between pickup and dropoff in kilometres.
  /// Calculated at booking using the Haversine formula.
  /// Used for price estimation and ETA calculation.
  final double distanceKm;

  /// Estimated delivery duration in minutes.
  /// Calculated at booking based on distance and vehicle type.
  final int estimatedDurationMinutes;

  // ── Ratings ────────────────────────────────────────────────────────────────

  /// Customer's rating of the rider. Range: 1 to 5.
  /// Null until the customer submits a rating after delivery.
  final int? customerRating;

  /// Rider's rating of the customer. Range: 1 to 5.
  /// Null until the rider submits a rating after delivery.
  final int? riderRating;

  // ── Lifecycle timestamps ──────────────────────────────────────────────────
  // These are set progressively — only createdAt and updatedAt are always present.
  // The rest are set as the shipment moves through its lifecycle.
  // Storing these timestamps enables performance analytics:
  //   acceptedAt - createdAt = time to find rider (key metric)
  //   deliveredAt - pickedUpAt = actual transit time vs estimate

  /// When the shipment was created by the customer. Always set.
  final DateTime createdAt;

  /// Last time this document was modified. Always set.
  final DateTime updatedAt;

  /// When a rider accepted the job. Null until accepted.
  final DateTime? acceptedAt;

  /// When the rider confirmed pickup. Null until picked up.
  final DateTime? pickedUpAt;

  /// When the rider confirmed delivery. Null until delivered.
  final DateTime? deliveredAt;

  /// When the shipment was cancelled. Null unless cancelled.
  final DateTime? cancelledAt;

  // ── Computed helpers ──────────────────────────────────────────────────────

  /// Whether a rider has been assigned to this shipment.
  bool get hasRider => riderId != null;

  /// Whether the shipment is currently active (in progress).
  bool get isActive => status.isActive;

  /// Whether the shipment has reached a terminal state.
  bool get isTerminal => status.isTerminal;

  /// Time from creation to rider acceptance.
  /// Null if rider has not yet accepted.
  /// This is the key customer satisfaction metric.
  Duration? get timeToAccept {
    if (acceptedAt == null) return null;
    return acceptedAt!.difference(createdAt);
  }

  /// Actual transit time from pickup to delivery.
  /// Null if delivery is not yet complete.
  Duration? get actualTransitTime {
    if (pickedUpAt == null || deliveredAt == null) return null;
    return deliveredAt!.difference(pickedUpAt!);
  }

  /// Returns a copy of this shipment with the given fields replaced.
  Shipment copyWith({
    String? id,
    String? customerId,
    String? riderId,
    ShipmentStatus? status,
    Location? pickup,
    Location? dropoff,
    String? packageSize,
    String? packageDescription,
    String? packagePhotoUrl,
    String? customerNote,
    ShipmentPrice? price,
    double? distanceKm,
    int? estimatedDurationMinutes,
    int? customerRating,
    int? riderRating,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? acceptedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
  }) {
    return Shipment(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      riderId: riderId ?? this.riderId,
      status: status ?? this.status,
      pickup: pickup ?? this.pickup,
      dropoff: dropoff ?? this.dropoff,
      packageSize: packageSize ?? this.packageSize,
      packageDescription: packageDescription ?? this.packageDescription,
      packagePhotoUrl: packagePhotoUrl ?? this.packagePhotoUrl,
      customerNote: customerNote ?? this.customerNote,
      price: price ?? this.price,
      distanceKm: distanceKm ?? this.distanceKm,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      customerRating: customerRating ?? this.customerRating,
      riderRating: riderRating ?? this.riderRating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }

  /// Serialise to a plain [Map] for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      if (riderId != null) 'riderId': riderId,
      'status': status.value,
      'pickup': pickup.toMap(),
      'dropoff': dropoff.toMap(),
      if (packageSize != null) 'packageSize': packageSize,
      if (packageDescription != null) 'packageDescription': packageDescription,
      if (packagePhotoUrl != null) 'packagePhotoUrl': packagePhotoUrl,
      if (customerNote != null) 'customerNote': customerNote,
      'price': price.toMap(),
      'distanceKm': distanceKm,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      if (customerRating != null) 'customerRating': customerRating,
      if (riderRating != null) 'riderRating': riderRating,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      if (pickedUpAt != null) 'pickedUpAt': pickedUpAt!.toIso8601String(),
      if (deliveredAt != null) 'deliveredAt': deliveredAt!.toIso8601String(),
      if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
    };
  }

  /// Deserialise from a Firestore [Map].
  factory Shipment.fromMap(Map<String, dynamic> map) {
    return Shipment(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      riderId: map['riderId'] as String?,
      status: ShipmentStatus.fromValue(map['status'] as String),
      pickup: Location.fromMap(map['pickup'] as Map<String, dynamic>),
      dropoff: Location.fromMap(map['dropoff'] as Map<String, dynamic>),
      packageSize: map['packageSize'] as String?,
      packageDescription: map['packageDescription'] as String?,
      packagePhotoUrl: map['packagePhotoUrl'] as String?,
      customerNote: map['customerNote'] as String?,
      price: ShipmentPrice.fromMap(map['price'] as Map<String, dynamic>),
      distanceKm: (map['distanceKm'] as num).toDouble(),
      estimatedDurationMinutes: map['estimatedDurationMinutes'] as int,
      customerRating: map['customerRating'] as int?,
      riderRating: map['riderRating'] as int?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      acceptedAt: map['acceptedAt'] != null
          ? DateTime.parse(map['acceptedAt'] as String)
          : null,
      pickedUpAt: map['pickedUpAt'] != null
          ? DateTime.parse(map['pickedUpAt'] as String)
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? DateTime.parse(map['deliveredAt'] as String)
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? DateTime.parse(map['cancelledAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shipment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Shipment(id: $id, status: ${status.value}, customerId: $customerId, riderId: $riderId)';
}

/// The pricing breakdown for a single shipment.
///
/// Embedded inside [Shipment] — not a separate Firestore document.
///
/// Why embed and not reference?
/// Price is always read together with the shipment.
/// A separate document would mean 2 reads every time you load a shipment.
/// Embedding costs nothing and saves a read on every query.
class ShipmentPrice {
  const ShipmentPrice({
    required this.estimatedFee,
    required this.currency,
    this.finalFee,
    this.riderEarnings,
  });

  /// The fee shown to the customer at booking time.
  /// Calculated from distance + vehicle type + surge multiplier.
  final double estimatedFee;

  /// The actual fee charged after delivery.
  /// Usually equals [estimatedFee] unless dynamic pricing applied.
  /// Null until the shipment is delivered.
  final double? finalFee;

  /// The rider's share of [finalFee]. Always 80% of [finalFee].
  /// Null until delivery is confirmed and payment is processed.
  final double? riderEarnings;

  /// Currency code. Always 'UGX' for now.
  /// Stored explicitly so adding multi-currency later requires
  /// zero schema changes.
  final String currency;

  /// The effective fee — final if available, estimated otherwise.
  double get effectiveFee => finalFee ?? estimatedFee;

  ShipmentPrice copyWith({
    double? estimatedFee,
    double? finalFee,
    double? riderEarnings,
    String? currency,
  }) {
    return ShipmentPrice(
      estimatedFee: estimatedFee ?? this.estimatedFee,
      finalFee: finalFee ?? this.finalFee,
      riderEarnings: riderEarnings ?? this.riderEarnings,
      currency: currency ?? this.currency,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'estimatedFee': estimatedFee,
      if (finalFee != null) 'finalFee': finalFee,
      if (riderEarnings != null) 'riderEarnings': riderEarnings,
      'currency': currency,
    };
  }

  factory ShipmentPrice.fromMap(Map<String, dynamic> map) {
    return ShipmentPrice(
      estimatedFee: (map['estimatedFee'] as num).toDouble(),
      finalFee: map['finalFee'] != null
          ? (map['finalFee'] as num).toDouble()
          : null,
      riderEarnings: map['riderEarnings'] != null
          ? (map['riderEarnings'] as num).toDouble()
          : null,
      currency: map['currency'] as String,
    );
  }

  @override
  String toString() =>
      'ShipmentPrice(estimatedFee: $estimatedFee, finalFee: $finalFee, currency: $currency)';
}
