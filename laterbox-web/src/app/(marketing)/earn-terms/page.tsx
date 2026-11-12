// laterbox-web/src/app/(marketing)/earn-terms/page.tsx
import type {Metadata} from 'next';
import Link from 'next/link';
import {
  ArrowLeft, ArrowUpRight, BadgeCheck, CalendarClock, CircleDollarSign,
  FileCheck2, Gift, Link2, LockKeyhole, ShieldCheck,
} from 'lucide-react';

export const metadata: Metadata = {
  title: 'LaterBox Earn Terms | Referral and Affiliate Program',
  description: 'Eligibility, verified referrals, free trials, recurring commissions, holds, disclosures and Whop payouts for LaterBox Earn.',
};

const updated = 'November 12, 2026';

const sections = [
  {
    id: 'eligibility', number: '01', title: 'Who can participate',
    paragraphs: [
      'LaterBox Earn is available to eligible signed-in adults aged 18 or older, including members on the Free plan. You do not need a paid Plus or Vault subscription, and there is no requirement to have held a paid LaterBox plan for two months to become a referrer.',
      'Before you can actively refer others, you must connect and verify your own Whop account, confirm your age, accept these Earn Terms and be approved by the active program. Availability may depend on your location, applicable laws, identity verification and Whop support. Suspended or otherwise ineligible accounts cannot participate.',
      'An account may have a reserved referral code before Earn is active. A reserved code, visible dashboard or connected Whop account does not mean that referral attribution or commissions are enabled. Program availability is shown in the Earn dashboard.',
    ],
  },
  {
    id: 'codes', number: '02', title: 'Your referral link and code',
    paragraphs: [
      'Each LaterBox account is assigned a unique code. Your personal shareable link is made available after Whop verification. You may customize the code to an available, non-reserved name using 8–32 lowercase letters, numbers, hyphens or underscores. Codes are checked for uniqueness, and customization is limited to one change every 30 days.',
      'Share your own referral link or code with genuine prospective customers. Attribution only occurs through an eligible tracked referral and verified checkout while the program is active. We cannot guarantee attribution for untracked visits, unsupported purchases, purchases completed without the code, or transactions that do not meet the program rules.',
    ],
  },
  {
    id: 'trial', number: '03', title: 'Referral trials and eligible purchases',
    paragraphs: [
      'An eligible newly referred customer may receive a one-month (normally 30-day) free trial when a verified referral-trial offer is enabled for the selected plan and shown during checkout. Trials are not automatically included with every referral, plan or promotion; the checkout offer controls what the buyer receives.',
      'The trial is intended for qualifying new customers, not existing subscribers or repeat trial claimants. A customer can receive at most one eligible referral-trial claim, and referrals to yourself, the same person using multiple accounts, or ineligible purchases are not commissionable.',
      'The referred customer must complete checkout using the eligible referral attribution and maintain a qualifying subscription. No commission is earned merely because someone clicks a link, registers, starts a trial, or makes an unverified payment.',
    ],
  },
  {
    id: 'qualification', number: '04', title: 'When a referral becomes commissionable',
    paragraphs: [
      'A referral with a trial must remain subscribed for at least three calendar months from trial activation, including the free month followed by at least two calendar months after the trial ends. Qualifying paid transactions must be verified by the payment provider. For monthly subscriptions, the qualification process also checks two distinct successful paid billing periods; annual subscriptions are assessed using their verified payment and equivalent paid-duration requirements.',
      'A referral may remain Pending or Trialing while verification, subscription history and qualification conditions are checked. Cancelled subscriptions, failed charges, refunds, chargebacks and other disqualified transactions may prevent qualification or cause a later reversal. The referred user must not be the referrer.',
      'Qualification makes subsequent eligible paid renewals potentially commissionable; it does not guarantee a payment, and it does not make the free trial itself commissionable.',
    ],
  },
  {
    id: 'commissions', number: '05', title: 'Commission calculation and rates',
    paragraphs: [
      'LaterBox Earn uses recurring commissions on eligible, provider-verified subscription renewals after qualification—not a guaranteed bounty for a first purchase. Commissions are calculated in USD on eligible net revenue after applicable payment processing fees, refunds, discounts and other permitted adjustments, rather than on the full advertised plan price.',
      'The current configuration provides for an introductory rate of 15% on up to the first 12 eligible commissionable payments, followed by an ongoing rate of 10%. These figures describe the configured program, not an unconditional promise: applicable rates, eligible transaction counts and any future changes are controlled by the active program terms and dashboard at the time of the qualifying transaction. A buyer’s plan price and billing frequency affect the net payment amount; a Free referrer is not automatically paid a lower rate.',
      'We may change commission rates or eligibility requirements prospectively with notice where reasonably practicable. Already recorded commissions remain subject to validation, reversals, legal obligations and these Terms.',
    ],
  },
  {
    id: 'balances', number: '06', title: 'Pending, available and paid balances',
    paragraphs: [
      'Earn may show Pending, Available, Processing, Paid and Reversed amounts. Pending means an eligible commission is still being verified or held; Available means it has passed the applicable checks but has not yet been transferred; Processing means a payout attempt has been initiated; and Paid means the provider has confirmed successful transfer.',
      'Commissions normally enter a hold period of at least 30 days under the current configuration, which can be extended for fraud review, payment disputes, refunds, compliance checks or operational delays. Any refund, reversal, fraudulent activity or chargeback may lead to cancellation, withholding or recovery of the corresponding commission, including after it was previously displayed as Available.',
      'A displayed amount is not a promise of immediate payment. Any minimum payout threshold, review period and transfer schedule are governed by the active payout configuration and supported payment arrangements.',
    ],
  },
  {
    id: 'payouts', number: '07', title: 'Whop identity verification and payouts',
    paragraphs: [
      'Whop is used to verify affiliate identity and to support payout transfers and withdrawal arrangements. You may need to complete Whop’s identity checks, tax verification, account setup and any other requirements applicable in your country. LaterBox does not ask for or store your withdrawal banking credentials.',
      'Automatic payouts are not currently enabled by default. Transfers only occur when LaterBox has explicitly enabled payout operations, the commission is eligible and available, required thresholds are met, and Whop and applicable law permit the transfer. Withdrawal methods, processing times and currency conversions may be subject to Whop terms and fees.',
      'You are responsible for determining and paying any taxes due on commissions. If a payout fails or your Whop account cannot receive funds, the displayed balance does not override those restrictions.',
    ],
  },
  {
    id: 'conduct', number: '08', title: 'Affiliate disclosures and prohibited activity',
    paragraphs: [
      'Clearly and prominently disclose your affiliate relationship whenever you post or send a promotional link that may earn you a commission. For example, you can state that you may earn a commission if someone buys using your link. Follow advertising, consumer protection and privacy rules applicable to you and your audience.',
      'Do not send unsolicited spam, fabricate testimonials, impersonate LaterBox or Whop, make misleading pricing or earnings claims, use unauthorized paid-search or brand impersonation tactics, create fake users or self-referrals, manipulate attribution, use stolen payment methods, or offer unauthorized incentives. Do not suggest that trials, savings, commission rates or earnings are guaranteed.',
      'LaterBox may investigate suspicious activity, reject invalid attribution, suspend referrals, withhold or reverse related commissions and remove access to Earn, subject to applicable law.',
    ],
  },
  {
    id: 'data', number: '09', title: 'Referral records and privacy',
    paragraphs: [
      'We process the information necessary to operate Earn, including your LaterBox account identifier, referral code, Whop verification status, tracked qualifying referral events, subscription/payment verification, commission history and payout statuses. We do not provide referrers with private payment credentials or full financial information about referred customers.',
      'Whop processes information under its own terms and privacy practices. For more about LaterBox’s handling of account information, see our Privacy Policy.',
    ],
  },
  {
    id: 'changes', number: '10', title: 'Program availability, changes and disputes',
    paragraphs: [
      'LaterBox may launch, pause, modify or end Earn, its free-trial offers or its payout features to meet operational, fraud-prevention, legal or provider requirements. When the program is paused or not launched, referral codes may remain reserved and historical balances may remain visible, but new referral attribution and commissions are not automatically available.',
      'Material changes to these terms will be reflected on this page with an updated date, with additional notice when appropriate. Disputes over tracked referrals or commissions may be reviewed against server-side transaction records and Whop confirmation. Contact support with the relevant date and referral or payout reference for assistance.',
      'These Earn Terms supplement the LaterBox Terms of Service. Applicable mandatory consumer or statutory rights are not excluded by this page.',
    ],
  },
];

