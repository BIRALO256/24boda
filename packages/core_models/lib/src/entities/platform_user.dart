import '../contracts/contract_enums.dart';
import '../contracts/contract_parsing.dart';
import '../enums/user_role.dart';

final class PlatformUser {
  PlatformUser({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phoneE164,
    this.email,
    this.profilePhotoPath,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  }) {
    if (uid.trim().isEmpty) throw ArgumentError.value(uid, 'uid');
    if (displayName.trim().isEmpty &&
        status != AccountStatus.pendingOnboarding) {
      throw ArgumentError.value(displayName, 'displayName');
    }
    if (phoneE164 == null && email == null) {
      throw ArgumentError('A phone number or email is required');
    }
  }

  final String uid;
  final UserRole role;
  final String? phoneE164;
  final String? email;
  final String displayName;
  final String? profilePhotoPath;
  final AccountStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  factory PlatformUser.fromMap(Map<String, dynamic> map) => PlatformUser(
    uid: ContractParsing.string(map['uid'] ?? map['id'], 'uid'),
    role: UserRole.fromValue(ContractParsing.string(map['role'], 'role')),
    phoneE164: ContractParsing.optionalString(
      map['phoneE164'] ?? map['phone'],
      'phoneE164',
    ),
    email: ContractParsing.optionalString(map['email'], 'email'),
    displayName: ContractParsing.string(
      map['displayName'] ?? map['name'],
      'displayName',
      allowEmpty: true,
    ),
    profilePhotoPath: ContractParsing.optionalString(
      map['profilePhotoPath'] ?? map['profilePhotoUrl'],
      'profilePhotoPath',
    ),
    status: map['status'] != null
        ? AccountStatus.fromValue(
            ContractParsing.string(map['status'], 'status'),
          )
        : ContractParsing.boolean(map['isActive'], 'isActive')
        ? AccountStatus.active
        : AccountStatus.suspended,
    createdAt: ContractParsing.dateTime(map['createdAt'], 'createdAt'),
    updatedAt: ContractParsing.dateTime(map['updatedAt'], 'updatedAt'),
    schemaVersion: ContractParsing.schemaVersion(map),
  );

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'role': role.value,
    'phoneE164': phoneE164,
    'email': email,
    'displayName': displayName,
    'profilePhotoPath': profilePhotoPath,
    'status': status.value,
    'createdAt': createdAt.toUtc(),
    'updatedAt': updatedAt.toUtc(),
    'schemaVersion': schemaVersion,
  };

  bool get isActive => status == AccountStatus.active;
}
