import { browser } from '../platform/api';
import type { Capture, CaptureResult } from '../types/capture';

export const LOCAL_ORIGIN = 'http://localhost:8080';

export const TRUSTED_ORIGINS = new Set([
  'http://localhost:8080',
  'http://localhost:3000',
  'https://app.laterbox.dev',
  'https://laterbox.dev',
  'https://www.laterbox.dev',
  'https://laterbox.micorp.pro',
  'https://app.laterbox.com',
]);

export function isTrustedDashboardOrigin(origin: string): boolean {
  if (!origin) return false;
  if (TRUSTED_ORIGINS.has(origin)) return true;
  const configured = import.meta.env?.VITE_LATERBOX_WEB_URL;
  if (configured) {
    try {
      if (configured === origin || new URL(configured).origin === origin) return true;
    } catch {}
  }
  return false;
}

export async function isLocalMode(): Promise<boolean> {
  const { captureMode, accessToken, hasProPlan } = await browser.storage.local.get(['captureMode', 'accessToken', 'hasProPlan']);
  if (captureMode === 'local') return true;
  if (captureMode === 'account' && hasProPlan === true) return false;
  // Authenticated Free users save locally on device without syncing to cloud
  if (accessToken && hasProPlan !== true) return true;
  return !captureMode && !accessToken && import.meta.env?.VITE_LATERBOX_WEB_URL === LOCAL_ORIGIN;
}

// Only the background worker writes the outbox, serializing saves and acknowledgements.
let tail: Promise<unknown> = Promise.resolve();
export function localOperation<T>(operation: () => Promise<T>): Promise<T> {
  const result = tail.then(operation, operation); tail = result.catch(() => {}); return result;
}

export async function readLocalCaptures(userId?: string): Promise<Capture[]> {
  const { localCaptures } = await browser.storage.local.get('localCaptures');
  const rows = Array.isArray(localCaptures) ? localCaptures : [];
  if (userId) {
    return rows.filter((row: any) => !row.userId || row.userId === userId);
  }
  return rows;
}

export function saveLocalCapture(capture: Capture): Promise<CaptureResult> {
  return localOperation(async () => {
    const rows = await readLocalCaptures();
    const { connectedUserId } = await browser.storage.local.get('connectedUserId');
    const entry = { ...capture, captureId: capture.captureId || crypto.randomUUID(), userId: connectedUserId || undefined };
    if (!rows.some(row => row.captureId === entry.captureId)) rows.push(entry);
    await browser.storage.local.set({ localCaptures: rows });
    await browser.action.setBadgeText({ text: '✓' });
    if (browser.action?.setBadgeBackgroundColor) {
      await browser.action.setBadgeBackgroundColor({ color: '#26734d' });
    }
    await browser.action.setTitle({ title: 'Saved locally on this device (Free plan) — open LaterBox to view' });
    return { status: 'saved', id: entry.captureId, local: true };
  });
}

export function acknowledgeLocalCaptures(ids: string[]): Promise<void> {
  return localOperation(async () => {
    const rows = await readLocalCaptures();
    await browser.storage.local.set({ localCaptures: rows.filter(row => !ids.includes(row.captureId || '')) });
  });
}
