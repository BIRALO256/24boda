import '../contracts/contract_enums.dart';
import '../contracts/contract_parsing.dart';
import '../enums/vehicle_type.dart';
import '../value_objects/geo_coordinate.dart';

final class RiderApplication {
  RiderApplication({
    required this.id,
    required this.phoneE164,
    required this.displayName,
    required this.vehicleType,
    required this.plateNumber,
    required this.documentPaths,
    required this.status,
    required this.createdByAdminId,
    required this.createdAt,
    required this.updatedAt,
    this.linkedUid,
    this.reviewedByAdminId,
    this.rejectionCode,
    this.verifiedAt,
    this.reviewedAt,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  }) {
    if (!RegExp(r'^\+256\d{9}$').hasMatch(phoneE164)) {
      throw ArgumentError.value(phoneE164, 'phoneE164');
    }
    if (id.isEmpty ||
        displayName.trim().isEmpty ||
        plateNumber.trim().isEmpty) {
      throw ArgumentError('Application identity fields cannot be empty');
    }
  }

  final String id;
  final String phoneE164;
  final String displayName;
  final VehicleType vehicleType;
  final String plateNumber;
  final Map<String, String> documentPaths;
  final RiderApplicationStatus status;
  final String? linkedUid;
  final String createdByAdminId;
  final String? reviewedByAdminId;
  final String? rejectionCode;
  final DateTime createdAt;
  final DateTime? verifiedAt;
  final DateTime? reviewedAt;
  final DateTime updatedAt;
  final int schemaVersion;

