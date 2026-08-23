'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { Cloud, CloudOff, RefreshCw, AlertCircle } from 'lucide-react';

export function CloudSyncIndicator({ compact = false }: { compact?: boolean }) {
  const { syncStatus, syncNow } = useItems();
  const { user, isGuest } = useAuth();

  const getStatusDetails = () => {
    if (isGuest || !user) {
      return {
        icon: <CloudOff className="w-4 h-4 text-zinc-400" />,
        label: 'Local Only (Guest)',
        tooltip: 'Changes saved locally. Sign in to enable cloud sync.',
        color: 'text-zinc-600 bg-zinc-100',
      };
    }

    switch (syncStatus) {
      case 'syncing':
        return {
          icon: <RefreshCw className="w-4 h-4 text-emerald-600 animate-spin" />,
          label: 'Syncing…',
          tooltip: 'Syncing with Supabase cloud…',
          color: 'text-emerald-700 bg-emerald-50',
        };
      case 'error':
        return {
          icon: <AlertCircle className="w-4 h-4 text-amber-600" />,
          label: 'Sync Failed',
          tooltip: 'Could not reach cloud. Click to retry.',
          color: 'text-amber-700 bg-amber-50',
        };
      case 'synced':
      default:
        return {
          icon: <Cloud className="w-4 h-4 text-emerald-600" />,
          label: 'Cloud Synced',
          tooltip: 'All changes saved and synced.',
          color: 'text-emerald-700 bg-emerald-50',
        };
    }
  };

  const status = getStatusDetails();

  if (compact) {
    return (
      <button
        onClick={() => syncNow()}
        title={status.tooltip}
        className="p-2 rounded-xl hover:bg-zinc-100 transition-colors focus:outline-none focus:ring-2 focus:ring-emerald-500"
      >
        {status.icon}
      </button>
    );
  }

  return (
    <button
      onClick={() => syncNow()}
      title={status.tooltip}
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold tracking-tight transition-all duration-200 hover:opacity-85 ${status.color}`}
    >
      {status.icon}
      <span>{status.label}</span>
    </button>
  );
}
