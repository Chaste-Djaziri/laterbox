// laterbox-web/src/components/admin/AdminUsersView.tsx
'use client';

import { useMemo, useState } from 'react';
import { Search, Trash2 } from 'lucide-react';
import { useAdmin, type UserRow } from './AdminContext';

export function AdminUsersView() {
  const { data, busyUser, changeUserRole, deleteUser } = useAdmin();
  const [query, setQuery] = useState('');
  const [deleteTarget, setDeleteTarget] = useState<UserRow | null>(null);
  const [confirmEmail, setConfirmEmail] = useState('');
  const [deleteReason, setDeleteReason] = useState('');
  const [isDeleting, setIsDeleting] = useState(false);

  const visibleUsers = useMemo(
    () =>
      data?.users.filter(u =>
        [u.email ?? '', u.id, u.role, u.referralCode ?? ''].some(x =>
          x.toLowerCase().includes(query.toLowerCase())
        )
      ) ?? [],
    [data, query]
  );

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setIsDeleting(true);
    try {
      await deleteUser(deleteTarget, confirmEmail, deleteReason);
      setDeleteTarget(null);
      setConfirmEmail('');
      setDeleteReason('');
    } finally {
      setIsDeleting(false);
    }
  };

  if (!data) return null;

  return (
    <div className="space-y-6">
      <section className="overflow-hidden rounded-2xl border border-[#e4e5d9] bg-white shadow-sm">
        {/* Table Top Header & Search */}
        <div className="flex flex-wrap items-center justify-between gap-4 border-b border-[#e4e5d9] p-5">
          <div>
            <h2 className="font-bold text-base text-[#171711]">Accounts and permissions</h2>
            <p className="mt-1 text-xs text-[#677362]">
              Whop roles are informational and do not grant admin access.
            </p>
          </div>
          <label className="flex items-center gap-2 rounded-xl border border-[#d9dece] bg-[#f9faf5] px-3.5 py-1.5 focus-within:border-[#9bad79] focus-within:bg-white transition-colors">
            <Search size={16} className="text-[#677362]" />
            <input
              aria-label="Search users"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Search users or IDs…"
              className="w-48 sm:w-64 bg-transparent py-1 text-sm text-[#171711] outline-none placeholder:text-[#90988a]"
            />
          </label>
        </div>

        {/* Users Table */}
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-left text-sm">
            <thead className="bg-[#fafbf6] text-xs font-bold uppercase tracking-wider text-[#677362]">
              <tr>
                {['Account', 'LaterBox role', 'Whop role', 'Subscription', 'Referral', 'Management'].map(x => (
                  <th key={x} className="border-b border-[#e4e5d9] px-5 py-4 font-semibold">
                    {x}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#f2efe6]">
              {visibleUsers.map(u => (
                <tr key={u.id} className="hover:bg-[#fcfdfa] transition-colors">
                  <td className="px-5 py-4">
                    <p className="font-bold text-[#171711]">{u.email ?? 'No email'}</p>
                    <p className="mt-1 font-mono text-[11px] text-[#86907f]">{u.id}</p>
                  </td>
                  <td className="px-5 py-4">
                    <span
                      className={`inline-flex items-center rounded-lg px-2.5 py-1 text-xs font-bold capitalize ${
                        u.role === 'owner'
                          ? 'bg-[#171711] text-[#e6edb0]'
                          : u.role === 'admin'
                          ? 'bg-[#e6edb0] text-[#171711]'
                          : 'bg-[#eff2e5] text-[#55634d]'
                      }`}
                    >
                      {u.role}
                    </span>
                  </td>
                  <td className="px-5 py-4 text-[#677362]">
                    {u.whopConnected ? u.whopTeamRole ?? 'Connected · no team role' : 'Not connected'}
                  </td>
                  <td className="px-5 py-4 text-xs font-medium text-[#171711]">
                    {u.subscriptions.length ? u.subscriptions.join(', ') : 'Free'}
                  </td>
                  <td className="px-5 py-4 font-mono text-xs text-[#677362]">
                    {u.referralCode ?? '—'}
                  </td>
                  <td className="px-5 py-4">
                    <div className="flex flex-col items-start gap-2">
                      {data.scope.roles && u.role !== 'owner' ? (
                        <select
                          aria-label={'Change role for ' + u.email}
                          value={['admin', 'analyst', 'support'].includes(u.role) ? u.role : 'member'}
                          onChange={e => void changeUserRole(u, 'role', e.target.value)}
                          disabled={busyUser === u.id}
                          className="rounded-lg border border-[#d2d9c8] bg-white px-3 py-1.5 text-xs font-medium text-[#171711] shadow-sm outline-none focus:border-[#9bad79]"
                        >
                          <option value="member">Member / Advocate</option>
                          <option value="support">Support</option>
                          <option value="analyst">Analyst</option>
                          <option value="admin">Admin</option>
                        </select>
                      ) : (
                        <span className="text-xs text-[#677362]">
                          {u.role === 'owner' ? 'Protected owner' : 'Read only'}
                        </span>
                      )}

                      {data.scope.roles && u.whopConnected && u.role !== 'owner' && (
                        <button
                          type="button"
                          disabled={busyUser === u.id}
                          onClick={() =>
                            void changeUserRole(
                              u,
                              'affiliate_status',
                              u.affiliateStatus === 'suspended' ? 'active' : 'suspended'
                            )
                          }
                          className="text-xs font-semibold text-[#435b34] underline hover:text-[#28381e]"
                        >
                          {u.affiliateStatus === 'suspended' ? 'Restore referrals' : 'Suspend referrals'}
                        </button>
                      )}

                      {data.scope.roles && u.role !== 'owner' && (
                        <button
                          type="button"
                          disabled={busyUser === u.id}
                          onClick={() => {
                            setDeleteTarget(u);
                            setConfirmEmail('');
                            setDeleteReason('');
                          }}
                          className="inline-flex items-center gap-1.5 text-xs font-semibold text-red-700 hover:text-red-900 hover:underline"
                        >
                          <Trash2 size={13} />
                          <span>Delete account</span>
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
              {visibleUsers.length === 0 && (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-sm text-[#788272]">
                    No accounts match your search filter.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </section>

      {/* Account Deletion Dialog */}
      {deleteTarget && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="delete-account-title"
          className="fixed inset-0 z-[100] flex items-center justify-center bg-[#171711]/50 p-4 backdrop-blur-sm"
        >
          <div className="w-full max-w-md rounded-3xl bg-white p-7 shadow-2xl border border-[#e4e5d9]">
            <h2 id="delete-account-title" className="text-xl font-bold text-[#171711]">
              Permanently delete account?
            </h2>
            <p className="mt-3 text-sm leading-6 text-[#636a60]">
              This deletes the user and their LaterBox data, including attachments, using the existing
              account deletion workflow. This cannot be undone.
            </p>
            <div className="mt-3 rounded-xl bg-[#f7f8f2] p-3 text-sm font-semibold text-[#171711]">
              {deleteTarget.email}
            </div>

            <label className="mt-5 block text-xs font-bold text-[#171711]">
              Type the full account email to confirm
              <input
                value={confirmEmail}
                onChange={e => setConfirmEmail(e.target.value)}
                className="mt-2 w-full rounded-xl border border-[#d6dcc9] px-3.5 py-2.5 text-sm outline-none focus:border-red-500"
                placeholder="Exact account email"
              />
            </label>

            <label className="mt-4 block text-xs font-bold text-[#171711]">
              Reason (minimum 10 characters)
              <textarea
                value={deleteReason}
                onChange={e => setDeleteReason(e.target.value)}
                rows={3}
                className="mt-2 w-full rounded-xl border border-[#d6dcc9] px-3.5 py-2.5 text-sm outline-none focus:border-[#9bad79]"
                placeholder="Document why the account is being deleted"
              />
            </label>

            <div className="mt-6 flex justify-end gap-3">
              <button
                type="button"
                className="rounded-xl border border-[#d6dcc9] px-5 py-2.5 text-sm font-semibold text-[#171711] hover:bg-[#f5f6ee] transition-colors"
                onClick={() => setDeleteTarget(null)}
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={() => void handleDelete()}
                disabled={
                  isDeleting ||
                  confirmEmail.toLowerCase().trim() !== deleteTarget.email?.toLowerCase() ||
                  deleteReason.trim().length < 10
                }
                className="rounded-xl bg-red-700 px-5 py-2.5 text-sm font-bold text-white shadow-sm hover:bg-red-800 transition-colors disabled:opacity-40"
              >
                {isDeleting ? 'Deleting…' : 'Permanently delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
