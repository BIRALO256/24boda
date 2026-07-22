import 'package:core_models/src/enums/vehicle_type.dart';
import 'package:core_models/src/value_objects/location.dart';

/// Extended profile for a 24Boda rider.
///
/// Maps to the [riders/{userId}] Firestore collection.
/// The document ID matches the rider's Firebase Auth UID
/// and their [users/{userId}] document.
///
/// Why a separate entity from [UserProfile]?
/// A rider has 9+ fields that are completely irrelevant to customers
/// and admins. Mixing them into [UserProfile] would mean every customer
/// profile load carries vehicle, location, and earnings data they
/// will never use. Clean separation keeps queries lean and secure.
///
/// A complete rider profile is the combination of:
///   [UserProfile] (from users collection) + [Rider] (from riders collection)
class Rider {
  const Rider({
    required this.id,
    required this.vehicleType,
    required this.plateNumber,
    required this.idPhotoUrl,
    required this.isApproved,
    required this.isOnline,
    required this.rating,
    required this.totalTrips,
    required this.totalEarnings,
    required this.createdAt,
    required this.updatedAt,
    this.currentLocation,
    this.lastSeen,
  });

  /// Firebase Auth UID. Matches the document ID in riders/{id}
  /// and the corresponding users/{id} document.
  final String id;

  /// The type of vehicle this rider uses.
  /// Affects matching radius, pricing, and capacity.
  final VehicleType vehicleType;

  /// Vehicle registration plate number.
  /// Required for approval — verified by admin before rider goes live.
  final String plateNumber;

  /// Firebase Storage URL of the rider's national ID photo.
  /// Uploaded during registration, reviewed during manual approval.
  final String idPhotoUrl;

  /// Whether this rider has been approved by an admin.
  /// Only approved riders can go online and receive jobs.
  /// Set to false on registration, true after admin review.
  /// This is the manual gate that every ride-hailing platform uses.
  final bool isApproved;

  /// Whether the rider is currently available to receive jobs.
  /// Only meaningful when [isApproved] is true.
  /// Toggled by the rider from their home screen.
  final bool isOnline;

  /// The rider's current GPS position.
  /// Updated every 5 seconds while [isOnline] is true.
  /// Null when the rider is offline.
  final Location? currentLocation;

  /// Average rating from customers. Range: 1.0 to 5.0.
  /// Initialised at 5.0 on creation (benefit of the doubt).
  /// Recalculated after each delivered shipment.
  final double rating;

  /// Total number of successfully completed deliveries.
  /// Incremented on each [ShipmentStatus.delivered] event.
  final int totalTrips;

  /// Cumulative earnings in UGX across all completed trips.
  /// 80% of each delivery fee — the platform retains 20%.
  final double totalEarnings;

  /// When the rider last updated their location or status.
  /// Used to detect stale online riders and remove them from
  /// the active pool if they haven't updated in 60+ seconds.
  final DateTime? lastSeen;

  /// When this rider document was first created (registration date).
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Whether this rider can currently receive job requests.
  /// Both conditions must be true.
  bool get isAvailable => isApproved && isOnline;

  /// Returns a copy of this rider with the given fields replaced.
  Rider copyWith({
    String? id,
    VehicleType? vehicleType,
    String? plateNumber,
    String? idPhotoUrl,
    bool? isApproved,
    bool? isOnline,
    Location? currentLocation,
    double? rating,
    int? totalTrips,
    double? totalEarnings,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Rider(
      id: id ?? this.id,
      vehicleType: vehicleType ?? this.vehicleType,
      plateNumber: plateNumber ?? this.plateNumber,
      idPhotoUrl: idPhotoUrl ?? this.idPhotoUrl,
      isApproved: isApproved ?? this.isApproved,
      isOnline: isOnline ?? this.isOnline,
      currentLocation: currentLocation ?? this.currentLocation,
      rating: rating ?? this.rating,
      totalTrips: totalTrips ?? this.totalTrips,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serialise to a plain [Map] for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleType': vehicleType.value,
      'plateNumber': plateNumber,
      'idPhotoUrl': idPhotoUrl,
      'isApproved': isApproved,
      'isOnline': isOnline,
      if (currentLocation != null) 'currentLocation': currentLocation!.toMap(),
      'rating': rating,
      'totalTrips': totalTrips,
      'totalEarnings': totalEarnings,
      if (lastSeen != null) 'lastSeen': lastSeen!.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Deserialise from a Firestore [Map].
  factory Rider.fromMap(Map<String, dynamic> map) {
    return Rider(
      id: map['id'] as String,
      vehicleType: VehicleType.fromValue(map['vehicleType'] as String),
      plateNumber: map['plateNumber'] as String,
      idPhotoUrl: map['idPhotoUrl'] as String,
      isApproved: map['isApproved'] as bool,
      isOnline: map['isOnline'] as bool,
      currentLocation: map['currentLocation'] != null
          ? Location.fromMap(map['currentLocation'] as Map<String, dynamic>)
          : null,
      rating: (map['rating'] as num).toDouble(),
      totalTrips: map['totalTrips'] as int,
      totalEarnings: (map['totalEarnings'] as num).toDouble(),
      lastSeen: map['lastSeen'] != null
          ? DateTime.parse(map['lastSeen'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Rider(id: $id, vehicleType: ${vehicleType.value}, isOnline: $isOnline, isApproved: $isApproved, rating: $rating)';
}