export default function EarnTermsPage() {
  return (
    <main className="mx-auto w-full max-w-5xl px-4 pb-20 pt-8 text-[#171711] sm:px-6 sm:pt-12">
      <Link href="/earn" className="inline-flex items-center gap-2 text-sm font-bold text-[#61764d] hover:text-[#171711]">
        <ArrowLeft size={16} /> Back to Earn
      </Link>
      <header className="mt-8 border-b border-[#e3e7d9] pb-10">
        <span className="inline-flex items-center gap-2 rounded-full border border-[#d2deae] bg-[#e6edb0] px-3 py-1.5 text-xs font-extrabold tracking-wide">
          <FileCheck2 size={15} /> REFERRAL & AFFILIATE PROGRAM
        </span>
        <h1 className="mt-5 text-4xl font-black tracking-tight sm:text-5xl">LaterBox Earn Terms</h1>
        <p className="mt-4 max-w-3xl text-sm leading-7 text-[#65715e] sm:text-base">
          How eligibility, verified referrals, trial qualification, commissions and Whop payouts work.
          These terms apply when you enroll in LaterBox Earn.
        </p>
        <p className="mt-5 text-xs font-semibold text-[#85907d]">Last updated: {updated}</p>
      </header>

      <div className="mt-7 rounded-2xl border border-[#d8e3c7] bg-[#f0f5e3] p-5 text-sm leading-7 text-[#536448] sm:p-6">
        <strong className="text-[#273423]">Launch and availability notice.</strong>{' '}
        A referral code or Whop connection does not mean Earn is live. Enrollment, referral attribution,
        trial offers and commission accrual only work when the corresponding features are enabled and
        the participant meets the conditions in these Terms. Check the <Link href="/earn" className="font-bold underline underline-offset-2">Earn dashboard</Link> for current availability.
      </div>

      <div className="mt-7 grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { icon: BadgeCheck, name: 'Free plans welcome', text: 'No paid LaterBox plan is needed to join.' },
          { icon: Link2, name: 'Your own referral code', text: 'Whop verification unlocks sharing and customization.' },
          { icon: CalendarClock, name: 'Qualification first', text: 'A free trial, when offered, plus verified paid subscription time.' },
          { icon: CircleDollarSign, name: 'Provider-verified rewards', text: 'Commissions depend on eligible paid renewals.' },
        ].map(({icon: Icon, name, text}) => (
          <div key={name} className="rounded-2xl border border-[#e2e6d9] bg-white p-4">
            <Icon size={20} className="text-[#657d50]" />
            <h2 className="mt-3 text-sm font-extrabold">{name}</h2>
            <p className="mt-1 text-xs leading-5 text-[#72806b]">{text}</p>
          </div>
        ))}
      </div>

      <div className="mt-10 grid items-start gap-9 lg:grid-cols-[220px_minmax(0,1fr)]">
        <nav aria-label="Earn terms sections" className="hidden rounded-2xl border border-[#e3e7db] bg-white p-4 lg:sticky lg:top-24 lg:block">
          <p className="mb-3 text-xs font-extrabold uppercase tracking-wider text-[#798572]">On this page</p>
          <ol className="space-y-1">
            {sections.map(section => (
              <li key={section.id}>
                <a className="block rounded-lg px-2 py-1.5 text-xs font-semibold text-[#596751] hover:bg-[#eff3e5] hover:text-[#171711]" href={'#' + section.id}>
                  {section.title}
                </a>
              </li>
            ))}
          </ol>
        </nav>
        <div className="space-y-4">
          {sections.map(section => (
            <section id={section.id} key={section.id} className="scroll-mt-28 rounded-2xl border border-[#e2e6d9] bg-white p-5 sm:p-7">
              <div className="flex items-center gap-3">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-[#e6edb0] text-xs font-black text-[#171711]">
                  {section.number}
                </span>
                <h2 className="text-lg font-black tracking-tight">{section.title}</h2>
              </div>
              <div className="mt-4 space-y-3 text-sm leading-7 text-[#586452]">
                {section.paragraphs.map(paragraph => <p key={paragraph}>{paragraph}</p>)}
              </div>
            </section>
          ))}
          <section className="rounded-2xl border border-[#cbdba8] bg-[#e6edb0] p-6 sm:p-7">
            <div className="flex items-center gap-2"><ShieldCheck size={20} /><h2 className="text-lg font-black">Questions about Earn?</h2></div>
            <p className="mt-3 text-sm leading-6 text-[#48543d]">
              For enrollment, attribution, rate, verification or commission questions, contact LaterBox support.
              Include your referral or payout reference when applicable. Never send passwords or bank credentials.
            </p>
            <a href="mailto:support@micorp.pro" className="mt-4 inline-flex items-center gap-2 text-sm font-extrabold underline underline-offset-4">
              support@micorp.pro <ArrowUpRight size={16} />
            </a>
          </section>
        </div>
      </div>
      <footer className="mt-10 flex flex-wrap items-center justify-between gap-3 border-t border-[#e3e7d9] pt-6 text-xs font-medium text-[#798572]">
        <span>LaterBox Earn · MICORP PRO</span>
        <div className="flex gap-5">
          <Link href="/terms" className="hover:text-[#171711]">Terms of Service</Link>
          <Link href="/privacy" className="hover:text-[#171711]">Privacy Policy</Link>
          <Link href="/earn" className="hover:text-[#171711]">Earn dashboard</Link>
        </div>
      </footer>
    </main>
  );
}
