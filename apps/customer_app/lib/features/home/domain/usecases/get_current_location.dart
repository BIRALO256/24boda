import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/home/data/repositories/location_repository_impl.dart';
import 'package:customer_app/features/home/domain/models/current_location.dart';
import 'package:customer_app/features/home/domain/repositories/location_repository.dart';

/// Use case: Get the device's current GPS location.
///
/// Returns a [Location] with lat, lng, and a human-readable address.
/// This is called when the home screen loads to auto-fill the pickup location.
///
/// Why auto-fill the pickup location?
/// Research on ride-hailing apps (Uber, Bolt) shows that pre-filling
/// the pickup location from GPS reduces booking time by ~40%.
/// "Don't Make Me Think" — the user shouldn't have to type where they are.
class GetCurrentLocation {
  const GetCurrentLocation(this._repository);

  final LocationRepository _repository;

  LocationRepository get repository => _repository;

  Future<CurrentLocation> call() => _repository.getCurrentLocation();
}

/// Riverpod provider for [GetCurrentLocation].
final getCurrentLocationProvider = Provider<GetCurrentLocation>((ref) {
  return GetCurrentLocation(ref.watch(locationRepositoryProvider));
});
