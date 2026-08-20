import { flushQueue, saveCapture } from "../lib/capture";
import { highlightTextInTab } from "../lib/highlight";
import { getPageContext } from "../lib/page";
import { chromiumCapabilities } from "../platform/chromium";

const PAGE_MENU = "save-page";
const LINK_MENU = "save-link";
const SELECTION_MENU = "save-selection";
const NAVIGATION_TIMEOUT_MS = 15_000;

chrome.runtime.onInstalled.addListener(() => {
  void createContextMenus();
  void flushQueue();
});

chrome.runtime.onStartup.addListener(() => {
  void flushQueue();
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  void handleContextMenu(info, tab);
});

chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message?.type !== "save-page") return false;
  void savePageMessage(message, sender).then(sendResponse);
  return true;
});

chrome.runtime.onMessageExternal.addListener((message, _sender, sendResponse) => {
  if (message?.type !== "open-with-highlight") return false;
  void handleOpenWithHighlight(message).then(sendResponse);
  return true;
});

chrome.commands.onCommand.addListener((command) => {
  console.log("[LaterBox command]", command);
  void handleCommand(command);
});

async function handleCommand(command: string): Promise<void> {
  try {
    if (command === "open-sidepanel") {
      await chromiumCapabilities.openSidePanel();
      return;
    }
    if (command !== "save-current-page") return;

    const [tab] = await chrome.tabs.query({ active: true, lastFocusedWindow: true });
    if (tab.id === undefined) return;
    let page = { url: tab.url ?? "", title: tab.title ?? "", selection: "" };
    try {
      page = await getPageContext(tab.id, page);
    } catch (error) {
      console.warn("Could not read active page context", error);
    }
    if (chromiumCapabilities.isRestrictedUrl(page.url)) {
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
  await chrome.action.setBadgeText({ text });
  await chrome.action.setBadgeBackgroundColor({
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

async function handleOpenWithHighlight(message: OpenWithHighlightMessage) {
  const url = typeof message.url === "string" ? message.url : null;
  if (!url || !/^https?:\/\//i.test(url)) return { status: "invalid-url" };
  const fragmentUrl =
    typeof message.fragmentUrl === "string" ? message.fragmentUrl : undefined;
  const selector = parseSelector(message.selector);
  if (!selector) return { status: "invalid-selector" };

  const tab = await chrome.tabs.create({ url });
  const tabId = tab.id;
  if (tabId === undefined) return { status: "error" };

  const loaded = await waitForTabLoad(tabId);
  if (!loaded) {
    await maybeNavigateToFragment(tabId, fragmentUrl);
    return { status: "timeout" };
  }

  const highlighted = await highlightTextInTab(tabId, selector);
  if (!highlighted) {
    await maybeNavigateToFragment(tabId, fragmentUrl);
    return { status: "not-found" };
  }
  return { status: "ok" };
}

function parseSelector(raw: unknown): {
  exact: string;
  prefix: string | null;
  suffix: string | null;
} | null {
  if (typeof raw !== "object" || raw === null) return null;
  const selector = raw as Record<string, unknown>;
  const exact = typeof selector.exact === "string" ? selector.exact.trim() : "";
  if (!exact) return null;
  const prefix =
    typeof selector.prefix === "string" && selector.prefix.trim()
      ? selector.prefix.trim()
      : null;
  const suffix =
    typeof selector.suffix === "string" && selector.suffix.trim()
      ? selector.suffix.trim()
      : null;
  return { exact, prefix, suffix };
}

async function maybeNavigateToFragment(
  tabId: number,
  fragmentUrl?: string,
): Promise<void> {
  if (!fragmentUrl || !/^https?:\/\//i.test(fragmentUrl)) return;
  try {
    await chrome.tabs.update(tabId, { url: fragmentUrl });
  } catch (error) {
    console.warn("Could not fall back to text fragment", error);
  }
}

function waitForTabLoad(tabId: number): Promise<boolean> {
  return new Promise((resolve) => {
    const timer = setTimeout(() => {
      chrome.tabs.onUpdated.removeListener(onUpdated);
      resolve(false);
    }, NAVIGATION_TIMEOUT_MS);
    function onUpdated(id: number, changeInfo: chrome.tabs.TabChangeInfo) {
      if (id !== tabId || changeInfo.status !== "complete") return;
      clearTimeout(timer);
      chrome.tabs.onUpdated.removeListener(onUpdated);
      resolve(true);
    }
    chrome.tabs.onUpdated.addListener(onUpdated);
  });
}

async function createContextMenus(): Promise<void> {
  await chrome.contextMenus.removeAll();
  chrome.contextMenus.create({
    id: PAGE_MENU,
    title: "Save page to LaterBox",
    contexts: ["page"],
  });
  chrome.contextMenus.create({
    id: LINK_MENU,
    title: "Save link to LaterBox",
    contexts: ["link"],
  });
  chrome.contextMenus.create({
    id: SELECTION_MENU,
    title: "Save selection to LaterBox",
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

  await chrome.action.setBadgeText({
    text: result.status === "saved" ? "✓" : result.status === "needsAuth" ? "!" : "…",
  });
  await chrome.action.setBadgeBackgroundColor({
    color: result.status === "saved" ? "#171711" : "#6c6b63",
  });
}
