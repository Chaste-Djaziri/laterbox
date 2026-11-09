<!-- laterbox-web/PRICING_AND_AFFILIATE_RESEARCH_2026-11.md -->
# LaterBox — pricing, storage expansion and affiliate economics

Research date: 2026-11-09. **Proposal only: not activated in Whop or the production LaterBox catalog.**

## Decision

**Do not increase the current $2.99/10 GiB Plus or $6.99/100 GiB Vault prices yet.**
Offer opt-in higher capacities as *new* plans, test revenue conversion and actual
R2 consumption, and keep legacy customer prices grandfathered. Compete on the
save-for-later workflow—not on bulk storage price alone.

### Why

- Today's free tier is 500 MB; paid catalog currently contains Plus 10 GiB
  ($2.99/$29.99) and Vault 100 GiB ($6.99/$69.99).
- LaterBox's published file metadata points to **Cloudflare R2** objects, while
  Supabase stores attachment metadata and quota/entitlement rules. R2 Standard
  charges **$0.015 per decimal GB-month**, plus Class A/B operations, with no
  Internet egress fee (see linked primary sources).
- Supabase Storage would cost **$0.0213/GB-month** plus data transfer overages,
  so **don't silently assume every stored asset uses the same supplier**.
- A read-only, aggregated Supabase usage check indicated **very little
  production history so far**. That sample is too small to estimate
  willingness to pay, actual usage at capacity, churn, or affiliate earnings.
  The query measures attachment metadata, not the actual R2 supplier invoice.
- Whop's advertised base domestic-card fee is **2.7% + $0.30**. Potential
  additions: **0.5% billing**, **2% tax/remittance when tax is collected**,
  international card and conversion surcharges, plus payout/affiliate fees.
  Effective charges must be reconciled against real Whop settlements.

## Suggested retail catalog (USD)

Storage quota units are binary GiB; 1 TB shown as 1,024 GiB and
2 TB as 2,048 GiB. Do not swap displayed GB/TB and implementation units
without documenting the convention to customers.

| Display | Capacity | Monthly | Annual | Positioning |
|---|---:|---:|---:|---|
| Free | 500 MB | Free | Free | Fast links and sync |
| Plus | 10 GiB | $2.99 | $29.99 | Existing entry plan — preserve |
| Plus 50 | 50 GiB | $4.99 | $49.99 | New bridge between Plus and Vault |
| Vault | 100 GiB | $6.99 | $69.99 | Existing standard — preserve |
| Vault 250 | 250 GiB | $11.99 | $119.99 | Creators saving more PDFs and media |
| Vault 500 | 500 GiB | $19.99 | $209.99 | Larger personal library |
| Vault 1 TB | 1,024 GiB | $39.99 | $419.99 | Heavy use; watch utilization |
| Vault 2 TB | 2,048 GiB | $69.99 | $739.99 | Advanced heavy use; strict trial safeguards |
| Enterprise / 5 TB+ | Custom | Quote | Quote | Review actual egress/storage/support economics |

Market comparison: Google One 100 GB **$1.99/mo**, 2 TB **$9.99/mo**;
Proton Drive 200 GB **$4.99/mo**; Instapaper Premium **$5.99/mo**;
Raindrop.io Pro approximately **$2.99/mo**. LaterBox cannot win a
commodity price/GB war. Charge extra for capture from iOS/share extension,
browser capture, scheduling, archive, useful media preview, and search—not
for the raw bytes alone.

**UI:** Keep the main pricing view compact with Free, Plus, Vault,
Vault 500 and Vault 2 TB featured; put the 50/250/1 TB size options
under one capacity selector. Show actual provider-reported price and billing
period, including applicable taxes. Never advertise new plans until the
Whop catalog *and* every quota/entitlement API recognize the new IDs.

## Monthly model: *illustrative* cash contribution

The reusable assumptions and computations are in
`src/lib/billing/pricing-proposal.ts`.
The model uses 15% affiliate commission on net revenue during launch,
a domestic Whop payment fee of 2.7% + $0.30, optional 0.5% billing,
2% tax processing, full real R2 storage charge at 1 GiB = 1.07374 decimal GB,
and a hypothetical $0.35–$3 monthly operations budget.

| Plan | Referrer at 15%/month | Modeled contribution at 100% quota utilization | Contribution at 40% utilization |
|---|---:|---:|---:|
| Plus 10 | $0.38 | $1.64 | $1.74 |
| Plus 50 | $0.66 | $2.46 | $2.94 |
| Vault 100 | $0.95 | $3.02 | $3.98 |
| Vault 250 | $1.66 | $4.38 | $6.80 |
| Vault 500 | $2.80 | $6.55 | $11.38 |
| Vault 1 TB | $5.64 | $13.48 | $23.37 |
| Vault 2 TB | $9.91 | $20.16 | $39.95 |

