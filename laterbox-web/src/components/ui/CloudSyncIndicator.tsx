'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import { Cloud, CloudOff, RefreshCw, AlertCircle } from 'lucide-react';

export function CloudSyncIndicator({ compact = false }: { compact?: boolean }) {
  const { syncStatus, syncNow } = useItems();
  const { user, isGuest } = useAuth();
  const { isPro } = useBilling();

  if (isGuest || !user || !isPro) {
    return null;
  }

  const getStatusDetails = () => {
    switch (syncStatus) {
      case 'syncing':
        return {
          icon: <RefreshCw className="w-3.5 h-3.5 text-[#171711] animate-spin" />,
          label: 'Syncing…',
          tooltip: 'Syncing with Supabase cloud…',
          color: 'bg-[#e6edb0] border border-[#d0db84] text-[#171711]',
        };
      case 'error':
        return {
          icon: <AlertCircle className="w-3.5 h-3.5 text-amber-700" />,
          label: 'Sync Failed',
          tooltip: 'Could not reach cloud. Click to retry.',
          color: 'bg-amber-100 border border-amber-300 text-amber-900',
        };
      case 'synced':
      default:
        return {
          icon: <Cloud className="w-3.5 h-3.5 text-[#171711]" />,
          label: 'Synced',
          tooltip: 'All changes saved and synced with cloud.',
          color: 'bg-[#e6edb0] border border-[#d0db84] text-[#171711]',
        };
    }
  };

  const status = getStatusDetails();

  if (compact) {
    return (
      <button
        onClick={() => isPro ? syncNow() : window.location.assign('/plans')}
        title={status.tooltip}
        className="p-1.5 rounded-lg hover:bg-[#ebe7dc]/70 transition-colors focus:outline-none cursor-pointer"
      >
        {status.icon}
      </button>
    );
  }

  return (
    <button
      onClick={() => isPro ? syncNow() : window.location.assign('/plans')}
      title={status.tooltip}
      className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold tracking-tight transition-all duration-150 hover:opacity-85 cursor-pointer shadow-xs ${status.color}`}
    >
      {status.icon}
      <span>{status.label}</span>
    </button>
  );
}
