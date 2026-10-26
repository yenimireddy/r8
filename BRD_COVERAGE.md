# BRD coverage (v0.2 Firebase-ready)

| ID | Mock | Firebase |
|----|------|----------|
| FR-01 Auth OTP | Yes (123456) | Phone Auth (you enable) |
| FR-02–06 Profile / location | Yes | `profiles` + Rules (no phone/home/GPS) |
| FR-07 Discovery | Yes | Profile listeners + client filter |
| FR-08–11 Jobs / dual accept | Yes | Client create + **Functions** accept/confirm |
| FR-12–13 Chat / privacy | Yes | Firestore messages + block |
| FR-14–18 Lifecycle / reviews | Yes | Functions for completion / reviews |
| FR-19 Reports / block | Yes | `reports` + Rules |
| FR-20 Admin | In-app | `admins/{uid}` + `resolveReport` |
| FR-21 Notifications | In-app list | Firestore `notifications` (+ FCM wiring next) |
| FR-22 Account controls | Yes | Profile + deletion flag |
| FR-23 Audit | Memory | `audit` collection (Functions) |
| FR-24 Errors | Basic | Basic + Crashlytics |

**You still must:** complete SETUP_YOU_MUST_DO.md before real users.
