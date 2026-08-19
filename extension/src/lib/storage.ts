import type { Capture } from "../types/capture";

const QUEUE_KEY = "pendingCaptures";
const TOKEN_KEY = "accessToken";

export async function getAccessToken(): Promise<string> {
  const values = await chrome.storage.local.get(TOKEN_KEY);
  return typeof values[TOKEN_KEY] === "string" ? values[TOKEN_KEY] : "";
}

export async function setAccessToken(token: string): Promise<void> {
  await chrome.storage.local.set({ [TOKEN_KEY]: token.trim() });
}

export async function getPendingCaptures(): Promise<Capture[]> {
  const values = await chrome.storage.local.get(QUEUE_KEY);
  return Array.isArray(values[QUEUE_KEY]) ? values[QUEUE_KEY] : [];
}

export async function enqueueCapture(capture: Capture): Promise<void> {
  const queue = await getPendingCaptures();
  await chrome.storage.local.set({ [QUEUE_KEY]: [...queue, capture] });
}

export async function replacePendingCaptures(queue: Capture[]): Promise<void> {
  await chrome.storage.local.set({ [QUEUE_KEY]: queue });
}