**Not net profit**: omitted/variable costs include backups and versioning,
R2 read/write operations beyond the small assumed budget, AI inference,
email/push delivery, web/compute, support, customer acquisition, fraud,
refunds/chargebacks, capital/operating expenses, tax as applicable, FX,
Whop payout/affiliate processing charges, and potential Apple App Store
commissions. This is a planning envelope, **not an accounting forecast**.
At high-capacity annual subscriptions, margins are lower: the draft
2 TB annual price has approximately **22% modeled contribution margin**
under full utilization and a 15% affiliate before other omitted costs.

### Affiliate incentives

- Everyone may register and share a unique/customizable referral code
  while on Free. An affiliate payout requires legal age, identity and payout
  verification; having a paid LaterBox subscription is **not** necessary.
- Referral recipient gets the selected plan's qualifying trial **only if
  Whop confirms its trial configuration**. The first month's trial earns
  zero commission. The referred customer must stay subscribed, complete
  two genuinely successful paid billing periods, and pass the three-month
  tenure gate. Chargebacks and refunds reverse eligibility.
- Recommended **15%** of eligible post-fee revenue for the first 12
  commissionable paid transactions, **10%** for later payments. This means
  a larger plan earns more while the affiliate rate is transparent.
- For **20 active Vault 500 referrals**, modeled commissions would be
  about **$56/month** at 15% or **$37/month** at 10%. These are examples,
  not guaranteed or passive-income claims.
- Competitor context: Notion advertises 20% of first-year revenue plus a
  qualifying bonus, Todoist up to 25% for 12 monthly transactions,
  and Readwise 33% per paying signup. Programs differ in eligibility and
  duration: percentages are not directly interchangeable.
- Whop's separate default affiliate marketplace and LaterBox's own
  commission ledger must never pay twice on the same purchase.
- Annual plans need special handling: at least three months of verified
  membership before first release, with no fictional monthly billing events.

### Trial-risk warning

**A full 30-day free trial of a 2 TB R2-backed plan can cost LaterBox about
$33 in storage alone if it is fully filled.** Repeating this with fake
accounts makes the referral promotion economically unsafe before any payment.

Keep **all launch switches off** until trial controls exist: one trial per
verified person/payment method; verified payment method via Whop; fraud,
device and account limits; abuse monitoring; disclosed trial upload
allowance; billing reminders and cancellation transparency. If the
customer must receive all 2 TB during the free month, price in the abuse
risk and consider manual verification or a temporary higher-plan freeze.
Do not silently present a restricted trial as a full-capacity trial.

### Operational decisions before rollout

1. Obtain R2 **actual daily storage** and operations charges, per-plan
   GB percentiles, bandwidth, and cloud bill; estimate conversion and churn
   over a meaningful cohort (e.g. 90 days). The current customer sample is
   not enough to model pricing elasticity.
2. Keep current Plus/Vault products and grandfather existing prices. Create
   **additional** Whop plans; do not alter existing plan prices or charged
   subscriptions silently. Verify billing period, currency, trial, product,
   and tax options via the API.
3. Update Supabase storage-plan allowlist, Whop plan mapping, quota function,
   iOS entitlement display, web pricing/checkout, billing tests, capacity
   selectors, and R2 guards **atomically** before enabling any new SKU.
4. Add one-time unique referral attribution and recurring commission ledger
   with 3-month qualification, refund reversals, double-payment prevention,
   and anti-fraud; escrow/hold can be represented as pending, not promised paid.
5. Implement customer-facing subscription renewal disclosures and refund
   policy, country/age rules, tax and Whop KYC rules. App Store iOS external
   payment flows need to comply with the latest Apple storefront policies;
   rules vary by region and entitlements.
6. Sandbox test both normal and promo Whop checkout, repeated webhook events,
   upgrade/downgrade, trial expiration, cancellation, refunds, annual plans,
   app reinstall, and all storage quota enforcement code.
7. Launch with **program disabled and payouts disabled** by default. Activate
   only after reconciliation, legal review and verified provider capabilities.
8. Experiment on conversion and 30/90-day retention before raising any
   existing price. Revisit affiliate payout rates after real cohort data.

## Primary references (viewed 2026-11-09)

- Cloudflare R2 costs: https://developers.cloudflare.com/r2/pricing/
- Whop transaction, billing, tax and affiliate fees: https://whop.com/network/pricing/
- Whop trial plan fields: https://docs.whop.com/api-reference/plans/create-plan
- Google One prices: https://one.google.com/about/plans?hl=en_US
- Proton Drive prices: https://proton.me/drive/pricing
- Raindrop.io: https://raindrop.io/pro
- Instapaper: https://instapaper.com/premium
- Notion affiliates: https://www.notion.com/affiliates
- Todoist partner program: https://www.todoist.com/help/todoist/billing/todoist-partner-programs-t8t2hZ0Z
- Readwise affiliate program: https://docs.readwise.io/affiliates
- Apple App Review guidelines: https://developer.apple.com/app-store/review/guidelines/

**This file is strategic research. It does not provision a plan, change a
customer's price, modify production Supabase, or authorize a Whop transfer.**
