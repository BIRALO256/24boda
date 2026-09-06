/// The lifecycle of a shipment from creation to completion.
///
/// Every status maps to a distinct UI state in both the customer
/// and rider apps. Granular statuses are intentional — they are
/// what enables accurate real-time tracking.
///
/// Status flow:
/// ```
/// pending → searching → accepted → en_route_pickup
///   → picked_up → in_transit → delivered
///
/// Any state → cancelled
/// Any state → failed
/// ```
enum ShipmentStatus {
  /// Customer submitted the shipment. System has not yet started
  /// searching for a rider. Brief transitional state.
  pending,

  /// System is actively broadcasting the job to nearby riders.
  /// Customer sees "Looking for a rider..." UI.
  searching,

  /// A rider accepted the job. Rider is not yet moving.
  /// Both apps transition to the active delivery view.
  accepted,

  /// Rider is navigating to the pickup location.
  /// Customer sees rider moving toward them on the map.
  enRoutePickup,

  /// Rider physically confirmed they have the package.
  /// This is a manual confirmation tap by the rider.
  /// Marks the handoff from sender to rider.
  pickedUp,

  /// Rider is navigating to the dropoff location.
  /// Customer sees rider moving toward the recipient on the map.
  inTransit,

  /// Rider confirmed delivery at the dropoff location.
  /// Triggers payment processing and rating prompts.
  delivered,

  /// Shipment cancelled. Can be triggered by:
  /// - Customer before rider accepts
  /// - System if no rider found within timeout
  /// - Rider before pickup (penalised)
  cancelled,

  /// Delivery attempted but could not be completed.
  /// Examples: recipient not found, access denied, package refused.
  /// Distinct from cancelled — this was an attempted delivery.
  failed;

  /// Whether this status represents an active, ongoing delivery.
  bool get isActive =>
      this == accepted ||
      this == enRoutePickup ||
      this == pickedUp ||
      this == inTransit;

  /// Whether this status represents a terminal state (no further transitions).
  bool get isTerminal =>
      this == delivered || this == cancelled || this == failed;

  /// Human-readable label shown in the UI.
  String get label => switch (this) {
    ShipmentStatus.pending => 'Pending',
    ShipmentStatus.searching => 'Finding Rider',
    ShipmentStatus.accepted => 'Rider Assigned',
    ShipmentStatus.enRoutePickup => 'Rider On The Way',
    ShipmentStatus.pickedUp => 'Package Picked Up',
    ShipmentStatus.inTransit => 'In Transit',
    ShipmentStatus.delivered => 'Delivered',
    ShipmentStatus.cancelled => 'Cancelled',
    ShipmentStatus.failed => 'Delivery Failed',
  };

  /// Firestore-safe string value for serialisation.
  /// Never use [name] directly for Firestore — it couples your
  /// database to Dart enum naming conventions.
  String get value => switch (this) {
    ShipmentStatus.pending => 'pending',
    ShipmentStatus.searching => 'searching',
    ShipmentStatus.accepted => 'accepted',
    ShipmentStatus.enRoutePickup => 'en_route_pickup',
    ShipmentStatus.pickedUp => 'picked_up',
    ShipmentStatus.inTransit => 'in_transit',
    ShipmentStatus.delivered => 'delivered',
    ShipmentStatus.cancelled => 'cancelled',
    ShipmentStatus.failed => 'failed',
  };

  /// Deserialise from Firestore string value.
  static ShipmentStatus fromValue(String value) => switch (value) {
    'pending' => ShipmentStatus.pending,
    'searching' => ShipmentStatus.searching,
    'accepted' => ShipmentStatus.accepted,
    'en_route_pickup' => ShipmentStatus.enRoutePickup,
    'picked_up' => ShipmentStatus.pickedUp,
    'in_transit' => ShipmentStatus.inTransit,
    'delivered' => ShipmentStatus.delivered,
    'cancelled' => ShipmentStatus.cancelled,
    'failed' => ShipmentStatus.failed,
    _ => throw ArgumentError('Unknown ShipmentStatus value: $value'),
  };
}
