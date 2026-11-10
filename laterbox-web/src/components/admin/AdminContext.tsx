// laterbox-web/src/components/admin/AdminContext.tsx
'use client';

import { createContext, useContext, useCallback, useEffect, useState, type ReactNode } from 'react';
import { getSupabaseClient } from '@/lib/supabase/client';

export type Role = 'member' | 'advocate' | 'support' | 'analyst' | 'admin' | 'owner';

export type UserRow = {
  id: string;
  email: string | null;
  createdAt: string;
  role: Role;
  whopConnected: boolean;
  whopTeamRole: string | null;
  referralCode: string | null;
  affiliateStatus: string | null;
  subscriptions: string[];
};

export type Plan = {
  provider_price_id: string;
  sku_key: string;
  family: string;
  quotaBytes: number;
  trial_days: number;
};

export type AdminDashboardData = {
  role: Role;
  scope: { read: boolean; manage: boolean; roles: boolean };
  users: UserRow[];
  totals: {
    users: number;
    advocates: number;
    activeSubscriptions: number;
    referrals: number;
    pendingCommissionCents: number;
    totalCommissionCents: number;
    totalPaidCents: number;
    payoutCount: number;
    subscriptionsByStatus: Record<string, number>;
  };
  monthly: { month: string; newUsers: number; commissionsCents: number }[];
  plans: Plan[];
  settings: {
    enabled: boolean;
    automatic_payouts: boolean;
    trial_enabled: boolean;
    trial_days: number;
    intro_commission_bps: number;
    ongoing_commission_bps: number;
    hold_days: number;
    minimum_payout_cents: number;
  };
  earnings: {
    commissions: number;
    payouts: number;
    byStatus: Record<string, number>;
  };
  whopRoleAvailable: boolean;
};

export type Mode = 'off' | 'scheduled' | 'active';
export type FeatureKey = 'referrals' | 'checkout' | 'support' | 'ai';

export type Ticket = {
  id: string;
  user_id: string | null;
  email: string;
  category: string;
  subject: string;
  message: string;
  platform: string;
  app_version: string | null;
  status: 'open' | 'in_progress' | 'resolved';
  created_at: string;
};

export type AuditLogItem = {
  id: number;
  action: string;
  target: string | null;
  created_at: string;
};

export type AdminOperationsPayload = {
  operations: {
    features: Record<FeatureKey, boolean>;
    maintenanceMode: Mode;
    maintenanceStartsAt: string | null;
    maintenanceEndsAt: string | null;
    maintenanceMessage: string;
    updatedAt: string | null;
  };
  maintenanceState: string;
  tickets: Ticket[];
  audit: AuditLogItem[];
  isOwner: boolean;
  canManage: boolean;
};

interface AdminContextValue {
  data: AdminDashboardData | null;
  operations: AdminOperationsPayload | null;
  loading: boolean;
  operationsLoading: boolean;
  error: string;
  notice: string;
  signedIn: boolean | null;
  busyUser: string | null;
  busyOperations: boolean;
  refreshDashboard: () => Promise<void>;
  refreshOperations: () => Promise<void>;
  refreshAll: () => Promise<void>;
  changeUserRole: (user: UserRow, action: 'role' | 'affiliate_status', value: string) => Promise<void>;
  deleteUser: (user: UserRow, confirmEmail: string, reason: string) => Promise<void>;
  updateOperations: (payload: Record<string, unknown>, confirmMsg?: string) => Promise<boolean>;
  setNotice: (msg: string) => void;
  setError: (msg: string) => void;
  clearFeedback: () => void;
}

const AdminContext = createContext<AdminContextValue | null>(null);

export function useAdmin() {
  const context = useContext(AdminContext);
  if (!context) {
    throw new Error('useAdmin must be used within an AdminProvider');
  }
  return context;
}

