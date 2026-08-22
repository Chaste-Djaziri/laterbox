import {
  cancelPendingConnection,
  connectLaterBoxViaTab,
  openPendingApprovalTab,
} from "../lib/auth";
import { flushQueue, saveCapture } from "../lib/capture";
import { highlightTextInTab } from "../lib/highlight";
import { getPageContext } from "../lib/page";
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
      await browserCapabilities.openSidePanel();
      return;
    }
    if (command !== "save-current-page") return;

    const [tab] = await browser.tabs.query({ active: true, lastFocusedWindow: true });
    if (tab.id === undefined) return;
    let page = { url: tab.url ?? "", title: tab.title ?? "", selection: "" };
    try {
      page = await getPageContext(tab.id, page);
    } catch (error) {
      console.warn("Could not read active page context", error);
    }
    if (browserCapabilities.isRestrictedUrl(page.url)) {
      await setCommandBadge("!");
      return;
    }
    const result = await saveCapture({
      url: page.url,
      title: page.title,
      source: "browserExtension",
      createdAt: new Date().toISOString(),
    });
    await setCommandBadge(
      result.status === "saved" ? "✓" : result.status === "needsAuth" ? "!" : "…",
    );
  } catch (error) {
    console.error("[LaterBox command] failed", command, error);
  }
}

async function setCommandBadge(text: string): Promise<void> {
  await browser.action.setBadgeText({ text });
  await browser.action.setBadgeBackgroundColor({
    color: text === "✓" ? "#26734d" : text === "!" ? "#a33a32" : "#6c6b63",
  });
}

async function savePageMessage(
  message: { url?: unknown; title?: unknown },
  sender: chrome.runtime.MessageSender,
) {
  const url = typeof message.url === "string" ? message.url : sender.tab?.url;
  if (!url || !/^https?:\/\//i.test(url)) return { status: "needsAuth" };
  return saveCapture({
    url,
    title: typeof message.title === "string" ? message.title : sender.tab?.title,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  });
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

const MAX_URL_LENGTH = 2000;
const MAX_SELECTOR_EXACT = 5000;
const MAX_SELECTOR_CONTEXT = 2000;

const ALLOWED_EXTERNAL_HOSTS = new Set([
  "laterbox.micorp.pro",
  "app.laterbox.com",
  "localhost",
]);

function isTrustedSender(sender: chrome.runtime.MessageSender): boolean {
  const origin = sender.origin;
  if (!origin) return false;
  try {
    const url = new URL(origin);
    if (url.hostname === "laterbox.micorp.pro" || url.hostname === "app.laterbox.com") {
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

  const prefix = typeof parts.prefix === "string" ? parts.prefix.trim() : "";
  const suffix = typeof parts.suffix === "string" ? parts.suffix.trim() : "";
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
    id: PAGE_MENU,
    title: "Save page to laterbox",
    contexts: ["page"],
  });
  browser.contextMenus.create({
    id: LINK_MENU,
    title: "Save link to laterbox",
    contexts: ["link"],
  });
  browser.contextMenus.create({
    id: SELECTION_MENU,
    title: "Save selection to laterbox",
    contexts: ["selection"],
  });
}

async function handleContextMenu(
  info: chrome.contextMenus.OnClickData,
  tab?: chrome.tabs.Tab,
): Promise<void> {
  const result =
    info.menuItemId === LINK_MENU && info.linkUrl
      ? await saveCapture({
          url: info.linkUrl,
          source: "browserExtension",
          createdAt: new Date().toISOString(),
        })
      : info.menuItemId === SELECTION_MENU && info.selectionText?.trim()
        ? await saveCapture({
            text: info.selectionText.trim(),
            url: info.pageUrl ?? tab?.url,
            title: tab?.title,
            source: "browserExtension",
            createdAt: new Date().toISOString(),
          })
        : info.menuItemId === PAGE_MENU && (info.pageUrl ?? tab?.url)
          ? await saveCapture({
              url: info.pageUrl ?? tab?.url,
              title: tab?.title,
              source: "browserExtension",
              createdAt: new Date().toISOString(),
            })
          : null;
  if (!result) return;

  await browser.action.setBadgeText({
    text: result.status === "saved" ? "✓" : result.status === "needsAuth" ? "!" : "…",
  });
  await browser.action.setBadgeBackgroundColor({
    color: result.status === "saved" ? "#171711" : "#6c6b63",
  });
}
