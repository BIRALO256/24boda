# 24Boda — Mobile Monorepo

> Fast pickup and delivery across Uganda.

This repository contains the Flutter mobile applications for the 24Boda platform. It is structured as a **monorepo**, meaning both the Customer App and the Rider App live here alongside shared packages that both apps use.

---

## Repositories Overview

The 24Boda platform is split across two repositories:

| Repository | What it contains |
|---|---|
| `24boda` *(this repo)* | Customer App, Rider App, shared Flutter packages |
| `24boda-web` *(separate repo)* | Admin Dashboard (React) |

---

## What is 24Boda?

24Boda is a same-day pickup and delivery platform. Customers place delivery requests, riders fulfill them, and the admin team manages the entire operation through the web dashboard.

**What gets delivered:**
- Documents
- Packages and parcels
- Clothes, phones, electronics
- Food and groceries
- Gifts and personal items

**Business model:** Commission per completed delivery. The platform takes 20% and the rider receives 80% of the delivery fee.

---

## Repository Structure

```
24boda/                          ← You are here (mobile monorepo)
│
├── apps/
│   ├── customer_app/            ← Flutter app for customers
│   └── rider_app/               ← Flutter app for riders/drivers
│
├── packages/
│   ├── core_models/             ← Shared data models (Shipment, User, Rider...)
│   ├── firebase_services/       ← Firestore, Auth, Storage logic
│   ├── maps/                    ← Google Maps integration
│   ├── notifications/           ← Firebase Cloud Messaging (FCM)
│   ├── theme/                   ← Colors, typography, shared UI components
│   └── utils/                   ← Validators, formatters, helpers
│
├── analysis_options.yaml        ← Shared lint rules for all packages
└── README.md
```

> **Note:** The `lib/` folder at the root is temporary from the initial Flutter scaffold. It will be removed as the monorepo structure is set up.

---

## Applications

### Customer App (`apps/customer_app`)

The app used by people who want to send packages.

**Key features:**
- Phone number + OTP registration (no password needed)
- Place a delivery request (pickup location, dropoff location, package description)
- Real-time tracking of the rider on a map
- Delivery history
- Push notifications for every status update
- In-app support

### Rider App (`apps/rider_app`)

The app used by boda boda riders who fulfill deliveries.

**Key features:**
- Phone number + OTP registration
- Document upload for verification (National ID, Driving Permit, bike photo)
- Pending approval state until admin approves
- Accept or reject incoming delivery jobs
- Navigation to pickup and dropoff points
- Earnings summary and history
- Status updates throughout the delivery

---

## Shared Packages

Packages in the `packages/` folder are internal Dart packages. Both apps import them using local path dependencies. This means:

- Authentication logic is written once, used in both apps
- Data models (like `Shipment`, `UserProfile`, `Rider`) are defined once
- Firestore query logic is written once
- The app theme (colors, fonts, button styles) is defined once

If a bug is found in how shipment status is calculated, you fix it in `core_models` and both apps get the fix automatically.

---

## Shipment Status Flow

A delivery goes through these states:

```
created
    ↓
searching_for_rider
    ↓
rider_assigned
    ↓
rider_accepted
    ↓
rider_at_pickup
    ↓
picked_up
    ↓
in_transit
    ↓
at_destination
    ↓
delivered
    ↓
completed
```

Every status change is timestamped and logged with GPS coordinates. This gives full audit history for disputes and admin reporting.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile apps | Flutter (Dart) |
| Authentication | Firebase Authentication (Phone OTP) |
| Database | Cloud Firestore |
| File storage | Firebase Storage |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Backend logic | Firebase Cloud Functions |
| Maps and location | Google Maps Platform |
| CI/CD | GitHub Actions |

---

## Roles and Permissions

| Role | Access |
|---|---|
| Customer | Create shipments, track, view history, contact support |
| Rider | Accept jobs, update delivery status, view earnings |
| Admin | Full platform access (managed via the web dashboard) |

---

## Related Repository

The Admin Dashboard is maintained separately:

- **`24boda-web`** — React web application for admins to manage riders, customers, shipments, payments, and reports.

Admin features include:
- Approve or reject rider applications
- View and manage all active deliveries
- Manually create deliveries (for phone orders)
- View payment and commission reports
- Manage disputes and support tickets

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.12.2`
- Dart SDK (comes with Flutter)
- Android Studio or Xcode (for running on device/emulator)
- A Firebase project with Android and iOS apps configured
- Google Maps API key

### Running the Customer App

```bash
cd apps/customer_app
flutter pub get
flutter run
```

### Running the Rider App

```bash
cd apps/rider_app
flutter pub get
flutter run
```

### Getting dependencies for all packages

```bash
# From the root of the repo, run for each package
cd packages/core_models && flutter pub get
cd packages/firebase_services && flutter pub get
cd packages/maps && flutter pub get
cd packages/notifications && flutter pub get
cd packages/theme && flutter pub get
cd packages/utils && flutter pub get
```

---

## Environment Configuration

Each app requires a `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from your Firebase project. These files are **not committed to the repository**.

Place them as follows:

```
apps/customer_app/android/app/google-services.json
apps/customer_app/ios/Runner/GoogleService-Info.plist

apps/rider_app/android/app/google-services.json
apps/rider_app/ios/Runner/GoogleService-Info.plist
```

> Each app has its own Firebase app registration because they are separate apps on the Play Store and App Store.

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Production — what is live on the app stores |
| `develop` | Integration branch — all features merge here first |
| `feature/*` | Individual feature branches |
| `hotfix/*` | Urgent fixes going directly to production |

---

## Contributing

1. Branch off `develop`
2. Name your branch `feature/your-feature-name`
3. Open a pull request back to `develop`
4. Request review before merging

---

## License

Private. All rights reserved. 24Boda — Uganda.
