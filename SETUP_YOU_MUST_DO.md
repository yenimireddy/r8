# What YOU must do (Firebase production for ~1k users)

Code for Auth, Firestore, Security Rules, Cloud Functions, Crashlytics, and Storage rules is in this repo.  
Only you can create the Firebase project and paste secrets. Do these steps once.

## 0. Prerequisites

- Working Flutter SDK (`flutter doctor` clean for Android)
- Node.js 20+ (for Cloud Functions)
- Firebase CLI: `npm install -g firebase-tools` then `firebase login`
- A Google account

## 1. Create Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/) → Add project (e.g. `r8-prod`).
2. Prefer region **asia-south1** (Mumbai) when asked for Functions later.
3. Upgrade to **Blaze (pay as you go)** — required for Phone Auth SMS + Cloud Functions. Set a budget alert (e.g. ₹1,000–2,000/month).

## 2. Enable products

In the Firebase project:

| Product | Action |
|---------|--------|
| Authentication | Sign-in method → **Phone** → Enable |
| Cloud Firestore | Create database → production mode → location `asia-south1` |
| Storage | Get started → same location if possible |
| Cloud Messaging | Enabled by default |
| Crashlytics | Enable for the Android app |
| App Check (recommended) | Play Integrity for Android after first release |

## 3. Register Android app

1. Project settings → Add app → Android  
2. Package name: **`com.r8.app.r8`** (must match `android/app/build.gradle.kts`)  
3. Download **`google-services.json`** and **overwrite** the stub at:

```text
android/app/google-services.json
```

(The repo ships a placeholder so the project builds; production needs your real file.)

4. Add your **debug SHA-1** (required for Phone Auth on device):

```bash
# macOS / Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Paste SHA-1 (and SHA-256) into Firebase Android app settings.

## 4. Generate Flutter Firebase options

From the repo root:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android
```

This overwrites `lib/firebase_options.dart` with real keys.  
Until this is done, the app **auto-falls back to mock mode**.

## 5. Deploy rules + functions

```bash
firebase use YOUR_PROJECT_ID   # or: firebase use --add
cd functions && npm install && npm run build && cd ..
firebase deploy --only firestore:rules,firestore:indexes,storage,functions
```

## 6. Make yourself an admin

After you sign in once on the app, copy your Auth UID from Firebase Console → Authentication.

In Firestore, create document:

```text
admins/{YOUR_UID}
```

with fields e.g. `{ "role": "admin", "createdAt": <timestamp> }`

Then Account → Admin report queue can resolve cases via Cloud Function.

## 7. Run the app (production mode)

```bash
flutter pub get
flutter run   # do NOT pass USE_MOCK
```

Mock demo (no Firebase):

```bash
flutter run --dart-define=USE_MOCK=true
```

## 8. Ops checklist before inviting ~1k users

- [ ] Budget alert on Google Cloud billing  
- [ ] Phone Auth test numbers for QA (Auth → Phone → Phone numbers for testing)  
- [ ] Crashlytics receiving events from a test crash  
- [ ] Firestore Rules tested: unauthenticated read denied; phone not in `profiles`  
- [ ] Dual-accept booking works only via Functions  
- [ ] Support mailbox / WhatsApp for safety reports  
- [ ] Terms + Privacy URLs linked in Play Store and in-app Account screen  
- [ ] Play Store closed testing track with 20–50 real users in one town first  

## 9. Costs to watch (1k users)

- SMS OTP (biggest risk if abused) — use test numbers in QA; enable App Check  
- Firestore reads — paginate; avoid listening to huge collections  
- Cloud Functions invocations — fine at 1k if dual-accept stays on Functions  

## Support

If Firebase init fails, the app prints why and falls back to mock. Fix `firebase_options.dart` + `google-services.json` + SHA-1 first.
