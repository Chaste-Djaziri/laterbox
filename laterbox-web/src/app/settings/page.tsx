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
  HardDrive,
  FileSpreadsheet,
} from 'lucide-react';

export default function SettingsPage() {
  const { user, signOut } = useAuth();
  const { items, collections, syncNow } = useItems();

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
      <div className="max-w-4xl mx-auto px-6 sm:px-8 py-7 sm:py-9 space-y-8">
        <div>
          <h1 className="text-3xl font-black text-[#171711] tracking-tight">
            Settings
          </h1>
          <p className="text-sm text-[#6c6b63] font-medium mt-0.5">
            Manage your account, cloud sync preferences, and connected applications
          </p>
        </div>

        {/* Account Section */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] space-y-4">
          <div className="flex items-center gap-3">
            <User className="w-5 h-5 text-[#171711]" />
            <h2 className="text-base font-extrabold text-[#171711]">Account</h2>
          </div>

          {user ? (
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-2">
              <div>
                <p className="text-sm font-bold text-[#171711]">{user.email}</p>
                <p className="text-xs text-[#9e9b92] font-mono mt-0.5">User ID: {user.id}</p>
              </div>
              <button
                onClick={() => signOut()}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#ebe7dc] hover:bg-red-50 text-[#171711] hover:text-red-600 text-xs font-bold transition-colors w-fit cursor-pointer"
              >
                <LogOut className="w-4 h-4" />
                <span>Sign Out</span>
              </button>
            </div>
          ) : (
            <div className="space-y-3 pt-2">
              <p className="text-xs text-[#6c6b63] leading-relaxed">
                You are currently in <strong>Guest Mode</strong>. Items are saved locally in your browser storage.
                Sign in to sync your saves across mobile and desktop.
              </p>
              <Link
                href="/login"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold shadow-xs"
              >
                <span>Sign In or Create Account</span>
              </Link>
            </div>
          )}
        </section>

        {/* Cloud Sync & Storage Diagnostics */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <HardDrive className="w-5 h-5 text-[#171711]" />
              <h2 className="text-base font-extrabold text-[#171711]">Cloud Sync & Storage</h2>
            </div>
            <CloudSyncIndicator />
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 pt-2">
            <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]">
              <p className="text-2xl font-black text-[#171711]">{items.length}</p>
              <p className="text-xs text-[#9e9b92] font-medium">Total Items</p>
            </div>
            <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]">
              <p className="text-2xl font-black text-[#171711]">{collections.length}</p>
              <p className="text-xs text-[#9e9b92] font-medium">Collections</p>
            </div>
            <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]">
              <p className="text-2xl font-black text-[#171711]">
                {items.filter((i) => i.note?.content).length}
              </p>
              <p className="text-xs text-[#9e9b92] font-medium">Notes Saved</p>
            </div>
          </div>

          <div className="pt-2 flex flex-wrap items-center gap-3">
            <button
              onClick={() => syncNow()}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-colors cursor-pointer"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Force Sync Now</span>
            </button>

            <button
              onClick={handleExportData}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-colors cursor-pointer"
            >
              <FileSpreadsheet className="w-3.5 h-3.5" />
              <span>Export Library (JSON)</span>
            </button>
          </div>
        </section>

        {/* Extensions & Native Apps */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] space-y-4">
          <div className="flex items-center gap-3">
            <Puzzle className="w-5 h-5 text-[#171711]" />
            <h2 className="text-base font-extrabold text-[#171711]">Connected Applications</h2>
          </div>
          <p className="text-xs sm:text-sm text-[#6c6b63] leading-relaxed">
            Download our native desktop apps for macOS & Windows or install the browser extensions to capture from any tab.
          </p>
          <div className="pt-2">
            <Link
              href="/download"
              className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold"
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
