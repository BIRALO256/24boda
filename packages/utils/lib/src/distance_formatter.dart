import 'dart:math';

/// Distance formatting and calculation utilities for 24Boda.
///
/// Two responsibilities:
/// 1. Formatting distances for display (meters → human readable string)
/// 2. Calculating straight-line distance between two lat/lng points
///    using the Haversine formula.
///
/// Why Haversine and not Google Maps Distance Matrix API?
/// - Haversine is instant — zero network call, zero cost
/// - Accurate enough for price estimation (within 5-10% of road distance)
/// - Google Distance Matrix API costs money per call
/// - We use Google Maps for actual navigation — not for price estimation
///
/// Display rules:
/// - Under 1 km  → show in metres:     "850 m"
/// - 1 km and up → show in kilometres: "2.3 km"
abstract final class DistanceFormatter {
  /// Earth's mean radius in kilometres.
  static const double _earthRadiusKm = 6371.0;

  /// Formats a distance in kilometres for display.
  ///
  /// Examples:
  /// - 0.35  → "350 m"
  /// - 0.999 → "999 m"
  /// - 1.0   → "1.0 km"
  /// - 2.367 → "2.4 km"
  /// - 15.0  → "15.0 km"
  static String format(double distanceKm) {
    if (distanceKm < 1.0) {
      final metres = (distanceKm * 1000).round();
      return '$metres m';
    }
    // Round to 1 decimal place
    final rounded = (distanceKm * 10).round() / 10;
    return '${rounded.toStringAsFixed(1)} km';
  }

  /// Formats a distance with a descriptive label for the booking screen.
  ///
  /// Examples:
  /// - 2.3  → "2.3 km away"
  /// - 0.5  → "500 m away"
  static String formatWithLabel(double distanceKm) {
    return '${format(distanceKm)} away';
  }

  /// Formats an estimated duration in minutes for display.
  ///
  /// Examples:
  /// - 3   → "3 mins"
  /// - 1   → "1 min"
  /// - 65  → "1 hr 5 mins"
  /// - 120 → "2 hrs"
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes ${minutes == 1 ? 'min' : 'mins'}';
    }
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) {
      return '$hours ${hours == 1 ? 'hr' : 'hrs'}';
    }
    return '$hours ${hours == 1 ? 'hr' : 'hrs'} $remainingMins mins';
  }

  /// Calculates the straight-line distance between two lat/lng points
  /// using the Haversine formula. Returns distance in kilometres.
  ///
  /// The Haversine formula accounts for the curvature of the Earth.
  /// For Kampala distances (typically 0.5–20 km), accuracy is within
  /// 5-10% of actual road distance — sufficient for price estimation.
  ///
  /// Parameters:
  /// - [lat1], [lng1]: coordinates of point A (e.g. pickup)
  /// - [lat2], [lng2]: coordinates of point B (e.g. dropoff)
  static double haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusKm * c;
  }

  /// Estimates delivery duration in minutes based on distance and
  /// an assumed average speed for boda boda in Kampala traffic.
  ///
  /// Average speeds used (based on Kampala traffic reality):
  /// - Short distances (< 3 km): 20 km/h — dense city traffic
  /// - Medium distances (3–10 km): 25 km/h — mixed traffic
  /// - Long distances (> 10 km): 30 km/h — outskirts, less traffic
  ///
  /// A minimum of 5 minutes is always applied regardless of distance
  /// to account for pickup/handoff time.
  static int estimateDurationMinutes(double distanceKm) {
    const int minimumMinutes = 5;

    final double speedKmh = switch (distanceKm) {
      < 3.0 => 20.0,
      < 10.0 => 25.0,
      _ => 30.0,
    };

    final int calculated = (distanceKm / speedKmh * 60).ceil();
    return max(calculated, minimumMinutes);
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
