/// Full details for a selected place — lat, lng, and formatted address.
///
/// Returned by the Places Details API after the user selects
/// a suggestion from the autocomplete list.
class PlaceDetails {
  const PlaceDetails({
    required this.lat,
    required this.lng,
    required this.formattedAddress,
    required this.name,
  });

  final double lat;
  final double lng;
  final String formattedAddress;
  final String name;

  /// The display address — prefer name for short places,
  /// formatted_address for full street addresses.
  String get displayAddress => name.isNotEmpty ? name : formattedAddress;

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};

    return PlaceDetails(
      lat: (location['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (location['lng'] as num?)?.toDouble() ?? 0.0,
      formattedAddress: json['formatted_address'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
