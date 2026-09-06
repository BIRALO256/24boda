import '../contracts/contract_enums.dart';
import '../contracts/contract_parsing.dart';
import '../value_objects/delivery_snapshots.dart';
import '../value_objects/geo_coordinate.dart';

final class DeliveryQuote {
  const DeliveryQuote({
    required this.id,
    required this.customerId,
    required this.pickup,
    required this.dropoff,
    required this.routeDistanceMeters,
    required this.routeDurationSeconds,
    required this.price,
    required this.pricingRuleVersion,
    required this.serviceZoneId,
    required this.createdAt,
    required this.expiresAt,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String id;
  final String customerId;
  final LocationSnapshot pickup;
  final LocationSnapshot dropoff;
  final int routeDistanceMeters;
  final int routeDurationSeconds;
  final PriceSnapshot price;
  final int pricingRuleVersion;
  final String serviceZoneId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int schemaVersion;

  bool isExpiredAt(DateTime instant) =>
      !instant.toUtc().isBefore(expiresAt.toUtc());

  factory DeliveryQuote.fromMap(Map<String, dynamic> map) => DeliveryQuote(
    id: ContractParsing.string(map['id'], 'id'),
    customerId: ContractParsing.string(map['customerId'], 'customerId'),
    pickup: LocationSnapshot.fromMap(
      ContractParsing.map(map['pickup'], 'pickup'),
    ),
    dropoff: LocationSnapshot.fromMap(
      ContractParsing.map(map['dropoff'], 'dropoff'),
    ),
    routeDistanceMeters: ContractParsing.integer(
      map['routeDistanceMeters'],
      'routeDistanceMeters',
      minimum: 0,
    ),
    routeDurationSeconds: ContractParsing.integer(
      map['routeDurationSeconds'],
      'routeDurationSeconds',
      minimum: 0,
    ),
    price: PriceSnapshot.fromMap(ContractParsing.map(map['price'], 'price')),
    pricingRuleVersion: ContractParsing.integer(
      map['pricingRuleVersion'],
      'pricingRuleVersion',
      minimum: 1,
    ),
    serviceZoneId: ContractParsing.string(
      map['serviceZoneId'],
      'serviceZoneId',
    ),
    createdAt: ContractParsing.dateTime(map['createdAt'], 'createdAt'),
    expiresAt: ContractParsing.dateTime(map['expiresAt'], 'expiresAt'),
    schemaVersion: ContractParsing.schemaVersion(map),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'pickup': pickup.toMap(),
    'dropoff': dropoff.toMap(),
    'routeDistanceMeters': routeDistanceMeters,
    'routeDurationSeconds': routeDurationSeconds,
    'price': price.toMap(),
    'pricingRuleVersion': pricingRuleVersion,
    'serviceZoneId': serviceZoneId,
    'createdAt': createdAt.toUtc(),
    'expiresAt': expiresAt.toUtc(),
    'schemaVersion': schemaVersion,
  };
}

final class DeliveryShipment {
  const DeliveryShipment({
    required this.id,
    required this.publicCode,
    required this.customerId,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.package,
    required this.quoteId,
    required this.price,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.createdAt,
    required this.updatedAt,
    this.assignedRiderId,
    this.acceptedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String id;
  final String publicCode;
  final String customerId;
  final String? assignedRiderId;
  final DeliveryStatus status;
  final LocationSnapshot pickup;
  final LocationSnapshot dropoff;
  final PackageSnapshot package;
  final String quoteId;
  final PriceSnapshot price;
  final PaymentStatus paymentStatus;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? acceptedAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final int schemaVersion;

  factory DeliveryShipment.fromMap(Map<String, dynamic> map) =>
      DeliveryShipment(
        id: ContractParsing.string(map['id'], 'id'),
        publicCode: ContractParsing.string(map['publicCode'], 'publicCode'),
        customerId: ContractParsing.string(map['customerId'], 'customerId'),
        assignedRiderId: ContractParsing.optionalString(
          map['assignedRiderId'],
          'assignedRiderId',
        ),
        status: DeliveryStatus.fromValue(
          ContractParsing.string(map['status'], 'status'),
        ),
        pickup: LocationSnapshot.fromMap(
          ContractParsing.map(map['pickup'], 'pickup'),
        ),
        dropoff: LocationSnapshot.fromMap(
          ContractParsing.map(map['dropoff'], 'dropoff'),
        ),
        package: PackageSnapshot.fromMap(
          ContractParsing.map(map['package'], 'package'),
        ),
        quoteId: ContractParsing.string(map['quoteId'], 'quoteId'),
        price: PriceSnapshot.fromMap(
          ContractParsing.map(map['price'], 'price'),
        ),
        paymentStatus: PaymentStatus.fromValue(
          ContractParsing.string(map['paymentStatus'], 'paymentStatus'),
        ),
        paymentMethod: PaymentMethod.fromValue(
          ContractParsing.string(map['paymentMethod'], 'paymentMethod'),
        ),
        createdAt: ContractParsing.dateTime(map['createdAt'], 'createdAt'),
        updatedAt: ContractParsing.dateTime(map['updatedAt'], 'updatedAt'),
        acceptedAt: ContractParsing.optionalDateTime(
          map['acceptedAt'],
          'acceptedAt',
        ),
        pickedUpAt: ContractParsing.optionalDateTime(
          map['pickedUpAt'],
          'pickedUpAt',
        ),
        deliveredAt: ContractParsing.optionalDateTime(
          map['deliveredAt'],
          'deliveredAt',
        ),
        cancelledAt: ContractParsing.optionalDateTime(
          map['cancelledAt'],
          'cancelledAt',
        ),
        schemaVersion: ContractParsing.schemaVersion(map),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'publicCode': publicCode,
    'customerId': customerId,
    'assignedRiderId': assignedRiderId,
    'status': status.value,
    'pickup': pickup.toMap(),
    'dropoff': dropoff.toMap(),
    'package': package.toMap(),
    'quoteId': quoteId,
    'price': price.toMap(),
    'paymentStatus': paymentStatus.value,
    'paymentMethod': paymentMethod.value,
    'createdAt': createdAt.toUtc(),
    'updatedAt': updatedAt.toUtc(),
    'acceptedAt': acceptedAt?.toUtc(),
    'pickedUpAt': pickedUpAt?.toUtc(),
    'deliveredAt': deliveredAt?.toUtc(),
    'cancelledAt': cancelledAt?.toUtc(),
    'schemaVersion': schemaVersion,
  };
}

final class ShipmentOffer {
  const ShipmentOffer({
    required this.id,
    required this.shipmentId,
    required this.riderId,
    required this.status,
    required this.distanceToPickupMeters,
    required this.offeredAt,
    required this.expiresAt,
    this.respondedAt,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String id;
  final String shipmentId;
  final String riderId;
  final ShipmentOfferStatus status;
  final int distanceToPickupMeters;
  final DateTime offeredAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final int schemaVersion;

  factory ShipmentOffer.fromMap(Map<String, dynamic> map) => ShipmentOffer(
    id: ContractParsing.string(map['id'], 'id'),
    shipmentId: ContractParsing.string(map['shipmentId'], 'shipmentId'),
    riderId: ContractParsing.string(map['riderId'], 'riderId'),
    status: ShipmentOfferStatus.fromValue(
      ContractParsing.string(map['status'], 'status'),
    ),
    distanceToPickupMeters: ContractParsing.integer(
      map['distanceToPickupMeters'],
      'distanceToPickupMeters',
      minimum: 0,
    ),
    offeredAt: ContractParsing.dateTime(map['offeredAt'], 'offeredAt'),
    expiresAt: ContractParsing.dateTime(map['expiresAt'], 'expiresAt'),
    respondedAt: ContractParsing.optionalDateTime(
      map['respondedAt'],
      'respondedAt',
    ),
    schemaVersion: ContractParsing.schemaVersion(map),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'shipmentId': shipmentId,
    'riderId': riderId,
    'status': status.value,
    'distanceToPickupMeters': distanceToPickupMeters,
    'offeredAt': offeredAt.toUtc(),
    'expiresAt': expiresAt.toUtc(),
    'respondedAt': respondedAt?.toUtc(),
    'schemaVersion': schemaVersion,
  };
}

final class ShipmentEvent {
  const ShipmentEvent({
    required this.id,
    required this.type,
    required this.actorRole,
    required this.occurredAt,
    this.fromStatus,
    this.toStatus,
    this.actorId,
    this.reasonCode,
    this.location,
    this.metadata = const {},
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String id;
  final String type;
  final DeliveryStatus? fromStatus;
  final DeliveryStatus? toStatus;
  final String? actorId;
  final EventActorRole actorRole;
  final String? reasonCode;
  final GeoCoordinate? location;
  final Map<String, Object?> metadata;
  final DateTime occurredAt;
  final int schemaVersion;

  factory ShipmentEvent.fromMap(Map<String, dynamic> map) => ShipmentEvent(
    id: ContractParsing.string(map['id'], 'id'),
    type: ContractParsing.string(map['type'], 'type'),
    fromStatus: map['fromStatus'] == null
        ? null
        : DeliveryStatus.fromValue(
            ContractParsing.string(map['fromStatus'], 'fromStatus'),
          ),
    toStatus: map['toStatus'] == null
        ? null
        : DeliveryStatus.fromValue(
            ContractParsing.string(map['toStatus'], 'toStatus'),
          ),
    actorId: ContractParsing.optionalString(map['actorId'], 'actorId'),
    actorRole: EventActorRole.fromValue(
      ContractParsing.string(map['actorRole'], 'actorRole'),
    ),
    reasonCode: ContractParsing.optionalString(map['reasonCode'], 'reasonCode'),
    location: map['location'] == null
        ? null
        : GeoCoordinate.fromMap(
            ContractParsing.map(map['location'], 'location'),
          ),
    metadata: Map<String, Object?>.from(
      ContractParsing.map(map['metadata'] ?? {}, 'metadata'),
    ),
    occurredAt: ContractParsing.dateTime(map['occurredAt'], 'occurredAt'),
    schemaVersion: ContractParsing.schemaVersion(map),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'fromStatus': fromStatus?.value,
    'toStatus': toStatus?.value,
    'actorId': actorId,
    'actorRole': actorRole.value,
    'reasonCode': reasonCode,
    'location': location?.toMap(),
    'metadata': metadata,
    'occurredAt': occurredAt.toUtc(),
    'schemaVersion': schemaVersion,
  };
}
