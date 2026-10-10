import { isLocalMode, LOCAL_ORIGIN } from '../lib/local-library';
import {
  cancelConnectionRequest,
  connectLaterBox,
  disconnectLaterBox,
  getAccessToken,
  getPendingConnection,
  openApprovalTab,
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


  browser.storage.onChanged.addListener((changes, areaName) => {
    if (areaName === "local" && ["accessToken", "connectedUserId", "hasProPlan", "pendingConnection", "captureMode"].some(key => key in changes)) {
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
  if (!browserCapabilities.supportsSidePanel) return;
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
  const connected = await isLocalMode() || (token.startsWith("lb_ext_") && userId.length > 0);
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
    await browser.storage.local.set({ captureMode: "account" });
    await connectLaterBox();
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
  const result = await saveCapture(captureFromPage(pageContext));

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
    setStatus(result.local ? "Saved locally. Open localhost:8080 to import." : "Saved to laterbox.", "success");
    window.setTimeout(() => window.close(), 700);
  } else if (result.status === "proRequired") {
    await updateConnectionState();
    setStatus("Capture access was rejected. Update the capture backend and reconnect.", "error");
    button.disabled = false;
  } else if (result.status === "needsAuth") {
    await updateConnectionState();
    setStatus("Reconnect your LaterBox account. Pending captures stay assigned to their original account.", "error");
    button.disabled = false;
  } else if (result.status === "error") {
    setStatus("Could not save this content. Reload the page and try again.", "error"); button.disabled=false;
  } else {
    setStatus(
      result.reason === "server"
        ? "Capture service unavailable. Pending save will retry automatically."
        : "Offline. Pending save will sync to your account when online.",
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

const injectedToggle = document.querySelector<HTMLInputElement>('#injected-controls')!;
void browser.storage.local.get('injectedControls').then(values=>{ injectedToggle.checked=values.injectedControls!==false; });
injectedToggle.addEventListener('change',()=>{void browser.storage.local.set({injectedControls:injectedToggle.checked});});
void browser.commands.getAll().then(commands=>{
  document.querySelector<HTMLElement>('#shortcuts')!.textContent=commands.filter(command=>command.name==='save-current-page' || command.name==='save-selection').map(command=>`${command.name==='save-selection' ? 'Highlight' : 'Page'}: ${command.shortcut || 'Unassigned — choose a shortcut'}`).join(' · ');
});
document.querySelector('#configure-shortcuts')!.addEventListener('click',()=>{
  const firefox=!!(globalThis as {browser?:unknown}).browser;
  if(browserCapabilities.supportsSidePanel) void browser.tabs.create({url:firefox ? 'about:addons' : 'chrome://extensions/shortcuts'});
  else setStatus('Configure extension keyboard shortcuts in your browser extension settings.');
});
function renderCaptureState(state:{status?:string;pending?:number}) {
  if(state.status==='queued')setStatus(`Offline or service unavailable. ${state.pending || 0} pending saves will sync to your account automatically.`, 'error');
  if(state.status==='needsAuth')setStatus('Reconnect your account to resume pending saves.', 'error');
  if(state.status==='proRequired')setStatus('LaterBox Pro is required to save and sync.', 'error');
}
void browser.storage.local.get(['captureState','connectionError']).then(values=>{if(values.captureState)renderCaptureState(values.captureState);if(values.connectionError)setStatus(values.connectionError,'error');});
browser.storage.onChanged.addListener((changes,area)=>{
  if(area==='local' && changes.captureState?.newValue)renderCaptureState(changes.captureState.newValue);
  if(area==='local' && changes.connectionError?.newValue)setStatus(changes.connectionError.newValue,'error');
});

const modeControls = document.createElement('div');
modeControls.className = 'connection-panel';
const localButton = document.createElement('button');
localButton.textContent = 'Local library';
localButton.addEventListener('click', async () => {
  await browser.storage.local.set({ captureMode: 'local' });
  await cancelConnectionRequestIfPending();
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

async function cancelConnectionRequestIfPending() { if (await getPendingConnection()) await cancelConnectionRequest(); }
