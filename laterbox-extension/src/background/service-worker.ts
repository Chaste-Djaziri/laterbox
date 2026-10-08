import {
  cancelPendingConnection,
  connectLaterBoxViaTab,
  openPendingApprovalTab,
  resumePendingConnection,
  checkProEntitlement,
  getConnectedUserId,
  getAccessToken,
} from "../lib/auth";
import { captureQueue, enrichCapture } from "./capture-service";
import type { Capture, CaptureResult } from "../types/capture";
const flushQueue = () => captureQueue.flush();
async function saveCapture(capture: Capture): Promise<CaptureResult> {
  if (!capture || typeof capture !== "object" || (capture.url && !/^https?:\/\//i.test(capture.url)) || (capture.url?.length || 0) > 8192 || (capture.text?.length || 0) > 10000 || new TextEncoder().encode(capture.markdown || "").length > 204800) return { status: "error", reason: "invalid" };
  return captureQueue.save(await enrichCapture(capture));
}
import { highlightTextInTab } from "../lib/highlight";
import { captureFromPage, getPageContext } from "../lib/page";
import type { PageContext } from "../lib/page";
import { browser } from "../platform/api";
import { browserCapabilities } from "../platform";

const PAGE_MENU = "save-page";
const LINK_MENU = "save-link";
const SELECTION_MENU = "save-selection";
const NAVIGATION_TIMEOUT_MS = 15_000;

browser.runtime.onInstalled.addListener(() => {
  void createContextMenus();
  void flushQueue();
});

browser.runtime.onStartup.addListener(() => {
  void flushQueue();
});

browser.contextMenus.onClicked.addListener((info, tab) => {
  void handleContextMenu(info, tab);
});

browser.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (sender.id !== browser.runtime.id) return false;
  if (message?.type === 'dashboard-status') {
    if (!isTrustedSender(sender) || typeof message.userId !== 'string') return false;
    void Promise.all([getConnectedUserId(), getAccessToken()])
      .then(([userId, token]) => sendResponse({ installed: true, connected: Boolean(token && userId && userId === message.userId) }))
      .catch(() => sendResponse({ installed: true, connected: false }));
    return true;
  }
  if (message?.type === 'capture') {
    void saveCapture(message.capture).then(sendResponse).catch(()=>sendResponse({status:'error',reason:'server'})); return true;
  }
  if (message?.type === 'flush-captures') {
    void flushQueue().then(count=>sendResponse({count})).catch(()=>sendResponse({count:0})); return true;
  }
  if (message?.type === "connect-laterbox") {
    connectLaterBoxViaTab()
      .then((userId) => {
        try {
          sendResponse({ userId });
        } catch {}
      })
      .catch((error: unknown) => {
        try {
          sendResponse({
            error: error instanceof Error ? error.message : "Connection cancelled.",
          });
        } catch {}
      });
    return true;
  }
  if (message?.type === "cancel-connect") {
    cancelPendingConnection()
      .then(() => {
        try {
          sendResponse({ status: "cancelled" });
        } catch {}
      })
      .catch(() => {
        try {
          sendResponse({ status: "error" });
        } catch {}
      });
    return true;
  }
  if (message?.type === "open-approval-tab") {
    openPendingApprovalTab()
      .then(() => {
        try {
          sendResponse({ status: "ok" });
        } catch {}
      })
      .catch(() => {
        try {
          sendResponse({ status: "error" });
        } catch {}
      });
    return true;
  }
  if (message?.type === "save-page") {
    void savePageMessage(message, sender).then(sendResponse);
    return true;
  }
  if (message?.type === "open-with-highlight") {
    void handleOpenWithHighlight(message).then(sendResponse);
    return true;
  }
  return false;
});

browser.runtime.onMessageExternal.addListener((message, sender, sendResponse) => {
  if (!isTrustedSender(sender)) return false;
  if (message?.type !== "open-with-highlight") return false;
  void handleOpenWithHighlight(message).then(sendResponse);
  return true;
});

browser.commands.onCommand.addListener((command) => {
  console.log("[LaterBox command]", command);
  void handleCommand(command);
});

