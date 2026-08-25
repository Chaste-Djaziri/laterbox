import { handleInternalHealthCheck } from "../_shared/health.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const json = (data: unknown, status: number): Response =>
  new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

type CaptureBody = {
  url?: unknown;
  text?: unknown;
  title?: unknown;
  description?: unknown;
  previewImageUrl?: unknown;
  preview_image_url?: unknown;
  faviconUrl?: unknown;
  favicon_url?: unknown;
  siteName?: unknown;
  site_name?: unknown;
  os?: unknown;
  platform?: unknown;
  selector?: unknown;
  source?: unknown;
};

type CaptureDependencies = {
  fetch: typeof fetch;
  supabaseUrl: string;
  anonKey: string;
  serviceRoleKey: string;
  createId: () => string;
  now: () => Date;
};

const defaultDependencies = (): CaptureDependencies => ({
  fetch,
  supabaseUrl: Deno.env.get("SUPABASE_URL") ?? "",
  anonKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  serviceRoleKey: Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  createId: () => crypto.randomUUID(),
  now: () => new Date(),
});

export const createCaptureHandler = (
  overrides: Partial<CaptureDependencies> = {},
): ((request: Request) => Promise<Response>) => {
  const dependencies = { ...defaultDependencies(), ...overrides };

  return async (request: Request): Promise<Response> => {
    const healthResponse = handleInternalHealthCheck(request, "capture");
    if (healthResponse) {
      return healthResponse;
    }

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const token = bearerToken(request.headers.get("authorization"));
    if (token === null) return json({ error: "Authentication required" }, 401);

    let body: CaptureBody;
    try {
      body = await request.json();
    } catch {
      return json({ error: "Invalid JSON body" }, 400);
    }

    const capture = validateCaptureBody(body);
    if (capture === null) {
      return json(
        { error: "Expected a URL or text, with an optional title and source" },
        400,
      );
    }

    const userId = await authenticate(token, dependencies);
    if (userId === null) return json({ error: "Invalid access token" }, 401);

    const itemId = dependencies.createId();
    const timestamp = dependencies.now().toISOString();
    const row = {
      id: itemId,
      user_id: userId,
      url: capture.url,
      title: capture.title,
      text_content: capture.text,
      text_selector: capture.selector === null
        ? null
        : JSON.stringify(capture.selector),
      type: capture.text !== null ? "note" : "link",
      favorite: false,
      status: "inbox",
      created_at: timestamp,
      updated_at: timestamp,
    };
    const databaseToken = token.startsWith("lb_ext_")
      ? dependencies.serviceRoleKey
      : token;
    const databaseKey = token.startsWith("lb_ext_")
      ? dependencies.serviceRoleKey
      : dependencies.anonKey;

    const insertResponse = await dependencies.fetch(
      `${dependencies.supabaseUrl}/rest/v1/items`,
      {
        method: "POST",
        headers: {
          apikey: databaseKey,
          authorization: `Bearer ${databaseToken}`,
          "content-type": "application/json",
          prefer: "return=representation",
        },
        body: JSON.stringify(row),
      },
    );

    if (!insertResponse.ok) {
      console.error("capture insert failed", insertResponse.status);
      return json({ error: "Could not save capture" }, 502);
    }

    // Insert metadata row if a URL was captured
    if (capture.url) {
      try {
        const domain = new URL(capture.url).hostname.replace(/^www\./i, "");
        const metaRow = {
          item_id: itemId,
          user_id: userId,
          domain: domain,
          site_name: capture.siteName ?? domain,
          title: capture.title ?? domain,
          description: capture.description ?? null,
          favicon_url: capture.faviconUrl ?? `https://www.google.com/s2/favicons?domain=${domain}&sz=128`,
          preview_image_url: capture.previewImageUrl ?? null,
          status: capture.previewImageUrl ? "enriched" : "pending",
          content_type: "link",
          classification_source: capture.source,
          structured_data: JSON.stringify({
            source: capture.source,
            os: capture.os ?? "Desktop",
          }),
          created_at: timestamp,
          updated_at: timestamp,
        };

        await dependencies.fetch(
          `${dependencies.supabaseUrl}/rest/v1/item_metadata`,
          {
            method: "POST",
            headers: {
              apikey: databaseKey,
              authorization: `Bearer ${databaseToken}`,
              "content-type": "application/json",
              prefer: "resolution=merge-duplicates",
            },
            body: JSON.stringify(metaRow),
          },
        );
      } catch (err) {
        console.warn("Could not insert initial item_metadata", err);
      }
    }

    return json(
      {
        id: itemId,
        status: "saved",
        source: capture.source,
      },
      201,
    );
  };
};

function bearerToken(value: string | null): string | null {
  if (value === null) return null;
  const match = value.match(/^Bearer\s+(.+)$/i);
  return match?.[1] ?? null;
}

async function authenticate(
  token: string,
  dependencies: CaptureDependencies,
): Promise<string | null> {
  if (token.startsWith("lb_ext_")) {
    return authenticateExtension(token, dependencies);
  }

  const response = await dependencies.fetch(`${dependencies.supabaseUrl}/auth/v1/user`, {
    headers: {
      apikey: dependencies.anonKey,
      authorization: `Bearer ${token}`,
    },
  });
  if (!response.ok) return null;

  const user = await response.json();
  return typeof user?.id === "string" ? user.id : null;
}

