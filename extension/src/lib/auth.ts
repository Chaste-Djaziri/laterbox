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

  const requestId = crypto.randomUUID().replaceAll("-", "");
  const requestSecret = createSecret();
  const redirectUri = chrome.identity.getRedirectURL("laterbox-connected");

  await postConnection(connectionEndpoint, {
    action: "request",
    request_id: requestId,
    request_secret: requestSecret,
  });

  const connectUrl = new URL("/extension/connect", webUrl);
  connectUrl.searchParams.set("request_id", requestId);
  connectUrl.searchParams.set("request_secret", requestSecret);
  connectUrl.searchParams.set("redirect_uri", redirectUri);

  const finalUrl = await chrome.identity.launchWebAuthFlow({
    url: connectUrl.toString(),
    interactive: true,
  });
  const callback = new URL(finalUrl);
  if (
    callback.searchParams.get("status") !== "approved" ||
    callback.searchParams.get("request_id") !== requestId
  ) {
    throw new Error("LaterBox connection was cancelled");
  }

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
