import 'package:core_models/core_models.dart';
import 'package:customer_app/features/home/data/repositories/location_repository_impl.dart';
import 'package:customer_app/features/home/domain/models/current_location.dart';
import 'package:customer_app/features/home/domain/repositories/location_repository.dart';
import 'package:customer_app/features/home/presentation/providers/location_provider.dart';
import 'package:customer_app/features/home/presentation/providers/map_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test(
    'a camera target is retained until the map controller is ready',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final subscription = container.listen(mapNotifierProvider, (_, _) {});
      addTearDown(subscription.close);

      const target = LatLng(0.3136, 32.5811);
      await container.read(mapNotifierProvider.notifier).animateTo(target);

      final state = container.read(mapNotifierProvider);
      expect(state, isA<MapUninitialized>());
      expect((state as MapUninitialized).pendingCamera?.target, target);
    },
  );

  test('an accurate result becomes a loaded location', () async {
    final container = _containerWith(
      const CurrentLocation(
        location: Location(lat: 0.3136, lng: 32.5811, address: 'Kampala'),
        accuracyMeters: 12,
      ),
    );
    addTearDown(container.dispose);

    await container
        .read(locationNotifierProvider.notifier)
        .fetchCurrentLocation();

    expect(
      container.read(locationNotifierProvider).valueOrNull,
      isA<LocationLoaded>(),
    );
  });

  test(
    'an inaccurate result remains usable but is explicitly marked',
    () async {
      final container = _containerWith(
        const CurrentLocation(
          location: Location(lat: 0.3136, lng: 32.5811, address: 'Kampala'),
          accuracyMeters: 180,
        ),
      );
      addTearDown(container.dispose);

      await container
          .read(locationNotifierProvider.notifier)
          .fetchCurrentLocation();

      final state = container.read(locationNotifierProvider).valueOrNull;
      expect(state, isA<LocationLowAccuracy>());
      expect((state as LocationLowAccuracy).accuracyMeters, 180);
    },
  );

  test('a typed permission failure is preserved for recovery UI', () async {
    final repository = _FakeLocationRepository.failure(
      const LocationException(
        LocationFailureReason.permissionDeniedForever,
        'Enable location in settings.',
      ),
    );
    final container = ProviderContainer(
      overrides: [locationRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container
        .read(locationNotifierProvider.notifier)
        .fetchCurrentLocation();

    final state = container.read(locationNotifierProvider).valueOrNull;
    expect(state, isA<LocationError>());
    expect(
      (state as LocationError).reason,
      LocationFailureReason.permissionDeniedForever,
    );
  });
}

ProviderContainer _containerWith(CurrentLocation result) => ProviderContainer(
  overrides: [
    locationRepositoryProvider.overrideWithValue(
      _FakeLocationRepository.success(result),
    ),
  ],
);

final class _FakeLocationRepository implements LocationRepository {
  const _FakeLocationRepository.success(this._result) : _failure = null;
  const _FakeLocationRepository.failure(this._failure) : _result = null;

  final CurrentLocation? _result;
  final LocationException? _failure;

  @override
  Future<CurrentLocation> getCurrentLocation() async {
    if (_failure case final failure?) throw failure;
    return _result!;
  }

  @override
  Future<String> getAddressFromCoordinates(double lat, double lng) async =>
      _result?.location.address ?? '';
}
