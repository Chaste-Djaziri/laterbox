// laterbox-web/src/components/settings/SettingsContent.tsx
'use client';

import { InboxNotificationSettings } from '@/components/notifications/InboxNotifications';
import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { useAuth } from '@/lib/store/AuthContext';
import { useItems } from '@/lib/store/ItemContext';
import { useBilling } from '@/lib/store/BillingContext';
import { AppleSubscriptionDetails } from '@/components/billing/AppleSubscriptionDetails';
import { ConnectedSignIns } from '@/components/account/ConnectedSignIns';
import { presentEntitlement } from '@/lib/billing/types';
import { CloudSyncIndicator } from '@/components/ui/CloudSyncIndicator';
import { BackupRestorePanel } from '@/components/settings/BackupRestorePanel';
import { SettingsSwitch } from '@/components/settings/SettingsSwitch';
import { getSettingsSection, type SettingsSectionId } from '@/lib/utils/settingsNavigation';
import {
  User,
  LogOut,
  RefreshCw,
  Download,
  Puzzle,
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
  Crown,
  Volume2,
  Database,
  Shield,
  Calendar,
  ArrowDownCircle,
  ArrowUpCircle,
} from 'lucide-react';

interface VersionInfo {
  app?: string;
  version?: string;
  buildTime?: string;
  timestamp?: number;
}

