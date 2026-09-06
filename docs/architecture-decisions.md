# 24Boda Architecture Decisions

Status: Proposed baseline  
Applies to: Customer app, rider app, admin web and Firebase backend

These decisions optimize for correctness, low-end Android devices, unreliable mobile networks,
operational visibility and a path toward one million registered users. Product-sensitive values are
configuration, not constants embedded in mobile applications.

## ADR-001: Durable data and live location use different stores

Decision:

- Cloud Firestore stores durable business records: users, riders, applications, shipments, offers,
  events, payments and ledger entries.
- Firebase Realtime Database stores high-frequency rider presence and live location.
- Firestore stores only meaningful location snapshots attached to business events, such as arrival,
  pickup and delivery.

Rationale:

- A rider location update every few seconds is ephemeral and high-volume.
- Mixing location updates into `riders/{uid}` continually rewrites a durable profile and triggers
  unrelated listeners.
- Realtime Database supports presence semantics and small, rapidly changing records well.
- Separating the workloads allows independent rules, retention and cost controls.

Realtime Database shape:

```text
/riderPresence/{uid}
  availability: offline | available | offered | assigned
  lat: number | null
  lng: number | null
  geohash: string | null
  headingDegrees: number | null
  speedMps: number | null
  accuracyMeters: number | null
  activeShipmentId: string | null
  sessionId: string
  recordedAtMs: integer
  connected: boolean
```

Rules require the authenticated UID to match the path. Server processes may read the matching pool;
customers never query all rider locations. A customer may only receive the assigned rider location
for their active shipment through a narrowly scoped projection or authorized channel.

Location frequency is adaptive:

- Offline: no updates.
- Available and stationary: low frequency.
- Available and moving: moderate frequency.
- Assigned to an active shipment: higher frequency appropriate for tracking.
- Poor accuracy: do not publish misleading coordinates as authoritative.

## ADR-002: Backend-controlled, targeted rider dispatch

Decision:

- A backend matching worker selects eligible riders using zone, approval, availability, staleness,
  vehicle type and distance to pickup.
- The first implementation offers a shipment to a small scored batch, initially three riders.
- Each offer has a short configured expiry.
- Exactly one rider wins through a Firestore transaction in `acceptShipmentOffer`.
- Unsuccessful acceptance returns a clear `offer_taken` result rather than a generic error.

Rationale:

- A global query exposes every searching job to every rider and produces excessive listener fanout.
- Direct client assignment allows races where two riders believe they accepted the same shipment.
- A small batch reduces customer wait time without notifying an entire city.

Initial score inputs:

```text
pickup distance
vehicle compatibility
availability freshness
current assignment
recent offer acceptance behavior
fairness / time since last completed job
service-zone membership
```

Acceptance behavior must not become a hidden discriminatory score. Dispatch inputs and weights are
versioned and auditable.

## ADR-003: Server-authoritative route and pricing quotes

Decision:

- The client sends pickup, drop-off, package and service options to `createDeliveryQuote`.
- The backend obtains route distance and duration from an approved routing provider.
- The backend applies a versioned pricing rule and returns a signed, expiring quote.
- `createShipment` accepts a valid `quoteId`; it never accepts a client-calculated final price.
- All monetary amounts are integer UGX.

Quote shape includes:

```text
routeDistanceMeters
routeDurationSeconds
baseFareUgx
distanceFareUgx
serviceFeeUgx
surgeAmountUgx
discountUgx
customerTotalUgx
riderEarningUgx
platformCommissionUgx
pricingRuleVersion
expiresAt
```

The existing Haversine calculation may remain as a UI-only preview while awaiting a server quote;
it is never billable truth.

## ADR-004: Payment providers sit behind a platform interface

Decision:

- Launch sequencing may support cash and mobile money first; exact providers remain a business
  decision.
- Provider-specific payloads do not become the core shipment model.
- Cloud Functions create payment intents, verify callbacks and write append-only ledger entries.
- A payment callback is authenticated, idempotent and safe to replay.
- The client never marks a payment successful.

Canonical payment states:

```text
created -> pending_customer_action -> processing -> succeeded
                                          |-> failed
succeeded -> partially_refunded | refunded
```

Cash collection is also represented in the ledger so reconciliation does not depend on a mutable
rider earnings total.

