import {
  connectLaterBox,
  disconnectLaterBox,
  getAccessToken,
} from "../lib/auth";
import { flushQueue, formatHighlight, saveCapture } from "../lib/capture";
import { getConnectedUserId } from "../lib/storage";

const domainElement = document.querySelector<HTMLElement>("#domain")!;
const titleElement = document.querySelector<HTMLElement>("#title")!;
const urlElement = document.querySelector<HTMLElement>("#url")!;
const highlightPanel = document.querySelector<HTMLElement>("#highlight")!;
const selectionElement = document.querySelector<HTMLElement>("#selection")!;
const saveHighlightButton = document.querySelector<HTMLButtonElement>("#save-highlight")!;
const disconnectedPanel = document.querySelector<HTMLElement>("#disconnected")!;
const connectedPanel = document.querySelector<HTMLElement>("#connected")!;
const connectButton = document.querySelector<HTMLButtonElement>("#connect")!;
const saveButton = document.querySelector<HTMLButtonElement>("#save")!;
const disconnectButton = document.querySelector<HTMLButtonElement>("#disconnect")!;
const statusElement = document.querySelector<HTMLElement>("#status")!;

let activeTab: chrome.tabs.Tab | undefined;
let highlightText = "";

void initialize();

async function initialize(): Promise<void> {
  activeTab = (await chrome.tabs.query({ active: true, currentWindow: true }))[0];
  const url = activeTab?.url ?? "";
  titleElement.textContent = activeTab?.title || "Current page";
  urlElement.textContent = url;
  domainElement.textContent = domainFor(url);
  highlightText = await getSelection();
  if (highlightText) {
    highlightPanel.hidden = false;
    selectionElement.textContent = highlightText;
  }
  await updateConnectionState();
}

connectButton.addEventListener("click", () => {
  void connect();
});

saveButton.addEventListener("click", () => {
  void saveCurrentPage();
});

saveHighlightButton.addEventListener("click", () => {
  void saveHighlight();
});

disconnectButton.addEventListener("click", () => {
  void disconnect();
});

async function updateConnectionState(): Promise<boolean> {
  const token = await getAccessToken();
  const userId = await getConnectedUserId();
  const connected = token.startsWith("lb_ext_") && userId.length > 0;
  disconnectedPanel.hidden = connected;
  connectedPanel.hidden = !connected;

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
  try {
    await disconnectLaterBox();
    await updateConnectionState();
    setStatus("Disconnected from LaterBox.");
  } finally {
    disconnectButton.disabled = false;
  }
}

async function saveCurrentPage(): Promise<void> {
  const url = activeTab?.url ?? "";
  if (!/^https?:\/\//i.test(url)) {
    setStatus("This page cannot be captured.", "error");
    return;
  }

  saveButton.disabled = true;
  setStatus("Saving...");
  const result = await saveCapture({
    url,
    title: activeTab?.title,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  });

  await showCaptureResult(result, saveButton);
}

async function saveHighlight(): Promise<void> {
  const url = activeTab?.url ?? "";
  if (!highlightText || !/^https?:\/\//i.test(url)) {
    setStatus("No web highlight is available.", "error");
    return;
  }

  saveHighlightButton.disabled = true;
  setStatus("Saving highlight...");
  const result = await saveCapture({
    text: formatHighlight(highlightText, url, activeTab?.title),
    title: activeTab?.title,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  });
  await showCaptureResult(result, saveHighlightButton);
}

async function showCaptureResult(
  result: Awaited<ReturnType<typeof saveCapture>>,
  button: HTMLButtonElement,
): Promise<void> {
  if (result.status === "saved") {
    setStatus("Saved to LaterBox.", "success");
    window.setTimeout(() => window.close(), 700);
  } else if (result.status === "needsAuth") {
    await disconnectLaterBox();
    await updateConnectionState();
    setStatus("Saved on this browser. Connect LaterBox to sync.");
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

async function getSelection(): Promise<string> {
  const tabId = activeTab?.id;
  if (tabId === undefined) return "";
  try {
    const results = await chrome.scripting.executeScript({
      target: { tabId },
      func: () => window.getSelection()?.toString().trim() ?? "",
    });
    return results[0]?.result ?? "";
  } catch {
    return "";
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
