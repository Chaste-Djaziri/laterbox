import { flushQueue, saveCapture } from "../lib/capture";
import type { Capture } from "../types/capture";

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
  const pageUrl = info.pageUrl ?? tab?.url;
  const capture: Capture = {
    source: "browserExtension",
    createdAt: new Date().toISOString(),
    title: tab?.title,
  };

  if (info.menuItemId === LINK_MENU && info.linkUrl) {
    capture.url = info.linkUrl;
  } else if (info.menuItemId === SELECTION_MENU && info.selectionText) {
    capture.text = info.selectionText;
    capture.url = undefined;
  } else if (info.menuItemId === PAGE_MENU && pageUrl) {
    capture.url = pageUrl;
  } else {
    return;
  }

  const result = await saveCapture(capture);
  await chrome.action.setBadgeText({ text: result.status === "saved" ? "✓" : "…" });
  await chrome.action.setBadgeBackgroundColor({
    color: result.status === "saved" ? "#171711" : "#6c6b63",
  });
}
