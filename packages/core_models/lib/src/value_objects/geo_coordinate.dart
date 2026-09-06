import 'package:core_models/src/contracts/contract_parsing.dart';

/// Firebase-independent latitude and longitude pair.
final class GeoCoordinate {
  GeoCoordinate({required this.latitude, required this.longitude}) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Must be between -90 and 90',
      );
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be between -180 and 180',
      );
    }
  }

  final double latitude;
  final double longitude;

  factory GeoCoordinate.fromMap(Map<String, dynamic> map) => GeoCoordinate(
    latitude: ContractParsing.decimal(map['latitude'], 'latitude'),
    longitude: ContractParsing.decimal(map['longitude'], 'longitude'),
  );

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  @override
  bool operator ==(Object other) =>
      other is GeoCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}
