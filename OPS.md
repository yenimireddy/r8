# R8 ops runbook (~1k users)

## Daily / weekly

- Check Firebase Console → Crashlytics for new fatal issues  
- Check Authentication → usage spikes (OTP abuse)  
- Review open `reports` in admin queue within 24h for safety cases  
- Glance at Google Cloud billing vs budget alert  

## Incidents

| Symptom | First actions |
|---------|----------------|
| OTP not arriving | SHA-1 registered? Blaze plan? Quotas? Try test phone number |
| Permission denied on offers | Functions deployed? User signed in? |
| Booking without dual accept | Should be impossible — verify Rules deny client offer status edits |
| Spam chat | Block + report; tighten rate limit in Functions `hitRateLimit` |
| Cost spike | Disable Phone Auth temporarily; check rateLimits collection |

## Data model (short)

- `profiles/{uid}` — public fields only (no phone / home / GPS)  
- `userPrivate/{uid}` — phone (owner/admin)  
- `jobs`, `offers` — booking state changes via Cloud Functions  
- `conversations/{id}/messages` — chat  
- `reports`, `notifications`, `audit`, `admins`  

## Deletion requests

Profile flag `deletionRequested: true`. Process manually: disable Auth user, delete/anonymize profile + private docs, keep audit as required by policy.
