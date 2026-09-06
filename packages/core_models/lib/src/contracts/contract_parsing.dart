/// Strict helpers used at untyped storage and network boundaries.
abstract final class ContractParsing {
  static const int currentSchemaVersion = 1;

  static Map<String, dynamic> map(Object? value, String field) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw FormatException('$field must be an object');
  }

  static String string(Object? value, String field, {bool allowEmpty = false}) {
    if (value is! String || (!allowEmpty && value.trim().isEmpty)) {
      throw FormatException('$field must be a non-empty string');
    }
    return value;
  }

  static String? optionalString(Object? value, String field) {
    if (value == null) return null;
    return string(value, field);
  }

  static int integer(Object? value, String field, {int? minimum}) {
    if (value is! num ||
        value.isNaN ||
        value.isInfinite ||
        value != value.round()) {
      throw FormatException('$field must be an integer');
    }
    final result = value.toInt();
    if (minimum != null && result < minimum) {
      throw FormatException('$field must be at least $minimum');
    }
    return result;
  }

  static double decimal(Object? value, String field) {
    if (value is! num || value.isNaN || value.isInfinite) {
      throw FormatException('$field must be a finite number');
    }
    return value.toDouble();
  }

  static bool boolean(Object? value, String field) {
    if (value is! bool) throw FormatException('$field must be a boolean');
    return value;
  }

  /// Reads the Firebase-independent timestamp representation produced by the
  /// infrastructure adapter.
  static DateTime dateTime(Object? value, String field) {
    if (value is DateTime) return value.toUtc();
    throw FormatException('$field must be a timestamp');
  }

  static DateTime? optionalDateTime(Object? value, String field) =>
      value == null ? null : dateTime(value, field);

  static int schemaVersion(Map<String, dynamic> map) {
    final version = integer(map['schemaVersion'], 'schemaVersion', minimum: 1);
    if (version > currentSchemaVersion) {
      throw FormatException('Unsupported schema version: $version');
    }
    return version;
  }
}
