# 24Boda Platform Contract

Status: Draft v1  
Audience: Customer app, rider app, admin web, Firebase backend, operations and data  
Purpose: One authoritative contract for every 24Boda client.

## System boundaries

| Role | Client | Authentication | Account creation |
| --- | --- | --- | --- |
| Customer | Flutter customer app | Phone OTP | After verified phone sign-in |
| Rider | Flutter rider app | Phone OTP | Admin pre-registers; rider verifies and links phone |
| Admin | React admin web | Email/password plus MFA | Trusted backend only |

Firebase Functions own identity, money, assignment, shared state and privileged fields. Clients may
only write narrowly scoped preferences and ephemeral data allowed by Security Rules.

## Global conventions

- Firebase Auth UID is the canonical ID for an activated user.
- Firestore auto IDs are used for shipments, offers, events, payments and ledger entries.
- Authoritative dates are server-generated Firestore timestamps, never device-generated strings.
- UGX amounts are integers; floating-point values are never used for money.
- Coordinates use Firestore `GeoPoint`; searchable positions also include a geohash.
- Important documents include `schemaVersion`, beginning at `1`.
- Field names use `lowerCamelCase`; enum values use `snake_case`.
- Historical financial values and audit events are immutable.
- Analytics events exclude personal data unless strictly required.

## Canonical collections

### `users/{uid}`

```text
uid: string
role: customer | rider | admin
phoneE164: string | null
email: string | null
displayName: string
profilePhotoPath: string | null
status: active | suspended | closed
createdAt: Timestamp
updatedAt: Timestamp
schemaVersion: 1
```

Role and status are server-controlled. Device tokens are stored separately because a user may have
multiple devices.

### `users/{uid}/devices/{deviceId}`

```text
fcmToken: string
platform: android | ios | web
app: customer | rider | admin
appVersion: string
lastSeenAt: Timestamp
createdAt: Timestamp
```

### `rider_applications/{applicationId}`

```text
phoneE164: string
displayName: string
vehicleType: boda | bicycle | car
plateNumber: string
documentPaths: map
status: pending_verification | verified | approved | rejected | withdrawn
linkedUid: string | null
createdByAdminId: string
reviewedByAdminId: string | null
rejectionCode: string | null
createdAt: Timestamp
verifiedAt: Timestamp | null
reviewedAt: Timestamp | null
updatedAt: Timestamp
schemaVersion: 1
```

### `riders/{uid}`

Durable rider data only; live position is stored separately.

```text
applicationId: string
vehicleType: boda | bicycle | car
plateNumber: string
approvalStatus: approved | suspended | revoked
ratingAverage: number
ratingCount: integer
completedShipmentCount: integer
createdAt: Timestamp
updatedAt: Timestamp
schemaVersion: 1
```

### `rider_presence/{uid}`

Ephemeral availability. This may move to Realtime Database after load testing.

```text
availability: offline | available | offered | assigned
location: GeoPoint | null
geohash: string | null
headingDegrees: number | null
speedMps: number | null
accuracyMeters: number | null
activeShipmentId: string | null
lastSeenAt: Timestamp
locationRecordedAt: Timestamp | null
schemaVersion: 1
```

### `shipments/{shipmentId}`

```text
publicCode: string
customerId: string
assignedRiderId: string | null
status: ShipmentStatus
pickup: LocationSnapshot
dropoff: LocationSnapshot
package: PackageSnapshot
quoteId: string
price: PriceSnapshot
paymentStatus: unpaid | authorized | paid | partially_refunded | refunded | failed
paymentMethod: cash | mobile_money | card | wallet
createdAt: Timestamp
updatedAt: Timestamp
acceptedAt: Timestamp | null
pickedUpAt: Timestamp | null
deliveredAt: Timestamp | null
cancelledAt: Timestamp | null
schemaVersion: 1
```

`LocationSnapshot` contains an address label, `GeoPoint`, optional place ID and contact details.
`PriceSnapshot` contains immutable integer UGX amounts: subtotal, discount, customer total, rider
earning, commission and tax. A later pricing change must never alter an old shipment.

### `shipments/{shipmentId}/events/{eventId}`

Append-only audit history:

```text
type: string
fromStatus: ShipmentStatus | null
toStatus: ShipmentStatus | null
actorId: string | null
actorRole: customer | rider | admin | system
reasonCode: string | null
location: GeoPoint | null
metadata: map
occurredAt: Timestamp
schemaVersion: 1
```

### `shipment_offers/{offerId}`

