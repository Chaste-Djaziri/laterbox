# Inbox device notifications

Notifications are opt-in per device/browser in **Settings → Device notifications**. They use generic text; saved titles, URLs, and note contents are never placed in push payloads. Notification taps validate the active account and item availability before opening the item, otherwise opening the inbox.

## Delivery model

| Client | Local-only scheduled items | Cloud-synced arrivals and returns |
| --- | --- | --- |
| iOS / macOS | OS-scheduled local notification | APNs, including while closed |
| Android | OS-scheduled local notification | FCM, including while closed |
| Windows / Linux | Timer while running, including tray | Authenticated outbox polling every 30 seconds while running |
| Web | Notification while the page runs | Web Push/service worker, including while closed |

Windows/Linux native apps do not install a background service. For closed-app delivery, enable Web Push in a supported browser. Linux requires a desktop notification daemon. Unpackaged Windows apps can display notifications, but Windows requires package identity/MSIX to remove already displayed toasts; timer cancellation still works.

Cloud delivery follows existing Pro/cloud-sync eligibility. Local reminders remain available without a subscription. iOS web notifications require a supported Home Screen web app; permission must be granted through a user action. Android FCM requires Google Play services. OS permissions, Focus modes, power management, force-stop, connectivity, browser support, and vendor restrictions can delay or suppress delivery.

An installation owns either a local or server reminder for a given synced item. Native clients cancel the local request before upload, record handoff, and restore the local reminder if upload fails. Web tabs serialize handoff and local presentation using Web Locks. Guest/local-only reminders work offline; cloud-owned reminders require delivery connectivity. Offline edits on one device cannot cancel alerts already queued on another until those edits sync.

The local native queue holds the earliest 60 future reminders and refills when the app runs. This respects iOS's pending-notification limit. Android uses inexact alarms (no exact-alarm permission); times are best effort. Windows/Linux require the app to run; local-only web pages must remain active. All scheduled instants use the existing UTC `return_at` value.

## Backend deployment

1. Apply `202609190001_inbox_notifications.sql` and `202609190002_notification_dispatch_schedule.sql` using the project's normal Supabase migration workflow. The second migration uses Supabase's `pg_net`, `pg_cron`, and Vault. Deploy backend changes before updated clients.
2. Configure the Edge Function secrets shown in `supabase/functions/.env.notifications.example`. Do not commit filled-in files, Apple keys, or Google service-account credentials.
3. Deploy the `notifications`, `capture`, and `extension-connect` Edge Functions. The dispatcher disables gateway JWT verification because it checks its separate `NOTIFICATION_DISPATCH_SECRET`; it never accepts a client JWT as dispatcher authorization.
4. In Supabase Vault, create `notification_dispatch_url` with `https://YOUR_PROJECT.supabase.co/functions/v1/notifications` and `notification_dispatch_secret` with the exact dispatcher secret. Use the dashboard or the normal secret provisioning workflow.
5. Deploy the web app with `NEXT_PUBLIC_WEB_PUSH_PUBLIC_KEY` matching the server's VAPID public key. This public key is intentionally browser-visible. Keep the private key server-side.

The migration installs a one-minute cron schedule and an immediate database wakeup for new inbox saves. Without the Vault values, wakeups are no-ops; item saving continues. Due events aim for the next minute, with additional provider/network delay. Workers claim 40 deliveries per invocation using five-minute leases, recheck current state immediately before sending, retry transient failures up to eight times, and disable expired registrations. Event history expires after seven days; unsent events older than 24 hours are discarded.

Inspect `notification_deliveries.state`, `attempts`, `retry_at`, and `last_error`, the `cron.job_run_details` view, and Edge Function logs for failures. Errors deliberately omit tokens, subscription URLs, and content. A timeout after provider acceptance can still cause a retry; event IDs, provider collapse tags, and client deduplication reduce duplicates but cannot promise exactly-once OS presentation.

## Apple setup

- Enable **Push Notifications** for the existing iOS and macOS App IDs in Apple Developer. Regenerate/download provisioning profiles that contain the capability. Existing profiles without it will fail signing.
- Create an APNs authentication key and configure `APNS_PRIVATE_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID`, and `APNS_TOPIC`. Set `APNS_MACOS_TOPIC` if the macOS bundle identifier differs. Never upload the private key into the client.
- Use separate development and production backend configurations. Set `APNS_ENVIRONMENT=development` for sandbox tokens or `production` for distribution tokens. iOS Debug uses the development entitlement and Release/Profile production. macOS Debug and Release entitlements follow the same split.
- Firebase is deliberately not initialized on Apple platforms. The native `laterbox/notifications` bridge handles APNs directly; Firebase delegate swizzling and automatic messaging initialization are disabled there.
- Rebuild, sign, and install the clients. No silent/background fetch entitlement is needed: these are visible alert pushes.

