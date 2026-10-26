# R8 — Local Services Marketplace

Android-first Flutter app for discovering local workers, profiles, chat, and job booking.

**v0.2** — Firebase-ready for a ~1k user pilot (Auth, Firestore, Rules, Functions, Crashlytics).  
Falls back to **mock mode** until you complete [SETUP_YOU_MUST_DO.md](SETUP_YOU_MUST_DO.md).

## Quick start

```bash
flutter pub get

# Demo without Firebase
flutter run --dart-define=USE_MOCK=true

# Production (after SETUP_YOU_MUST_DO.md)
flutter run
```

Mock OTP: any 10-digit phone + `123456`.

## Architecture

| Layer | Implementation |
|-------|----------------|
| Android app | Flutter (`lib/`) |
| Auth | Firebase Phone Auth (mock OTP in USE_MOCK) |
| Database | Cloud Firestore |
| Security | `firestore.rules` + `storage.rules` |
| Business rules | Cloud Functions (`functions/`) — dual-accept, completion, reviews |
| Crashes | Firebase Crashlytics |
| Admin | In-app report queue + `admins/{uid}` docs |

Sensitive booking transitions are **not** trusted from the client alone.

## Repo map

- `lib/` — Flutter UI + `FirebaseR8Store` / mock  
- `functions/` — TypeScript Cloud Functions (region `asia-south1`)  
- `firestore.rules` / `storage.rules` / `firebase.json`  
- `SETUP_YOU_MUST_DO.md` — **your** Firebase console steps  
- `OPS.md` — ops runbook  
- `docs/ui-mocks/` — UI mock images  

## What you must do

Only you can create the Firebase project, enable Phone Auth (Blaze), add SHA-1, download `google-services.json`, run `flutterfire configure`, and deploy rules/functions. Follow **SETUP_YOU_MUST_DO.md**.

## Disclaimer

R8 records discovery, chat, and agreed job terms. Off-platform payment is not guaranteed by R8. See BRD.
