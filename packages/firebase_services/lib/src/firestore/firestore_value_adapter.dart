import 'package:cloud_firestore/cloud_firestore.dart';

/// Converts Firebase SDK values at the infrastructure boundary while keeping
/// core_models independent of Firebase.
abstract final class FirestoreValueAdapter {
  static DateTime dateTime(Object? value, String field) {
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    throw FormatException('$field must be a Firestore timestamp');
  }

  static GeoPoint geoPoint(Object? value, String field) {
    if (value is GeoPoint) return value;
    throw FormatException('$field must be a GeoPoint');
  }

  /// Normalizes Firestore-only values into maps understood by core_models.
  static Map<String, dynamic> forCoreModel(Map<String, dynamic> source) {
    Object? normalize(Object? value) {
      if (value is Timestamp) return value.toDate().toUtc();
      if (value is GeoPoint) {
        return {'latitude': value.latitude, 'longitude': value.longitude};
      }
      if (value is Map) {
        return value.map<String, dynamic>(
          (key, item) => MapEntry(key.toString(), normalize(item)),
        );
      }
      if (value is Iterable) {
        return value.map(normalize).toList(growable: false);
      }
      return value;
    }

    return normalize(source)! as Map<String, dynamic>;
  }

  /// Converts canonical coordinate maps to native GeoPoint values recursively.
  /// DateTime values are accepted directly by cloud_firestore and become Timestamp.
  static Map<String, dynamic> forFirestore(Map<String, dynamic> source) {
    Object? encode(Object? value, {String? key}) {
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        if (key == 'coordinate' &&
            map['latitude'] is num &&
            map['longitude'] is num) {
          return GeoPoint(
            (map['latitude'] as num).toDouble(),
            (map['longitude'] as num).toDouble(),
          );
        }
        return map.map(
          (childKey, item) => MapEntry(childKey, encode(item, key: childKey)),
        );
      }
      if (value is Iterable) return value.map((item) => encode(item)).toList();
      return value;
    }

    return encode(source)! as Map<String, dynamic>;
  }
}
