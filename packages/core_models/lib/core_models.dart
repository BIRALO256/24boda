/// 24Boda core domain models.
///
/// Pure Dart package — zero Flutter, zero Firebase dependencies.
/// Import this single file to access all entities, enums, and value objects:
///
/// ```dart
/// import 'package:core_models/core_models.dart';
///
/// // Enums
/// UserRole.customer
/// VehicleType.boda
/// ShipmentStatus.inTransit
///
/// // Value objects
/// Location(lat: 0.3476, lng: 32.5825, address: 'Kampala, Uganda')
///
/// // Entities
/// UserProfile(...)
/// Rider(...)
/// Shipment(...)
/// ShipmentPrice(...)
/// ```
library;

// Enums
export 'src/enums/shipment_status.dart';
export 'src/enums/user_role.dart';
export 'src/enums/vehicle_type.dart';

// Value objects
export 'src/value_objects/location.dart';

// Entities
export 'src/entities/user_profile.dart';
export 'src/entities/rider.dart';
export 'src/entities/shipment.dart';
