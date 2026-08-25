import { getAccessToken } from "./auth";
import { buildScrollToTextFragment, getPageContext } from "./page";
import {
  enqueueCapture,
  getPendingCaptures,
  replacePendingCaptures,
} from "./storage";
import type { Capture, CaptureResult } from "../types/capture";

const captureEndpoint = import.meta.env.VITE_CAPTURE_API_URL ?? "";

export async function saveSelectionFromTab(
  tab: chrome.tabs.Tab,
): Promise<CaptureResult> {
  if (tab.id === undefined) throw new Error("Missing active tab.");

  const page = await getPageContext(tab.id, {
    url: tab.url ?? "",
    title: tab.title ?? "",
    selection: "",
  });

  const selectedText = page.selection.trim();
  if (!selectedText) throw new Error("No text selected.");

  const rawUrl = page.url || tab.url || "";
  const highlightedUrl = buildScrollToTextFragment(
    rawUrl,
    selectedText,
    page.selector,
  );

  return saveCapture({
    text: selectedText,
    url: highlightedUrl,
    title: page.title || tab.title || undefined,
    description: page.description,
    previewImageUrl: page.previewImageUrl,
    faviconUrl: page.faviconUrl,
    siteName: page.siteName,
    os: page.os,
    selector: page.selector ?? undefined,
    source: "browserExtension",
    createdAt: new Date().toISOString(),
  });
}

export async function saveCapture(capture: Capture): Promise<CaptureResult> {
  const token = await getAccessToken();
  if (!captureEndpoint || !token) {
    await enqueueCapture(capture);
    return { status: token ? "queued" : "needsAuth" };
  }

  try {
    const id = await sendCapture(capture, token);
    return { id, status: "saved" };
  } catch (error) {
    await enqueueCapture(capture);
    if (error instanceof AuthenticationError) return { status: "needsAuth" };
    return {
      status: "queued",
      reason: error instanceof TypeError ? "network" : "server",
    };
  }
}

export async function flushQueue(): Promise<number> {
  const token = await getAccessToken();
  if (!captureEndpoint || !token) return 0;

  const pending = await getPendingCaptures();
  const remaining: Capture[] = [];
  let flushed = 0;
  for (const capture of pending) {
    try {
      await sendCapture(capture, token);
      flushed++;
    } catch {
      remaining.push(capture);
    }
  }
  await replacePendingCaptures(remaining);
  return flushed;
}

async function sendCapture(capture: Capture, token: string): Promise<string> {
  const response = await fetch(captureEndpoint, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(capture),
  });
  if (response.status === 401 || response.status === 403) {
    throw new AuthenticationError();
  }
  if (!response.ok) throw new Error(`Capture failed with ${response.status}`);

  const body = await response.json() as { id?: unknown };
  return typeof body.id === "string" ? body.id : "";
}

class AuthenticationError extends Error {}
