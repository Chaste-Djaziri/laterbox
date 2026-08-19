import { getAccessToken } from "./auth";
import {
  enqueueCapture,
  getPendingCaptures,
  replacePendingCaptures,
} from "./storage";
import type { Capture, CaptureResult } from "../types/capture";

const captureEndpoint = import.meta.env.VITE_CAPTURE_API_URL ?? "";

export function formatHighlight(selection: string, url: string, title?: string): string {
  const quote = selection
    .trim()
    .split("\n")
    .map((line) => `> ${line.trim()}`)
    .join("\n");
  const source = title?.trim() ? `${title.trim()}\n${url}` : url;
  return `${quote}\n\nSource: ${source}`;
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
    return { status: error instanceof AuthenticationError ? "needsAuth" : "queued" };
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
