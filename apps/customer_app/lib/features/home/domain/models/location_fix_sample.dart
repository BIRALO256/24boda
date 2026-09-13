import 'dart:async';
import 'dart:math' as math;

final class LocationFixSample {
  const LocationFixSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.timestamp,
    required this.isMocked,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime timestamp;
  final bool isMocked;
}

final class LocationFixAcquirer {
  const LocationFixAcquirer();

  Future<LocationFixResult> select(
    Stream<LocationFixSample> samples, {
    DateTime Function()? now,
  }) async {
    final clock = now ?? DateTime.now;
    LocationFixSample? best;
    LocationFixSample? previousReliable;

    await for (final sample in samples) {
      if (!LocationFixPolicy.isEligible(sample, clock())) continue;
      best = best == null ? sample : LocationFixPolicy.better(best, sample);
      if (!LocationFixPolicy.isReliable(sample)) continue;
      if (previousReliable != null &&
          LocationFixPolicy.areConsistent(previousReliable, sample)) {
        return LocationFixResult(
          sample: LocationFixPolicy.better(previousReliable, sample),
          isStable: true,
        );
      }
      previousReliable = sample;
    }

    if (best != null) return LocationFixResult(sample: best, isStable: false);
    throw TimeoutException('No fresh location fix was received.');
  }
}

final class LocationFixResult {
  const LocationFixResult({required this.sample, required this.isStable});

  final LocationFixSample sample;
  final bool isStable;
}

abstract final class LocationFixPolicy {
  static const maxAge = Duration(seconds: 10);
  static const reliableAccuracyMeters = 30.0;
  static const usableAccuracyMeters = 50.0;
  static const consistencyDistanceMeters = 30.0;

  static bool isEligible(LocationFixSample sample, DateTime now) {
    final age = now.toUtc().difference(sample.timestamp.toUtc());
    return !sample.isMocked &&
        sample.latitude >= -90 &&
        sample.latitude <= 90 &&
        sample.longitude >= -180 &&
        sample.longitude <= 180 &&
        sample.accuracyMeters.isFinite &&
        sample.accuracyMeters > 0 &&
        age >= const Duration(seconds: -2) &&
        age <= maxAge;
  }

  static bool isReliable(LocationFixSample sample) =>
      sample.accuracyMeters <= reliableAccuracyMeters;

  static bool areConsistent(
    LocationFixSample first,
    LocationFixSample second,
  ) => distanceMeters(first, second) <= consistencyDistanceMeters;

  static LocationFixSample better(
    LocationFixSample current,
    LocationFixSample candidate,
  ) => candidate.accuracyMeters < current.accuracyMeters ? candidate : current;

  static double distanceMeters(
    LocationFixSample first,
    LocationFixSample second,
  ) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(second.latitude - first.latitude);
    final longitudeDelta = _radians(second.longitude - first.longitude);
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(_radians(first.latitude)) *
            math.cos(_radians(second.latitude)) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
