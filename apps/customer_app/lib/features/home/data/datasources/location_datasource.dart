import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:http/http.dart' as http;

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

    // Step 4 — Get the current position.
    // We use AndroidSettings with forceLocationManager: false to use
    // Google's Fused Location Provider which intelligently combines
    // GPS + WiFi + cell towers and picks the best available source.
    // No timeLimit — let it wait for the best fix rather than cutting
    // off at 10s and returning a WiFi-based inaccurate result.
    if (kIsWeb) {
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        // forceLocationManager: false uses Google Fused Location Provider
        // which gives much better accuracy than raw GPS on Android
        forceLocationManager: false,
        // timeLimit removed — better to wait for accurate GPS
        // than return fast but wrong WiFi position
      ),
    );
  }

  /// Converts lat/lng coordinates to a human-readable address string.
  ///
  /// On web: calls Google Maps Geocoding API directly via HTTP.
  /// On mobile: uses the geocoding package (native device geocoding).
  ///
  /// Why two approaches?
  /// The geocoding package uses native iOS/Android geocoding APIs
  /// which don't exist in a browser. On web we call the REST API directly.
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    if (kIsWeb) {
      return _getAddressWeb(lat, lng);
    }
    return _getAddressMobile(lat, lng);
  }

  /// Web: calls Google Maps Geocoding REST API.
  /// Requires the Maps JavaScript API key to be loaded in index.html.
  Future<String> _getAddressWeb(double lat, double lng) async {
    // We read the API key from the script tag loaded in index.html
    // by calling the Google Maps JS API geocoder via HTTP REST endpoint.
    // This avoids hardcoding the key in Dart code.
    const apiKey = String.fromEnvironment(
      'GOOGLE_MAPS_API_KEY',
      defaultValue: '',
    );

    if (apiKey.isEmpty) {
      // Fallback if key not injected via --dart-define
      // The address will show as coordinates on web dev
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=$lat,$lng&key=$apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      // Use the first result's formatted_address
      final formatted = results.first['formatted_address'] as String?;
      if (formatted == null || formatted.isEmpty) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      // Trim to the first two comma-separated parts for concise display
      // "39 Bukoto St, Kampala, Uganda" → "39 Bukoto St, Kampala"
      final parts = formatted.split(',');
      return parts.take(2).map((p) => p.trim()).join(', ');
    } catch (_) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }

  /// Mobile: uses the geocoding package (native device geocoding).
  Future<String> _getAddressMobile(double lat, double lng) async {
    try {
      final placemarks = await geo.placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      final place = placemarks.first;
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

      return parts.take(2).join(', ');
    } catch (_) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}
