import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/home/domain/usecases/get_current_location.dart';
import 'package:customer_app/features/home/domain/repositories/location_repository.dart';

/// State of the location detection process.
sealed class LocationState {
  const LocationState();
}

/// Initial state — location not yet fetched.
final class LocationInitial extends LocationState {
  const LocationInitial();
}

/// Fetching GPS position.
final class LocationLoading extends LocationState {
  const LocationLoading();
}

/// GPS position fetched successfully.
final class LocationLoaded extends LocationState {
  const LocationLoaded({required this.location, required this.accuracyMeters});
  final Location location;
  final double accuracyMeters;
}

final class LocationLowAccuracy extends LocationState {
  const LocationLowAccuracy({
    required this.location,
    required this.accuracyMeters,
  });

  final Location location;
  final double accuracyMeters;
}

/// Location fetch failed.
final class LocationError extends LocationState {
  const LocationError({required this.reason, required this.message});
  final LocationFailureReason reason;
  final String message;
}

/// Manages GPS location state for the home screen.
///
/// Called once when the home screen mounts.
/// The fetched location becomes the default pickup address.
///
/// Why a separate provider and not inline in home_screen?
/// Separation of concerns — the home screen widget should not
/// contain location-fetching logic. It reads state, displays UI.
/// The notifier owns the business logic of how location is obtained.
class LocationNotifier extends AutoDisposeAsyncNotifier<LocationState> {
  @override
  Future<LocationState> build() async {
    return const LocationInitial();
  }

  /// Fetches the current GPS location.
  /// Called from home_screen when it first mounts.
  Future<void> fetchCurrentLocation() async {
    state = const AsyncData(LocationLoading());

    try {
      final result = await ref.read(getCurrentLocationProvider).call();
      state = result.accuracyMeters > 100
          ? AsyncData(
              LocationLowAccuracy(
                location: result.location,
                accuracyMeters: result.accuracyMeters,
              ),
            )
          : AsyncData(
              LocationLoaded(
                location: result.location,
                accuracyMeters: result.accuracyMeters,
              ),
            );
    } on LocationException catch (error) {
      state = AsyncData(
        LocationError(reason: error.reason, message: error.message),
      );
    } catch (_) {
      state = const AsyncData(
        LocationError(
          reason: LocationFailureReason.unknown,
          message: 'Something went wrong while finding your location.',
        ),
      );
    }
  }
}

/// Provider for [LocationNotifier].
final locationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<LocationNotifier, LocationState>(() {
      return LocationNotifier();
    });
