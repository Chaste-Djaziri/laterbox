import { browser } from '../platform/api';
import type { Capture, CaptureResult } from '../types/capture';
export const LOCAL_ORIGIN = 'http://localhost:8080';
export async function isLocalMode(): Promise<boolean> {
  const { captureMode, accessToken } = await browser.storage.local.get(['captureMode', 'accessToken']);
  return captureMode === 'local' || (!captureMode && !accessToken && import.meta.env?.VITE_LATERBOX_WEB_URL === LOCAL_ORIGIN);
}
// Only the background worker writes the outbox, serializing saves and acknowledgements.
let tail: Promise<unknown> = Promise.resolve();
export function localOperation<T>(operation: () => Promise<T>): Promise<T> {
  const result = tail.then(operation, operation); tail = result.catch(() => {}); return result;
}
export async function readLocalCaptures(): Promise<Capture[]> {
  const { localCaptures } = await browser.storage.local.get('localCaptures');
  return Array.isArray(localCaptures) ? localCaptures : [];
}
export function saveLocalCapture(capture: Capture): Promise<CaptureResult> {
  return localOperation(async () => {
    const rows = await readLocalCaptures();
    const entry = { ...capture, captureId: capture.captureId || crypto.randomUUID() };
    if (!rows.some(row => row.captureId === entry.captureId)) rows.push(entry);
    await browser.storage.local.set({ localCaptures: rows });
    await browser.action.setBadgeText({ text: '✓' });
    await browser.action.setTitle({ title: 'Saved locally — open localhost:8080 to import' });
    return { status: 'saved', id: entry.captureId, local: true };
  });
}
export function acknowledgeLocalCaptures(ids: string[]): Promise<void> {
  return localOperation(async () => {
    const rows = await readLocalCaptures();
    await browser.storage.local.set({ localCaptures: rows.filter(row => !ids.includes(row.captureId || '')) });
  });
}
