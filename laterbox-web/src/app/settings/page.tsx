'use client';

import React, { useState, useEffect } from 'react';
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
  Layers,
  CheckCircle2,
  AlertCircle,
  Loader2,
  ShieldCheck,
  Scale,
  ExternalLink,
} from 'lucide-react';

interface VersionInfo {
  app?: string;
  version?: string;
  buildTime?: string;
  timestamp?: number;
}

export default function SettingsPage() {
  const { user, signOut } = useAuth();
  const { items, collections, syncNow } = useItems();

  const [currentVersion, setCurrentVersion] = useState<VersionInfo | null>(null);
  const [checkingUpdate, setCheckingUpdate] = useState(false);
  const [updateStatus, setUpdateStatus] = useState<'idle' | 'upToDate' | 'updateAvailable' | 'error'>('idle');
  const [latestVersion, setLatestVersion] = useState<VersionInfo | null>(null);
  const [lastChecked, setLastChecked] = useState<Date | null>(null);
  const [isReloading, setIsReloading] = useState(false);

  useEffect(() => {
    // Fetch initial version info
    fetch(`/api/version?_t=${Date.now()}`, { cache: 'no-store' })
      .then((res) => res.json() as Promise<VersionInfo>)
      .then((data) => {
        setCurrentVersion(data);
      })
      .catch(() => {
        setCurrentVersion({
          app: 'laterbox-web',
          version: '1.0.0',
          buildTime: new Date().toISOString(),
        });
      });
  }, []);

  const handleCheckForUpdates = async () => {
    setCheckingUpdate(true);
    setUpdateStatus('idle');

    try {
      const res = await fetch(`/api/version?_t=${Date.now()}`, {
        cache: 'no-store',
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          Pragma: 'no-cache',
        },
      });

      if (!res.ok) {
        setUpdateStatus('error');
        return;
      }

      const remoteData: VersionInfo = await res.json();
      setLatestVersion(remoteData);
      setLastChecked(new Date());

      // If initial buildTime exists and remote is different
      if (
        currentVersion &&
        remoteData.buildTime &&
        currentVersion.buildTime &&
        remoteData.buildTime !== currentVersion.buildTime
      ) {
        setUpdateStatus('updateAvailable');
      } else {
        setUpdateStatus('upToDate');
      }
    } catch {
      setUpdateStatus('error');
    } finally {
      setCheckingUpdate(false);
    }
  };

  const handleApplyUpdate = async () => {
    setIsReloading(true);
    try {
      if (typeof window !== 'undefined' && 'caches' in window) {
        const cacheKeys = await caches.keys();
        await Promise.all(cacheKeys.map((key) => caches.delete(key)));
      }
      if (typeof navigator !== 'undefined' && 'serviceWorker' in navigator) {
        const registrations = await navigator.serviceWorker.getRegistrations();
        await Promise.all(registrations.map((reg) => reg.unregister()));
      }
    } catch {
      // Proceed with reload
    }
    if (typeof window !== 'undefined') {
      const url = new URL(window.location.href);
      url.searchParams.set('_lb_reload', Date.now().toString());
      window.location.replace(url.toString());
    }
  };

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
            Manage your account, cloud sync preferences, deployment updates, and connected applications
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

        {/* Web App Deployment Version & Updates */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Layers className="w-5 h-5 text-[#171711]" />
              <h2 className="text-base font-extrabold text-[#171711]">Web Deployment & Updates</h2>
            </div>
            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#e6edb0] text-[#171711] border border-[#d0db84]">
              v{currentVersion?.version || '1.0.0'}
            </span>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-1">
            <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] space-y-1">
              <p className="text-xs text-[#9e9b92] font-semibold">Current Version</p>
              <p className="text-sm font-bold text-[#171711]">
                laterbox web v{currentVersion?.version || '1.0.0'}
              </p>
              <p className="text-[11px] text-[#6c6b63] font-mono truncate">
                Build: {currentVersion?.buildTime ? new Date(currentVersion.buildTime).toLocaleString() : 'Production Build'}
              </p>
            </div>

            <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] space-y-1">
              <p className="text-xs text-[#9e9b92] font-semibold">Update Status</p>
              {checkingUpdate ? (
                <div className="flex items-center gap-2 text-xs font-bold text-[#171711] pt-1">
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  <span>Checking server for deployments…</span>
                </div>
              ) : updateStatus === 'updateAvailable' ? (
                <div className="flex items-center gap-1.5 text-xs font-bold text-amber-600 pt-1">
                  <AlertCircle className="w-4 h-4" />
                  <span>New deployment ready!</span>
                </div>
              ) : updateStatus === 'upToDate' ? (
                <div className="flex items-center gap-1.5 text-xs font-bold text-emerald-600 pt-1">
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Latest version installed</span>
                </div>
              ) : updateStatus === 'error' ? (
                <p className="text-xs font-bold text-red-600 pt-1">
                  Unable to check update server
                </p>
              ) : (
                <p className="text-xs text-[#6c6b63] pt-1">
                  {lastChecked ? `Checked ${lastChecked.toLocaleTimeString()}` : 'Ready to check'}
                </p>
              )}
            </div>
          </div>

          {/* Update Action Prompt Banner */}
          {updateStatus === 'updateAvailable' && (
            <div className="p-4 rounded-2xl bg-[#171711] text-white border border-white/10 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 animate-in fade-in">
              <div>
                <p className="text-xs sm:text-sm font-bold text-white">
                  A newer web build is available on the server.
                </p>
                <p className="text-[11px] text-[#c7c6bc]">
                  Reload now to apply the latest features and cache updates immediately.
                </p>
              </div>
              <button
                type="button"
                onClick={handleApplyUpdate}
                disabled={isReloading}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#E7FF57] hover:bg-[#d8f044] text-[#171711] text-xs font-bold transition-all cursor-pointer shrink-0 shadow-xs"
              >
                {isReloading ? (
                  <>
                    <Loader2 className="w-3.5 h-3.5 animate-spin" />
                    <span>Updating…</span>
                  </>
                ) : (
                  <>
                    <RefreshCw className="w-3.5 h-3.5" />
                    <span>Reload & Update</span>
                  </>
                )}
              </button>
            </div>
          )}

          <div className="pt-2 flex flex-wrap items-center gap-3">
            <button
              onClick={handleCheckForUpdates}
              disabled={checkingUpdate}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] disabled:opacity-50 text-white text-xs font-bold transition-all cursor-pointer shadow-xs"
            >
              {checkingUpdate ? (
                <>
                  <Loader2 className="w-3.5 h-3.5 animate-spin" />
                  <span>Checking…</span>
                </>
              ) : (
                <>
                  <RefreshCw className="w-3.5 h-3.5" />
                  <span>Check for Updates</span>
                </>
              )}
            </button>
          </div>
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

        {/* Legal & Policies */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] space-y-4">
          <div className="flex items-center gap-3">
            <Scale className="w-5 h-5 text-[#171711]" />
            <h2 className="text-base font-extrabold text-[#171711]">About & Legal</h2>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
            <Link
              href="/privacy"
              className="flex items-center justify-between p-3.5 rounded-2xl bg-[#f7f5ee] hover:bg-[#ebe7dc] border border-[#e4e0d5] transition-colors"
            >
              <div className="flex items-center gap-2.5">
                <ShieldCheck className="w-4 h-4 text-emerald-600" />
                <span className="text-xs font-bold text-[#171711]">Privacy Policy</span>
              </div>
              <ExternalLink className="w-3.5 h-3.5 text-[#9e9b92]" />
            </Link>

            <Link
              href="/terms"
              className="flex items-center justify-between p-3.5 rounded-2xl bg-[#f7f5ee] hover:bg-[#ebe7dc] border border-[#e4e0d5] transition-colors"
            >
              <div className="flex items-center gap-2.5">
                <Scale className="w-4 h-4 text-[#171711]" />
                <span className="text-xs font-bold text-[#171711]">Terms of Service</span>
              </div>
              <ExternalLink className="w-3.5 h-3.5 text-[#9e9b92]" />
            </Link>
          </div>
        </section>
      </div>
    </AppShell>
  );
}
