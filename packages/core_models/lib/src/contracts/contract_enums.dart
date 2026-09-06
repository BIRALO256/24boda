/// Lifecycle of an account across all 24Boda clients.
enum AccountStatus {
  pendingOnboarding('pending_onboarding'),
  active('active'),
  suspended('suspended'),
  closed('closed');

  const AccountStatus(this.value);
  final String value;

  static AccountStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown account status: $value'),
  );
}

enum RiderApplicationStatus {
  pendingVerification('pending_verification'),
  verified('verified'),
  approved('approved'),
  rejected('rejected'),
  withdrawn('withdrawn');

  const RiderApplicationStatus(this.value);
  final String value;

  static RiderApplicationStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () =>
        throw FormatException('Unknown rider application status: $value'),
  );
}

enum RiderApprovalStatus {
  approved('approved'),
  suspended('suspended'),
  revoked('revoked');

  const RiderApprovalStatus(this.value);
  final String value;

  static RiderApprovalStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () =>
        throw FormatException('Unknown rider approval status: $value'),
  );
}

enum RiderAvailability {
  offline('offline'),
  available('available'),
  offered('offered'),
  assigned('assigned');

  const RiderAvailability(this.value);
  final String value;

  static RiderAvailability fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown rider availability: $value'),
  );
}

enum DeliveryStatus {
  quoted('quoted'),
  searching('searching'),
  offered('offered'),
  accepted('accepted'),
  enRoutePickup('en_route_pickup'),
  arrivedPickup('arrived_pickup'),
  pickedUp('picked_up'),
  inTransit('in_transit'),
  arrivedDropoff('arrived_dropoff'),
  delivered('delivered'),
  cancelled('cancelled'),
  expired('expired'),
  failed('failed');

  const DeliveryStatus(this.value);
  final String value;

  bool get isTerminal => switch (this) {
    delivered || cancelled || expired || failed => true,
    _ => false,
  };

  static DeliveryStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown delivery status: $value'),
  );
}

enum ShipmentOfferStatus {
  pending('pending'),
  accepted('accepted'),
  declined('declined'),
  expired('expired'),
  cancelled('cancelled');

  const ShipmentOfferStatus(this.value);
  final String value;

  static ShipmentOfferStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown offer status: $value'),
  );
}

enum PaymentStatus {
  unpaid('unpaid'),
  authorized('authorized'),
  paid('paid'),
  partiallyRefunded('partially_refunded'),
  refunded('refunded'),
  failed('failed');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown payment status: $value'),
  );
}

enum PaymentMethod {
  cash('cash'),
  mobileMoney('mobile_money'),
  card('card'),
  wallet('wallet');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown payment method: $value'),
  );
}

enum EventActorRole {
  customer('customer'),
  rider('rider'),
  admin('admin'),
  system('system');

  const EventActorRole(this.value);
  final String value;

  static EventActorRole fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown actor role: $value'),
  );
}

enum PaymentProcessingStatus {
  created('created'),
  pendingCustomerAction('pending_customer_action'),
  processing('processing'),
  succeeded('succeeded'),
  failed('failed'),
  partiallyRefunded('partially_refunded'),
  refunded('refunded');

  const PaymentProcessingStatus(this.value);
  final String value;

  static PaymentProcessingStatus fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () =>
        throw FormatException('Unknown payment processing status: $value'),
  );
}

enum LedgerDirection {
  debit('debit'),
  credit('credit');

  const LedgerDirection(this.value);
  final String value;

  static LedgerDirection fromValue(String value) => values.firstWhere(
    (item) => item.value == value,
    orElse: () => throw FormatException('Unknown ledger direction: $value'),
  );
}
