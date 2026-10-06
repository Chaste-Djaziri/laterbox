import { browser } from '../platform/api';
import { createAccountQueue } from '../lib/account-queue';
import { getAccessToken, getConnectedUserId, getIsPro, getPendingCaptures, replacePendingCaptures, setIsPro } from '../lib/storage';
import type { Capture, CaptureResult } from '../types/capture';

const captureEndpoint = import.meta.env.VITE_CAPTURE_API_URL || '';
export const captureQueue = createAccountQueue({
  connection: async () => { const values=await browser.storage.local.get(['connectedUserId','accessToken','hasProPlan']);return {userId:values.connectedUserId || '',token:values.accessToken || '',isPro:values.hasProPlan ?? null}; },
  read: getPendingCaptures, write: replacePendingCaptures, send: sendCapture, state: updateCaptureState,
});

async function sendCapture(capture: Capture, token: string): Promise<CaptureResult> {
  try {
    const response = await fetch(captureEndpoint, { method: 'POST', headers: { authorization: `Bearer ${token}`, 'content-type': 'application/json' }, body: JSON.stringify(capture), signal: AbortSignal.timeout(15000) });
    if (response.status === 401) return { status: 'needsAuth' };
    if (response.status === 403) { if (await getAccessToken() === token) await setIsPro(false); return { status: 'proRequired' }; }
    if (response.status === 400 || response.status === 413) return { status: 'error', reason: 'invalid' };
    if (!response.ok) return { status: 'queued', reason: 'server' };
    const body = await response.json();
    if (typeof body.id !== 'string' || !body.id) return { status: 'queued', reason: 'server' };
    return { status: 'saved', id: body.id };
  } catch { return { status: 'queued', reason: 'network' }; }
}

export async function updateCaptureState(result: CaptureResult, pending: number): Promise<void> {
  const status = result.status === 'saved' && pending ? 'queued' : result.status;
  const text = status === 'queued' ? String(pending || '…') : status === 'proRequired' ? 'PRO' : status === 'needsAuth' ? '!' : status === 'error' ? '!' : '✓';
  const color = status === 'saved' ? '#26734d' : status === 'queued' ? '#b7791f' : '#a33a32';
  await browser.action.setBadgeText({ text });
  await browser.action.setBadgeBackgroundColor({ color });
  await browser.action.setTitle({ title: status === 'queued' ? `${pending} pending captures — offline or service unavailable` : status === 'needsAuth' ? 'Reconnect LaterBox to sync pending captures' : status === 'proRequired' ? 'LaterBox Pro required' : status === 'error' ? 'Could not capture this content' : 'Saved to LaterBox' });
  if (status === 'queued' && typeof OffscreenCanvas !== 'undefined') {
    const canvas=new OffscreenCanvas(32,32);const ctx=canvas.getContext('2d');
    if(ctx){ctx.fillStyle='#777';ctx.fillRect(3,3,26,26);ctx.fillStyle='#ddd';ctx.font='bold 22px sans-serif';ctx.fillText('L',9,24);await browser.action.setIcon({imageData:ctx.getImageData(0,0,32,32)});}
  } else { await browser.action.setIcon({path:{16:'icons/icon-16.png',32:'icons/icon-32.png'}}); }
  await browser.storage.local.set({ captureState: { status, pending, reason: result.reason || null } });
}

export async function enrichCapture(capture: Capture): Promise<Capture> {
  // Never send page HTML or session credentials to enrichment; only the explicit public source URL.
  if (!capture.url || capture.kind === 'highlight' || capture.kind === 'social' || (capture.markdown && capture.previewImageUrl && capture.description)) return capture;
  try {
    const origin = import.meta.env.VITE_LATERBOX_WEB_URL || 'https://app.laterbox.dev';
    const response = await fetch(`${origin}/api/enrich`, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({url:capture.url.split("#")[0]}), signal: AbortSignal.timeout(5000) });
    if (!response.ok) return capture;
    const data = await response.json();
    return { ...capture, title: capture.title || data.title, description: capture.description || data.description,
      previewImageUrl: capture.previewImageUrl || data.previewImageUrl || data.preview_image_url,
      faviconUrl: capture.faviconUrl || data.faviconUrl, siteName: capture.siteName || data.siteName,
      author: capture.author || data.author, publishedAt: capture.publishedAt || data.publishedTime,
      truncated: capture.truncated };
  } catch { return capture; }
}
