'use client';

import React from 'react';
import Link from 'next/link';
import { AppShell } from '@/components/layout/AppShell';
import { useAuth } from '@/lib/store/AuthContext';
import { useItems } from '@/lib/store/ItemContext';
import { CloudSyncIndicator } from '@/components/ui/CloudSyncIndicator';
import {
  User,
  LogOut,
  RefreshCw,
  Download,
  Puzzle,
  Shield,
  HardDrive,
  Moon,
  Sun,
  FileSpreadsheet,
} from 'lucide-react';

export default function SettingsPage() {
  const { user, isGuest, signOut } = useAuth();
  const { items, collections, syncNow, syncStatus } = useItems();

  const handleExportData = () => {
    const dataStr = 'data:text/json;charset=utf-8,' + encodeURIComponent(JSON.stringify(items, null, 2));
    const downloadAnchor = document.createElement('a');
    downloadAnchor.setAttribute('href', dataStr);
    downloadAnchor.setAttribute('download', `laterbox-export-${new Date().toISOString().slice(0, 10)}.json`);
    document.body.appendChild(downloadAnchor);
    downloadAnchor.click();
    downloadAnchor.remove();
  };

  return (
    <AppShell>
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8 space-y-8">
        <div>
          <h1 className="text-2xl sm:text-3xl font-black text-zinc-900 dark:text-white tracking-tight">
            Settings
          </h1>
          <p className="text-xs sm:text-sm text-zinc-500 dark:text-zinc-400 font-medium mt-0.5">
            Manage your account, cloud sync preferences, and connected applications
          </p>
        </div>

        {/* Account Section */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 space-y-4">
          <div className="flex items-center gap-3">
            <User className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
            <h2 className="text-base font-extrabold text-zinc-900 dark:text-white">Account</h2>
          </div>

          {user ? (
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2">
              <div>
                <p className="text-sm font-bold text-zinc-900 dark:text-zinc-100">{user.email}</p>
                <p className="text-xs text-zinc-400 font-mono mt-0.5">User ID: {user.id}</p>
              </div>
              <button
                onClick={() => signOut()}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 hover:bg-red-50 dark:hover:bg-red-950/40 text-zinc-700 dark:text-zinc-300 hover:text-red-600 dark:hover:text-red-400 text-xs font-bold transition-colors w-fit"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out</span>
              </button>
            </div>
          ) : (
            <div className="space-y-3 pt-2">
              <p className="text-xs text-zinc-500 dark:text-zinc-400 leading-relaxed">
                You are currently in <strong>Guest Mode</strong>. Items are saved locally in your browser storage.
                Sign in to sync your saves across mobile and desktop.
              </p>
              <Link
                href="/login"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold shadow-sm"
              >
                <span>Sign In or Create Account</span>
              </Link>
            </div>
          )}
        </section>

        {/* Cloud Sync & Storage Diagnostics */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <HardDrive className="w-5 h-5 text-blue-500" />
              <h2 className="text-base font-extrabold text-zinc-900 dark:text-white">Cloud Sync & Storage</h2>
            </div>
            <CloudSyncIndicator />
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 pt-2">
            <div className="p-4 rounded-2xl bg-zinc-50 dark:bg-zinc-950 border border-zinc-200/60 dark:border-zinc-800">
              <p className="text-2xl font-black text-zinc-900 dark:text-white">{items.length}</p>
              <p className="text-xs text-zinc-400 font-medium">Total Items</p>
            </div>
            <div className="p-4 rounded-2xl bg-zinc-50 dark:bg-zinc-950 border border-zinc-200/60 dark:border-zinc-800">
              <p className="text-2xl font-black text-zinc-900 dark:text-white">{collections.length}</p>
              <p className="text-xs text-zinc-400 font-medium">Collections</p>
            </div>
            <div className="p-4 rounded-2xl bg-zinc-50 dark:bg-zinc-950 border border-zinc-200/60 dark:border-zinc-800">
              <p className="text-2xl font-black text-zinc-900 dark:text-white">
                {items.filter((i) => i.note?.content).length}
              </p>
              <p className="text-xs text-zinc-400 font-medium">Notes Saved</p>
            </div>
          </div>

          <div className="pt-2 flex flex-wrap items-center gap-3">
            <button
              onClick={() => syncNow()}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 hover:bg-zinc-200 text-zinc-800 dark:text-zinc-200 text-xs font-bold transition-colors"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Force Sync Now</span>
            </button>

            <button
              onClick={handleExportData}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 hover:bg-zinc-200 text-zinc-800 dark:text-zinc-200 text-xs font-bold transition-colors"
            >
              <FileSpreadsheet className="w-3.5 h-3.5" />
              <span>Export Library (JSON)</span>
            </button>
          </div>
        </section>

        {/* Extensions & Native Apps */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white dark:bg-zinc-900 border border-zinc-200/80 dark:border-zinc-800 space-y-4">
          <div className="flex items-center gap-3">
            <Puzzle className="w-5 h-5 text-amber-500" />
            <h2 className="text-base font-extrabold text-zinc-900 dark:text-white">Connected Applications</h2>
          </div>
          <p className="text-xs sm:text-sm text-zinc-500 dark:text-zinc-400 leading-relaxed">
            Download our native desktop apps for macOS & Windows or install the browser extensions to capture from any tab.
          </p>
          <div className="pt-2">
            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-zinc-100 dark:bg-zinc-800 hover:bg-zinc-200 text-zinc-800 dark:text-zinc-200 text-xs font-bold"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download Center</span>
            </Link>
          </div>
        </section>
      </div>
    </AppShell>
  );
}
