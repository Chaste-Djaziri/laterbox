import { browser } from "../platform/api";
import type { Capture } from "../types/capture";

const QUEUE_KEY = "pendingCaptures";
const TOKEN_KEY = "accessToken";
const USER_ID_KEY = "connectedUserId";

export async function getAccessToken(): Promise<string> {
  const values = await browser.storage.local.get(TOKEN_KEY);
  return typeof values[TOKEN_KEY] === "string" ? values[TOKEN_KEY] : "";
}

export async function setAccessToken(token: string): Promise<void> {
  await browser.storage.local.set({ [TOKEN_KEY]: token.trim() });
}

export async function setConnectedUserId(userId: string): Promise<void> {
  await browser.storage.local.set({ [USER_ID_KEY]: userId });
}

export async function getConnectedUserId(): Promise<string> {
  const values = await browser.storage.local.get(USER_ID_KEY);
  return typeof values[USER_ID_KEY] === "string" ? values[USER_ID_KEY] : "";
}

export async function clearConnection(): Promise<void> {
  await browser.storage.local.remove([TOKEN_KEY, USER_ID_KEY]);
}

export async function getPendingCaptures(): Promise<Capture[]> {
  const values = await browser.storage.local.get(QUEUE_KEY);
  return Array.isArray(values[QUEUE_KEY]) ? values[QUEUE_KEY] : [];
}

export async function enqueueCapture(capture: Capture): Promise<void> {
  const queue = await getPendingCaptures();
  await browser.storage.local.set({ [QUEUE_KEY]: [...queue, capture] });
}

export async function replacePendingCaptures(queue: Capture[]): Promise<void> {
  await browser.storage.local.set({ [QUEUE_KEY]: queue });
}
