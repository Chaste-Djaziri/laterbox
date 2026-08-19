import { connectWithAccessToken, getAccessToken } from "../lib/auth";
import { flushQueue, saveCapture } from "../lib/capture";

const domainElement = document.querySelector<HTMLElement>("#domain")!;
const titleElement = document.querySelector<HTMLElement>("#title")!;
const urlElement = document.querySelector<HTMLElement>("#url")!;
const tokenInput = document.querySelector<HTMLInputElement>("#token")!;
const form = document.querySelector<HTMLFormElement>("#capture-form")!;
const saveButton = document.querySelector<HTMLButtonElement>("#save")!;
const statusElement = document.querySelector<HTMLElement>("#status")!;

let activeTab: chrome.tabs.Tab | undefined;

void initialize();

async function initialize(): Promise<void> {
  activeTab = (await chrome.tabs.query({ active: true, currentWindow: true }))[0];
  const url = activeTab?.url ?? "";
  titleElement.textContent = activeTab?.title || "Current page";
  urlElement.textContent = url;
  domainElement.textContent = domainFor(url);
  tokenInput.value = await getAccessToken();

  const flushed = await flushQueue();
  if (flushed > 0) setStatus(`Synced ${flushed} queued capture${flushed === 1 ? "" : "s"}.`);
}

form.addEventListener("submit", (event) => {
  event.preventDefault();
  void saveCurrentPage();
});

async function saveCurrentPage(): Promise<void> {
  const url = activeTab?.url ?? "";
  if (!/^https?:\/\//i.test(url)) {
    setStatus("This page cannot be captured.", "error");
    return;
  }

  saveButton.disabled = true;
  setStatus("Saving...");
  await connectWithAccessToken(tokenInput.value);

  const result = await saveCapture({
    url,
    title: activeTab?.title,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  });

  if (result.status === "saved") {
    setStatus("Saved to LaterBox.", "success");
    window.setTimeout(() => window.close(), 700);
  } else {
    setStatus("Saved offline. It will sync when connected.");
    saveButton.disabled = false;
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
