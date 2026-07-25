import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/home/data/datasources/location_datasource.dart';
import 'package:customer_app/features/home/domain/repositories/location_repository.dart';

/// Concrete implementation of [LocationRepository].
///
/// Orchestrates the location flow:
/// 1. Calls [LocationDatasource] for raw GPS position
/// 2. Calls [LocationDatasource] for reverse geocoded address
/// 3. Combines into a [Location] domain entity
///
/// The domain layer only knows about [LocationRepository] (the interface).
/// This implementation detail lives entirely in the data layer.
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._datasource);

  final LocationDatasource _datasource;

  @override
  Future<Location> getCurrentLocation() async {
    final position = await _datasource.getCurrentPosition();

    // Reverse geocode the coordinates to get a human-readable address
    final address = await _datasource.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    return Location(
      lat: position.latitude,
      lng: position.longitude,
      address: address,
    );
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) {
    return _datasource.getAddressFromCoordinates(lat, lng);
  }
}

/// Riverpod provider for [LocationDatasource].
final locationDatasourceProvider = Provider<LocationDatasource>((ref) {
  return LocationDatasource();
});

/// Riverpod provider for [LocationRepository].
/// Exposes [LocationRepositoryImpl] as [LocationRepository] so all
/// consumers depend on the interface, not the implementation.
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(
    ref.watch(locationDatasourceProvider),
  );
});
