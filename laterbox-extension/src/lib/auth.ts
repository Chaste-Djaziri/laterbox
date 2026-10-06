import { browser } from "../platform/api";
import {
  clearConnection,
  clearPendingConnection,
  getAccessToken,
  getConnectedUserId,
  getIsPro,
  getPendingConnection,
  setAccessToken,
  setConnectedUserId,
  setIsPro,
  setPendingConnection,
} from "./storage";

export { getAccessToken, getConnectedUserId, getIsPro, getPendingConnection, clearPendingConnection };

export async function connectWithAccessToken(token: string): Promise<void> {
  await setAccessToken(token);
}

export async function connectLaterBox(): Promise<string> {
  const response = await browser.runtime.sendMessage({ type: "connect-laterbox" });
  if (typeof response?.error === "string") throw new Error(response.error);
  if (typeof response?.userId === "string") {
    return response.userId;
  }
  const storedUserId = await getConnectedUserId();
  if (storedUserId) return storedUserId;
  return "";
}

export async function cancelConnectionRequest(): Promise<void> {
  await browser.runtime.sendMessage({ type: "cancel-connect" });
}

export async function openApprovalTab(): Promise<void> {
  await browser.runtime.sendMessage({ type: "open-approval-tab" });
}

let polling: Promise<string> | null = null;
const CONNECT_TIMEOUT_MS = 5 * 60 * 1000;

export async function cancelPendingConnection(): Promise<void> {
  const pending = await getPendingConnection();
  await clearPendingConnection();
  if (pending?.tabId !== undefined) await closeTab(pending.tabId);
}
export async function openPendingApprovalTab(): Promise<void> {
  const pending = await getPendingConnection();
  if (!pending) { await connectLaterBoxViaTab(); return; }
  if (pending.tabId !== undefined) {
    try { await browser.tabs.update(pending.tabId,{ active: true }); return; } catch {}
  }
  const tab = await browser.tabs.create({ url: pending.connectUrl });
  await setPendingConnection({ ...pending, tabId: tab.id });
}
export async function connectLaterBoxViaTab(): Promise<string> {
  const pending = await getPendingConnection();
  if (pending && Date.now()-pending.createdAt < CONNECT_TIMEOUT_MS) {
    await openPendingApprovalTab(); void resumePendingConnection(); return '';
  }
  await clearPendingConnection();
  const endpoint = getConnectionEndpoint();
  const webUrl = import.meta.env.VITE_LATERBOX_WEB_URL || 'https://app.laterbox.dev';
  const { requestId, requestSecret } = createConnectCredentials();
  await postConnection(endpoint,{ action: 'request', request_id: requestId, request_secret: requestSecret });
  const url = new URL('/extension/connect',webUrl);
  url.searchParams.set('request_id',requestId); url.searchParams.set('request_secret',requestSecret);
  url.searchParams.set('redirect_uri',new URL('/extension/connected',webUrl).href);
  // Persist before opening the tab so worker suspension cannot lose the request.
  await setPendingConnection({ requestId, requestSecret, connectUrl: url.href, createdAt: Date.now() });
  const tab = await browser.tabs.create({ url: url.href });
  await setPendingConnection({ requestId, requestSecret, connectUrl: url.href, createdAt: Date.now(), tabId: tab.id });
  void resumePendingConnection(); return '';
}
export function resumePendingConnection(): Promise<string> {
  if (polling) return polling;
  polling = pollConnection().finally(()=>{ polling=null; }); return polling;
}
async function pollConnection(): Promise<string> {
  const pending = await getPendingConnection();
  if (!pending) return '';
  if (Date.now()-pending.createdAt >= CONNECT_TIMEOUT_MS) {
    await clearPendingConnection();
    await browser.storage.local.set({ connectionError: 'Approval expired. Connect again.' }); return '';
  }
  try {
    const endpoint = getConnectionEndpoint();
    const response = await postConnection(endpoint,{ action:'status', request_id:pending.requestId, request_secret:pending.requestSecret });
    if ((await getPendingConnection())?.requestId !== pending.requestId) return '';
    if (response.status === 'approved' || response.status === 'used') {
      const userId = await exchangeConnection(endpoint,pending.requestId,pending.requestSecret);
      await clearPendingConnection(); await browser.storage.local.remove('connectionError'); return userId;
    }
    if (response.status === 'expired') {
      await clearPendingConnection(); await browser.storage.local.set({ connectionError:'Approval unavailable. Connect again.' }); return '';
    }
  } catch { /* transient errors stay pending until persistent alarm retries */ }
  setTimeout(()=>void resumePendingConnection(),1000);
  return '';
}