async function handleCommand(command: string): Promise<void> {
  try {
    if (command === "open-sidepanel") {
      if (browserCapabilities.supportsSidePanel) await browserCapabilities.openSidePanel();
      return;
    }
    if (command !== 'save-current-page' && command !== 'save-selection') return;
    const [tab] = await browser.tabs.query({ active: true, lastFocusedWindow: true });
    if (tab?.id === undefined) return;
    const page = await getPageContext(tab.id,{ url:tab.url || '', title:tab.title || '', selection:'' });
    if (browserCapabilities.isRestrictedUrl(page.url)) { await setCommandBadge('!'); return; }
    if (command === 'save-selection' && !page.selection) { await setCommandBadge('!'); return; }
    await saveCapture(captureFromPage(page,command === 'save-selection' ? 'highlight' : 'page'));
  } catch (error) {
    console.error("[LaterBox command] failed", command, error);
  }
}

async function setCommandBadge(text: string): Promise<void> {
  await browser.action.setBadgeText({ text });
  await browser.action.setBadgeBackgroundColor({
    color: text === "✓" ? "#26734d" : text === "PRO" || text === "!" ? "#a33a32" : "#6c6b63",
  });
}

async function savePageMessage(
  message: { url?: unknown; title?: unknown },
  sender: chrome.runtime.MessageSender,
) {
  const url = typeof message.url === "string" ? message.url : sender.tab?.url;
  if (!url || !/^https?:\/\//i.test(url)) return { status: "needsAuth" };
  const [tab] = await browser.tabs.query({ active:true,lastFocusedWindow:true });
  const page = tab?.id !== undefined && tab.url === url ? await getPageContext(tab.id) : { url,title:typeof message.title === 'string' ? message.title : '',selection:'' };
  return saveCapture(captureFromPage(page));
}

type OpenWithHighlightMessage = {
  type: "open-with-highlight";
  url?: unknown;
  fragmentUrl?: unknown;
  selector?: unknown;
};

type ParsedHighlightRequest = {
  url: string;
  fragmentUrl?: string;
  exact: string;
  prefix: string | null;
  suffix: string | null;
};

const MAX_URL_LENGTH = 8192;
const MAX_SELECTOR_EXACT = 10000;
const MAX_SELECTOR_CONTEXT = 2000;

const ALLOWED_EXTERNAL_HOSTS = new Set([
  "laterbox.dev",
  "app.laterbox.dev",
  "www.laterbox.dev",
  "laterbox.micorp.pro",
  "app.laterbox.com",
  "localhost",
]);

function isTrustedSender(sender: chrome.runtime.MessageSender): boolean {
  const origin = sender.origin || sender.url;
  if (!origin) return false;
  try {
    const url = new URL(origin);
    if (
      url.hostname === "app.laterbox.dev" ||
      url.hostname === "laterbox.dev" ||
      url.hostname === "www.laterbox.dev" ||
      url.hostname === "laterbox.micorp.pro" ||
      url.hostname === "app.laterbox.com"
    ) {
      return url.protocol === "https:";
    }
    if (url.hostname === "localhost") {
      return url.protocol === "http:" || url.protocol === "https:";
    }
    return false;
  } catch {
    return false;
  }
}

function parseSafeWebUrl(value: unknown): string | null {
  if (typeof value !== "string" || value.length === 0 || value.length > MAX_URL_LENGTH) {
    return null;
  }
  try {
    const url = new URL(value);
    if (url.protocol !== "http:" && url.protocol !== "https:") return null;
    return url.toString();
  } catch {
    return null;
  }
}

function parseHighlightRequest(raw: unknown): ParsedHighlightRequest | null {
  if (typeof raw !== "object" || raw === null) return null;
  const message = raw as Record<string, unknown>;
  if (message.type !== "open-with-highlight") return null;

  const url = parseSafeWebUrl(message.url);
  if (!url) return null;

  let fragmentUrl: string | undefined;
  if (message.fragmentUrl !== undefined) {
    const parsed = parseSafeWebUrl(message.fragmentUrl);
    if (parsed === null) return null;
    fragmentUrl = parsed;
  }

  const selector = message.selector;
  if (typeof selector !== "object" || selector === null) return null;
  const parts = selector as Record<string, unknown>;

  const exact = typeof parts.exact === "string" ? parts.exact.trim() : "";
  if (!exact || exact.length > MAX_SELECTOR_EXACT) return null;

  const prefix = typeof parts.prefix === "string" ? parts.prefix.trim() : typeof parts.before === "string" ? parts.before.trim() : "";
  const suffix = typeof parts.suffix === "string" ? parts.suffix.trim() : typeof parts.after === "string" ? parts.after.trim() : "";
  if (prefix.length > MAX_SELECTOR_CONTEXT || suffix.length > MAX_SELECTOR_CONTEXT) {
    return null;
  }

  return {
    url,
    fragmentUrl,
    exact,
    prefix: prefix || null,
    suffix: suffix || null,
  };
}

async function handleOpenWithHighlight(raw: unknown): Promise<{ status: string }> {
  const message = parseHighlightRequest(raw);
  if (!message) return { status: "invalid" };

  let tab;
  try {
    tab = await browser.tabs.create({ url: message.url });
  } catch (error) {
    console.warn("Could not open tab", error);
    return { status: "error" };
  }
  const tabId = tab.id;
  if (tabId === undefined) return { status: "error" };

  const loaded = await waitForTabLoad(tabId);
  if (!loaded) {
    await maybeNavigateToFragment(tabId, message.fragmentUrl);
    return { status: "timeout" };
  }

  if (await hasHostAccess(message.url)) {
    const highlighted = await highlightTextInTab(tabId, {
      exact: message.exact,
      prefix: message.prefix,
      suffix: message.suffix,
    });
    if (highlighted) return { status: "ok" };
  }

  await maybeNavigateToFragment(tabId, message.fragmentUrl);
  return { status: "not-found" };
}

async function hasHostAccess(url: string): Promise<boolean> {
  const pattern = `${new URL(url).origin}/*`;
  if (await browser.permissions.contains({ origins: [pattern] })) return true;
  try {
    return await browser.permissions.request({ origins: [pattern] });
  } catch (error) {
    console.warn("Could not request host access for highlighting", error);
    return false;
  }
}

async function maybeNavigateToFragment(
  tabId: number,
  fragmentUrl?: string,
): Promise<void> {
  if (!fragmentUrl) return;
  try {
    await browser.tabs.update(tabId, { url: fragmentUrl });
  } catch (error) {
    console.warn("Could not fall back to text fragment", error);
  }
}

function waitForTabLoad(tabId: number): Promise<boolean> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      browser.tabs.onUpdated.removeListener(onUpdated);
      resolve(false);
    }, NAVIGATION_TIMEOUT_MS);
    function onUpdated(id: number, changeInfo: chrome.tabs.TabChangeInfo) {
      if (id !== tabId || changeInfo.status !== "complete") return;
      clearTimeout(timer);
      browser.tabs.onUpdated.removeListener(onUpdated);
      resolve(true);
    }
    browser.tabs.onUpdated.addListener(onUpdated);
  });
}

