import 'package:core_models/src/enums/user_role.dart';

/// A 24Boda platform user.
///
/// This entity represents every person in the system regardless of role.
/// It maps directly to the [users/{userId}] Firestore collection.
///
/// All three roles (customer, rider, admin) have a [UserProfile].
/// Riders additionally have a [Rider] document in the [riders] collection
/// which extends this with vehicle and operational data.
///
/// Fields marked required vs optional:
/// - Required at creation: [id], [phone], [role], [createdAt]
/// - Required after onboarding: [name]
/// - Optional always: [profilePhotoUrl], [fcmToken]
///
/// Why [fcmToken] is here and not in [Rider]:
/// Both customers and riders receive push notifications.
/// The token is updated on every login regardless of role.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.phone,
    required this.role,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    this.profilePhotoUrl,
    this.fcmToken,
  });

  /// Firebase Auth UID. This is the primary key for this document.
  /// It matches the document ID in Firestore: users/{id}
  final String id;

  /// Phone number in E.164 format: +256XXXXXXXXX
  /// This is the user's identity — it never changes after registration.
  final String phone;

  /// The user's role in the platform.
  /// Drives access control in Firebase Security Rules.
  final UserRole role;

  /// Display name. Collected during onboarding, shown to other parties
  /// in the delivery (rider sees customer name, customer sees rider name).
  final String name;

  /// URL to the user's profile photo in Firebase Storage.
  /// Null until the user uploads one — never required to use the app.
  final String? profilePhotoUrl;

  /// Firebase Cloud Messaging token for push notifications.
  /// Updated every time the user opens the app. Null until first login
  /// with notifications permission granted.
  final String? fcmToken;

  /// Account creation timestamp. Set once, never updated.
  final DateTime createdAt;

  /// Last update timestamp. Updated on every document write.
  final DateTime updatedAt;

  /// Whether the account is active. False = soft-deleted or banned.
  /// We never hard-delete users — always soft delete to preserve
  /// shipment history integrity.
  final bool isActive;

  /// Convenience getter — is this user a customer?
  bool get isCustomer => role == UserRole.customer;

  /// Convenience getter — is this user a rider?
  bool get isRider => role == UserRole.rider;

  /// Convenience getter — is this user an admin?
  bool get isAdmin => role == UserRole.admin;

  /// Returns a copy of this profile with the given fields replaced.
  UserProfile copyWith({
    String? id,
    String? phone,
    UserRole? role,
    String? name,
    String? profilePhotoUrl,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      name: name ?? this.name,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Serialise to a plain [Map] for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'role': role.value,
      'name': name,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Deserialise from a Firestore [Map].
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      phone: map['phone'] as String,
      role: UserRole.fromValue(map['role'] as String),
      name: map['name'] as String,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isActive: map['isActive'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserProfile(id: $id, name: $name, phone: $phone, role: ${role.value})';
}
