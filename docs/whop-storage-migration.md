# LaterBox × Whop storage billing: rollout

**Status: implemented in local source only. Do not deploy or accept real charges until staging acceptance.**

## Product decisions

- Free: 500,000,000 cloud file bytes, free authenticated sync between iOS, Web, and Chrome. Ordinary bookmark metadata is not charged against cloud file capacity, but is still subject to fair-use protections.
- Plus: 10 GiB for $2.99/month or $29.99/year (proposed).
- Vault: 100 GiB for $6.99/month or $69.99/year (proposed).
- Existing Paddle and Apple StoreKit customers remain valid. Their current purchases are grandfathered with a 10 GiB cloud allowance until a deliberate migration; **never** silently cancel, re-bill, or switch payment providers.
- Whop checkout is embedded inside `/checkout`. A server-authenticated checkout configuration associates the Whop payment with a LaterBox checkout intent.
- A Whop payment is not sufficient to grant access until a verified webhook and Whop membership lookup succeed. A return URL alone is not evidence of payment.
- Start without free trials until trialing-membership ownership and activation is tested against Whop sandbox.

## Sandbox configuration

Set these secrets in the server environment, never in client bundle or Git:

```sh
WHOP_SANDBOX=true
WHOP_COMPANY_API_KEY=<Whop sandbox company API key>
WHOP_WEBHOOK_SECRET=<Whop sandbox webhook verification secret>
WHOP_PLUS_MONTHLY_PLAN_ID=plan_...
WHOP_PLUS_YEARLY_PLAN_ID=plan_...
WHOP_VAULT_MONTHLY_PLAN_ID=plan_...
WHOP_VAULT_YEARLY_PLAN_ID=plan_...
SUPABASE_SERVICE_ROLE_KEY=<server-only>
```

Whop Company ID / business: configure the Whop app and matching products in the connected Whop dashboard. Plan IDs must match **recurring subscriptions**, not one-time purchases. Checkout code validates plan IDs on the server and does not accept arbitrary plan IDs supplied by the client.

Use distinct Whop sandbox accounts, API tokens, plan IDs and webhook verification secrets from production. Set `WHOP_SANDBOX=false` only in production after sandbox acceptance. The server sends the chosen environment to the embedded checkout client so they agree.

Configure Whop's webhook endpoint as `https://app.laterbox.dev/api/billing/whop/webhook`, after deploying the API. Subscribe to payment and membership lifecycle events. Verify a real sandbox event and the SDK's webhook signature algorithm. Rate-limit abuse-prone endpoints at your edge.

## Production deployment: Cloudflare, not Supabase Edge secrets

The deployed Next.js app uses OpenNext and **Cloudflare Worker `laterbox-web`**
(see `laterbox-web/wrangler.jsonc`). Routes
`/api/billing/checkout`, `/api/billing/whop/webhook`, and the account billing
portal run in that Worker. Configure the production credentials **in Cloudflare**
so those routes can read them through `process.env`.

Recommended deployment values:

| Setting | Runtime | Type |
| --- | --- | --- |
| `WHOP_COMPANY_API_KEY` | Cloudflare Worker `laterbox-web` | Encrypted Secret |
| `WHOP_WEBHOOK_SECRET` | Cloudflare Worker `laterbox-web` | Encrypted Secret |
| `WHOP_SANDBOX=false` | Cloudflare Worker `laterbox-web` | Non-secret variable |
| Four `WHOP_*_PLAN_ID` settings | Cloudflare Worker `laterbox-web` | Non-secret variables |

Open Cloudflare → Workers & Pages → `laterbox-web` → Settings →
Variables and Secrets. Add the two credentials with **Secret** type, the
environment switch and four recurring plan IDs as normal variables. This
avoids writing sensitive values into terminal history or source control.
When using Wrangler instead, `wrangler secret put` prompts securely
for each value but may create and deploy a new Worker version immediately;
coordinate this with a staged rollout.

