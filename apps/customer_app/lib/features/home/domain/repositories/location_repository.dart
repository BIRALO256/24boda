import 'package:core_models/core_models.dart';

/// Abstract contract for location operations.
///
/// Why abstract?
/// The domain layer must not know about geolocator, GPS hardware,
/// or any platform API. It only defines WHAT is needed.
/// The data layer defines HOW it is obtained.
///
/// This means:
/// - Swap geolocator for any other location plugin → zero domain changes
/// - Unit test use cases with a fake location → no real GPS needed
abstract interface class LocationRepository {
  /// Returns the device's current GPS position as a [Location].
  ///
  /// Requests location permission if not already granted.
  /// Throws a [LocationException] if permission is denied
  /// or if the device GPS is unavailable.
  Future<Location> getCurrentLocation();

  /// Returns a human-readable address string for the given coordinates.
  ///
  /// Uses reverse geocoding — converts lat/lng → street address.
  /// Example: (0.3476, 32.5825) → "Kampala Road, Kampala, Uganda"
  Future<String> getAddressFromCoordinates(double lat, double lng);
}

/// Thrown when location operations fail.
class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => 'LocationException: $message';
}
