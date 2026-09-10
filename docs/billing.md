# LaterBox billing

LaterBox uses a provider-neutral entitlement model. Paddle sandbox is the first billing provider; Apple StoreKit can populate the same subscription table before paid gates are enabled in App Store builds.

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

Apply the Supabase migrations before enabling checkout. The billing launch migration grants accounts that already exist at migration time 30 days of Pro access.

## Distribution flags

Flutter builds accept `--dart-define=LATERBOX_DISTRIBUTION=direct|play|app-store`. Direct desktop builds may open web billing. Google Play builds are consumption-only and show no checkout link. Apple App Store builds disable billing enforcement until StoreKit is implemented. `LATERBOX_WEB_URL` controls the entitlement API origin and defaults to `https://app.laterbox.dev`.

## Access behavior

Local saving, reading, search, organization, and export remain free. Cloud sync, cloud attachments, connected extensions, Watch Mode, and automated capture require Pro. When entitlement expires, local pending data is retained and sync resumes after access is restored.

Paddle webhooks are the provisioning authority. Checkout completion only triggers an entitlement refresh; it never grants access by itself. Portal URLs are minted per authenticated request and are not cached.
