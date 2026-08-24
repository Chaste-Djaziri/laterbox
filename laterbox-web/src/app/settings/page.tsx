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
  Key,
  Lock,
  Trash2,
  Eye,
  EyeOff,
  AlertTriangle,
} from 'lucide-react';

interface VersionInfo {
  app?: string;
  version?: string;
  buildTime?: string;
  timestamp?: number;
}

export default function SettingsPage() {
  const { user, signOut, updatePassword, deleteAccount } = useAuth();
  const { items, collections, syncNow } = useItems();

  const [currentVersion, setCurrentVersion] = useState<VersionInfo | null>(null);
  const [checkingUpdate, setCheckingUpdate] = useState(false);
  const [updateStatus, setUpdateStatus] = useState<'idle' | 'upToDate' | 'updateAvailable' | 'error'>('idle');
  const [latestVersion, setLatestVersion] = useState<VersionInfo | null>(null);
  const [lastChecked, setLastChecked] = useState<Date | null>(null);
  const [isReloading, setIsReloading] = useState(false);

  // Password update state
  const [showPasswordForm, setShowPasswordForm] = useState(false);
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [passwordMsg, setPasswordMsg] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Delete account state
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deleteConfirmText, setDeleteConfirmText] = useState('');
  const [deleteLoading, setDeleteLoading] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);

  const handleUpdatePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setPasswordMsg(null);

    if (newPassword.length < 6) {
      setPasswordMsg({ type: 'error', text: 'Password must be at least 6 characters.' });
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordMsg({ type: 'error', text: 'Passwords do not match.' });
      return;
    }

    setPasswordLoading(true);
    const { error } = await updatePassword(newPassword);
    setPasswordLoading(false);

    if (error) {
      setPasswordMsg({ type: 'error', text: error.message || 'Failed to update password.' });
    } else {
      setPasswordMsg({ type: 'success', text: 'Password updated successfully!' });
      setNewPassword('');
      setConfirmPassword('');
      setTimeout(() => setShowPasswordForm(false), 2000);
    }
  };

  const handleDeleteAccount = async () => {
    if (deleteConfirmText !== 'DELETE') return;
    setDeleteLoading(true);
    setDeleteError(null);

    const { error } = await deleteAccount();
    if (error) {
      setDeleteLoading(false);
      setDeleteError(error.message || 'Failed to delete account.');
    } else {
      setShowDeleteModal(false);
      if (typeof window !== 'undefined') {
        window.location.href = '/login';
      }
    }
  };

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
        <section className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] space-y-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <User className="w-5 h-5 text-[#171711]" />
              <h2 className="text-base font-extrabold text-[#171711]">Account & Security</h2>
            </div>
            {user && (
              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                <CheckCircle2 className="w-3.5 h-3.5" />
                <span>Authenticated</span>
              </span>
            )}
          </div>

          {user ? (
            <div className="space-y-5">
              {/* User Email & Details */}
              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-bold text-[#171711]">{user.email}</p>
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-semibold bg-[#e4e0d5]/60 text-[#6c6b63]" title="Email cannot be changed">
                      <Lock className="w-3 h-3" />
                      <span>Locked</span>
                    </span>
                  </div>
                  <p className="text-xs text-[#9e9b92] font-mono mt-0.5">User ID: {user.id}</p>
                </div>

                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setShowPasswordForm(!showPasswordForm);
                      setPasswordMsg(null);
                    }}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-white border border-[#e4e0d5] hover:border-[#171711] text-[#171711] text-xs font-bold transition-all cursor-pointer shadow-2xs"
                  >
                    <Key className="w-3.5 h-3.5" />
                    <span>{showPasswordForm ? 'Close' : 'Change Password'}</span>
                  </button>
                  <button
                    type="button"
                    onClick={() => signOut()}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#ebe7dc] hover:bg-red-50 text-[#171711] hover:text-red-600 text-xs font-bold transition-colors cursor-pointer"
                  >
                    <LogOut className="w-3.5 h-3.5" />
                    <span>Sign Out</span>
                  </button>
                </div>
              </div>

              {/* Password Update Form */}
              {showPasswordForm && (
                <form
                  onSubmit={handleUpdatePassword}
                  className="p-5 rounded-2xl bg-white border border-[#171711]/20 space-y-4 animate-in fade-in"
                >
                  <div className="flex items-center gap-2">
                    <Key className="w-4 h-4 text-[#171711]" />
                    <h3 className="text-xs font-bold text-[#171711] uppercase tracking-wider">
                      Update Password
                    </h3>
                  </div>

                  {passwordMsg && (
                    <div
                      className={`p-3 rounded-xl text-xs font-semibold flex items-center gap-2 ${
                        passwordMsg.type === 'success'
                          ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                          : 'bg-red-50 text-red-700 border border-red-200'
                      }`}
                    >
                      {passwordMsg.type === 'success' ? (
                        <CheckCircle2 className="w-4 h-4 shrink-0 text-emerald-600" />
                      ) : (
                        <AlertCircle className="w-4 h-4 shrink-0 text-red-600" />
                      )}
                      <span>{passwordMsg.text}</span>
                    </div>
                  )}

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div>
                      <label className="block text-[11px] font-bold text-[#6c6b63] mb-1">
                        New Password
                      </label>
                      <div className="relative">
                        <input
                          type={showPassword ? 'text' : 'password'}
                          value={newPassword}
                          onChange={(e) => setNewPassword(e.target.value)}
                          placeholder="Min. 6 characters"
                          required
                          className="w-full px-3.5 py-2 text-xs bg-[#f7f5ee] border border-[#e4e0d5] rounded-xl text-[#171711] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 pr-9"
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[#9e9b92] hover:text-[#171711]"
                        >
                          {showPassword ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-[11px] font-bold text-[#6c6b63] mb-1">
                        Confirm New Password
                      </label>
                      <input
                        type={showPassword ? 'text' : 'password'}
                        value={confirmPassword}
                        onChange={(e) => setConfirmPassword(e.target.value)}
                        placeholder="Repeat new password"
                        required
                        className="w-full px-3.5 py-2 text-xs bg-[#f7f5ee] border border-[#e4e0d5] rounded-xl text-[#171711] focus:outline-none focus:ring-2 focus:ring-zinc-900/10"
                      />
                    </div>
                  </div>

                  <div className="flex items-center justify-end gap-2 pt-1">
                    <button
                      type="button"
                      onClick={() => setShowPasswordForm(false)}
                      className="px-3.5 py-1.5 text-xs font-semibold text-[#6c6b63] hover:bg-[#ebe7dc]/60 rounded-xl cursor-pointer"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      disabled={passwordLoading || !newPassword}
                      className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-xl bg-[#171711] hover:bg-[#282723] disabled:opacity-50 text-white text-xs font-bold cursor-pointer"
                    >
                      {passwordLoading && <Loader2 className="w-3 h-3 animate-spin" />}
                      <span>Save New Password</span>
                    </button>
                  </div>
                </form>
              )}

              {/* Danger Zone: Delete Account */}
              <div className="pt-2 border-t border-[#e4e0d5]">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-2xl bg-red-50/50 border border-red-100">
                  <div>
                    <h3 className="text-xs font-bold text-red-950 flex items-center gap-1.5">
                      <Trash2 className="w-3.5 h-3.5 text-red-600" />
                      <span>Delete Account &amp; All Data</span>
                    </h3>
                    <p className="text-[11px] text-red-700/80 mt-0.5">
                      Permanently wipe your account, saved links, notes, collections, and cloud records.
                    </p>
                  </div>
                  <button
                    type="button"
                    onClick={() => {
                      setShowDeleteModal(true);
                      setDeleteConfirmText('');
                      setDeleteError(null);
                    }}
                    className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-red-600 hover:bg-red-700 text-white text-xs font-bold transition-colors cursor-pointer shrink-0 shadow-xs"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                    <span>Delete Account</span>
                  </button>
                </div>
              </div>
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

      {/* Delete Account Confirmation Modal */}
      {showDeleteModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-in fade-in">
          <div className="w-full max-w-md bg-[#f7f5ee] rounded-3xl p-6 shadow-2xl border border-red-200 space-y-4">
            <div className="flex items-center gap-3 text-red-600">
              <div className="w-10 h-10 rounded-2xl bg-red-100 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-bold text-[#171711]">Delete Account</h3>
                <p className="text-xs text-red-600 font-semibold">Irreversible destructive action</p>
              </div>
            </div>

            <p className="text-xs text-[#6c6b63] leading-relaxed">
              This will permanently delete your LaterBox account, wipe all your links, notes, collections, attachments, and cloud sync data.
            </p>

            <div className="p-3 rounded-xl bg-red-50 border border-red-100 text-[11px] text-red-800">
              To confirm deletion, type <strong>DELETE</strong> below:
            </div>

            {deleteError && (
              <div className="p-3 rounded-xl bg-red-100 text-red-700 text-xs font-semibold flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{deleteError}</span>
              </div>
            )}

            <input
              type="text"
              value={deleteConfirmText}
              onChange={(e) => setDeleteConfirmText(e.target.value)}
              placeholder="Type DELETE to confirm"
              autoFocus
              className="w-full px-3.5 py-2.5 text-xs bg-white border border-[#e4e0d5] rounded-xl text-[#171711] focus:outline-none focus:ring-2 focus:ring-red-500/20 uppercase font-mono font-bold"
            />

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setShowDeleteModal(false)}
                disabled={deleteLoading}
                className="px-4 py-2 text-xs font-semibold text-[#6c6b63] hover:bg-[#ebe7dc]/60 rounded-xl cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleDeleteAccount}
                disabled={deleteConfirmText !== 'DELETE' || deleteLoading}
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-red-600 hover:bg-red-700 disabled:opacity-50 text-white text-xs font-bold transition-all cursor-pointer shadow-xs"
              >
                {deleteLoading && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                <span>Permanently Delete</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </AppShell>
  );
}