export function AdminProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<AdminDashboardData | null>(null);
  const [operations, setOperations] = useState<AdminOperationsPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [operationsLoading, setOperationsLoading] = useState(true);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');
  const [signedIn, setSignedIn] = useState<boolean | null>(null);
  const [busyUser, setBusyUser] = useState<string | null>(null);
  const [busyOperations, setBusyOperations] = useState(false);

  const getToken = useCallback(async () => {
    const {
      data: { session },
    } = await getSupabaseClient().auth.getSession();
    if (!session?.access_token) {
      throw new Error('Please sign in to the LaterBox Control Center.');
    }
    return session.access_token;
  }, []);

  const refreshDashboard = useCallback(async () => {
    setLoading(true);
    setError('');
    try {
      const token = await getToken();
      setSignedIn(true);
      const res = await fetch('/api/admin/dashboard', {
        headers: { Authorization: `Bearer ${token}` },
        cache: 'no-store',
      });
      const body = (await res.json()) as AdminDashboardData & { error?: string };
      if (!res.ok) {
        throw new Error(body.error || 'Could not load administrative dashboard.');
      }
      setData(body);
    } catch (e) {
      const message = e instanceof Error ? e.message : 'Dashboard unavailable.';
      if (message.toLowerCase().includes('sign in')) {
        setSignedIn(false);
      }
      setError(message);
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [getToken]);

  const refreshOperations = useCallback(async () => {
    setOperationsLoading(true);
    try {
      const token = await getToken();
      const res = await fetch('/api/admin/operations', {
        headers: { Authorization: `Bearer ${token}` },
        cache: 'no-store',
      });
      const body = (await res.json()) as AdminOperationsPayload & { error?: string };
      if (!res.ok) {
        throw new Error(body.error || 'Could not load operations.');
      }
      setOperations(body);
    } catch (e) {
      // Keep dashboard active even if operations fetch fails
      const message = e instanceof Error ? e.message : 'Operations unavailable.';
      if (!data) setError(message);
    } finally {
      setOperationsLoading(false);
    }
  }, [getToken, data]);

  const refreshAll = useCallback(async () => {
    await Promise.all([refreshDashboard(), refreshOperations()]);
  }, [refreshDashboard, refreshOperations]);

  useEffect(() => {
    void refreshAll();
  }, [refreshAll]);

  const changeUserRole = useCallback(
    async (user: UserRow, action: 'role' | 'affiliate_status', value: string) => {
      if (!data?.scope.roles) return;
      const promptText = `Change ${action === 'role' ? 'role' : 'referral status'} for ${
        user.email || user.id
      } to "${value}"? This changes production access.`;
      if (!window.confirm(promptText)) return;

      setBusyUser(user.id);
      setNotice('');
      setError('');
      try {
        const token = await getToken();
        const response = await fetch('/api/admin/dashboard', {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            action,
            userId: user.id,
            [action === 'role' ? 'role' : 'status']: value,
          }),
        });
        const result = (await response.json()) as { error?: string };
        if (!response.ok) throw new Error(result.error || 'Update failed.');
        setNotice('Account updated.');
        await refreshDashboard();
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Update failed.');
      } finally {
        setBusyUser(null);
      }
    },
    [data?.scope.roles, getToken, refreshDashboard]
  );

  const deleteUser = useCallback(
    async (user: UserRow, confirmEmail: string, reason: string) => {
      setBusyUser(user.id);
      setError('');
      setNotice('');
      try {
        const token = await getToken();
        const res = await fetch(`/api/admin/users/${user.id}`, {
          method: 'DELETE',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ confirmEmail, reason }),
        });
        const body = (await res.json()) as { error?: string };
        if (!res.ok) throw new Error(body.error || 'Could not delete account');
        setNotice('Account permanently deleted.');
        await refreshDashboard();
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Delete failed.');
      } finally {
        setBusyUser(null);
      }
    },
    [getToken, refreshDashboard]
  );

  const updateOperations = useCallback(
    async (payload: Record<string, unknown>, confirmMsg?: string): Promise<boolean> => {
      if (!operations?.isOwner) return false;
      if (confirmMsg && !window.confirm(confirmMsg)) return false;

      setBusyOperations(true);
      setError('');
      setNotice('');
      try {
        const token = await getToken();
        const response = await fetch('/api/admin/operations', {
          method: 'PATCH',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        });
        const result = (await response.json()) as { error?: string };
        if (!response.ok) throw new Error(result.error || 'Operation failed.');
        setNotice('Change saved and recorded in the audit log.');
        await refreshOperations();
        return true;
      } catch (e) {
        setError(e instanceof Error ? e.message : 'Operation failed.');
        return false;
      } finally {
        setBusyOperations(false);
      }
    },
    [operations?.isOwner, getToken, refreshOperations]
  );

  const clearFeedback = useCallback(() => {
    setError('');
    setNotice('');
  }, []);

  return (
    <AdminContext.Provider
      value={{
        data,
        operations,
        loading,
        operationsLoading,
        error,
        notice,
        signedIn,
        busyUser,
        busyOperations,
        refreshDashboard,
        refreshOperations,
        refreshAll,
        changeUserRole,
        deleteUser,
        updateOperations,
        setNotice,
        setError,
        clearFeedback,
      }}
    >
      {children}
    </AdminContext.Provider>
  );
}

