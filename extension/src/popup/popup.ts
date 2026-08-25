import {
  cancelConnectionRequest,
  connectLaterBox,
  disconnectLaterBox,
  getAccessToken,
  getPendingConnection,
  openApprovalTab,
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
const saveHighlightButton = document.querySelector<HTMLButtonElement>("#save-highlight")!;
const disconnectedPanel = document.querySelector<HTMLElement>("#disconnected")!;
const pendingPanel = document.querySelector<HTMLElement>("#pending")!;
const connectedPanel = document.querySelector<HTMLElement>("#connected")!;
const connectButton = document.querySelector<HTMLButtonElement>("#connect")!;
const openApprovalButton = document.querySelector<HTMLButtonElement>("#open-approval")!;
const cancelConnectButton = document.querySelector<HTMLButtonElement>("#cancel-connect")!;
const saveButton = document.querySelector<HTMLButtonElement>("#save")!;
const openPanelButton = document.querySelector<HTMLButtonElement>("#open-panel")!;
const disconnectButton = document.querySelector<HTMLButtonElement>("#disconnect")!;
const statusElement = document.querySelector<HTMLElement>("#status")!;

let activeTab: chrome.tabs.Tab | undefined;
let pageContext: PageContext = { url: "", title: "", selection: "" };
let highlightText = "";

void initialize();

async function initialize(): Promise<void> {
  activeTab = (await browser.tabs.query({ active: true, currentWindow: true }))[0];
  if (activeTab?.id !== undefined) {
    try {
      pageContext = await getPageContext(activeTab.id, {
        url: activeTab.url ?? "",
        title: activeTab.title ?? "",
        selection: "",
      });
    } catch {
      pageContext = {
        url: activeTab.url ?? "",
        title: activeTab.title ?? "",
        selection: "",
      };
    }
  }
  titleElement.textContent = pageContext.title || "Current page";
  urlElement.textContent = pageContext.url;
  domainElement.textContent = domainFor(pageContext.url);
  highlightText = pageContext.selection;
  if (highlightText) {
    highlightPanel.hidden = false;
    selectionElement.textContent = highlightText;
  }
  await updateConnectionState();
  openPanelButton.hidden = !browserCapabilities.supportsSidePanel;

  browser.storage.onChanged.addListener((changes, areaName) => {
    if (areaName === "local") {
      void updateConnectionState();
    }
  });
}

connectButton.addEventListener("click", () => {
  void connect();
});

openApprovalButton.addEventListener("click", () => {
  void openApprovalTab();
});

cancelConnectButton.addEventListener("click", () => {
  void cancelConnect();
});

saveButton.addEventListener("click", () => {
  void saveCurrentPage();
});

saveHighlightButton.addEventListener("click", () => {
  void saveHighlight();
});

openPanelButton.addEventListener("click", () => {
  void openSidePanel();
});

async function openSidePanel(): Promise<void> {
  try {
    await browserCapabilities.openSidePanel();
  } catch (error) {
    setStatus(error instanceof Error ? error.message : "Could not open side panel.", "error");
  }
}

disconnectButton.addEventListener("click", () => {
  void disconnect();
});

async function updateConnectionState(): Promise<boolean> {
  const token = await getAccessToken();
  const userId = await getConnectedUserId();
  const connected = token.startsWith("lb_ext_") && userId.length > 0;
  const pending = !connected && (await getPendingConnection()) !== null;

  disconnectedPanel.hidden = connected || pending;
  pendingPanel.hidden = connected || !pending;
  connectedPanel.hidden = !connected;
  connectButton.hidden = connected || pending;
  disconnectButton.hidden = !connected;
  openPanelButton.hidden = !browserCapabilities.supportsSidePanel;

  if (connected) {
    const flushed = await flushQueue();
    if (flushed > 0) {
      setStatus(`Synced ${flushed} queued capture${flushed === 1 ? "" : "s"}.`);
    }
  }
  return connected;
}

async function connect(): Promise<void> {
  connectButton.disabled = true;
  setStatus("Opening laterbox in browser...");
  try {
    void connectLaterBox();
    await updateConnectionState();
  } catch (error) {
    setStatus(error instanceof Error ? error.message : "Connection cancelled.", "error");
  } finally {
    connectButton.disabled = false;
  }
}

async function cancelConnect(): Promise<void> {
  cancelConnectButton.disabled = true;
  try {
    await cancelConnectionRequest();
    await updateConnectionState();
    setStatus("Connection request cancelled.");
  } finally {
    cancelConnectButton.disabled = false;
  }
}

async function disconnect(): Promise<void> {
  disconnectButton.disabled = true;
  try {
    await disconnectLaterBox();
    await updateConnectionState();
    setStatus("Disconnected from laterbox.");
  } finally {
    disconnectButton.disabled = false;
  }
}

async function saveCurrentPage(): Promise<void> {
  const url = pageContext.url;
  if (browserCapabilities.isRestrictedUrl(url)) {
    setStatus("This page cannot be captured.", "error");
    return;
  }

  saveButton.disabled = true;
  setStatus("Saving...");
  const result = await saveCapture({
    url,
    title: pageContext.title,
    description: pageContext.description,
    previewImageUrl: pageContext.previewImageUrl,
    faviconUrl: pageContext.faviconUrl,
    siteName: pageContext.siteName,
    os: pageContext.os,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  });

  await showCaptureResult(result, saveButton);
}

async function saveHighlight(): Promise<void> {
  if (!highlightText || browserCapabilities.isRestrictedUrl(pageContext.url)) {
    setStatus("No web highlight is available.", "error");
    return;
  }
  if (activeTab === undefined) {
    setStatus("No active tab is available.", "error");
    return;
  }

  saveHighlightButton.disabled = true;
  setStatus("Saving highlight...");
  try {
    const result = await saveSelectionFromTab(activeTab);
    await showCaptureResult(result, saveHighlightButton);
  } catch {
    saveHighlightButton.disabled = false;
    setStatus("No text is selected.", "error");
  }
}

async function showCaptureResult(
  result: Awaited<ReturnType<typeof saveCapture>>,
  button: HTMLButtonElement,
): Promise<void> {
  if (result.status === "saved") {
    setStatus("Saved to laterbox.", "success");
    window.setTimeout(() => window.close(), 700);
  } else if (result.status === "needsAuth") {
    await disconnectLaterBox();
    await updateConnectionState();
    setStatus("Saved on this browser. Connect laterbox to sync.");
    button.disabled = false;
  } else {
    setStatus(
      result.reason === "server"
        ? "Capture service unavailable. Saved on this browser."
        : "Saved offline. It will sync when connected.",
    );
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
