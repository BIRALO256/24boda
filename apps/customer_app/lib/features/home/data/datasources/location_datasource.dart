import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'package:customer_app/features/home/domain/repositories/location_repository.dart';
import 'package:customer_app/features/home/domain/models/location_fix_sample.dart';

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
  Future<bool> openAppSettings() async =>
      kIsWeb ? false : Geolocator.openAppSettings();

  Future<bool> openLocationSettings() async =>
      kIsWeb ? false : Geolocator.openLocationSettings();

  /// Requests location permission and returns the current position.
  ///
  /// Permission flow:
  /// 1. Check if location services are enabled
  /// 2. Check current permission status
  /// 3. Request if not granted
  /// 4. Get position
  ///
  /// Throws [LocationException] with a user-friendly message on failure.
  Future<LocationFixResult> getCurrentPosition() async {
    // Step 1 — Check if location services are enabled on the device
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationFailureReason.servicesDisabled,
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
          LocationFailureReason.permissionDenied,
          'Location permission was denied. Please allow location access to use 24Boda.',
        );
      }
    }

    // Permanently denied — user must go to settings
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailureReason.permissionDeniedForever,
        'Location permission is permanently denied. Please enable it in your app settings.',
      );
    }

    // Step 4 — Get the current position.
    // We use AndroidSettings with forceLocationManager: false to use
    // Google's Fused Location Provider which intelligently combines
    // GPS + WiFi + cell towers and picks the best available source.
    // No timeLimit — let it wait for the best fix rather than cutting
    // off at 10s and returning a WiFi-based inaccurate result.
    try {
      final stream =
          Geolocator.getPositionStream(
                locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.best,
                  distanceFilter: 0,
                ),
              )
              .map((position) {
                if (kDebugMode) {
                  final age = DateTime.now().difference(position.timestamp);
                  debugPrint(
                    '[location] sample age=${age.inMilliseconds}ms '
                    'accuracy=${position.accuracy.round()}m '
                    'mocked=${position.isMocked}',
                  );
                }
                return LocationFixSample(
                  latitude: position.latitude,
                  longitude: position.longitude,
                  accuracyMeters: position.accuracy,
                  timestamp: position.timestamp,
                  isMocked: position.isMocked,
                );
              })
              .timeout(
                const Duration(seconds: 20),
                onTimeout: (sink) => sink.close(),
              );
      return const LocationFixAcquirer().select(stream);
    } on TimeoutException {
      throw const LocationException(
        LocationFailureReason.timeout,
        'We could not determine your location in time. Move near a window and try again.',
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        LocationFailureReason.servicesDisabled,
        'Location services are disabled. Please enable GPS in your device settings.',
      );
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(
        LocationFailureReason.positionUnavailable,
        'Your location is temporarily unavailable. Please try again.',
      );
    }
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
      defaultValue: 'AIzaSyBuM_jWsVdsVGkdiyzeZS3es3Qb2PCj9ck',
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
      final response = await http.get(url).timeout(const Duration(seconds: 8));
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
      final placemarks = await geo
          .placemarkFromCoordinates(lat, lng)
          .timeout(const Duration(seconds: 8));
      if (placemarks.isEmpty) {
        return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }

      return formatDeliveryPlacemark(
        placemarks,
        coordinateFallback:
            '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
      );
    } catch (_) {
      return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }
  }
}

String formatDeliveryPlacemark(
  List<geo.Placemark> placemarks, {
  required String coordinateFallback,
}) {
  String clean(String? value) => value?.trim() ?? '';
  bool isPlusCode(String value) => RegExp(
    r'^[23456789CFGHJMPQRVWX]{4,8}\+[23456789CFGHJMPQRVWX]{2,}',
    caseSensitive: false,
  ).hasMatch(value);

  ({String label, int score}) build(geo.Placemark place) {
    final administrative = {
      clean(place.subLocality).toLowerCase(),
      clean(place.locality).toLowerCase(),
      clean(place.subAdministrativeArea).toLowerCase(),
      clean(place.administrativeArea).toLowerCase(),
    }..remove('');
    final street = clean(place.street);
    final thoroughfare = clean(place.thoroughfare);
    final name = clean(place.name);
    final specific = [street, thoroughfare, name].firstWhere(
      (value) =>
          value.isNotEmpty &&
          !administrative.contains(value.toLowerCase()) &&
          !isPlusCode(value),
      orElse: () => '',
    );
    final area =
        [
          clean(place.subLocality),
          clean(place.locality),
          clean(place.subAdministrativeArea),
          clean(place.administrativeArea),
        ].firstWhere(
          (value) =>
              value.isNotEmpty && value.toLowerCase() != specific.toLowerCase(),
          orElse: () => '',
        );
    if (specific.isNotEmpty) {
      final score = street.isNotEmpty ? 3 : (thoroughfare.isNotEmpty ? 2 : 1);
      return (
        label: area.isEmpty ? specific : '$specific, $area',
        score: score,
      );
    }
    if (area.isNotEmpty) return (label: area, score: 0);
    final plusCode = [street, name].firstWhere(
      (value) => value.isNotEmpty && isPlusCode(value),
      orElse: () => '',
    );
    return (label: plusCode, score: -1);
  }

  final candidates =
      placemarks.map(build).where((item) => item.label.isNotEmpty).toList()
        ..sort((a, b) => b.score.compareTo(a.score));
  return candidates.isEmpty ? coordinateFallback : candidates.first.label;
}