## ADR-005: Service areas are data, not application constants

Decision:

- `service_zones/{zoneId}` defines enabled operating polygons, service types and pricing rule IDs.
- The initial enabled zone may be Kampala, but no app assumes all Uganda is serviceable.
- Quote creation verifies that pickup and drop-off comply with the selected service zone.
- Zone changes do not require an app-store release.

The admin web manages zones only through privileged backend validation. Polygon complexity and
index representation are bounded.

## ADR-006: Cancellation is a command with policy results

Decision:

- Customers, riders and admins call `cancelShipment`; they do not write `status = cancelled`.
- The backend evaluates the actor, current state, elapsed time, payment state and configured policy.
- The resulting event stores a stable reason code, responsible actor and assessed fee.
- Free-text support notes are separate from analytical reason codes.

Initial reason families:

```text
customer_changed_mind
customer_unreachable
rider_unavailable
rider_vehicle_issue
pickup_not_found
package_not_allowed
no_rider_found
system_timeout
admin_intervention
```

Exact fee amounts and grace periods remain configuration pending product approval.

## ADR-007: Identity documents are private and lifecycle-managed

Decision:

- Rider identity files are stored by object path, not permanent download URL.
- Access uses authenticated Storage rules or short-lived signed access from a privileged backend.
- Only assigned reviewers and tightly scoped administrative roles may view documents.
- Reads and decisions are audit logged.
- Retention duration is configurable and must be confirmed with legal/privacy requirements before
  production launch.
- Rejected or withdrawn applications enter a deletion schedule unless retention is legally needed.

The mobile and admin applications must never log document URLs, phone numbers or identity values.

## ADR-008: Separate Firebase projects per environment

Decision:

```text
24boda-dev
24boda-staging
24boda-prod
```

- Each environment has separate Auth users, databases, buckets, API keys, Functions and analytics.
- Flutter uses explicit build flavors and generated Firebase options per environment.
- React uses validated environment configuration.
- CI deploys only from protected branches with an explicit target.
- Production deployment cannot rely on an ambiguous default `.firebaserc` alias.

## ADR-009: Analytics uses versioned business events

Decision:

- Operational documents remain optimized for product workflows.
- Functions emit privacy-safe, versioned business events after authoritative commits.
- Firestore dashboards use bounded projections; historical analysis moves to BigQuery.
- Event IDs make ingestion idempotent.

Required common event fields:

```text
eventId
eventName
eventVersion
occurredAt
actorRole
customerIdHash where needed
riderIdHash where needed
shipmentId
serviceZoneId
app
appVersion
platform
```

Raw phone numbers, exact identity data and unrestricted live coordinates are not analytics fields.

## ADR-010: Shared contracts are generated or compatibility-tested

Decision:

- The canonical schema is defined once and mapped into Dart and TypeScript.
- Dart and TypeScript models include explicit serializers and runtime validation at network/storage
  boundaries.
- Contract fixtures verify that Flutter, Functions and React read the same documents.
- Schema evolution follows additive changes first, compatibility windows and controlled migrations.
- A mobile release must remain compatible with the backend during its supported upgrade window.

The current ISO-string versus Firestore-Timestamp and numeric versus embedded-price disagreements
are contract violations to be migrated, not patterns to preserve.

## Implementation sequence

1. Define canonical enums and schema value objects.
2. Add contract fixtures for users, rider applications, riders, shipments, offers and events.
3. Update shared Dart models and serializers while preserving temporary legacy readers.
4. Implement backend commands and emulator tests.
5. Align Security Rules with those commands.
6. Align React types and admin workflows.
7. Migrate development data.
8. Fix map readiness and platform configuration.
9. Implement presence and targeted dispatch.
10. Load test before enabling production traffic.

## References

- Flutter architecture: https://docs.flutter.dev/app-architecture/guide
- Firestore scaling: https://firebase.google.com/docs/firestore/understand-reads-writes-scale
- Firestore real-time queries: https://firebase.google.com/docs/firestore/real-time_queries_at_scale
- Firestore geoqueries: https://firebase.google.com/docs/firestore/solutions/geoqueries
- Realtime Database presence: https://firebase.google.com/docs/database/web/offline-capabilities
- Google Maps API security: https://developers.google.com/maps/api-security-best-practices
