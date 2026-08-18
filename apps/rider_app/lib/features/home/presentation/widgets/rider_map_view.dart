import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// Kampala city centre — default before GPS locks
const LatLng kKampalaDefault = LatLng(0.3476, 32.5825);
const double kDefaultZoom = 15.0;

/// Full-screen Google Map for the rider app.
///
/// Shows the rider's current position with the blue dot.
/// Camera follows the rider automatically when they go online.
/// Traffic layer enabled — helps riders find faster routes.
class RiderMapView extends ConsumerStatefulWidget {
  const RiderMapView({super.key});

  @override
  ConsumerState<RiderMapView> createState() => _RiderMapViewState();
}

class _RiderMapViewState extends ConsumerState<RiderMapView> {
  GoogleMapController? _mapController;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInitMap();
  }

  Future<void> _checkPermissionAndInitMap() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (mounted) {
      setState(() => _locationPermissionGranted = granted);
    }

    if (granted) {
      _moveToCurrentLocation();
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: kDefaultZoom,
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: kKampalaDefault,
        zoom: kDefaultZoom,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        if (_locationPermissionGranted) {
          _moveToCurrentLocation();
        }
      },
      myLocationEnabled: _locationPermissionGranted,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      trafficEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      rotateGesturesEnabled: true,
    );
  }
}
