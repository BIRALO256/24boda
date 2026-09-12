import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:theme/theme.dart';

import 'package:customer_app/features/home/presentation/providers/location_provider.dart';
import 'package:customer_app/features/home/presentation/providers/map_provider.dart';

class MapView extends ConsumerWidget {
  const MapView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markers = ref.watch(mapMarkersProvider);
    final locationState = ref.watch(locationNotifierProvider).valueOrNull;
    final hasLocationPermission =
        locationState is LocationLoaded || locationState is LocationLowAccuracy;

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: kKampalaDefault,
        zoom: kDefaultZoom,
      ),
      onMapCreated: ref.read(mapNotifierProvider.notifier).onMapCreated,
      markers: markers,
      myLocationEnabled: hasLocationPermission,
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

class MyLocationButton extends ConsumerWidget {
  const MyLocationButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        final state = ref.read(locationNotifierProvider).valueOrNull;
        final location = switch (state) {
          LocationLoaded(:final location) => location,
          LocationLowAccuracy(:final location) => location,
          _ => null,
        };
        if (location != null) {
          await ref
              .read(mapNotifierProvider.notifier)
              .animateTo(LatLng(location.lat, location.lng));
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
