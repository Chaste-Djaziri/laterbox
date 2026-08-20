import { browser } from "../platform/api";
import {
  clearConnection,
  getAccessToken,
  setAccessToken,
  setConnectedUserId,
} from "./storage";

export { getAccessToken };

export async function connectWithAccessToken(token: string): Promise<void> {
  await setAccessToken(token);
}

export async function connectLaterBox(): Promise<string> {
  const connectionEndpoint = getConnectionEndpoint();
  const webUrl = import.meta.env.VITE_LATERBOX_WEB_URL ?? "";
  if (!connectionEndpoint || !webUrl) {
    throw new Error("LaterBox connection is not configured");
  }

  if (typeof browser.identity?.launchWebAuthFlow === "function") {
    return await connectViaIdentityFlow(webUrl, connectionEndpoint);
  }

  // Safari has no `identity` API: run the tab-and-poll flow in the background
  // so it survives the popup closing when the user focuses the approval tab.
  const response = await browser.runtime.sendMessage({ type: "connect-laterbox" });
  if (typeof response?.error === "string") throw new Error(response.error);
  if (typeof response?.userId !== "string") {
    throw new Error("LaterBox connection was cancelled");
  }
  return response.userId;
}

async function connectViaIdentityFlow(
  webUrl: string,
  connectionEndpoint: string,
): Promise<string> {
  const { requestId, requestSecret } = createConnectCredentials();
  await postConnection(connectionEndpoint, {
    action: "request",
    request_id: requestId,
    request_secret: requestSecret,
  });

  const redirectUri = browser.identity.getRedirectURL("laterbox-connected");

  const connectUrl = new URL("/extension/connect", webUrl);
  connectUrl.searchParams.set("request_id", requestId);
  connectUrl.searchParams.set("request_secret", requestSecret);
  connectUrl.searchParams.set("redirect_uri", redirectUri);

  const finalUrl = await browser.identity.launchWebAuthFlow({
    url: connectUrl.toString(),
    interactive: true,
  });
  if (!finalUrl) throw new Error("LaterBox connection was cancelled");
  const callback = new URL(finalUrl);
  if (
    callback.searchParams.get("status") !== "approved" ||
    callback.searchParams.get("request_id") !== requestId
  ) {
    throw new Error("LaterBox connection was cancelled");
  }

  return await exchangeConnection(connectionEndpoint, requestId, requestSecret);
}

const POLL_INTERVAL_MS = 1_000;
const CONNECT_TIMEOUT_MS = 5 * 60 * 1_000;

/** Tab-based connect for browsers without `identity` (Safari). Runs in the background. */
export async function connectLaterBoxViaTab(): Promise<string> {
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

  const deadline = Date.now() + CONNECT_TIMEOUT_MS;
  let status = "pending";
  while (Date.now() < deadline) {
    await sleep(POLL_INTERVAL_MS);
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

  if (status !== "approved") {
    await closeTab(tab.id);
    throw new Error("LaterBox connection was cancelled");
  }

  return await exchangeConnection(connectionEndpoint, requestId, requestSecret);
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
