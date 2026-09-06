import '../contracts/contract_enums.dart';
import '../contracts/contract_parsing.dart';

final class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.shipmentId,
    required this.customerId,
    required this.amountUgx,
    required this.method,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
    this.providerReference,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String id;
  final String shipmentId;
  final String customerId;
  final int amountUgx;
  final PaymentMethod method;
  final PaymentProcessingStatus status;
  final String idempotencyKey;
  final String? providerReference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int schemaVersion;

  factory PaymentRecord.fromMap(Map<String, dynamic> map) {
    final currency = ContractParsing.string(
      map['currency'] ?? 'UGX',
      'currency',
    );
    if (currency != 'UGX') {
      throw FormatException('Unsupported currency: $currency');
    }
    return PaymentRecord(
      id: ContractParsing.string(map['id'], 'id'),
      shipmentId: ContractParsing.string(map['shipmentId'], 'shipmentId'),
      customerId: ContractParsing.string(map['customerId'], 'customerId'),
      amountUgx: ContractParsing.integer(
        map['amountUgx'],
        'amountUgx',
        minimum: 0,
      ),
      method: PaymentMethod.fromValue(
        ContractParsing.string(map['method'], 'method'),
      ),
      status: PaymentProcessingStatus.fromValue(
        ContractParsing.string(map['status'], 'status'),
      ),
      idempotencyKey: ContractParsing.string(
        map['idempotencyKey'],
        'idempotencyKey',
      ),
      providerReference: ContractParsing.optionalString(
        map['providerReference'],
        'providerReference',
      ),
      createdAt: ContractParsing.dateTime(map['createdAt'], 'createdAt'),
      updatedAt: ContractParsing.dateTime(map['updatedAt'], 'updatedAt'),
      schemaVersion: ContractParsing.schemaVersion(map),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'shipmentId': shipmentId,
    'customerId': customerId,
    'amountUgx': amountUgx,
    'currency': 'UGX',
    'method': method.value,
    'status': status.value,
    'idempotencyKey': idempotencyKey,
    'providerReference': providerReference,
    'createdAt': createdAt.toUtc(),
    'updatedAt': updatedAt.toUtc(),
    'schemaVersion': schemaVersion,
  };
}

final class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.accountId,
    required this.shipmentId,
    required this.type,
    required this.direction,
    required this.amountUgx,
    required this.idempotencyKey,
    required this.occurredAt,
    this.paymentId,
    this.schemaVersion = ContractParsing.currentSchemaVersion,
  });

  final String id;
  final String accountId;
  final String shipmentId;
  final String? paymentId;
  final String type;
  final LedgerDirection direction;
  final int amountUgx;
  final String idempotencyKey;
  final DateTime occurredAt;
  final int schemaVersion;

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    final currency = ContractParsing.string(
      map['currency'] ?? 'UGX',
      'currency',
    );
    if (currency != 'UGX') {
      throw FormatException('Unsupported currency: $currency');
    }
    return LedgerEntry(
      id: ContractParsing.string(map['id'], 'id'),
      accountId: ContractParsing.string(map['accountId'], 'accountId'),
      shipmentId: ContractParsing.string(map['shipmentId'], 'shipmentId'),
      paymentId: ContractParsing.optionalString(map['paymentId'], 'paymentId'),
      type: ContractParsing.string(map['type'], 'type'),
      direction: LedgerDirection.fromValue(
        ContractParsing.string(map['direction'], 'direction'),
      ),
      amountUgx: ContractParsing.integer(
        map['amountUgx'],
        'amountUgx',
        minimum: 0,
      ),
      idempotencyKey: ContractParsing.string(
        map['idempotencyKey'],
        'idempotencyKey',
      ),
      occurredAt: ContractParsing.dateTime(map['occurredAt'], 'occurredAt'),
      schemaVersion: ContractParsing.schemaVersion(map),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'accountId': accountId,
    'shipmentId': shipmentId,
    'paymentId': paymentId,
    'type': type,
    'direction': direction.value,
    'amountUgx': amountUgx,
    'currency': 'UGX',
    'idempotencyKey': idempotencyKey,
    'occurredAt': occurredAt.toUtc(),
    'schemaVersion': schemaVersion,
  };
}
