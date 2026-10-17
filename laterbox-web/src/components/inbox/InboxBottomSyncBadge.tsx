'use client';

import React from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { useBilling } from '@/lib/store/BillingContext';
import {
  RefreshCw,
  ArrowDownCircle,
  ArrowUpCircle,
  ArrowUpDown,
  CheckCircle2,
  Cloud,
} from 'lucide-react';

interface InboxBottomSyncBadgeProps {
  isInbox?: boolean;
}

export function InboxBottomSyncBadge({ isInbox = true }: InboxBottomSyncBadgeProps) {
  const {
    syncStatus,
    pullChanges,
    pushChanges,
    pullAndPushChanges,
    syncNow,
    pendingPullCount,
    pendingPushCount,
    isPulling,
    isPushing,
  } = useItems();
  const { user } = useAuth();
  const { isPro } = useBilling();

  if (!isInbox || !user || !isPro) {
    return null;
  }

  const isSyncing = syncStatus === 'syncing' || isPulling || isPushing;
  const hasPull = pendingPullCount > 0;
  const hasPush = pendingPushCount > 0;

  if (isSyncing) {
    return (
      <div className="shrink-0 mt-2 px-3.5 py-2.5 rounded-2xl bg-white border border-[#e4e0d5] shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 text-xs">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
            <RefreshCw className="w-4 h-4 animate-spin" />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-[#171711] truncate">Cloud Sync</span>
              <span className="px-2 py-0.5 rounded-full bg-blue-100 text-blue-700 text-[10px] font-black tracking-wider uppercase">
                Syncing…
              </span>
            </div>
            <p className="text-[11px] text-[#6c6b63] truncate">
              {isPulling
                ? 'Pulling latest changes from cloud…'
                : isPushing
                ? 'Pushing local edits to cloud…'
                : 'Resolving conflicts & syncing…'}
            </p>
          </div>
        </div>
      </div>
    );
  }

  if (hasPull && hasPush) {
    return (
      <div className="shrink-0 mt-2 px-3.5 py-2.5 rounded-2xl bg-purple-50/70 border border-purple-200/80 shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 text-xs">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-8 h-8 rounded-full bg-purple-100 text-purple-700 flex items-center justify-center shrink-0">
            <ArrowUpDown className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-purple-950 truncate">Cloud & Local Updates</span>
              <span className="px-2 py-0.5 rounded-full bg-purple-200/80 text-purple-800 text-[10px] font-black tracking-wider uppercase">
                {pendingPullCount}↓ • {pendingPushCount}↑
              </span>
            </div>
            <p className="text-[11px] text-purple-900/80 truncate">
              Pull remote changes first, then push local edits after conflict resolution
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => pullAndPushChanges()}
          className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl bg-purple-700 hover:bg-purple-800 text-white font-bold text-xs transition-colors cursor-pointer shrink-0 shadow-2xs"
        >
          <ArrowUpDown className="w-3.5 h-3.5" />
          <span>Pull & Push</span>
        </button>
      </div>
    );
  }

  if (hasPull) {
    return (
      <div className="shrink-0 mt-2 px-3.5 py-2.5 rounded-2xl bg-blue-50/70 border border-blue-200/80 shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 text-xs">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-8 h-8 rounded-full bg-blue-100 text-blue-700 flex items-center justify-center shrink-0">
            <ArrowDownCircle className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-blue-950 truncate">Cloud Updates</span>
              <span className="px-2 py-0.5 rounded-full bg-blue-200/80 text-blue-800 text-[10px] font-black tracking-wider uppercase">
                {pendingPullCount} NEW
              </span>
            </div>
            <p className="text-[11px] text-blue-900/80 truncate">
              {pendingPullCount} change{pendingPullCount === 1 ? '' : 's'} available to pull
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => pullChanges()}
          className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white font-bold text-xs transition-colors cursor-pointer shrink-0 shadow-2xs"
        >
          <ArrowDownCircle className="w-3.5 h-3.5" />
          <span>Pull Changes</span>
        </button>
      </div>
    );
  }

  if (hasPush) {
    return (
      <div className="shrink-0 mt-2 px-3.5 py-2.5 rounded-2xl bg-orange-50/70 border border-orange-200/80 shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 text-xs">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-8 h-8 rounded-full bg-orange-100 text-orange-700 flex items-center justify-center shrink-0">
            <ArrowUpCircle className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-orange-950 truncate">Local Edits</span>
              <span className="px-2 py-0.5 rounded-full bg-orange-200/80 text-orange-800 text-[10px] font-black tracking-wider uppercase">
                {pendingPushCount} UNPUSHED
              </span>
            </div>
            <p className="text-[11px] text-orange-900/80 truncate">
              {pendingPushCount} change{pendingPushCount === 1 ? '' : 's'} waiting to push
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => pushChanges()}
          className="inline-flex items-center justify-center gap-1.5 px-4 py-2 rounded-xl bg-orange-600 hover:bg-orange-700 text-white font-bold text-xs transition-colors cursor-pointer shrink-0 shadow-2xs"
        >
          <ArrowUpCircle className="w-3.5 h-3.5" />
          <span>Push Changes</span>
        </button>
      </div>
    );
  }

  // All Synced
  return (
    <div className="shrink-0 mt-2 px-3.5 py-2 rounded-2xl bg-white border border-[#e4e0d5] shadow-2xs flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
      <div className="flex items-center gap-2.5 min-w-0">
        <div className="w-6 h-6 rounded-full bg-[#e6edb0] text-[#171711] flex items-center justify-center shrink-0">
          <Cloud className="w-3.5 h-3.5" />
        </div>
        <div className="flex items-center gap-2 min-w-0">
          <span className="font-bold text-[#171711] truncate">Pro Cloud Sync</span>
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black tracking-wider uppercase">
            <CheckCircle2 className="w-3 h-3 text-[#171711]" />
            <span>Synced</span>
          </span>
          <span className="hidden sm:inline text-[11px] text-[#8e8d87] truncate">
            • All changes backed up to cloud
          </span>
        </div>
      </div>

      <button
        type="button"
        onClick={() => syncNow()}
        className="inline-flex items-center justify-center gap-1.5 px-3 py-1 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] font-bold text-[11px] transition-colors cursor-pointer shrink-0"
      >
        <RefreshCw className="w-3 h-3" />
        <span>Check Updates</span>
      </button>
    </div>
  );
}