async function authenticateExtension(
  token: string,
  dependencies: CaptureDependencies,
): Promise<string | null> {
  if (dependencies.serviceRoleKey.length === 0) return null;
  const tokenHash = await hash(token);
  const now = encodeURIComponent(dependencies.now().toISOString());
  const response = await dependencies.fetch(
    `${dependencies.supabaseUrl}/rest/v1/extension_sessions?select=user_id&token_hash=eq.${tokenHash}&revoked_at=is.null&expires_at=gt.${now}`,
    {
      headers: {
        apikey: dependencies.serviceRoleKey,
        authorization: `Bearer ${dependencies.serviceRoleKey}`,
      },
    },
  );
  if (!response.ok) return null;
  const rows = await response.json();
  const userId = Array.isArray(rows) && typeof rows[0]?.user_id === "string"
    ? rows[0].user_id
    : null;
  if (userId === null) return null;

  await dependencies.fetch(
    `${dependencies.supabaseUrl}/rest/v1/extension_sessions?token_hash=eq.${tokenHash}`,
    {
      method: "PATCH",
      headers: {
        apikey: dependencies.serviceRoleKey,
        authorization: `Bearer ${dependencies.serviceRoleKey}`,
        "content-type": "application/json",
        prefer: "return=minimal",
      },
      body: JSON.stringify({ last_used_at: dependencies.now().toISOString() }),
    },
  );
  return userId;
}

async function hash(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

function validateCaptureBody(body: CaptureBody): {
  url: string | null;
  text: string | null;
  title: string | null;
  description: string | null;
  previewImageUrl: string | null;
  faviconUrl: string | null;
  siteName: string | null;
  os: string | null;
  selector: { before: string; after: string } | null;
  source: string;
} | null {
  let url = typeof body.url === "string" ? body.url.trim() : "";
  let text = typeof body.text === "string" ? body.text.trim() : "";
  const title = typeof body.title === "string" ? body.title.trim() : "";
  const description = typeof body.description === "string" ? body.description.trim() : "";
  const previewImageUrl = typeof (body.previewImageUrl ?? body.preview_image_url) === "string"
    ? String(body.previewImageUrl ?? body.preview_image_url).trim()
    : "";
  const faviconUrl = typeof (body.faviconUrl ?? body.favicon_url) === "string"
    ? String(body.faviconUrl ?? body.favicon_url).trim()
    : "";
  const siteName = typeof (body.siteName ?? body.site_name) === "string"
    ? String(body.siteName ?? body.site_name).trim()
    : "";
  const os = typeof (body.os ?? body.platform) === "string"
    ? String(body.os ?? body.platform).trim()
    : "";
  const source = typeof body.source === "string" ? body.source : "api";
  const selector = parseSelector(body.selector);

  if (url.length === 0 && text.length === 0) return null;

  // Extract embedded URL if url is not explicitly provided
  if (url.length === 0 && text.length > 0) {
    const urlMatch = text.match(/(https?:\/\/[^\s]+)/);
    if (urlMatch) {
      const matchedUrl = urlMatch[0];
      const remainingText = text
        .replace(matchedUrl, "")
        .trim()
        .replace(/^["“”\s]+|["“”\s]+$/g, "");
      url = matchedUrl;
      text = remainingText;
    }
  }

  // Construct W3C scroll-to-text fragment if both url and text are present
  if (url.length > 0 && text.length > 0 && isHttpUrl(url) && !url.includes(":~:text=")) {
    const snippet = text.slice(0, 120);
    const encoded = encodeURIComponent(snippet);
    const separator = url.includes("#") ? ":~:text=" : "#:~:text=";
    url = `${url}${separator}${encoded}`;
  }

  if (url.length > 0 && !isHttpUrl(url)) return null;
  if (url.length > 2048 || text.length > 10000 || title.length > 500) return null;
  if (!CAPTURE_SOURCES.has(source)) return null;

  return {
    url: url.length > 0 ? url : null,
    text: text.length > 0 ? text : null,
    title: title.length > 0 ? title : null,
    description: description.length > 0 ? description : null,
    previewImageUrl: previewImageUrl.length > 0 ? previewImageUrl : null,
    faviconUrl: faviconUrl.length > 0 ? faviconUrl : null,
    siteName: siteName.length > 0 ? siteName : null,
    os: os.length > 0 ? os : null,
    selector,
    source,
  };
}

function parseSelector(
  value: unknown,
): { before: string; after: string } | null {
  if (typeof value !== "object" || value === null) return null;
  const raw = value as Record<string, unknown>;
  const before = typeof raw.before === "string" ? raw.before.trim().slice(0, 300) : "";
  const after = typeof raw.after === "string" ? raw.after.trim().slice(0, 300) : "";
  if (!before && !after) return null;
  return { before, after };
}

function isHttpUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "http:" || url.protocol === "https:";
  } catch {
    return false;
  }
}

const CAPTURE_SOURCES = new Set([
  "manual",
  "androidShare",
  "iosShare",
  "browserExtension",
  "desktopQuickCapture",
  "api",
]);

if (import.meta.main) {
  Deno.serve(createCaptureHandler());
}