export function SettingsContent({ section }: { section: SettingsSectionId }) {
  const { user, signOut, updatePassword, deleteAccount } = useAuth();
  const {
    items,
    collections,
    syncNow,
    pullChanges,
    pushChanges,
    pullAndPushChanges,
    pendingPullCount,
    pendingPushCount,
    isPulling,
    isPushing,
    syncStatus,
  } = useItems();
  const { entitlement, isPro, loading: billingLoading, manage } = useBilling();
  const [billingMessage, setBillingMessage] = useState<string | null>(null);
  const plan = presentEntitlement(entitlement);

  const [currentVersion, setCurrentVersion] = useState<VersionInfo | null>(null);
  const [checkingUpdate, setCheckingUpdate] = useState(false);
  const [updateStatus, setUpdateStatus] = useState<'idle' | 'upToDate' | 'updateAvailable' | 'error'>('idle');
  const [latestVersion, setLatestVersion] = useState<VersionInfo | null>(null);
  const [lastChecked, setLastChecked] = useState<Date | null>(null);
  const [isReloading, setIsReloading] = useState(false);

  // User Rules & Schedule Preferences
  const [morningTime, setMorningTime] = useState('09:00');
  const [afternoonTime, setAfternoonTime] = useState('14:00');
  const [eveningTime, setEveningTime] = useState('19:00');
  const [weekendDay, setWeekendDay] = useState('Saturday 10:00 AM');
  const [soundEnabled, setSoundEnabled] = useState(true);
  const [defaultSnooze, setDefaultSnooze] = useState('3hours');
  const [rulesSavedMsg, setRulesSavedMsg] = useState(false);

  useEffect(() => {
    try {
      const saved = localStorage.getItem('laterbox_user_rules');
      if (saved) {
        const parsed = JSON.parse(saved);
        if (parsed.morningTime) setMorningTime(parsed.morningTime);
        if (parsed.afternoonTime) setAfternoonTime(parsed.afternoonTime);
        if (parsed.eveningTime) setEveningTime(parsed.eveningTime);
        if (parsed.weekendDay) setWeekendDay(parsed.weekendDay);
        if (typeof parsed.soundEnabled === 'boolean') setSoundEnabled(parsed.soundEnabled);
        if (parsed.defaultSnooze) setDefaultSnooze(parsed.defaultSnooze);
      }
    } catch {
      // ignore
    }
  }, []);

  const handleSaveRules = () => {
    try {
      localStorage.setItem(
        'laterbox_user_rules',
        JSON.stringify({
          morningTime,
          afternoonTime,
          eveningTime,
          weekendDay,
          soundEnabled,
          defaultSnooze,
        })
      );
      setRulesSavedMsg(true);
      setTimeout(() => setRulesSavedMsg(false), 2500);
    } catch {
      // ignore
    }
  };

  const handleResetRules = () => {
    setMorningTime('09:00');
    setAfternoonTime('14:00');
    setEveningTime('19:00');
    setWeekendDay('Saturday 10:00 AM');
    setSoundEnabled(true);
    setDefaultSnooze('3hours');
    try {
      localStorage.removeItem('laterbox_user_rules');
      setRulesSavedMsg(false);
    } catch {
      // Browser storage may be disabled; the form still resets.
    }
  };

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
    if (section !== 'updates') return;
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
  }, [section]);

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
        await Promise.all(registrations.filter((reg) => ![reg.active, reg.waiting, reg.installing].some((worker) => worker?.scriptURL.endsWith('/notifications-sw.js'))).map((reg) => reg.unregister()));
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
    // A readable data snapshot, NOT an attachment backup or a restorable archive.
    const blob = new Blob([JSON.stringify(items, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = `laterbox-item-records-${new Date().toISOString().slice(0, 10)}.json`;
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    window.setTimeout(() => URL.revokeObjectURL(url), 30_000);
  };

  const selectedSection = getSettingsSection(section);


  return (
    <>
      <div className="mx-auto w-full max-w-[1020px] space-y-6 px-4 pb-12 pt-6 sm:px-7 sm:pt-8">
        <header className="space-y-2 border-b border-[#e9e7dc] pb-5">
          <p className="text-[10px] font-black uppercase tracking-[0.16em] text-[#969b8d]">Settings / {selectedSection.label}</p>
          <h1 className="text-2xl font-black tracking-tight text-[#171711] sm:text-[28px]">{selectedSection.title}</h1>
          <p className="max-w-2xl text-[13px] leading-6 text-[#82867c]">{selectedSection.description}</p>
        </header>

        {section === 'notifications' && (
          <>
        <InboxNotificationSettings />
          </>
        )}
        {section === 'billing' && (
          <>
        <section className="rounded-3xl border border-[#e4e0d5] bg-[#171711] p-6 text-white sm:p-7">
          <div className="flex flex-col gap-5 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <div className="flex items-center gap-2">
                <Crown className="size-5 text-[#e6edb0]" />
                <h2 className="font-extrabold">{plan.label}</h2>
              </div>
              <p className="mt-2 max-w-xl text-xs leading-5 text-zinc-300">
                {plan.description}
              </p>
              {plan.progress !== null && <div className="mt-3 h-1.5 max-w-md overflow-hidden rounded-full bg-white/15"><div className={`h-full ${plan.tone === 'warning' ? 'bg-amber-300' : 'bg-[#e6edb0]'}`} style={{ width: `${Math.round(plan.progress * 100)}%` }} /></div>}
              {entitlement.billingWarning && <p className="mt-2 text-xs font-bold text-amber-300">Payment needs attention. Update it in the billing portal to keep your storage plan active.</p>}
              {billingMessage && <p className="mt-2 text-xs font-bold text-red-300">{billingMessage}</p>}
            </div>
            {isPro && (entitlement.provider === 'paddle' || entitlement.provider === 'whop') ? (
              <button
                type="button"
                disabled={billingLoading}
                onClick={() => {
                  setBillingMessage(null);
                  void manage().catch((error) => setBillingMessage(error instanceof Error ? error.message : 'Unable to open billing.'));
                }}
                className="rounded-xl bg-white px-4 py-2.5 text-xs font-black text-[#171711] disabled:opacity-50 cursor-pointer"
              >
                Manage subscription
              </button>
            ) : isPro && entitlement.provider === 'apple' ? (
              <AppleSubscriptionDetails entitlement={entitlement} />
            ) : (
              <Link href="/plans" className="rounded-xl bg-[#e6edb0] hover:bg-[#d8e09e] px-4 py-2.5 text-center text-xs font-black text-[#171711] transition-colors">View storage plans</Link>
            )}
          </div>
        </section>
          </>
        )}

        {section === 'preferences' && (
          <>
        <div className="space-y-5">
          <section className="overflow-hidden rounded-[24px] border border-[#e5e4da] bg-white shadow-[0_3px_20px_rgba(36,42,29,0.035)]">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#edede6] px-5 py-5 sm:px-6">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#33452b]">
                  <Calendar className="h-5 w-5" aria-hidden="true" />
                </span>
                <div>
                  <h2 className="text-sm font-black text-[#242c20]">Return-time presets</h2>
                  <p className="mt-1 text-xs text-[#8c9187]">Customize the times in your saved preferences.</p>
                </div>
              </div>
              {rulesSavedMsg && (
                <span role="status" className="inline-flex items-center gap-1.5 rounded-full bg-[#edf5de] px-3 py-1.5 text-xs font-bold text-[#4c733e]">
                  <CheckCircle2 className="h-3.5 w-3.5" aria-hidden="true" /> Changes saved
                </span>
              )}
            </div>

            <div className="grid grid-cols-1 gap-3 p-5 sm:grid-cols-2 sm:p-6">
              {([
                { id: 'morning', label: 'Morning', help: 'Default reminder time for tomorrow', value: morningTime, change: setMorningTime },
                { id: 'afternoon', label: 'Afternoon', help: 'Later-in-the-day return time', value: afternoonTime, change: setAfternoonTime },
                { id: 'evening', label: 'Evening', help: 'A calmer time for reading and videos', value: eveningTime, change: setEveningTime },
              ] as const).map(preset => (
                <label key={preset.id} className="flex min-h-[106px] flex-col justify-between gap-2 rounded-2xl border border-[#e7e7de] bg-[#fafbf7] p-4">
                  <span>
                    <span className="block text-xs font-black text-[#303a2b]">{preset.label}</span>
                    <span className="mt-1 block text-[11px] leading-5 text-[#92988d]">{preset.help}</span>
                  </span>
                  <input
                    aria-label={`${preset.label} return time`}
                    type="time"
                    value={preset.value}
                    onChange={event => preset.change(event.target.value)}
                    className="min-h-10 w-full rounded-xl border border-[#dfe4d7] bg-white px-3 text-sm font-bold tabular-nums text-[#26311f] outline-none focus:border-[#8da66a] focus:ring-2 focus:ring-[#e6edb0]"
                  />
                </label>
              ))}
              <label className="flex min-h-[106px] flex-col justify-between gap-2 rounded-2xl border border-[#e7e7de] bg-[#fafbf7] p-4">
                <span>
                  <span className="block text-xs font-black text-[#303a2b]">Weekend</span>
                  <span className="mt-1 block text-[11px] leading-5 text-[#92988d]">Your preferred weekend reminder</span>
                </span>
                <select
                  aria-label="Weekend return preset"
                  value={weekendDay}
                  onChange={event => setWeekendDay(event.target.value)}
                  className="min-h-10 w-full rounded-xl border border-[#dfe4d7] bg-white px-3 text-xs font-bold text-[#26311f] outline-none focus:border-[#8da66a] focus:ring-2 focus:ring-[#e6edb0]"
                >
                  <option value="Saturday 10:00 AM">Saturday · 10:00 AM</option>
                  <option value="Sunday 10:00 AM">Sunday · 10:00 AM</option>
                  <option value="Monday 08:30 AM">Monday · 08:30 AM</option>
                </select>
              </label>
            </div>
          </section>

          <section className="overflow-hidden rounded-[24px] border border-[#e5e4da] bg-white shadow-[0_3px_20px_rgba(36,42,29,0.035)]">
            <div className="border-b border-[#edede6] px-5 py-5 sm:px-6">
              <h2 className="text-sm font-black text-[#242c20]">Quick actions</h2>
              <p className="mt-1 text-xs text-[#8c9187]">How LaterBox behaves when you return to saved things.</p>
            </div>
            <SettingsSwitch
              id="settings-sound"
              title="Gentle return sound"
              description="Preference for an acoustic chime when saved items resurface."
              icon={Volume2}
              checked={soundEnabled}
              onCheckedChange={setSoundEnabled}
            />
            <div className="flex flex-wrap items-center justify-between gap-4 border-t border-[#eeeae2] px-5 py-5 sm:px-6">
              <div>
                <label htmlFor="settings-default-snooze" className="text-[13px] font-extrabold text-[#262e21]">Default quick snooze</label>
                <p className="mt-1 max-w-md text-xs leading-5 text-[#858c80]">The default interval used by your one-click snooze preference.</p>
              </div>
              <select
                id="settings-default-snooze"
                value={defaultSnooze}
                onChange={event => setDefaultSnooze(event.target.value)}
                className="min-h-11 min-w-[184px] rounded-xl border border-[#dfe4d7] bg-[#fafbf7] px-3.5 text-xs font-bold text-[#2f392a] outline-none focus:border-[#8da66a] focus:ring-2 focus:ring-[#e6edb0]"
              >
                <option value="3hours">3 hours</option>
                <option value="tomorrow">Tomorrow morning</option>
                <option value="weekend">This weekend</option>
                <option value="someday">Someday</option>
              </select>
            </div>
            <div className="flex flex-wrap items-center justify-between gap-3 border-t border-[#edede6] bg-[#fcfcf9] px-5 py-4 sm:px-6">
              <p className="text-[11px] text-[#899082]">Saved to the preferences of this browser.</p>
              <div className="flex gap-2">
                <button
                  type="button"
                  onClick={handleResetRules}
                  className="min-h-10 rounded-xl border border-[#e2e4da] bg-white px-4 text-xs font-bold text-[#6e7a68] transition-colors hover:bg-[#f2f6e8] focus-visible:outline-2 focus-visible:outline-[#879c60]"
                >Reset defaults</button>
                <button
                  type="button"
                  onClick={handleSaveRules}
                  className="min-h-10 rounded-xl bg-[#20271d] px-5 text-xs font-black text-white transition-colors hover:bg-[#3a4a30] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#879c60]"
                >Save preferences</button>
              </div>
            </div>
          </section>
        </div>
          </>
        )}

        {section === 'account' && (
          <>
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

              <ConnectedSignIns userId={user.id} />

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
          </>
        )}

        {section === 'updates' && (
          <>
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
                className="inline-flex items-center gap-1.5 px-4 py-2 rounded-xl bg-[#e6edb0] hover:bg-[#d8e09e] text-[#171711] text-xs font-bold transition-all cursor-pointer shrink-0 shadow-xs"
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
          </>
        )}

        {section === 'sync' && (
          <>
        {/* Local browser storage, privacy and synchronization */}
        <section className="p-6 sm:p-7 rounded-3xl bg-white border border-[#e4e0d5] space-y-5">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="space-y-1">
              <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[#e6edb0] border border-[#d0db84] text-[10px] font-black text-[#171711] uppercase tracking-wider">
                <Shield className="w-3 h-3 text-[#171711]" />
                <span>Local-first web storage</span>
              </div>
              <h2 className="text-base font-extrabold text-[#171711] flex items-center gap-2">
                <Database className="w-4 h-4 text-[#171711]" />
                <span>Your things stay where they belong.</span>
              </h2>
              <p className="text-xs text-[#6c6b63] leading-relaxed max-w-xl">
                Items and collections are cached in this browser&apos;s local storage; attachment files are stored in IndexedDB. Signed-in users can sync eligible data using cloud services. Clearing site data may erase local-only copies. Use Backup &amp; Restore to save an encrypted copy of available records and file bytes.
              </p>
            </div>
            <CloudSyncIndicator />
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3.5 pt-1">
            <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5]">
              <p className="text-2xl font-black text-[#171711]">{items.length}</p>
              <p className="text-xs text-[#9e9b92] font-semibold">Total Items</p>
            </div>
            <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5]">
              <p className="text-2xl font-black text-[#171711]">{collections.length}</p>
              <p className="text-xs text-[#9e9b92] font-semibold">Collections</p>
            </div>
            <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5]">
              <p className="text-2xl font-black text-[#171711]">
                {items.filter((i) => i.note?.content).length}
              </p>
              <p className="text-xs text-[#9e9b92] font-semibold">Notes Saved</p>
            </div>
            <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5]">
              <p className="text-xs font-extrabold text-[#171711] flex items-center gap-1 mt-1">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                <span>Browser storage</span>
              </p>
              <p className="text-xs text-[#9e9b92] font-semibold mt-1">Cloud sync when enabled</p>
            </div>
          </div>

          {/* Cloud Sync Status & Diagnostics */}
          <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] space-y-3">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
              <div className="flex items-center gap-2">
                <ArrowDownCircle className={`w-4 h-4 ${pendingPullCount > 0 ? 'text-blue-600' : 'text-[#8e8d87]'}`} />
                <span className="font-bold text-[#171711]">Incoming Cloud Updates</span>
              </div>
              <span className={`font-semibold ${pendingPullCount > 0 ? 'text-blue-600' : 'text-[#8e8d87]'}`}>
                {pendingPullCount > 0 ? `${pendingPullCount} available to pull` : 'Up to date'}
              </span>
            </div>

            <div className="h-px bg-[#e4e0d5]/60" />

            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs">
              <div className="flex items-center gap-2">
                <ArrowUpCircle className={`w-4 h-4 ${pendingPushCount > 0 ? 'text-orange-600' : 'text-[#8e8d87]'}`} />
                <span className="font-bold text-[#171711]">Unpushed Local Changes</span>
              </div>
              <span className={`font-semibold ${pendingPushCount > 0 ? 'text-orange-600' : 'text-[#8e8d87]'}`}>
                {pendingPushCount > 0 ? `${pendingPushCount} pending push` : 'All pushed'}
              </span>
            </div>
          </div>

          <div className="pt-2 flex flex-wrap items-center gap-3">
            {/* 1. Separate Pull Changes */}
            <button
              type="button"
              disabled={isPulling || syncStatus === 'syncing'}
              onClick={() => pullChanges()}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-colors cursor-pointer disabled:opacity-50"
            >
              {isPulling ? (
                <RefreshCw className="w-3.5 h-3.5 animate-spin text-blue-600" />
              ) : (
                <ArrowDownCircle className={`w-3.5 h-3.5 ${pendingPullCount > 0 ? 'text-blue-600' : 'text-[#171711]'}`} />
              )}
              <span>{isPulling ? 'Pulling from Cloud…' : (pendingPullCount > 0 ? `Pull Changes (${pendingPullCount} Available)` : 'Pull Changes')}</span>
            </button>

            {/* 2. Separate Push Changes */}
            <button
              type="button"
              disabled={isPushing || syncStatus === 'syncing'}
              onClick={() => pushChanges()}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-colors cursor-pointer disabled:opacity-50"
            >
              {isPushing ? (
                <RefreshCw className="w-3.5 h-3.5 animate-spin text-orange-600" />
              ) : (
                <ArrowUpCircle className={`w-3.5 h-3.5 ${pendingPushCount > 0 ? 'text-orange-600' : 'text-[#171711]'}`} />
              )}
              <span>{isPushing ? 'Pushing to Cloud…' : (pendingPushCount > 0 ? `Push Changes (${pendingPushCount} Unpushed)` : 'Push Changes')}</span>
            </button>

            {/* 3. Full Sync (Pull then Push) */}
            <button
              type="button"
              disabled={syncStatus === 'syncing' || isPulling || isPushing}
              onClick={() => pullAndPushChanges()}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#ebe7dc] hover:bg-[#e0dbc9] text-[#171711] text-xs font-bold transition-colors cursor-pointer disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${syncStatus === 'syncing' ? 'animate-spin' : ''}`} />
              <span>{syncStatus === 'syncing' ? 'Syncing with Cloud…' : 'Full Sync (Pull then Push)'}</span>
            </button>

            <button
              type="button"
              onClick={handleExportData}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-bold transition-colors cursor-pointer shadow-2xs"
            >
              <FileSpreadsheet className="w-3.5 h-3.5" />
              <span>Export item records (JSON)</span>
            </button>
          </div>
          <p className="text-[11px] leading-relaxed text-[#77756d]">
            JSON export is readable but unencrypted and contains item records only. It does not include recoverable file bytes, a complete deleted-items history, or a guided restore.
          </p>
        </section>
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-[20px] border border-[#dfe9ce] bg-[#f5f9ed] px-5 py-4 sm:px-6">
          <div>
            <p className="text-xs font-black text-[#405a32]">Protect your local data</p>
            <p className="mt-1 text-[11px] leading-5 text-[#75836a]">Create a backup before clearing browser storage or changing devices.</p>
          </div>
          <Link href="/settings/backup" className="inline-flex min-h-10 items-center gap-2 rounded-xl bg-[#e6edb0] px-4 text-xs font-bold text-[#344629] hover:bg-[#dae7a0]">
            <ShieldCheck className="h-3.5 w-3.5" aria-hidden="true" /> Backup options
          </Link>
        </div>
          </>
        )}

        {section === 'backup' && (
          <>
        <BackupRestorePanel />
          </>
        )}

        {section === 'apps' && (
          <>
        <div className="space-y-5">
          <section className="overflow-hidden rounded-[24px] border border-[#e5e4da] bg-white shadow-[0_3px_20px_rgba(36,42,29,0.035)]">
            <div className="flex items-center gap-3 border-b border-[#edede6] px-5 py-5 sm:px-6">
              <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#3e5331]">
                <Puzzle className="h-5 w-5" aria-hidden="true" />
              </span>
              <div>
                <h2 className="text-sm font-black text-[#242c20]">LaterBox everywhere</h2>
                <p className="mt-1 text-xs text-[#8c9187]">Keep your captures close with the right platform.</p>
              </div>
            </div>
            <div className="grid gap-3 p-5 sm:grid-cols-2 sm:p-6">
              <div className="flex min-h-[180px] flex-col justify-between rounded-2xl border border-[#e5e8dc] bg-[#fafbf7] p-5">
                <div>
                  <div className="flex items-center gap-2 text-[#4f6b3d]"><Puzzle className="h-4 w-4" aria-hidden="true" /><span className="text-[10px] font-black uppercase tracking-[0.12em]">Browser</span></div>
                  <h3 className="mt-3 text-sm font-black text-[#232d20]">Chrome extension</h3>
                  <p className="mt-1.5 text-xs leading-5 text-[#818b7b]">Capture a page or link in one click while browsing.</p>
                </div>
                <Link
                  href="https://chromewebstore.google.com/detail/laterbox-save-for-later/egiodciikkepjielhbnihmmchkbpeikp"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-4 inline-flex items-center gap-1.5 self-start text-xs font-extrabold text-[#416332] hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#83995c]"
                >View extension <ExternalLink className="h-3.5 w-3.5" aria-hidden="true" /></Link>
              </div>
              <div className="flex min-h-[180px] flex-col justify-between rounded-2xl border border-[#e5e8dc] bg-[#fafbf7] p-5">
                <div>
                  <div className="flex items-center gap-2 text-[#4f6b3d]"><Download className="h-4 w-4" aria-hidden="true" /><span className="text-[10px] font-black uppercase tracking-[0.12em]">Mobile & desktop</span></div>
                  <h3 className="mt-3 text-sm font-black text-[#232d20]">Downloads</h3>
                  <p className="mt-1.5 text-xs leading-5 text-[#818b7b]">Find available LaterBox apps and setup information.</p>
                </div>
                <Link href="/downloads" className="mt-4 inline-flex items-center gap-1.5 self-start text-xs font-extrabold text-[#416332] hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#83995c]">
                  Open Download Center <ExternalLink className="h-3.5 w-3.5" aria-hidden="true" />
                </Link>
              </div>
            </div>
          </section>
          <section className="flex flex-wrap items-center justify-between gap-4 rounded-[20px] border border-[#dfe9ce] bg-[#f5f9ed] px-5 py-5 sm:px-6">
            <div>
              <h3 className="text-sm font-extrabold text-[#384b2e]">New to saving with LaterBox?</h3>
              <p className="mt-1 text-xs leading-5 text-[#73866a]">Read the setup guide for capturing, organizing and returning to saved things.</p>
            </div>
            <Link href="/guide" className="inline-flex min-h-10 items-center rounded-xl bg-[#e6edb0] px-4 text-xs font-bold text-[#36452c] transition-colors hover:bg-[#dae7a0]">
              Read guide
            </Link>
          </section>
        </div>
          </>
        )}

        {section === 'legal' && (
          <>
        <section className="overflow-hidden rounded-[24px] border border-[#e5e4da] bg-white shadow-[0_3px_20px_rgba(36,42,29,0.035)]">
          <div className="flex items-center gap-3 border-b border-[#edede6] px-5 py-5 sm:px-6">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#e6edb0] text-[#3e5331]">
              <ShieldCheck className="h-5 w-5" aria-hidden="true" />
            </span>
            <div>
              <h2 className="text-sm font-black text-[#242c20]">Your privacy and rights</h2>
              <p className="mt-1 text-xs text-[#8c9187]">Policy details, service terms and help.</p>
            </div>
          </div>
          <div className="divide-y divide-[#eeefe6]">
            {([
              { href: '/privacy', title: 'Privacy policy', description: 'How LaterBox handles and protects your data.', icon: ShieldCheck },
              { href: '/terms', title: 'Terms of service', description: 'Conditions for using LaterBox.', icon: Scale },
              { href: '/refund', title: 'Refund policy', description: 'Review subscription and refund information.', icon: ArrowDownCircle },
              { href: '/help', title: 'Help & support', description: 'Find answers and support resources.', icon: AlertCircle },
            ] as const).map(link => {
              const Icon = link.icon;
              return (
                <Link
                  key={link.href}
                  href={link.href}
                  className="group flex min-h-[76px] items-center gap-3 px-5 py-4 transition-colors hover:bg-[#f9fbf5] focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-[#859b5c] sm:px-6"
                >
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-[#e4e9dc] bg-[#f4f7ee] text-[#657b56]">
                    <Icon className="h-[18px] w-[18px]" aria-hidden="true" />
                  </span>
                  <div className="min-w-0 flex-1">
                    <h3 className="text-[13px] font-extrabold text-[#242c20]">{link.title}</h3>
                    <p className="mt-1 text-[11px] leading-5 text-[#898e84]">{link.description}</p>
                  </div>
                  <ExternalLink className="h-4 w-4 shrink-0 text-[#a3afa0] transition-transform group-hover:translate-x-0.5" aria-hidden="true" />
                </Link>
              );
            })}
          </div>
        </section>
          </>
        )}
      </div>

      {/* Delete Account Confirmation Modal */}
      {section === 'account' && showDeleteModal && (
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
    </>
  );
}
