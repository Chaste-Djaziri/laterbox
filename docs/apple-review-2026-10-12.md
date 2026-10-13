# Apple review correction: optional registration and subscription disclosures

Submission being corrected: `5db506a3-9f6e-4e38-931e-8212a33f0894` (1.0.181, build 186).

## Metadata to update in App Store Connect

Append this line to **every supported iOS description localization**:

```text
Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

Use Apple's standard license in App Information. Keep `https://laterbox.dev/privacy` in the Privacy Policy field. LaterBox service terms are separate from the iOS license. Select the corrected build only after its processing and required TestFlight validation finish.

## Suggested App Review Notes

```text
Registration is optional. On the welcome screen, choose “Continue without account”. Open the profile menu → Settings → Subscription & Plans → Upgrade to LaterBox Pro to view localized Apple subscription prices, duration, renewal/trial terms, privacy policy, and Apple standard EULA.

Guests may purchase, restore, and manage Apple subscriptions without creating a LaterBox account. Verified StoreKit purchases unlock device Pro features, including Pro app icons and compatible AI-provider options. Device purchase delivery and transaction completion do not require our backend.

Cloud sync, backup, and Pro on the web are account-specific features. “Sign in to connect Pro (optional)” offers account creation/sign-in, followed by a separate explicit “Connect Pro to your account” confirmation showing the destination account. Signing in alone does not claim the guest purchase. Guest device access remains available if account connection fails.

Restore Purchases is on the purchase screen; Restore Previous Purchases and Manage Apple Subscription are in Subscription & Plans. Apple subscriptions use native App Store management. An existing entitled subscription blocks duplicate checkout.

The iOS license uses Apple's standard EULA, linked in the purchase screen and App Store description. LaterBox service terms are provided separately.
```

Uncheck “Sign-in required” for the guest review flow. If supplying optional cloud test credentials, keep them exclusively in App Store Connect; never put passwords in this repository.

## Verification and submission handoff

- [Local StoreKit iPad walkthrough](../assets/app_store/ipad/review/guest-subscription-local-storekit.mp4) shows guest plan access, legal disclosures, simulated purchase delivery, restore, and the optional connection action. This is a local simulation, not a completed TestFlight account-linking check.
- Local iPad Air 11-inch (M3), iOS 27: native tests cover guest StoreKit purchase/restore, local access, finished transactions, durable anonymous identity, and outbox persistence.
- Local StoreKit recordings are simulations and do **not** demonstrate Apple server verification or TestFlight-to-web linking. Label them accordingly. Prefer a corrected TestFlight recording for Apple's final review response.
- Automated backend tests cover concurrent ownership claims, idempotency, account mismatch, unlinked guest notifications, lifecycle updates, and current-status lookup. They do not replace real App Store Server API validation.
- Before claiming cross-platform completion: configure dedicated In-App Purchase API credentials, deploy, explicitly connect an unexpired TestFlight purchase, then verify the same account has an Apple row in Supabase and Pro on web. Check cancellation/refund before linking and Apple/Paddle duplicate-checkout behavior.
- Update metadata, attach the actual walkthrough, add these notes, select the corrected build, and resubmit. Do not request the bug-fix exception. Approval remains Apple's decision.

The owner elected to handle App Store metadata and submission. No review reply or resubmission has been sent by this task.

## Delivery checks, October 13, 2026

- Migration `202610120003_optional_apple_account_links.sql` is applied to the live Supabase project.
- Dedicated In-App Purchase credentials are configured as encrypted deployment secrets and installed on the existing Worker. Sandbox and production API authentication were checked without using customer transactions.
- Both App Store Server Notification URLs are saved as `https://app.laterbox.dev/api/billing/apple/webhook`. Apple reports `SUCCESS` for fresh V2 test notifications in both environments after the Worker transport fix. These test events grant no account access.
- The deployed Worker accepts the signed test payloads with HTTP 204 while Apple's certificate chain and online certificate-status checks remain enabled.
- Local validation passes: 92 web tests, web type checks, Cloudflare packaging, nine CI helper tests, 48 native unit tests, and three UI tests on a fresh iPhone 18 Pro simulator. The iPad Air M3 walkthrough and reference captures are linked above.
- A corrected TestFlight upload is still subject to CI and Apple's build processing. A real TestFlight purchase → explicit account connection → Supabase Apple record → web Pro check remains outstanding. The local simulation does not satisfy that check.