## Android setup

Create/register the Android Firebase app with package ID `pro.micorp.laterbox`. Supply these public client values when building (for example through `--dart-define-from-file` in your release workflow):

```json
{
  "FIREBASE_API_KEY": "your Firebase Android API key",
  "FIREBASE_APP_ID": "your Firebase Android app ID",
  "FIREBASE_SENDER_ID": "your numeric messaging sender ID",
  "FIREBASE_PROJECT_ID": "your Firebase project ID"
}
```

Enable the FCM HTTP v1 API. Give the server service account permission to send messages for that project, and configure `FCM_PROJECT_ID`, `FCM_CLIENT_EMAIL`, and `FCM_PRIVATE_KEY` in Supabase. The Android client initializes Firebase explicitly from build values; a Google Services Gradle plugin/JSON file is not needed. Builds without these values keep local reminders and explain that cloud setup is missing.

Android 13+ notification permission is requested from the settings action. The manifest includes boot restoration and scheduled-notification receivers. Desugaring and a monochrome notification icon are configured. A force-stopped application may need to be reopened before the OS resumes delivery.

## Web setup

Generate a VAPID keypair with a standard Web Push implementation (for example `npx web-push generate-vapid-keys`). Set the server public/private keys and a `mailto:` contact in `WEB_PUSH_SUBJECT`. Serve over HTTPS (localhost is allowed for development).

`/notifications-sw.js` owns notifications only and has no asset-cache/fetch handler. Update/reset controls preserve it. Subscription rotation is reconciled when the app runs; expired endpoints are disabled by the server. After rotating the VAPID key, existing users must disable and re-enable browser notifications to obtain a matching subscription.

Account state and recently displayed event IDs are stored in IndexedDB for the service worker. Logout disables local worker delivery, unsubscribes browser push, and revokes the server registration. A separate random device revocation capability allows cleanup after a login expires; the database stores only its hash. Notification settings and history are scoped to the account. Browser extension connections approved by an updated client inherit its installation identity; reconnect older extensions to pair them.

## Event rules and compatibility

- Future active `return_at` values create return events. Archive, delete, reschedule, and Someday invalidate old revisions.
- Only newly inserted items already due in the inbox create remote-save events. Source installations are excluded. Imports with `created_at` older than two minutes are silent; existing overdue items are not backfilled.
- Initial activation uses a server-controlled baseline, so existing overdue events are not replayed. Metadata updates preserve the event revision and never produce another arrival.
- New item writes include an opaque `origin_installation_id`. Older clients still work, but without origin identity their immediate saves cannot be recognized as same-device saves.
- Notification settings apply per installation. Opening an item on one device does not acknowledge or dismiss notifications on all other devices.

## Verification

```sh
flutter test test/notification_plan_test.dart test/inbox_deduplication_test.dart
flutter analyze --no-pub
cd laterbox-web
npx tsc --noEmit
npm test
cd ..
npx --yes deno test -A supabase/tests/notifications.test.ts supabase/functions/notifications/providers.test.ts supabase/functions/capture/capture.test.ts supabase/functions/extension-connect/extension-connect.test.ts
```

The SQL regression suite runs the actual outbox migration in embedded PostgreSQL (PGlite); it does not contact production. CI also runs the web and backend notification suites. Provider secrets are not needed for these tests.

Validated during implementation: unsigned iOS and macOS compilation, native reminder planning and existing inbox tests, web TypeScript and unit tests, actual SQL outbox behavior, and Edge Function type checks/tests. Existing unrelated Flutter lint findings remain. Signed macOS build requires a new push-enabled provisioning profile. Android SDK and Windows/Linux toolchains were not available on the development machine. Real-device provider delivery is still a release acceptance step after credential provisioning.

On each target device, test permission denial/revocation, a two-minute local reminder while offline, reschedule/archive cancellation, a remote save from a second device, background/closed-app delivery where supported, notification taps with and without an existing session, logout/account switching, duplicate/retried pushes, and expired provider tokens. Verify that scheduled returns notify every opted-in device and immediate saves omit their originating device.
