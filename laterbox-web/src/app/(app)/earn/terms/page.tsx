// laterbox-web/src/app/(app)/earn/terms/page.tsx
import Link from 'next/link';
export default function EarnTermsPage(){
  return <main className="mx-auto max-w-3xl px-6 py-12 text-[#171711]">
    <Link href="/earn" className="text-sm font-semibold text-[#6b804b]">← Back to Earn</Link>
    <h1 className="mt-7 text-3xl font-extrabold">LaterBox Earn — program rules</h1>
    <p className="mt-3 text-sm text-[#75816e]">Operational program summary. The program remains inactive until LaterBox publishes final legal terms and enables registrations.</p>
    <div className="mt-9 space-y-7 text-sm leading-7 text-[#485244]">
      <section><h2 className="font-bold text-[#171711]">Eligibility and roles</h2><p>You must be at least 18 years old, have an active paid Plus or Vault subscription for two calendar months and meet the program’s payment-verification rules. Complimentary access, trials, overdue and suspended accounts do not qualify. Plus Partner and Vault Ambassador roles have different commission rates, disclosed at enrollment.</p></section>
      <section><h2 className="font-bold text-[#171711]">Attribution and earnings</h2><p>Only eligible, verified first purchases referred through your tracking link qualify. Self-referrals, repeated purchases, duplicate accounts and fraudulent transactions are excluded. Commissions are calculated against the payment amount received after processor fees, not the customer’s gross total. Your rate depends on your qualifying paid plan at the time the eligible first purchase is verified; that rate is recorded with the commission. Rates can change prospectively with program rules.</p></section>
      <section><h2 className="font-bold text-[#171711]">Pending and reversals</h2><p>Commissions are initially pending for at least 30 days and may be held longer for reviews, refunds or disputes. Refunded or otherwise disqualified transactions can be reversed. “Available” is not “paid”; earnings are paid only after Whop confirms a successful transfer.</p></section>
      <section><h2 className="font-bold text-[#171711]">Payouts and privacy</h2><p>Whop handles payout accounts, KYC, tax information and withdrawals. LaterBox does not collect bank credentials. Transfers depend on Whop permissions, eligibility, funds availability and country support. You are responsible for your own taxes.</p></section>
      <section><h2 className="font-bold text-[#171711]">Affiliate disclosure</h2><p>You must clearly disclose when a promotional post contains a link from which you may earn a commission. Do not misrepresent LaterBox or promise guaranteed earnings. Whop’s applicable platform terms also apply.</p></section>
    </div>
  </main>;
}