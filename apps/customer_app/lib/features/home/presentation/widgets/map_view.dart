import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/home/presentation/providers/location_provider.dart';
import 'package:customer_app/features/home/presentation/providers/map_provider.dart';

/// Full-screen Google Map widget.
class MapView extends ConsumerStatefulWidget {
  const MapView({super.key});

  @override
  ConsumerState<MapView> createState() => _MapViewState();
}

class _MapViewState extends ConsumerState<MapView> {
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    final granted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
    if (mounted) {
      setState(() => _locationPermissionGranted = granted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = ref.watch(mapMarkersProvider);
    final locationState = ref.watch(locationNotifierProvider).valueOrNull;

    // Re-check permission after location fetches — by then the
    // geolocator has already requested and the user may have granted it
    ref.listen<AsyncValue<LocationState>>(locationNotifierProvider, (_, next) {
      next.whenData((state) {
        if (state is LocationLoaded && !_locationPermissionGranted) {
          _checkLocationPermission();
        }
      });
    });

    // Start at Kampala until GPS resolves
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
      markers: markers,
      // Only enable after permission granted — avoids Android error log
      myLocationEnabled: _locationPermissionGranted,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      zoomGesturesEnabled: true,
      zoomControlsEnabled: false,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: true,
      trafficEnabled: true,
    );
  }
}

/// Custom my-location FAB — sits above the bottom sheet in the thumb zone.
class MyLocationButton extends ConsumerWidget {
  const MyLocationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final locationState = ref.read(locationNotifierProvider).valueOrNull;
        if (locationState is LocationLoaded) {
          await ref
              .read(mapNotifierProvider.notifier)
              .animateTo(
                LatLng(locationState.location.lat, locationState.location.lng),
              );
        } else {
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
