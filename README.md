# R8 — Local Services Marketplace

Android-first Flutter prototype for discovering local workers, profiles, in-app chat, and job booking.

This repo is **Phase 1 (UI + mock data)** from BRD v1.1. Firebase Auth/Firestore/FCM are **not** wired yet.

## What works (mock)

- Mobile + OTP login (any 10-digit number, OTP `123456`)
- Dual-role account (hire + offer on one account)
- Profiles with public general location (town/district/state; optional PIN; no home address/GPS)
- Discover / filter by category and area
- Jobs: fixed, negotiable, request-a-quote; offers; dual acceptance; completion; reviews
- Chat without mutual connection; block / report
- In-app admin report queue (mock)
- Payment disclaimer (payments outside R8)

## Run (when Flutter works)

```bash
flutter pub get
flutter run
```

## Mock credentials

| Field | Value |
|-------|--------|
| Phone | any 10 digits, e.g. `9876543210` |
| OTP | `123456` |

## Project layout

- `lib/` — Flutter app (mock store + screens)
- `admin/` — minimal static admin console mock
- `test/` — widget/smoke tests

## Not in this prototype

- Real OTP / Firebase / push notifications
- In-app payments
- iOS target
- Production security rules