async function exchangeConnection(
  connectionEndpoint: string,
  requestId: string,
  requestSecret: string,
): Promise<string> {
  const response = await postConnection(connectionEndpoint, {
    action: "exchange",
    request_id: requestId,
    request_secret: requestSecret,
  });
  if (typeof response.extensionToken !== "string") {
    throw new Error("laterbox did not return an extension credential");
  }

  const userId = typeof response.userId === "string" ? response.userId : "";
  if (!userId) throw new Error('Connection did not identify an account.');
  const pending = await getPendingConnection();
  if (pending?.requestId !== requestId) throw new Error('Connection was cancelled.');
  await browser.storage.local.set({ accessToken: response.extensionToken, connectedUserId: userId, hasProPlan: response.isPro === true });
  return userId;
}

export async function checkProEntitlement(): Promise<boolean> {
  const token = await getAccessToken();
  const connectionEndpoint = getConnectionEndpoint();
  if (!token || !connectionEndpoint) {
    return false;
  }

  try {
    const response = await fetch(connectionEndpoint, {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ action: "entitlement" }),
    });

    if (!response.ok) {
      if (response.status === 401) await clearConnection();
      if (response.status === 403) await setIsPro(false);
      return false;
    }

    const data = (await response.json()) as { isPro?: unknown };
    const isPro = data?.isPro === true;
    await setIsPro(isPro);
    return isPro;
  } catch {
    const cached = await getIsPro();
    return cached === true;
  }
}

export function getProUpgradeUrl(): string {
  const webUrl = import.meta.env.VITE_LATERBOX_WEB_URL || "https://app.laterbox.dev";
  return `${webUrl.replace(/\/$/, "")}/pricing?checkout=true&source=extension`;
}

function createConnectCredentials(): { requestId: string; requestSecret: string } {
  return {
    requestId: crypto.randomUUID().replaceAll("-", ""),
    requestSecret: createSecret(),
  };
}

async function closeTab(tabId: number | undefined): Promise<void> {
  if (tabId === undefined) return;
  try {
    await browser.tabs.remove(tabId);
  } catch {
    // The tab may already be closed by the user.
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function disconnectLaterBox(): Promise<void> {
  const token = await getAccessToken();
  const connectionEndpoint = getConnectionEndpoint();
  await clearConnection();
  await cancelPendingConnection();
  if (token && connectionEndpoint) {
    await fetch(connectionEndpoint, {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ action: "revoke" }), signal: AbortSignal.timeout(10000),
    }).catch(()=>{});
  }
  await clearConnection();
}

function getConnectionEndpoint(): string {
  const configured = import.meta.env.VITE_EXTENSION_CONNECT_URL ?? "";
  if (configured) return configured;
  return (import.meta.env.VITE_CAPTURE_API_URL ?? "").replace(
    /\/capture$/,
    "/extension-connect",
  );
}

async function postConnection(
  endpoint: string,
  body: Record<string, string>,
): Promise<Record<string, unknown>> {
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body), signal: AbortSignal.timeout(10000),
  });
  if (response.status === 404 && endpoint.startsWith("http://127.0.0.1:")) {
    throw new Error(
      "Local capture functions are not running. Run supabase functions serve --no-verify-jwt.",
    );
  }
  if (!response.ok) throw new Error(`Connection failed with ${response.status}`);
  return await response.json() as Record<string, unknown>;
}

function createSecret(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return btoa(String.fromCharCode(...bytes))
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}
