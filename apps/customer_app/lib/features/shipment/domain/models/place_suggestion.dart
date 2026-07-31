/// A single autocomplete suggestion from the Google Places API.
///
/// Contains the human-readable description shown in the list
/// and the placeId needed to fetch full details (lat/lng).
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  /// Unique Google Places identifier — used to fetch lat/lng.
  final String placeId;

  /// Full human-readable description.
  /// Example: "Kampala Road, Kampala, Uganda"
  final String description;

  /// The primary part of the description (bold in the UI).
  /// Example: "Kampala Road"
  final String mainText;

  /// The secondary part (dimmed in the UI).
  /// Example: "Kampala, Uganda"
  final String secondaryText;

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final structuredFormatting =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};

    return PlaceSuggestion(
      placeId: json['place_id'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: structuredFormatting['main_text'] as String? ?? '',
      secondaryText:
          structuredFormatting['secondary_text'] as String? ?? '',
    );
  }
}