async function createContextMenus(): Promise<void> {
  await browser.contextMenus.removeAll();
  browser.contextMenus.create({
    id: SELECTION_MENU,
    title: "Save Highlight to LaterBox",
    contexts: ["selection"],
  });
  browser.contextMenus.create({
    id: LINK_MENU,
    title: "Save Link to LaterBox",
    contexts: ["link"],
  });
  browser.contextMenus.create({
    id: PAGE_MENU,
    title: "Save Page to LaterBox",
    contexts: ["page"],
  });
}

async function handleContextMenu(info: chrome.contextMenus.OnClickData, tab?: chrome.tabs.Tab): Promise<void> {
  try {
    const fallback = { url: info.pageUrl || tab?.url || '', title:tab?.title || '',selection:info.selectionText || '' };
    const page = tab?.id !== undefined ? await getPageContext(tab.id,fallback) : fallback;
    if (info.menuItemId === SELECTION_MENU && info.selectionText) {
      await saveCapture(captureFromPage(page,'highlight',info.selectionText));
    } else if (info.menuItemId === LINK_MENU && info.linkUrl) {
      await saveCapture(captureFromPage({ url:info.linkUrl,title:'',selection:'' },'link'));
    } else if (info.menuItemId === PAGE_MENU && !browserCapabilities.isRestrictedUrl(page.url)) {
      await saveCapture(captureFromPage(page));
    }
  } catch { await setCommandBadge('!'); }
}

// Alarms wake a suspended MV3 worker; page online events provide an immediate retry.
async function recover() {
  await resumePendingConnection();
  await checkProEntitlement();
  await flushQueue();
}
browser.alarms.onAlarm.addListener(alarm=>{ if(alarm.name==='laterbox-recovery')void recover().catch(()=>{}); });
browser.tabs.onUpdated.addListener((_id,change)=>{ if(change.status==='complete')void resumePendingConnection().catch(()=>{}); });
void browser.alarms.create('laterbox-recovery',{periodInMinutes:0.5});
void resumePendingConnection().catch(()=>{});
