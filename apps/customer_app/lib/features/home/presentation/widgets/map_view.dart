import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/home/presentation/providers/map_provider.dart';
import 'package:customer_app/features/home/presentation/providers/location_provider.dart';

/// The Google Map widget — fills 100% of the screen.
///
/// Design decisions:
///
/// Full-screen map (no padding):
/// The map takes 100% of screen space. The top bar and bottom sheet
/// float OVER it. This is the Uber/Bolt/Google Maps pattern —
/// the map is the primary content, not a secondary element.
/// Research: users orient spatially first, then take action.
/// Giving the map full screen maximises this spatial understanding.
///
/// Map style — minimal UI controls:
/// We hide the default Google Maps toolbar (directions/maps buttons)
/// because they conflict with our custom UI and send users out of the app.
/// We keep the zoom controls off — pinch-to-zoom is the universal gesture.
///
/// Camera starts at Kampala:
/// Before GPS loads, the map shows Kampala city centre.
/// Users in Uganda immediately recognise their city — context is established
/// before the GPS pin drops. Zero confusion about "where am I".
///
/// My location button — custom, not default:
/// We use a custom FAB instead of the built-in myLocationButtonEnabled
/// because the built-in button's position cannot be customised — it always
/// appears top-right behind our top bar. Our custom button sits above
/// the bottom sheet in a reachable thumb-zone position.
class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(mapMarkersProvider);
    final locationState = ref.watch(locationNotifierProvider).valueOrNull;

    // Determine the initial camera target
    // If location is loaded, start there. Otherwise start at Kampala centre.
    LatLng initialTarget = kKampalaDefault;
    if (locationState is LocationLoaded) {
      initialTarget = LatLng(
        locationState.location.lat,
        locationState.location.lng,
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: kDefaultZoom,
      ),
      onMapCreated: (controller) {
        ref.read(mapNotifierProvider.notifier).onMapCreated(controller);
      },

      // Markers — pickup pin, rider location (added in tracking step)
      markers: markers,

      // My location layer — shows the blue dot at current GPS position
      myLocationEnabled: true,

      // Disable default my-location button — we use a custom one
      myLocationButtonEnabled: false,

      // Disable default toolbar — prevents users leaving the app via
      // Google Maps "open in Google Maps" button
      mapToolbarEnabled: false,

      // Disable compass — we control map orientation
      compassEnabled: false,

      // Enable zoom gestures — pinch to zoom is the universal touch gesture
      zoomGesturesEnabled: true,
      zoomControlsEnabled: false,

      // Enable scroll/tilt/rotate
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false, // Disable tilt — not needed for delivery map
      rotateGesturesEnabled: true,

      // Traffic layer — shows real-time Kampala traffic
      // Helps customers estimate delivery time more accurately
      trafficEnabled: true,
    );
  }
}

/// Custom "my location" FAB — repositioned above the bottom sheet.
///
/// Why custom instead of built-in?
/// The built-in button always appears top-right — behind our floating top bar.
/// This custom button sits above the bottom sheet in the right-thumb zone.
class MyLocationButton extends ConsumerWidget {
  const MyLocationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final locationState =
            ref.read(locationNotifierProvider).valueOrNull;
        if (locationState is LocationLoaded) {
          await ref.read(mapNotifierProvider.notifier).animateTo(
                LatLng(
                  locationState.location.lat,
                  locationState.location.lng,
                ),
              );
        } else {
          // Trigger a fresh location fetch
          await ref
              .read(locationNotifierProvider.notifier)
              .fetchCurrentLocation();
        }
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.background,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.dark.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location_rounded,
          color: AppColors.primary,
          size: AppSpacing.iconLg,
        ),
      ),
    );
  }
}
