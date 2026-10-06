import { browser } from '../platform/api';
import { captureFromPage, getPageContext } from './page';
import type { Capture, CaptureResult } from '../types/capture';
// UI contexts never mutate the queue. The worker owns persistence and replay.
export async function saveCapture(capture: Capture): Promise<CaptureResult> {
  try { return await browser.runtime.sendMessage({ type: 'capture', capture }); }
  catch { return { status: 'error', reason: 'server' }; }
}
export async function flushQueue(): Promise<number> {
  try { const result = await browser.runtime.sendMessage({ type: 'flush-captures' }); return result?.count || 0; }
  catch { return 0; }
}
export async function saveSelectionFromTab(tab: chrome.tabs.Tab): Promise<CaptureResult> {
  if (tab.id === undefined) throw new Error('Missing active tab.');
  const page = await getPageContext(tab.id);
  if (!page.selection) throw new Error('No text selected.');
  return saveCapture(captureFromPage(page,'highlight'));
}
