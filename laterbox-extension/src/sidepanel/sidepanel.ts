import { isLocalMode, LOCAL_ORIGIN } from '../lib/local-library';
import {
  connectLaterBox,
  disconnectLaterBox,
  getAccessToken,
} from "../lib/auth";
import { flushQueue, saveCapture, saveSelectionFromTab } from "../lib/capture";
import { captureFromPage, getPageContext, type PageContext } from "../lib/page";
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
    if (areaName === "local" && ["accessToken", "connectedUserId", "hasProPlan", "pendingConnection", "captureMode"].some(key => key in changes)) {
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
openButton.addEventListener("click", async () => {
  const webUrl = await isLocalMode() ? LOCAL_ORIGIN : import.meta.env.VITE_LATERBOX_WEB_URL ?? "";
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
  const token = await getAccessToken();
  const userId = await getConnectedUserId();
  const connected = await isLocalMode() || (token.startsWith("lb_ext_") && userId.length > 0);

  disconnectedPanel.hidden = connected;
  connectedPanel.hidden = !connected;
  if (connected) {
    const flushed = await flushQueue();
    if (flushed > 0) setStatus(`Synced ${flushed} queued capture${flushed === 1 ? "" : "s"}.`);
  }
}

async function connect(): Promise<void> {
  connectButton.disabled = true;
  setStatus("Opening laterbox...");
  try {
    await browser.storage.local.set({ captureMode: "account" });
    await connectLaterBox();
    await updateConnectionState();
    setStatus("Complete account approval in the opened tab.");
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
  setStatus("Disconnected from laterbox.");
  disconnectButton.disabled = false;
}

async function savePage(): Promise<void> {
  if (browserCapabilities.isRestrictedUrl(page.url)) {
    setStatus("This page cannot be captured.", "error");
    return;
  }
  saveButton.disabled = true;
  setStatus("Saving...");
  await showResult(await saveCapture(captureFromPage(page)), saveButton);
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
    setStatus(result.local ? "Saved locally. Open localhost:8080 to import." : "Saved to laterbox.", "success");
  } else if (result.status === "proRequired") {
    await updateConnectionState();
    setStatus("Get Pro to use this extension.", "error");
    button.disabled = false;
  } else if (result.status === "needsAuth") {
    await updateConnectionState();
    setStatus("Reconnect your LaterBox account. Pending captures stay assigned to their original account.", "error");
    button.disabled = false;
  } else if (result.status === "error") {
    setStatus("Could not save this content. Reload the page and try again.", "error"); button.disabled=false;
  } else {
    setStatus(result.reason === "server"
      ? "Capture service unavailable. Pending save will retry automatically."
      : "Offline. Pending save will sync to your account when online.");
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

const modeControls = document.createElement('div');
modeControls.className = 'connection-panel';
const localButton = document.createElement('button');
localButton.textContent = 'Local library';
localButton.addEventListener('click', async () => {
  await browser.storage.local.set({ captureMode: 'local' });
  await updateConnectionState();
  setStatus('Local library selected. Captures stay on this browser.');
});
const accountButton = document.createElement('button');
accountButton.textContent = 'Connect account';
accountButton.addEventListener('click', () => void connect());
const libraryButton = document.createElement('button');
libraryButton.textContent = 'Open local library';
libraryButton.addEventListener('click', () => void browser.tabs.create({ url: `${LOCAL_ORIGIN}/home` }));
modeControls.append(localButton, accountButton, libraryButton);
document.body.append(modeControls);
