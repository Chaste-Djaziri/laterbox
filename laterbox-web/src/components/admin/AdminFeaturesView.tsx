// laterbox-web/src/components/admin/AdminFeaturesView.tsx
'use client';

import { SlidersHorizontal } from 'lucide-react';
import { useAdmin, type FeatureKey } from './AdminContext';

const featureInfo: { key: FeatureKey; label: string; description: string }[] = [
  {
    key: 'referrals',
    label: 'Referral Earn',
    description: 'Activate referral enrollment and commission attribution. Automatic payouts remain disabled.',
  },
  {
    key: 'checkout',
    label: 'Subscription checkout',
    description: 'Allow users to initiate new Whop storage-plan purchases.',
  },
  {
    key: 'support',
    label: 'Support submissions',
    description: 'Accept new reports, feedback, and requests from users.',
  },
  {
    key: 'ai',
    label: 'AI services',
    description: 'Allow AI search, organization, and mobile AI proxy requests.',
  },
];

export function AdminFeaturesView() {
  const { operations, busyOperations, updateOperations } = useAdmin();

  if (!operations) return null;

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-[#e1e6d7] bg-white p-6 shadow-sm">
        <div className="flex items-center gap-3 border-b border-[#f0ede5] pb-5">
          <SlidersHorizontal size={22} className="text-[#435b34]" />
          <div>
            <h2 className="text-base font-bold text-[#171711]">Feature availability</h2>
            <p className="text-xs text-[#74806e]">Server-side controls with an immutable audit trail</p>
          </div>
        </div>

        <div className="mt-4 divide-y divide-[#edf0e7]">
          {featureInfo.map(f => {
            const enabled = Boolean(operations.operations.features[f.key]);
            return (
              <div key={f.key} className="flex flex-wrap items-center justify-between gap-5 py-5">
                <div className="max-w-lg">
                  <h3 className="text-sm font-bold text-[#171711]">{f.label}</h3>
                  <p className="mt-1 text-xs leading-5 text-[#788272]">{f.description}</p>
                </div>
                <button
                  type="button"
                  role="switch"
                  aria-checked={enabled}
                  disabled={!operations.isOwner || busyOperations}
                  onClick={() =>
                    void updateOperations(
                      { action: 'feature', feature: f.key, enabled: !enabled },
                      f.key === 'referrals' && !enabled
                        ? 'Enable the live referral program? This may begin new referral attribution. Automatic payouts remain off.'
                        : `Change ${f.label} availability for all users?`
                    )
                  }
                  className={`relative h-8 w-14 shrink-0 rounded-full transition-colors disabled:opacity-50 focus:outline-none focus:ring-2 focus:ring-[#9bad79] ${
                    enabled ? 'bg-[#829f5b]' : 'bg-[#c9d1c1]'
                  }`}
                >
                  <span
                    className={`absolute top-1 h-6 w-6 rounded-full bg-white shadow-md transition-all ${
                      enabled ? 'left-7' : 'left-1'
                    }`}
                  />
                </button>
              </div>
            );
          })}
        </div>

        <p className="mt-5 text-xs text-[#778370] leading-relaxed border-t border-[#f0ede5] pt-4">
          The verified Owner account can enable or pause these services. Turning off a feature does not cancel
          existing subscriptions or alter stored user content.
        </p>
      </section>
    </div>
  );
}
