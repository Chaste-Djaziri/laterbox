import { flushQueue, saveCapture } from "../lib/capture";
import { getPageContext } from "../lib/page";
import { chromiumCapabilities } from "../platform/chromium";

const PAGE_MENU = "save-page";
const LINK_MENU = "save-link";
const SELECTION_MENU = "save-selection";

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

chrome.commands.onCommand.addListener((command) => {
  void handleCommand(command);
});

async function handleCommand(command: string): Promise<void> {
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
