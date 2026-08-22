import { browser } from "../platform/api";
import {
  clearConnection,
  clearPendingConnection,
  getAccessToken,
  getConnectedUserId,
  getPendingConnection,
  setAccessToken,
  setConnectedUserId,
  setPendingConnection,
} from "./storage";

export { getAccessToken, getPendingConnection, clearPendingConnection };

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

let activeConnectPromise: Promise<string> | null = null;
let activeConnectCancel: (() => void) | null = null;

export async function cancelPendingConnection(): Promise<void> {
  if (activeConnectCancel) {
    activeConnectCancel();
    activeConnectCancel = null;
  }
  const pending = await getPendingConnection();
  if (pending?.tabId !== undefined) {
    await closeTab(pending.tabId);
  }
  await clearPendingConnection();
}

export async function openPendingApprovalTab(): Promise<void> {
  const pending = await getPendingConnection();
  if (!pending?.connectUrl) {
    await connectLaterBoxViaTab();
    return;
  }
  if (pending.tabId !== undefined) {
    try {
      await browser.tabs.update(pending.tabId, { active: true });
      return;
    } catch {}
  }
  const tab = await browser.tabs.create({ url: pending.connectUrl });
  await setPendingConnection({ ...pending, tabId: tab.id });
}

const POLL_INTERVAL_MS = 1_000;
const CONNECT_TIMEOUT_MS = 5 * 60 * 1_000;

/** Tab-based connect running in the background worker. */
export async function connectLaterBoxViaTab(): Promise<string> {
  if (activeConnectPromise) {
    return activeConnectPromise;
  }

  activeConnectPromise = (async () => {
    const connectionEndpoint = getConnectionEndpoint();
    const webUrl = import.meta.env.VITE_LATERBOX_WEB_URL ?? "";
    if (!connectionEndpoint || !webUrl) {
      throw new Error("LaterBox connection is not configured");
    }

    const { requestId, requestSecret } = createConnectCredentials();
    await postConnection(connectionEndpoint, {
      action: "request",
      request_id: requestId,
      request_secret: requestSecret,
    });

    const connectUrl = new URL("/extension/connect", webUrl);
    connectUrl.searchParams.set("request_id", requestId);
    connectUrl.searchParams.set("request_secret", requestSecret);
    connectUrl.searchParams.set(
      "redirect_uri",
      new URL("/extension/connected", webUrl).toString(),
    );

    const tab = await browser.tabs.create({ url: connectUrl.toString() });
    await setPendingConnection({
      requestId,
      requestSecret,
      connectUrl: connectUrl.toString(),
      tabId: tab.id,
      createdAt: Date.now(),
    });

    let cancelled = false;
    activeConnectCancel = () => {
      cancelled = true;
    };

    const deadline = Date.now() + CONNECT_TIMEOUT_MS;
    let status = "pending";
    try {
      while (Date.now() < deadline && !cancelled) {
        await sleep(POLL_INTERVAL_MS);
        if (cancelled) break;
        try {
          const response = await postConnection(connectionEndpoint, {
            action: "status",
            request_id: requestId,
            request_secret: requestSecret,
          });
          status = typeof response.status === "string" ? response.status : "pending";
        } catch {
          // Transient failures should not end the connection attempt.
        }
        if (status !== "pending") break;
      }

      if (cancelled) {
        throw new Error("Connection request cancelled.");
      }

      if (status !== "approved") {
        await closeTab(tab.id);
        throw new Error("LaterBox connection timed out or was not approved.");
      }

      const userId = await exchangeConnection(connectionEndpoint, requestId, requestSecret);
      await clearPendingConnection();
      return userId;
    } finally {
      activeConnectPromise = null;
      activeConnectCancel = null;
      if (status !== "approved") {
        await clearPendingConnection();
      }
    }
  })();

  return activeConnectPromise;
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
    throw new Error("LaterBox did not return an extension credential");
  }

  await setAccessToken(response.extensionToken);
  const userId = typeof response.userId === "string" ? response.userId : "";
  await setConnectedUserId(userId);
  return userId;
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
  if (token && connectionEndpoint) {
    await fetch(connectionEndpoint, {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({ action: "revoke" }),
    });
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
    body: JSON.stringify(body),
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
