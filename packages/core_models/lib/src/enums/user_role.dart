/// The role of a user in the 24Boda platform.
///
/// All three roles share a single [users] Firestore collection.
/// This field is what Firebase Security Rules reads to grant
/// or deny access to collections and documents.
///
/// - [customer] — books and tracks deliveries
/// - [rider]    — accepts and fulfils delivery jobs
/// - [admin]    — manages the platform via the React web dashboard
enum UserRole {
  customer,
  rider,
  admin;

  /// Firestore-safe string value for serialisation.
  String get value => switch (this) {
    UserRole.customer => 'customer',
    UserRole.rider => 'rider',
    UserRole.admin => 'admin',
  };

  /// Deserialise from Firestore string value.
  static UserRole fromValue(String value) => switch (value) {
    'customer' => UserRole.customer,
    'rider' => UserRole.rider,
    'admin' => UserRole.admin,
    _ => throw ArgumentError('Unknown UserRole value: $value'),
  };
}
