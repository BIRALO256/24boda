/// The type of vehicle a rider uses for deliveries.
///
/// Affects pricing, capacity, and matching logic:
/// - [boda]    — motorcycle. Primary vehicle type in Uganda.
///               Best for small packages, fastest, handles traffic.
/// - [bicycle] — pedal bicycle. Lower fee, eco-friendly,
///               suitable for very short distances only.
/// - [car]     — saloon or pickup. Higher fee, larger packages,
///               weather-protected. Future expansion vehicle type.
enum VehicleType {
  boda,
  bicycle,
  car;

  /// Human-readable label shown in the UI.
  String get label => switch (this) {
    VehicleType.boda => 'Boda Boda',
    VehicleType.bicycle => 'Bicycle',
    VehicleType.car => 'Car',
  };

  /// Firestore-safe string value for serialisation.
  String get value => switch (this) {
    VehicleType.boda => 'boda',
    VehicleType.bicycle => 'bicycle',
    VehicleType.car => 'car',
  };

  /// Deserialise from Firestore string value.
  static VehicleType fromValue(String value) => switch (value) {
    'boda' => VehicleType.boda,
    'bicycle' => VehicleType.bicycle,
    'car' => VehicleType.car,
    _ => throw ArgumentError('Unknown VehicleType value: $value'),
  };
}
