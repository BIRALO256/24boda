import 'package:core_models/core_models.dart';

enum DeliveryQuotePackageSize {
  small,
  medium,
  large,
  fragile;

  String get value => name;
}

final class CreateDeliveryQuoteRequest {
  CreateDeliveryQuoteRequest({
    required this.idempotencyKey,
    required this.pickup,
    required this.dropoff,
    required this.packageSize,
  }) {
    if (!RegExp(r'^[A-Za-z0-9_-]{16,128}$').hasMatch(idempotencyKey)) {
      throw ArgumentError.value(idempotencyKey, 'idempotencyKey');
    }
  }

  final String idempotencyKey;
  final LocationSnapshot pickup;
  final LocationSnapshot dropoff;
  final DeliveryQuotePackageSize packageSize;

  Map<String, Object?> toMap() => {
    'idempotencyKey': idempotencyKey,
    'pickup': pickup.toMap(),
    'dropoff': dropoff.toMap(),
    'packageSize': packageSize.value,
  };
}

DeliveryQuote parseDeliveryQuoteResponse(Object? value) {
  final map = ContractParsing.map(value, 'deliveryQuote');
  _requireExactKeys(map, const {
    'id',
    'customerId',
    'pickup',
    'dropoff',
    'routeDistanceMeters',
    'routeDurationSeconds',
    'price',
    'pricingRuleVersion',
    'serviceZoneId',
    'createdAt',
    'expiresAt',
    'schemaVersion',
  });
  final schemaVersion = ContractParsing.integer(
    map['schemaVersion'],
    'schemaVersion',
    minimum: 1,
  );
  if (schemaVersion != 1) {
    throw FormatException('Unsupported quote schema: $schemaVersion');
  }

  final createdAt = _parseIsoInstant(map['createdAt'], 'createdAt');
  final expiresAt = _parseIsoInstant(map['expiresAt'], 'expiresAt');
  if (!expiresAt.isAfter(createdAt)) {
    throw const FormatException('Quote expiry must follow creation time.');
  }

  return DeliveryQuote.fromMap({
    ...map,
    'createdAt': createdAt,
    'expiresAt': expiresAt,
  });
}

DateTime _parseIsoInstant(Object? value, String field) {
  final text = ContractParsing.string(value, field);
  final parsed = DateTime.tryParse(text);
  if (parsed == null || !text.endsWith('Z')) {
    throw FormatException('$field must be a UTC ISO-8601 timestamp');
  }
  return parsed.toUtc();
}

void _requireExactKeys(Map<String, dynamic> map, Set<String> expected) {
  final actual = map.keys.toSet();
  final unexpected = actual.difference(expected);
  final missing = expected.difference(actual);
  if (unexpected.isNotEmpty || missing.isNotEmpty) {
    throw FormatException(
      'Invalid delivery quote fields; missing=$missing unexpected=$unexpected',
    );
  }
}
