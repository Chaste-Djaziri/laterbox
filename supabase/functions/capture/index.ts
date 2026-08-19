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
  source?: unknown;
};

type CaptureDependencies = {
  fetch: typeof fetch;
  supabaseUrl: string;
  anonKey: string;
  createId: () => string;
  now: () => Date;
};

const defaultDependencies = (): CaptureDependencies => ({
  fetch,
  supabaseUrl: Deno.env.get("SUPABASE_URL") ?? "",
  anonKey: Deno.env.get("SUPABASE_ANON_KEY") ?? "",
  createId: () => crypto.randomUUID(),
  now: () => new Date(),
});

export const createCaptureHandler = (
  overrides: Partial<CaptureDependencies> = {},
): ((request: Request) => Promise<Response>) => {
  const dependencies = { ...defaultDependencies(), ...overrides };

  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { status: 204, headers: corsHeaders });
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
      text_content: capture.url === null ? capture.text : null,
      type: capture.url === null ? "note" : "link",
      favorite: false,
      status: "inbox",
      created_at: timestamp,
      updated_at: timestamp,
    };

    const insertResponse = await dependencies.fetch(
      `${dependencies.supabaseUrl}/rest/v1/items`,
      {
        method: "POST",
        headers: {
          apikey: dependencies.anonKey,
          authorization: `Bearer ${token}`,
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

function validateCaptureBody(body: CaptureBody): {
  url: string | null;
  text: string | null;
  title: string | null;
  source: string;
} | null {
  const url = typeof body.url === "string" ? body.url.trim() : "";
  const text = typeof body.text === "string" ? body.text.trim() : "";
  const title = typeof body.title === "string" ? body.title.trim() : "";
  const source = typeof body.source === "string" ? body.source : "api";

  if (url.length === 0 && text.length === 0) return null;
  if (url.length > 0 && !isHttpUrl(url)) return null;
  if (url.length > 2048 || text.length > 10000 || title.length > 500) return null;
  if (!CAPTURE_SOURCES.has(source)) return null;

  return {
    url: url.length > 0 ? url : null,
    text: text.length > 0 ? text : null,
    title: title.length > 0 ? title : null,
    source,
  };
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
