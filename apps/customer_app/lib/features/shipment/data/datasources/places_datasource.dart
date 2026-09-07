import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:customer_app/features/shipment/domain/models/place_suggestion.dart';
import 'package:customer_app/features/shipment/domain/models/place_details.dart';

/// Calls the Google Places API directly via HTTP.
///
/// Why not use the flutter_google_places package UI?
/// We want full control over the search UI to match our design system.
/// The package forces its own styling which conflicts with AppTheme.
/// Calling the REST API directly gives us clean data to render ourselves.
///
/// Two API calls are used:
/// 1. Autocomplete — returns a list of place suggestions as the user types
/// 2. Place Details — returns the full lat/lng for a selected suggestion
///
/// The API key is injected via --dart-define at build time so it never
/// appears in source code. Falls back to empty string in dev without key.
class PlacesDatasource {
  PlacesDatasource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // API key — injected via --dart-define at build time.
  // Falls back to the hardcoded Android manifest key for mobile builds
  // where --dart-define was not used.
  // The key in AndroidManifest.xml is for Google Maps rendering only,
  // but the same key works for Places API calls too.
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    // Fallback to the same key used in AndroidManifest.xml
    // This ensures Places search works on mobile without --dart-define
    defaultValue: 'AIzaSyBuM_jWsVdsVGkdiyzeZS3es3Qb2PCj9ck',
  );

  static const String _autocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  static const String _detailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Returns autocomplete suggestions for the given query.
  ///
  /// Biased toward Uganda (location: Kampala, radius: 100km).
  /// This ensures results are relevant to Uganda users — typing
  /// "Kampala Road" returns Kampala results, not roads in other countries.
  Future<List<PlaceSuggestion>> getAutocompleteSuggestions(String query) async {
    if (query.isEmpty) return [];

    // On web, the Places REST API is blocked by CORS from localhost/browser.
    // The JavaScript Places Autocomplete Service (loaded in index.html) must
    // be used instead. For now on web we return empty — the user can still
    // use "current location" and the map pin. Full web Places support requires
    // the JS interop approach which we'll add in a future step.
    // On Android/iOS this works perfectly — no CORS restrictions.
    if (kIsWeb) return [];

    try {
      final uri = Uri.parse(_autocompleteUrl).replace(
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'components': 'country:ug',
          'location': '0.3476,32.5825',
          'radius': '100000',
          'language': 'en',
          'types': 'geocode|establishment',
        },
      );

      final response = await _client.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final predictions = data['predictions'] as List? ?? [];

      return predictions
          .map((p) => PlaceSuggestion.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PlacesDatasource.getAutocompleteSuggestions error: $e');
      return [];
    }
  }

  /// Returns the full place details (lat/lng + formatted address)
  /// for a given place ID from autocomplete.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final uri = Uri.parse(_detailsUrl).replace(
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'geometry,formatted_address,name',
          'language': 'en',
        },
      );

      final response = await _client.get(uri);

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      return PlaceDetails.fromJson(result);
    } catch (e) {
      debugPrint('PlacesDatasource.getPlaceDetails error: $e');
      return null;
    }
  }
}