**Local Next.js:** use the tracked, blank template at
`laterbox-web/.env.example`; add real **sandbox** values only to the existing,
ignored `laterbox-web/.env.local`. Do not overwrite unrelated existing
environment settings. Cloudflare local preview via Wrangler may require an
ignored `laterbox-web/.dev.vars`; do not assume it reads `.env.local`.

**Supabase Edge Secrets are not shared with Cloudflare Workers.** Set Whop
credentials in Supabase only if billing endpoints are later migrated to
Supabase Edge Functions. Existing Supabase file-storage functions keep their
own secrets. Never publish keys as `NEXT_PUBLIC_*`, and rotate any secret
accidentally exposed in logs or commits.

## Key creation and verification

In the Whop Laterbox developer dashboard, create a **company API key**
scoped to the billing operations the backend actually needs (checkout
configuration creation, payment and membership lookup, billing management
as applicable). Confirm the exact scope names with Whop's current UI.
Create a separate, signed **webhook endpoint** for
`https://app.laterbox.dev/api/billing/whop/webhook`; its signing secret is
different from the company API key. Enable payment success and membership
lifecycle events used by `process-whop.ts`. Do not reuse production keys
while testing against Whop sandbox.

The dashboard may show a newly created key **only once**. Copy it directly
into an encrypted secret store or a Git-ignored local file; **never paste it
into an issue, a commit, or a chat transcript**.

## Database sequencing

1. Back up the Supabase database and snapshot current billing subscription rows.
2. On staging, apply `202611080001_whop_storage_plans.sql` **before** `202611080002_free_sync_and_storage_enforcement.sql`.
3. Verify all `billing_*_provider_check` constraints allow Paddle, Apple, and Whop, with no loss of historical billing events.
4. Verify free account read/write of its own items, notes, metadata and collections. Verify a user cannot read or modify another user's data.
5. Test two concurrent file uploads that would exceed quota combined. Confirm the second reservation fails, including when bypassing the UI.
6. Verify uploads at 99–101 MiB; the database currently caps a single attachment at 100 MiB, even for Vault subscribers.
7. Confirm storage used matches published attachment bytes, including deleted and permanently deleted files. Observe reservations expiring after 30 minutes without being counted as stored files.
8. Deploy backend/API handlers, then Web and iOS clients. No production DB migrations or live checkout credentials were applied in this local coding task.

## Acceptance / regression tests

- Free signed-in account: Chrome save → Web library → iOS library, schedules and collection membership round-trip.
- Guest/local-only data is safe and usable without an account.
- Plus/Vault checkout in Whop sandbox: verified `payment.succeeded` sets the correct `storage_plan` and period end; Web updates only once after verified webhook.
- Fake/expired webhook signature, unknown plan IDs, repeated webhook events, stale updates, wrong LaterBox account, missed checkout metadata, and mismatched buyer must not unlock capacity.
- Renewals, scheduled cancellation, actual expiration, refunds, and payment failures update entitlements without resurrecting old access.
- A canceled or downgraded user can still read/export existing files and bookmark metadata. Existing files must not be deleted automatically; only new chargeable uploads are blocked above quota.
- Existing active Apple/Paddle subscribers cannot start a second Whop checkout; account portal management still directs them to the original provider.
- iOS purchases still use StoreKit 2; Whop checkout is the web checkout, not a replacement for native IAP.
- Run `npx tsc --noEmit`, `npm test`, and release builds. Test real browser Whop embedding, including 3DS/wallet flows before going live.

## Rollback

If a live checkout issue appears, hide new Whop checkout buttons and disable new checkout API requests before changing subscription records. Keep the existing verified subscription records and read-only entitlement service available. Avoid reverting account-ownership RLS while new free-sync clients are active. Never drop event history or charged checkout intents during rollback.

## Existing billing source

See `docs/billing.md` for legacy Paddle and Apple migration instructions. Do not delete historical Paddle webhook handling, Apple verification, or Paddle customer portal endpoints until all paid subscriptions have been reconciled.
