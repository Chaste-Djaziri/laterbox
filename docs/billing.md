# LaterBox billing

LaterBox uses a provider-neutral entitlement model. Paddle powers web and direct desktop billing. StoreKit 2 powers iOS and Mac App Store purchases, while both providers unlock the same LaterBox account.

## Sandbox configuration

Set these only in local secrets or the deployment platform. Never commit their values.

```bash
# Server only
PADDLE_SANDBOX_API_KEY=pdl_sdbx_apikey_...
PADDLE_API_KEY=pdl_sdbx_apikey_...
PADDLE_NOTIFICATION_WEBHOOK_SECRET=pdl_ntfset_...
SUPABASE_SERVICE_ROLE_KEY=...

# Safe browser configuration
NEXT_PUBLIC_PADDLE_ENV=sandbox
NEXT_PUBLIC_PADDLE_CLIENT_TOKEN=test_...
NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID=pri_...
NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID=pri_...
```

Create the sandbox catalog once:

```bash
cd laterbox-web
node scripts/seed-paddle-catalog.mjs
```

Copy the printed price IDs into the deployment environment. In Paddle sandbox, set the default payment link and register `/api/billing/webhook` as a notification destination for:

- `customer.created`, `customer.updated`
- `subscription.created`, `subscription.updated`, `subscription.activated`, `subscription.canceled`
- `transaction.completed`

## Production Paddle catalog

Use a separate, short-lived production API key with only **Products Read/Write** and **Prices Read/Write** permissions. Read access lets the idempotent script reuse an existing catalog instead of creating duplicates. Do not add these catalog-management permissions to the runtime key. After the catalog is created and its IDs are stored, revoke the temporary key.

The seed script is safe to rerun: it reuses the active `LaterBox Pro` product and matching USD prices when they already exist. Production seeding also requires an explicit confirmation value:

```bash
cd laterbox-web
PADDLE_CATALOG_ENV=production \
PADDLE_CONFIRM_PRODUCTION=CREATE_LIVE_CATALOG \
PADDLE_CATALOG_API_KEY='pdl_live_apikey_...' \
node scripts/seed-paddle-catalog.mjs
```

The production catalog contains:

- `LaterBox Pro`, tax category `saas`
- `$3.99 USD` monthly with a 14-day trial
- `$39.99 USD` yearly with a 14-day trial

Copy the printed production price IDs into `NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD` and `NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD`. The temporary catalog key is not a deployment secret and should be revoked after use.

Apply the Supabase migrations before enabling checkout. The billing launch migration grants accounts that already exist at migration time 30 days of Pro access.

## Web deployment configuration

Next.js embeds `NEXT_PUBLIC_*` values at build time. Setting only Worker runtime
secrets cannot configure a browser bundle that was already built. The web release
workflow sets `NEXT_PUBLIC_PADDLE_ENV=production` and reads:

- GitHub Actions secret `NEXT_PUBLIC_PADDLE_CLIENT_TOKEN_PROD` (a `live_` client-side token).
- GitHub Actions variables `NEXT_PUBLIC_PADDLE_PRO_MONTHLY_PRICE_ID_PROD` and
  `NEXT_PUBLIC_PADDLE_PRO_YEARLY_PRICE_ID_PROD` (live catalog price IDs).

Configure these before running the release workflow. Production builds reject
missing public billing configuration and sandbox client tokens. Rebuild after
changing public values.

Configure these separately as Cloudflare Worker runtime secrets:

- `PADDLE_API_KEY`: live runtime key with transaction creation and customer portal session permissions.
- `PADDLE_NOTIFICATION_WEBHOOK_SECRET_PROD`: signing secret for the live notification destination.
- `SUPABASE_SERVICE_ROLE_KEY`: server-only key for billing storage.

Never put API keys, webhook secrets, or the service-role key in `NEXT_PUBLIC_*`
variables. Confirm the correct Cloudflare account and existing Worker before
checking secret names with `npx wrangler secret list` from `laterbox-web/`.

In Paddle live settings, confirm `app.laterbox.dev` is approved, set the default
payment link to `https://app.laterbox.dev/plans`, and register
`https://app.laterbox.dev/api/billing/webhook` for the events listed above.
Dashboard checkout styling and payment methods do not initialize Paddle.js.

The plans page waits for secure checkout to load and reports missing configuration
or initialization failures. Active Paddle subscriptions show separate management
and cancellation actions. Cancellation opens Paddle's hosted confirmation form;
webhook updates supply the scheduled cancellation and access end date. Portal
sessions are created for each action and scoped to the authenticated account.

## Native distribution

Apple applications use native StoreKit and verified server entitlements. Android billing lives in the Kotlin app; configure Google Play products and signing for its distribution. Web checkout uses Paddle. Release behavior must be verified in each native client rather than selected through a shared compile-time distribution flag.

## Apple configuration

App Store Connect must contain these auto-renewable subscriptions in the same `LaterBox Pro` group:

- `com.laterbox.pro.monthly`
- `com.laterbox.pro.annual`

Configure App Store Server Notifications V2 for both environments:

```text
Production: https://app.laterbox.dev/api/billing/apple/webhook
Sandbox:    https://app.laterbox.dev/api/billing/apple/webhook
```

Set the following Worker secrets. `APPLE_ROOT_CERTIFICATES_BASE64` is a comma-separated list of DER-encoded Apple root certificates converted to base64; download the trusted roots directly from Apple PKI. Never commit the certificates or private key.

```bash
APPLE_APP_ID=<numeric App Apple ID, not a subscription Apple ID>
APPLE_BUNDLE_ID=pro.micorp.laterbox
APPLE_ROOT_CERTIFICATES_BASE64=...
APPLE_ISSUER_ID=...
APPLE_KEY_ID=...
APPLE_PRIVATE_KEY=...
```

The current verification path uses Apple-signed StoreKit transaction JWS data and does not require the private API key for ordinary purchase verification. Keep the issuer/key values configured for App Store Server API operations and future subscription recovery tooling.

StoreKit purchases require an authenticated LaterBox account. The Supabase user UUID is sent as `appAccountToken`; the server rejects transactions that are missing it or belong to another user.

Build Apple releases through the native Xcode workflow in [deployment](deployment.md). Build Android App Bundles in Android Studio with the appropriate release signing and Google Play billing configuration.

## Access behavior

Local saving, reading, search, organization, and export remain free. Cloud sync, cloud attachments, connected extensions, Watch Mode, and automated capture require Pro. When entitlement expires, local pending data is retained and sync resumes after access is restored.

Paddle webhooks are the provisioning authority. Checkout completion only triggers an entitlement refresh; it never grants access by itself. Portal URLs are minted per authenticated request and are not cached.
