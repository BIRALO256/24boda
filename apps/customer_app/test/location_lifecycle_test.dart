import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:customer_app/features/home/data/repositories/location_repository_impl.dart';
import 'package:customer_app/features/home/domain/models/current_location.dart';
import 'package:customer_app/features/home/domain/models/location_fix_sample.dart';
import 'package:customer_app/features/home/domain/repositories/location_repository.dart';
import 'package:customer_app/features/home/presentation/providers/location_provider.dart';
import 'package:customer_app/features/home/presentation/providers/map_provider.dart';
import 'package:customer_app/features/home/presentation/providers/pickup_selection_provider.dart';
import 'package:customer_app/features/home/presentation/widgets/map_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('LocationFixPolicy', () {
    final now = DateTime.utc(2026, 9, 13, 11);

    LocationFixSample sample({
      double latitude = 0.332,
      double longitude = 32.568,
      double accuracy = 20,
      Duration age = Duration.zero,
      bool mocked = false,
    }) => LocationFixSample(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy,
      timestamp: now.subtract(age),
      isMocked: mocked,
    );

    test('rejects stale and mocked samples', () {
      expect(
        LocationFixPolicy.isEligible(
          sample(age: const Duration(seconds: 11)),
          now,
        ),
        isFalse,
      );
      expect(LocationFixPolicy.isEligible(sample(mocked: true), now), isFalse);
    });

    test('requires a fresh sample within 30 metres for reliability', () {
      expect(LocationFixPolicy.isReliable(sample(accuracy: 30)), isTrue);
      expect(LocationFixPolicy.isReliable(sample(accuracy: 31)), isFalse);
    });

    test('recognises consistent fixes and rejects distant fixes', () {
      final origin = sample();
      expect(
        LocationFixPolicy.areConsistent(
          origin,
          sample(latitude: 0.3321, longitude: 32.5681),
        ),
        isTrue,
      );
      expect(
        LocationFixPolicy.areConsistent(
          origin,
          sample(latitude: 0.34, longitude: 32.58),
        ),
        isFalse,
      );
    });

    test('keeps the most accurate improving candidate', () {
      expect(
        LocationFixPolicy.better(
          sample(accuracy: 80),
          sample(accuracy: 25),
        ).accuracyMeters,
        25,
      );
    });

    test('acquirer completes after two fresh consistent fixes', () async {
      final result = await const LocationFixAcquirer().select(
        Stream.fromIterable([
          sample(accuracy: 90),
          sample(latitude: 0.3321, accuracy: 28),
          sample(latitude: 0.33211, accuracy: 18),
        ]),
        now: () => now,
      );
      expect(result.sample.accuracyMeters, 18);
      expect(result.isStable, isTrue);
    });

    test('acquirer falls back to the best eligible fix', () async {
      final result = await const LocationFixAcquirer().select(
        Stream.fromIterable([sample(accuracy: 95), sample(accuracy: 60)]),
        now: () => now,
      );
      expect(result.sample.accuracyMeters, 60);
      expect(result.isStable, isFalse);
    });

    test('acquirer times out when every fix is rejected', () async {
      await expectLater(
        const LocationFixAcquirer().select(
          Stream.fromIterable([
            sample(age: const Duration(seconds: 20)),
            sample(mocked: true),
          ]),
          now: () => now,
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });

  test('GPS remains a suggestion until the customer confirms pickup', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pickupSelectionProvider), isNull);

    final pickup = LocationSnapshot(
      address: 'Kampala Road, Kampala',
      coordinate: GeoCoordinate(latitude: 0.3136, longitude: 32.5811),
      landmark: 'Main entrance',
    );
    container.read(pickupSelectionProvider.notifier).confirm(pickup);

    expect(container.read(pickupSelectionProvider), pickup);
  });

  test('map location layer waits until permission and a fix are resolved', () {
    expect(canShowDeviceLocation(const LocationInitial()), isFalse);
    expect(canShowDeviceLocation(const LocationLoading()), isFalse);
    expect(
      canShowDeviceLocation(
        const LocationLoaded(
          location: Location(lat: 0.332, lng: 32.568, address: 'Makerere'),
          accuracyMeters: 20,
        ),
      ),
      isTrue,
    );
  });

  test('home map starts at an already resolved location', () {
    const location = Location(lat: 0.332, lng: 32.568, address: 'Makerere');
    expect(
      initialMapTarget(
        const LocationLoaded(location: location, accuracyMeters: 20),
      ),
      const LatLng(0.332, 32.568),
    );
    expect(initialMapTarget(const LocationInitial()), kKampalaDefault);
  });

  test('location refreshes after returning with a stale fix', () {
    final now = DateTime.utc(2026, 9, 13, 11);
    final fresh = LocationLoaded(
      location: const Location(lat: 0.332, lng: 32.568, address: 'Makerere'),
      accuracyMeters: 20,
      acquiredAt: now.subtract(const Duration(seconds: 20)),
    );
    final stale = LocationLoaded(
      location: const Location(lat: 0.332, lng: 32.568, address: 'Makerere'),
      accuracyMeters: 20,
      acquiredAt: now.subtract(const Duration(seconds: 31)),
    );
    expect(locationNeedsRefresh(fresh, now), isFalse);
    expect(locationNeedsRefresh(stale, now), isTrue);
  });

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
          accuracyMeters: 75,
        ),
      );
      addTearDown(container.dispose);

      await container
          .read(locationNotifierProvider.notifier)
          .fetchCurrentLocation();

      final state = container.read(locationNotifierProvider).valueOrNull;
      expect(state, isA<LocationLowAccuracy>());
      expect((state as LocationLowAccuracy).accuracyMeters, 75);
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
    expect(state.actionLabel, 'Open settings');
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

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