  factory RiderApplication.fromMap(Map<String, dynamic> map) {
    final paths = ContractParsing.map(
      map['documentPaths'] ?? {},
      'documentPaths',
    );
    return RiderApplication(
      id: ContractParsing.string(map['id'], 'id'),
      phoneE164: ContractParsing.string(map['phoneE164'], 'phoneE164'),
      displayName: ContractParsing.string(map['displayName'], 'displayName'),
      vehicleType: VehicleType.fromValue(
        ContractParsing.string(map['vehicleType'], 'vehicleType'),
      ),
      plateNumber: ContractParsing.string(map['plateNumber'], 'plateNumber'),
      documentPaths: paths.map(
        (key, value) =>
            MapEntry(key, ContractParsing.string(value, 'documentPaths.$key')),
      ),
      status: RiderApplicationStatus.fromValue(
        ContractParsing.string(map['status'], 'status'),
      ),
      linkedUid: ContractParsing.optionalString(map['linkedUid'], 'linkedUid'),
      createdByAdminId: ContractParsing.string(
        map['createdByAdminId'],
        'createdByAdminId',
      ),
      reviewedByAdminId: ContractParsing.optionalString(
        map['reviewedByAdminId'],
        'reviewedByAdminId',
      ),
      rejectionCode: ContractParsing.optionalString(
        map['rejectionCode'],
        'rejectionCode',
      ),
      createdAt: ContractParsing.dateTime(map['createdAt'], 'createdAt'),
      verifiedAt: ContractParsing.optionalDateTime(
        map['verifiedAt'],
        'verifiedAt',
      ),
      reviewedAt: ContractParsing.optionalDateTime(
        map['reviewedAt'],
        'reviewedAt',
      ),
      updatedAt: ContractParsing.dateTime(map['updatedAt'], 'updatedAt'),
      schemaVersion: ContractParsing.schemaVersion(map),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'phoneE164': phoneE164,
    'displayName': displayName,
    'vehicleType': vehicleType.value,
    'plateNumber': plateNumber,
    'documentPaths': documentPaths,
    'status': status.value,
    'linkedUid': linkedUid,
    'createdByAdminId': createdByAdminId,
    'reviewedByAdminId': reviewedByAdminId,
    'rejectionCode': rejectionCode,
    'createdAt': createdAt.toUtc(),
    'verifiedAt': verifiedAt?.toUtc(),
    'reviewedAt': reviewedAt?.toUtc(),
    'updatedAt': updatedAt.toUtc(),
    'schemaVersion': schemaVersion,
  };
}

final class RiderProfile {
  const RiderProfile({
    required this.uid,
    required this.applicationId,
    required this.vehicleType,
    required this.plateNumber,
    required this.approvalStatus,
    required this.ratingAverage,
    required this.ratingCount,
    required this.completedShipmentCount,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String uid;
  final String applicationId;
  final VehicleType vehicleType;
  final String plateNumber;
  final RiderApprovalStatus approvalStatus;
  final double ratingAverage;
  final int ratingCount;
  final int completedShipmentCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  factory RiderProfile.fromMap(Map<String, dynamic> map) => RiderProfile(
    uid: ContractParsing.string(map['uid'] ?? map['id'], 'uid'),
    applicationId: ContractParsing.string(
      map['applicationId'],
      'applicationId',
    ),
    vehicleType: VehicleType.fromValue(
      ContractParsing.string(map['vehicleType'], 'vehicleType'),
    ),
    plateNumber: ContractParsing.string(map['plateNumber'], 'plateNumber'),
    approvalStatus: RiderApprovalStatus.fromValue(
      ContractParsing.string(map['approvalStatus'], 'approvalStatus'),
    ),
    ratingAverage: ContractParsing.decimal(
      map['ratingAverage'],
      'ratingAverage',
    ),
    ratingCount: ContractParsing.integer(
      map['ratingCount'],
      'ratingCount',
      minimum: 0,
    ),
    completedShipmentCount: ContractParsing.integer(
      map['completedShipmentCount'],
      'completedShipmentCount',
      minimum: 0,
    ),
    createdAt: ContractParsing.dateTime(map['createdAt'], 'createdAt'),
    updatedAt: ContractParsing.dateTime(map['updatedAt'], 'updatedAt'),
    schemaVersion: ContractParsing.schemaVersion(map),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'applicationId': applicationId,
    'vehicleType': vehicleType.value,
    'plateNumber': plateNumber,
    'approvalStatus': approvalStatus.value,
    'ratingAverage': ratingAverage,
    'ratingCount': ratingCount,
    'completedShipmentCount': completedShipmentCount,
    'createdAt': createdAt.toUtc(),
    'updatedAt': updatedAt.toUtc(),
    'schemaVersion': schemaVersion,
  };
}

final class RiderPresence {
  const RiderPresence({
    required this.uid,
    required this.availability,
    required this.sessionId,
    required this.lastSeenAt,
    this.location,
    this.geohash,
    this.headingDegrees,
    this.speedMps,
    this.accuracyMeters,
    this.activeShipmentId,
    this.locationRecordedAt,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String uid;
  final RiderAvailability availability;
  final GeoCoordinate? location;
  final String? geohash;
  final double? headingDegrees;
  final double? speedMps;
  final double? accuracyMeters;
  final String? activeShipmentId;
  final String sessionId;
  final DateTime lastSeenAt;
  final DateTime? locationRecordedAt;
  final int schemaVersion;

  factory RiderPresence.fromMap(String uid, Map<String, dynamic> map) =>
      RiderPresence(
        uid: uid,
        availability: RiderAvailability.fromValue(
          ContractParsing.string(map['availability'], 'availability'),
        ),
        location: map['location'] == null
            ? null
            : GeoCoordinate.fromMap(
                ContractParsing.map(map['location'], 'location'),
              ),
        geohash: ContractParsing.optionalString(map['geohash'], 'geohash'),
        headingDegrees: map['headingDegrees'] == null
            ? null
            : ContractParsing.decimal(map['headingDegrees'], 'headingDegrees'),
        speedMps: map['speedMps'] == null
            ? null
            : ContractParsing.decimal(map['speedMps'], 'speedMps'),
        accuracyMeters: map['accuracyMeters'] == null
            ? null
            : ContractParsing.decimal(map['accuracyMeters'], 'accuracyMeters'),
        activeShipmentId: ContractParsing.optionalString(
          map['activeShipmentId'],
          'activeShipmentId',
        ),
        sessionId: ContractParsing.string(map['sessionId'], 'sessionId'),
        lastSeenAt: ContractParsing.dateTime(map['lastSeenAt'], 'lastSeenAt'),
        locationRecordedAt: ContractParsing.optionalDateTime(
          map['locationRecordedAt'],
          'locationRecordedAt',
        ),
        schemaVersion: ContractParsing.schemaVersion(map),
      );

  Map<String, dynamic> toMap() => {
    'availability': availability.value,
    'location': location?.toMap(),
    'geohash': geohash,
    'headingDegrees': headingDegrees,
    'speedMps': speedMps,
    'accuracyMeters': accuracyMeters,
    'activeShipmentId': activeShipmentId,
    'sessionId': sessionId,
    'lastSeenAt': lastSeenAt.toUtc(),
    'locationRecordedAt': locationRecordedAt?.toUtc(),
    'schemaVersion': schemaVersion,
  };
}
