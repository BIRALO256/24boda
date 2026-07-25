import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import 'package:customer_app/features/home/domain/repositories/location_repository.dart';

/// All direct platform location API calls live here.
///
/// This is the ONLY file that imports geolocator or geocoding.
/// Isolating platform calls here means:
/// - Swapping geolocator for a different plugin = change one file
/// - Unit tests mock this class — no real GPS hardware needed
/// - The repository shapes data, this datasource fetches raw data
///
/// Web vs Mobile difference:
/// On web, geolocator uses the browser's Geolocation API.
/// On mobile, it uses the device GPS directly.
/// Both return the same Position object — no conditional code needed here.
class LocationDatasource {
  /// Requests location permission and returns the current position.
  ///
  /// Permission flow:
  /// 1. Check if location services are enabled
  /// 2. Check current permission status
  /// 3. Request if not granted
  /// 4. Get position
  ///
  /// Throws [LocationException] with a user-friendly message on failure.
  Future<Position> getCurrentPosition() async {
    // Step 1 — Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Location services are disabled. Please enable GPS in your device settings.',
      );
    }

    // Step 2 — Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // Step 3 — Request permission if denied
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Location permission was denied. Please allow location access to use 24Boda.',
        );
      }
    }

    // Permanently denied — user must go to settings
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Please enable it in your app settings.',
      );
    }

    // Step 4 — Get the current position
    // LocationAccuracy.high — we need precise GPS for pickup location
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Converts lat/lng coordinates to a human-readable address string.
  ///
  /// Uses reverse geocoding via the geocoding package.
  /// On web this calls the Google Maps Geocoding API.
  /// On mobile this calls the platform's native geocoding service.
  ///
  /// Returns a formatted address string or a fallback coordinate string
  /// if reverse geocoding fails (e.g. no network, unmapped area).
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // Web doesn't support geocoding package — return coordinate string
    if (kIsWeb) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }

    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      final place = placemarks.first;

      // Build a human-readable address from the placemark fields
      // Priority: street → subLocality → locality → country
      final parts = <String>[
        if (place.name != null && place.name!.isNotEmpty) place.name!,
        if (place.street != null && place.street!.isNotEmpty) place.street!,
        if (place.subLocality != null && place.subLocality!.isNotEmpty)
          place.subLocality!,
        if (place.locality != null && place.locality!.isNotEmpty)
          place.locality!,
      ];

      if (parts.isEmpty) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      // Take first 2 parts for a concise display address
      return parts.take(2).join(', ');
    } catch (_) {
      // Geocoding failed — return coordinates as fallback
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}
