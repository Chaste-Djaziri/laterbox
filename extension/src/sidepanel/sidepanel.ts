import {
  connectLaterBox,
  disconnectLaterBox,
  getAccessToken,
} from "../lib/auth";
import { flushQueue, formatHighlight, saveCapture } from "../lib/capture";
import { getPageContext, type PageContext } from "../lib/page";
import { getConnectedUserId } from "../lib/storage";

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
const statusElement = document.querySelector<HTMLElement>("#status")!;

let page: PageContext = { url: "", title: "", selection: "" };

void initialize();

async function initialize(): Promise<void> {
  const requestedTabId = Number(new URLSearchParams(location.search).get("tabId"));
  const tab = Number.isInteger(requestedTabId) && requestedTabId > 0
      ? await chrome.tabs.get(requestedTabId)
      : (await chrome.tabs.query({ active: true, currentWindow: true }))[0];
  if (tab.id !== undefined) {
    try {
      page = await getPageContext(tab.id, {
        url: tab.url ?? "",
        title: tab.title ?? "",
        selection: "",
      });
    } catch {
      page = { url: tab.url ?? "", title: tab.title ?? "", selection: "" };
    }
  }
  titleElement.textContent = page.title || "Current page";
  urlElement.textContent = page.url;
  domainElement.textContent = domainFor(page.url);
  if (page.selection) {
    highlightPanel.hidden = false;
    selectionElement.textContent = page.selection;
  }
  await updateConnectionState();
}

connectButton.addEventListener("click", () => void connect());
saveButton.addEventListener("click", () => void savePage());
saveSelectionButton.addEventListener("click", () => void saveSelection());
disconnectButton.addEventListener("click", () => void disconnect());
openButton.addEventListener("click", () => {
  const webUrl = import.meta.env.VITE_LATERBOX_WEB_URL ?? "";
  if (webUrl) void chrome.tabs.create({ url: `${webUrl}/inbox` });
});

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
  if (!/^https?:\/\//i.test(page.url)) {
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
  if (!page.selection || !/^https?:\/\//i.test(page.url)) return;
  saveSelectionButton.disabled = true;
  setStatus("Saving selection...");
  await showResult(await saveCapture({
    text: formatHighlight(page.selection, page.url, page.title),
    title: page.title,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  }), saveSelectionButton);
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
