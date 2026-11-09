<!-- laterbox-web/README-EARN.md -->
# LaterBox Earn — integration and launch checklist

## Scope

Earn is a native iOS tab and an authenticated web dashboard at `/earn`. The server enforces 18+ self-attestation, an active paid Plus/Vault subscription for **two calendar months**, and for Whop monthly plans at least two different successful invoices separated by 25 days. Free access, complimentary grants, trials and past-due subscriptions do not qualify.

The first paid subscription purchase attributed through a LaterBox referral link creates **one** commission on Whop's positive USD merchant-net `amount_after_fees`. Renewals count for subscription tenure, **not** further commissions. Program defaults: Plus Partner **10%**, Vault Ambassador **15%**, pending hold **30 days**, payout minimum **$10**. These are **draft configuration values** and must be approved before launch. No commissions or payouts are promised while the program is disabled.

## Deployment (required before use)

1. Apply `supabase/migrations/202611090002_laterbox_earn_affiliates.sql` **after** `202611080001_whop_storage_plans.sql`. Do not activate the program before deploying the migration and tested callback handler.
2. Create and approve your public affiliate terms, applicable privacy/tax disclosures, refund/dispute and commission policies. Confirm allowed regions/age, and budget for tax, processing fees and program fraud.
3. Verify Whop business ID and company API key with **`payout:transfer_funds`** permissions. Keep `WHOP_COMPANY_API_KEY` server-only. Make sure `WHOP_SANDBOX` matches production or sandbox correctly. Create a Whop OAuth app with `oauth:token_exchange` permission. Configure `WHOP_CLIENT_ID`, `WHOP_CLIENT_SECRET`, `WHOP_OAUTH_REDIRECT_URI=https://app.laterbox.dev/api/earn/connect/callback`, and a 32+-character random `EARN_OAUTH_COOKIE_SECRET` in the production environment. Register the **exact** callback URL in Whop's OAuth app. Affiliates can now click **Connect Whop**, authenticate through Whop's hosted screen, and have their `user_...` recipient identity verified server-side. Never accept a payout destination ID directly from the user.
4. Configure `EARN_TRACKING_ENABLED=true`, `WHOP_BUSINESS_ID`, `WHOP_COMPANY_API_KEY`, and a random secret `EARN_CRON_SECRET` (24+ characters) in the server's production environment. Do not enable `EARN_TRACKING_ENABLED` until the migration exists. With it disabled, existing Whop subscription webhooks remain unaffected and Earn is treated as inactive.
5. Perform sandbox purchase/refund, referral attribution and transfer idempotence tests; confirm no duplicate payout or cloud-account mixups.
6. Set the single `affiliate_program_settings` row to your approved rates and `enabled=true` only when ready to accept affiliates. Set `automatic_payouts=true` **only after transfer verification**. The migration defaults both switches to **false**.
7. In GitHub repository settings set variable `EARN_AUTOMATION_ENABLED=true`, variable `EARN_SETTLE_URL=https://app.laterbox.dev/api/earn/settle` and secret `EARN_CRON_SECRET`. The scheduled workflow runs daily at 06:19 UTC. With variables unset, it does nothing.

## Tracking

A generated link `https://laterbox.dev/r/lb_...` sets a secure HTTP-only 30-day referral cookie scoped to `.laterbox.dev`; users go through LaterBox signup and paid Whop checkout. The server attaches a verified affiliate user ID to the checkout intent. The verified Whop `payment.succeeded` webhook resolves owner, payment and membership from Whop, records a paid receipt, and creates a single commission only for an eligible initial purchase. Replays are idempotent using unique constraints.

The private cron route releases pending earnings after the hold period and (when automatic transfers are enabled) atomically claims available amounts, creates a Whop balance transfer to an administrator-verified Whop user ID, and records the returned transfer ID. Failed or timed-out transfers retain the same idempotence key and retry without creating a second payout.

Refunded earnings still pending/available are reversed upon verified refund webhooks. Paid chargeback clawbacks and more advanced dispute handling require a financial policy and further reconciliation.

## Payout and withdrawal UI

LaterBox shows `pending → available → processing → paid` and provides a direct link to the user's Whop balance management for KYC, bank setup, and withdrawal. Money is **never** sent directly from the iOS or web client; sensitive Whop operations use the server. Whop's own merchant affiliate program and this first-party referral ledger are **alternative** commission mechanisms; do not enable both on the same purchases or you may pay twice.

## Operational caveats

- Commission tracking currently covers **first-time paid Whop web checkouts**, not purchases through Apple's in-app StoreKit subscription flow. Referral links should clearly direct users to the web checkout.
- Failed Whop transfers are marked for manual financial review. Funds are returned to the available ledger, but automatic payout attempts for that affiliate remain blocked until the failed payout is resolved by an administrator.
- Commission rates are proposed defaults, not finalized economics. The applicable affiliate role and rate are recalculated from the member's qualifying subscription at the initial paid purchase, then snapshotted on each commission record.
- Historical Whop receipts before this migration are not backfilled. A verified manual historical-receipt reconciliation is needed to enroll long-time monthly subscribers immediately.
- Financial totals should use authoritative server state; never trust or accept client money amounts.
- Data migration, Whop product affiliate settings and production secret deployment must be completed separately. Merely creating the UI does not activate a live affiliate program.
