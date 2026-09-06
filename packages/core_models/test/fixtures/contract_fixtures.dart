const canonicalUserFixture = <String, Object?>{
  'uid': 'customer_01HXYZ',
  'role': 'customer',
  'phoneE164': '+256700000001',
  'email': null,
  'displayName': 'Demo Customer',
  'profilePhotoPath': null,
  'status': 'active',
  'createdAt': '2026-09-06T09:00:00.000Z',
  'updatedAt': '2026-09-06T09:00:00.000Z',
  'schemaVersion': 1,
};

const canonicalShipmentFixture = <String, Object?>{
  'publicCode': 'BODA-2026-000001',
  'customerId': 'customer_01HXYZ',
  'assignedRiderId': null,
  'status': 'searching',
  'quoteId': 'quote_01HXYZ',
  'price': {
    'customerTotalUgx': 12500,
    'riderEarningUgx': 10000,
    'platformCommissionUgx': 2500,
    'currency': 'UGX',
  },
  'paymentStatus': 'unpaid',
  'paymentMethod': 'cash',
  'createdAt': '2026-09-06T09:00:00.000Z',
  'updatedAt': '2026-09-06T09:00:00.000Z',
  'schemaVersion': 1,
};
