import {
  connectLaterBox,
  disconnectLaterBox,
  getAccessToken,
} from "../lib/auth";
import { flushQueue, saveCapture, saveSelectionFromTab } from "../lib/capture";
import { getPageContext, type PageContext } from "../lib/page";
import { getConnectedUserId } from "../lib/storage";
import { browser } from "../platform/api";
import { browserCapabilities } from "../platform";

const domainElement = document.querySelector<HTMLElement>("#domain")!;
const titleElement = document.querySelector<HTMLElement>("#title")!;
const urlElement = document.querySelector<HTMLElement>("#url")!;
const highlightPanel = document.querySelector<HTMLElement>("#highlight")!;
const selectionElement = document.querySelector<HTMLElement>("#selection")!;
const saveSelectionButton = document.querySelector<HTMLButtonElement>("#save-selection")!;
const disconnectedPanel = document.querySelector<HTMLElement>("#disconnected")!;
const connectedPanel = document.querySelector<HTMLElement>("#connected")!;
const connectButton = document.querySelector<HTMLButtonElement>("#connect")!;
const saveButton = document.querySelector<HTMLButtonElement>("#save")!;
const disconnectButton = document.querySelector<HTMLButtonElement>("#disconnect")!;
const openButton = document.querySelector<HTMLButtonElement>("#open-laterbox")!;
const permissionNote = document.querySelector<HTMLElement>("#highlight-permission")!;
const enableHighlightingButton = document.querySelector<HTMLButtonElement>("#enable-highlighting")!;
const statusElement = document.querySelector<HTMLElement>("#status")!;

const SITE_ACCESS_PATTERNS = ["http://*/*", "https://*/*"];

let page: PageContext = { url: "", title: "", selection: "" };
let activeTabId: number | undefined;

void initialize();

async function initialize(): Promise<void> {
  await refreshActivePage();
  await updateConnectionState();
  await refreshHighlightPermission();

  browser.storage.onChanged.addListener((changes, areaName) => {
    if (areaName === "local") {
      void updateConnectionState();
    }
  });
}

async function refreshActivePage(): Promise<void> {
  const [tab] = await browser.tabs.query({ active: true, lastFocusedWindow: true });
  if (tab?.id === undefined) {
    activeTabId = undefined;
    page = { url: "", title: "", selection: "" };
    renderPage();
    return;
  }
  activeTabId = tab.id;
  page = await getPageContext(tab.id, {
    url: tab.url ?? "",
    title: tab.title ?? "",
    selection: "",
  });
  renderPage();
}

function renderPage(): void {
  titleElement.textContent = page.title || "Current page";
  urlElement.textContent = page.url;
  domainElement.textContent = domainFor(page.url);
  if (page.selection) {
    highlightPanel.hidden = false;
    selectionElement.textContent = page.selection;
  } else {
    highlightPanel.hidden = true;
    selectionElement.textContent = "";
  }
}

browser.tabs.onActivated.addListener(() => void refreshActivePage());
browser.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (tabId !== activeTabId) return;
  if (changeInfo.url || changeInfo.title || changeInfo.status === "complete") {
    void refreshActivePage();
  }
});
browser.windows.onFocusChanged.addListener(() => void refreshActivePage());
window.addEventListener("focus", () => void refreshActivePage());
document.addEventListener("visibilitychange", () => {
  if (!document.hidden) void refreshActivePage();
});

connectButton.addEventListener("click", () => void connect());
saveButton.addEventListener("click", () => void savePage());
saveSelectionButton.addEventListener("click", () => void saveSelection());
disconnectButton.addEventListener("click", () => void disconnect());
openButton.addEventListener("click", () => {
  const webUrl = import.meta.env.VITE_LATERBOX_WEB_URL ?? "";
  if (webUrl) void browser.tabs.create({ url: `${webUrl}/inbox` });
});

enableHighlightingButton.addEventListener("click", () => void enableHighlighting());

async function refreshHighlightPermission(): Promise<void> {
  const granted = await browser.permissions.contains({ origins: SITE_ACCESS_PATTERNS });
  permissionNote.hidden = granted;
}

async function enableHighlighting(): Promise<void> {
  enableHighlightingButton.disabled = true;
  try {
    const granted = await browser.permissions.request({ origins: SITE_ACCESS_PATTERNS });
    permissionNote.hidden = granted;
    setStatus(
      granted
        ? "Precise highlighting enabled."
        : "Precise highlighting stays off.",
      granted ? "success" : "error",
    );
  } catch {
    setStatus("Could not enable precise highlighting.", "error");
  } finally {
    enableHighlightingButton.disabled = false;
  }
}

async function updateConnectionState(): Promise<void> {
  const connected = (await getAccessToken()).startsWith("lb_ext_") &&
      (await getConnectedUserId()).length > 0;
  disconnectedPanel.hidden = connected;
  connectedPanel.hidden = !connected;
  if (connected) {
    const flushed = await flushQueue();
    if (flushed > 0) setStatus(`Synced ${flushed} queued capture${flushed === 1 ? "" : "s"}.`);
  }
}

async function connect(): Promise<void> {
  connectButton.disabled = true;
  setStatus("Opening LaterBox...");
  try {
    await connectLaterBox();
    await updateConnectionState();
    setStatus("Connected to LaterBox.", "success");
  } catch (error) {
    setStatus(error instanceof Error ? error.message : "Connection cancelled.", "error");
  } finally {
    connectButton.disabled = false;
  }
}

async function disconnect(): Promise<void> {
  disconnectButton.disabled = true;
  await disconnectLaterBox();
  await updateConnectionState();
  setStatus("Disconnected from LaterBox.");
  disconnectButton.disabled = false;
}

async function savePage(): Promise<void> {
  if (browserCapabilities.isRestrictedUrl(page.url)) {
    setStatus("This page cannot be captured.", "error");
    return;
  }
  saveButton.disabled = true;
  setStatus("Saving...");
  await showResult(await saveCapture({
    url: page.url,
    title: page.title,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  }), saveButton);
}

async function saveSelection(): Promise<void> {
  if (!page.selection || browserCapabilities.isRestrictedUrl(page.url)) return;
  const [tab] = await browser.tabs.query({ active: true, lastFocusedWindow: true });
  if (tab?.id === undefined) return;
  saveSelectionButton.disabled = true;
  setStatus("Saving selection...");
  try {
    await showResult(await saveSelectionFromTab(tab), saveSelectionButton);
  } catch {
    saveSelectionButton.disabled = false;
    setStatus("No text is selected.", "error");
  }
}

async function showResult(
  result: Awaited<ReturnType<typeof saveCapture>>,
  button: HTMLButtonElement,
): Promise<void> {
  if (result.status === "saved") {
    setStatus("Saved to LaterBox.", "success");
  } else if (result.status === "needsAuth") {
    await disconnectLaterBox();
    await updateConnectionState();
    setStatus("Saved on this browser. Connect LaterBox to sync.");
    button.disabled = false;
  } else {
    setStatus(result.reason === "server"
      ? "Capture service unavailable. Saved on this browser."
      : "Saved offline. It will sync when connected.");
    button.disabled = false;
  }
}

function setStatus(message: string, kind?: "success" | "error"): void {
  statusElement.textContent = message;
  statusElement.className = kind ? `status ${kind}` : "status";
}

function domainFor(value: string): string {
  try {
    return new URL(value).hostname.replace(/^www\./, "").toUpperCase();
  } catch {
    return "CURRENT PAGE";
  }
}
