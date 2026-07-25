import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Kampala city centre — default map position before GPS loads.
/// Used so the map opens at a meaningful location for Uganda users
/// rather than the default (0,0) which is in the middle of the ocean.
const LatLng kKampalaDefault = LatLng(0.3476, 32.5825);

/// Default zoom level for the home screen map.
/// 15.0 = neighbourhood level — shows streets clearly without being too zoomed in.
/// Research: Google Maps UX guidelines recommend 14-16 for urban navigation.
const double kDefaultZoom = 15.0;

/// State of the Google Map controller.
sealed class MapState {
  const MapState();
}

final class MapUninitialized extends MapState {
  const MapUninitialized();
}

final class MapReady extends MapState {
  const MapReady({required this.controller});
  final GoogleMapController controller;
}

/// Manages the Google Map controller and camera state.
///
/// Responsibilities:
/// - Stores the GoogleMapController once the map is created
/// - Animates the camera to the user's GPS location when it loads
/// - Manages the current position marker on the map
///
/// Why store the controller in Riverpod and not in a StatefulWidget?
/// The controller needs to be accessed from multiple places:
/// - home_screen mounts and gets the initial location
/// - delivery_bottom_sheet needs to pan the camera when user picks a location
/// - map_view renders based on controller state
/// Storing it in Riverpod makes it accessible to all of them without prop drilling.
class MapNotifier extends AutoDisposeNotifier<MapState> {
  @override
  MapState build() => const MapUninitialized();

  /// Called by [MapView] when the GoogleMap widget is created.
  void onMapCreated(GoogleMapController controller) {
    state = MapReady(controller: controller);
  }

  /// Animates the camera to the given position.
  /// Called when the user's GPS location is fetched.
  Future<void> animateTo(LatLng position, {double zoom = kDefaultZoom}) async {
    final current = state;
    if (current is! MapReady) return;

    await current.controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: zoom),
      ),
    );
  }

  /// Disposes the map controller when the provider is disposed.
  /// Prevents memory leaks when navigating away from the home screen.
  void disposeController() {
    final current = state;
    if (current is MapReady) {
      current.controller.dispose();
    }
    state = const MapUninitialized();
  }
}

/// Provider for [MapNotifier].
final mapNotifierProvider =
    AutoDisposeNotifierProvider<MapNotifier, MapState>(() {
  return MapNotifier();
});

/// The set of markers shown on the map.
/// Currently only the user's current location marker.
/// Expanded later to include: rider location, dropoff pin.
final mapMarkersProvider = StateProvider.autoDispose<Set<Marker>>((ref) {
  return {};
});
