// laterbox-web/src/components/admin/AdminOperationsView.tsx
'use client';

import { LockKeyhole, ShieldCheck } from 'lucide-react';
import { useAdmin } from './AdminContext';

export function AdminOperationsView() {
  const { data } = useAdmin();

  if (!data) return null;

  return (
    <div className="space-y-6">
      <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
        <div className="flex items-center gap-2.5 border-b border-[#f0ede5] pb-5">
          <LockKeyhole size={20} className="text-[#435b34]" />
          <div>
            <h2 className="font-bold text-base text-[#171711]">Operations and safeguards</h2>
            <p className="text-xs text-[#677362]">Production integrity and security diagnostic status</p>
          </div>
        </div>

        <div className="mt-6 space-y-4 text-sm text-[#5a6654]">
          <div className="flex items-center justify-between rounded-xl bg-[#fafbf7] p-4 border border-[#f0ede5]">
            <span>Effective administrative role</span>
            <strong className="capitalize text-[#171711] font-bold">{data.role}</strong>
          </div>

          <div className="flex items-center justify-between rounded-xl bg-[#fafbf7] p-4 border border-[#f0ede5]">
            <span>Role changes mutation</span>
            <strong className={data.scope.roles ? 'text-[#435b34] font-bold' : 'text-[#677362]'}>
              {data.scope.roles ? 'Owner only — enabled' : 'Read only'}
            </strong>
          </div>

          <div className="flex items-center justify-between rounded-xl bg-[#fafbf7] p-4 border border-[#f0ede5]">
            <span>Whop business role lookup</span>
            <strong
              className={data.whopRoleAvailable ? 'text-[#435b34] font-bold' : 'text-amber-700 font-semibold'}
            >
              {data.whopRoleAvailable ? 'Available' : 'Unavailable or missing Whop permission'}
            </strong>
          </div>

          <div className="flex items-center justify-between rounded-xl bg-[#fafbf7] p-4 border border-[#f0ede5]">
            <span>Financial operations</span>
            <strong className="text-[#171711] font-bold">
              No automatic payout enablement from this dashboard
            </strong>
          </div>

          <div className="rounded-xl border border-[#e4e5d9] bg-[#fbfcf8] p-4 text-xs leading-relaxed text-[#677362] space-y-2">
            <p className="flex items-center gap-2 font-semibold text-[#171711]">
              <ShieldCheck size={16} className="text-[#435b34]" />
              Production Security Rules
            </p>
            <p>
              • For Whop team role visibility, grant <code>company:authorized_user:read</code> and{' '}
              <code>member:email:read</code> to the company API key.
            </p>
            <p>
              • All mutations require server-side role checks, RLS-protected database access, and verified Owner
              authorization.
            </p>
          </div>
        </div>
      </section>
    </div>
  );
}
