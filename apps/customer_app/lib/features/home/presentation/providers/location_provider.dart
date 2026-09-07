import 'package:core_models/core_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:customer_app/features/home/domain/usecases/get_current_location.dart';

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
  const LocationLoaded({required this.location});
  final Location location;
}

/// Location fetch failed.
final class LocationError extends LocationState {
  const LocationError({required this.message});
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
      final location = await ref.read(getCurrentLocationProvider).call();
      state = AsyncData(LocationLoaded(location: location));
    } catch (e) {
      state = AsyncData(
        LocationError(
          message: e.toString().replaceFirst('LocationException: ', ''),
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
