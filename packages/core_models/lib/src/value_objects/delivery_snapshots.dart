import '../contracts/contract_parsing.dart';
import 'geo_coordinate.dart';

final class LocationSnapshot {
  LocationSnapshot({
    required this.address,
    required this.coordinate,
    this.placeId,
    this.contactName,
    this.contactPhoneE164,
  }) {
    if (address.trim().isEmpty) throw ArgumentError.value(address, 'address');
  }

  final String address;
  final GeoCoordinate coordinate;
  final String? placeId;
  final String? contactName;
  final String? contactPhoneE164;

  factory LocationSnapshot.fromMap(Map<String, dynamic> map) =>
      LocationSnapshot(
        address: ContractParsing.string(map['address'], 'address'),
        coordinate: GeoCoordinate.fromMap(
          ContractParsing.map(map['coordinate'], 'coordinate'),
        ),
        placeId: ContractParsing.optionalString(map['placeId'], 'placeId'),
        contactName: ContractParsing.optionalString(
          map['contactName'],
          'contactName',
        ),
        contactPhoneE164: ContractParsing.optionalString(
          map['contactPhoneE164'],
          'contactPhoneE164',
        ),
      );

  Map<String, dynamic> toMap() => {
    'address': address,
    'coordinate': coordinate.toMap(),
    'placeId': placeId,
    'contactName': contactName,
    'contactPhoneE164': contactPhoneE164,
  };
}

final class PackageSnapshot {
  PackageSnapshot({
    required this.size,
    this.description,
    this.photoPath,
    this.customerNote,
  }) {
    if (size.trim().isEmpty) throw ArgumentError.value(size, 'size');
  }

  final String size;
  final String? description;
  final String? photoPath;
  final String? customerNote;

  factory PackageSnapshot.fromMap(Map<String, dynamic> map) => PackageSnapshot(
    size: ContractParsing.string(map['size'], 'size'),
    description: ContractParsing.optionalString(
      map['description'],
      'description',
    ),
    photoPath: ContractParsing.optionalString(map['photoPath'], 'photoPath'),
    customerNote: ContractParsing.optionalString(
      map['customerNote'],
      'customerNote',
    ),
  );

  Map<String, dynamic> toMap() => {
    'size': size,
    'description': description,
    'photoPath': photoPath,
    'customerNote': customerNote,
  };
}

final class PriceSnapshot {
  PriceSnapshot({
    required this.subtotalUgx,
    required this.discountUgx,
    required this.customerTotalUgx,
    required this.riderEarningUgx,
    required this.platformCommissionUgx,
    required this.taxUgx,
    required this.surgeBasisPoints,
    this.currency = 'UGX',
  }) {
    final amounts = [
      subtotalUgx,
      discountUgx,
      customerTotalUgx,
      riderEarningUgx,
      platformCommissionUgx,
      taxUgx,
    ];
    if (amounts.any((amount) => amount < 0)) {
      throw ArgumentError('Price amounts cannot be negative');
    }
    if (currency != 'UGX') throw ArgumentError.value(currency, 'currency');
  }

  final int subtotalUgx;
  final int discountUgx;
  final int customerTotalUgx;
  final int riderEarningUgx;
  final int platformCommissionUgx;
  final int taxUgx;
  final int surgeBasisPoints;
  final String currency;

  factory PriceSnapshot.fromMap(Map<String, dynamic> map) => PriceSnapshot(
    subtotalUgx: ContractParsing.integer(
      map['subtotalUgx'],
      'subtotalUgx',
      minimum: 0,
    ),
    discountUgx: ContractParsing.integer(
      map['discountUgx'],
      'discountUgx',
      minimum: 0,
    ),
    customerTotalUgx: ContractParsing.integer(
      map['customerTotalUgx'],
      'customerTotalUgx',
      minimum: 0,
    ),
    riderEarningUgx: ContractParsing.integer(
      map['riderEarningUgx'],
      'riderEarningUgx',
      minimum: 0,
    ),
    platformCommissionUgx: ContractParsing.integer(
      map['platformCommissionUgx'],
      'platformCommissionUgx',
      minimum: 0,
    ),
    taxUgx: ContractParsing.integer(map['taxUgx'], 'taxUgx', minimum: 0),
    surgeBasisPoints: ContractParsing.integer(
      map['surgeBasisPoints'],
      'surgeBasisPoints',
      minimum: 0,
    ),
    currency: ContractParsing.string(map['currency'], 'currency'),
  );

  Map<String, dynamic> toMap() => {
    'subtotalUgx': subtotalUgx,
    'discountUgx': discountUgx,
    'customerTotalUgx': customerTotalUgx,
    'riderEarningUgx': riderEarningUgx,
    'platformCommissionUgx': platformCommissionUgx,
    'taxUgx': taxUgx,
    'surgeBasisPoints': surgeBasisPoints,
    'currency': currency,
  };
}