```text
shipmentId: string
riderId: string
status: pending | accepted | declined | expired | cancelled
distanceToPickupMeters: integer
offeredAt: Timestamp
expiresAt: Timestamp
respondedAt: Timestamp | null
schemaVersion: 1
```

An offer targets one rider. The platform never broadcasts every searching shipment to every rider.

### Financial collections

```text
quotes/{quoteId}
payments/{paymentId}
ledger_entries/{entryId}
payouts/{payoutId}
```

Ledger entries are append-only and idempotent. Mutable rider totals are display projections, not the
financial source of truth.

## Shipment state machine

```text
quoted -> searching -> offered -> accepted -> en_route_pickup
       -> arrived_pickup -> picked_up -> in_transit
       -> arrived_dropoff -> delivered
```

Terminal states are `cancelled`, `expired` and `failed`. Only Functions perform transitions. Each
transition updates the shipment snapshot and appends an event atomically. Clients request actions;
they never submit arbitrary next states.

## Rider onboarding

1. Admin creates an application with a normalized phone number.
2. Rider signs into the rider app using that phone and OTP.
3. A Function finds the pending application using a protected keyed phone lookup.
4. The Function atomically links the verified Auth UID.
5. Admin reviews identity and vehicle documents.
6. Approval activates `users/{uid}` and creates `riders/{uid}`.
7. Only active, approved riders may become available or receive offers.

Raw phone numbers are not document IDs. A server-only lookup may use an HMAC of the normalized phone
for uniqueness and linking.

## Function boundaries

Initial commands:

- `completeCustomerOnboarding`
- `createRiderApplication`
- `linkRiderApplication`
- `reviewRiderApplication`
- `createDeliveryQuote`
- `createShipment`
- `cancelShipment`
- `setRiderAvailability`
- `acceptShipmentOffer`
- `transitionShipment`
- `registerDevice`
- `unregisterDevice`

Background Functions match nearby riders, expire offers, send notifications, maintain projections,
create ledger entries, detect stale presence and export privacy-safe product events. Retriable
commands accept idempotency keys.

## Location contract

- Customer location exposes denied, disabled, timeout and low-accuracy states.
- The map retains a desired target until its controller is ready.
- Customers confirm pickup; GPS is a suggestion, not unquestioned truth.
- Rider tracking adapts to movement, accuracy, app lifecycle and battery state.
- Durable rider data and high-frequency presence remain separate.
- Nearby search uses geohash bounds plus exact server-side distance filtering.
- Route distance, ETA and price use trusted route services, not Haversine distance alone.

## Analytics contract

Stable, versioned business events include:

```text
customer_onboarded
rider_application_created
rider_approved
quote_created
shipment_created
shipment_offer_sent
shipment_offer_accepted
shipment_status_changed
shipment_cancelled
payment_succeeded
shipment_delivered
```

Events contain `eventId`, `eventVersion`, `occurredAt`, relevant entity IDs, app version, platform
and privacy-safe dimensions such as service zone. Large analytical workloads run in BigQuery or
another warehouse, never in an admin browser scanning operational collections.

## Reliability and scale requirements

- No unbounded collection reads.
- List screens use indexed cursor pagination.
- Real-time listeners target one document or a small indexed result set.
- No high-frequency updates to a shared counter document.
- Critical operations are transactional and idempotent.
- Dev, staging and production use separate Firebase projects.
- App Check, Crashlytics, structured logs, alerts, backups and budget alerts precede launch.
- Rules and Functions have Firebase Emulator tests.
- Load tests model concurrent activity, not only registered-user count.

## Migration rules

- ISO date strings migrate to Firestore timestamps.
- Floating-point money migrates to integer UGX fields.
- Existing shipment price maps migrate to the canonical `PriceSnapshot`.
- Rider location migrates out of `riders/{uid}`.
- Readers may temporarily understand old data; all new writes use the newest schema.
- Migrations are resumable, observable, idempotent and executed in controlled batches.

## Open decisions

- Firestore versus Realtime Database for rider presence and location.
- Service zones and maximum operating radius.
- Mobile-money, cash, card and wallet payment sequencing.
- Rider offer strategy: sequential, small batch or scored auction.
- Cancellation windows, fees and responsible actors.
- Required identity documents and retention periods.
- Location retention and privacy policy.
- Regional versus multi-region Firebase/GCP placement.

No implementation is canonical when it conflicts with this contract. Contract changes require an
explicit architecture decision and a coordinated schema migration.
