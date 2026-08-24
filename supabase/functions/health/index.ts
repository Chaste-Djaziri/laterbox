const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

if (!SUPABASE_URL || !SUPABASE_ANON_KEY || !SUPABASE_SERVICE_ROLE_KEY) {
  throw new Error("Required Supabase environment variables are missing.");
}

type ProbeResult = {
  ok: boolean;
  statusCode: number | null;
  latencyMs: number;
};

async function probe(
  url: string,
  headers: Record<string, string> = {},
): Promise<ProbeResult> {
  const startedAt = performance.now();
  try {
    const response = await fetch(url, {
      method: "GET",
      headers,
      signal: AbortSignal.timeout(5000),
    });
    return {
      ok: response.ok,
      statusCode: response.status,
      latencyMs: Math.round(performance.now() - startedAt),
    };
  } catch {
    return {
      ok: false,
      statusCode: null,
      latencyMs: Math.round(performance.now() - startedAt),
    };
  }
}

function serviceRoleHeaders(): Record<string, string> {
  return {
    apikey: SUPABASE_SERVICE_ROLE_KEY!,
    Authorization: `Bearer ${SUPABASE_SERVICE_ROLE_KEY}`,
  };
}

function anonHeaders(): Record<string, string> {
  return {
    apikey: SUPABASE_ANON_KEY!,
  };
}

async function checkAuth(): Promise<ProbeResult> {
  return probe(
    `${SUPABASE_URL}/auth/v1/health`,
    anonHeaders(),
  );
}

async function checkDatabase(): Promise<ProbeResult> {
  return probe(
    `${SUPABASE_URL}/rest/v1/items?select=id&limit=1`,
    serviceRoleHeaders(),
  );
}

async function checkStorage(): Promise<ProbeResult> {
  return probe(
    `${SUPABASE_URL}/storage/v1/bucket`,
    serviceRoleHeaders(),
  );
}

async function checkEdgeFunction(
  functionName: string,
): Promise<ProbeResult> {
  return probe(
    `${SUPABASE_URL}/functions/v1/${functionName}?__health=1`,
    serviceRoleHeaders(),
  );
}

const checks: Record<string, () => Promise<ProbeResult>> = {
  auth: checkAuth,
  database: checkDatabase,
  storage: checkStorage,
  capture: () => checkEdgeFunction("capture"),
  enrichment: () => checkEdgeFunction("enrich-url"),
  attachments: () => checkEdgeFunction("attachment-storage"),
  extension: () => checkEdgeFunction("extension-connect"),
};

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  if (request.method !== "GET") {
    return Response.json(
      {
        status: "error",
        error: "Method not allowed",
      },
      {
        status: 405,
      },
    );
  }

  const url = new URL(request.url);
  const checkName = url.searchParams.get("check") ?? "all";

  if (checkName === "all") {
    const entries = await Promise.all(
      Object.entries(checks).map(async ([name, execute]) => {
        const result = await execute();
        return [name, result] as const;
      }),
    );

    const components = Object.fromEntries(entries);
    const healthy = entries.every(([, result]) => result.ok);

    return Response.json(
      {
        status: healthy ? "ok" : "degraded",
        marker: healthy ? "laterbox-health-ok" : "laterbox-health-failed",
        components,
        timestamp: new Date().toISOString(),
      },
      {
        status: healthy ? 200 : 503,
        headers: {
          "Cache-Control": "no-store",
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }

  const execute = checks[checkName];
  if (!execute) {
    return Response.json(
      {
        status: "error",
        error: "Unknown health check",
      },
      {
        status: 400,
        headers: {
          "Access-Control-Allow-Origin": "*",
        },
      },
    );
  }

  const result = await execute();
  return Response.json(
    {
      status: result.ok ? "ok" : "down",
      marker: result.ok ? "laterbox-health-ok" : "laterbox-health-failed",
      service: checkName,
      latencyMs: result.latencyMs,
      statusCode: result.statusCode,
      timestamp: new Date().toISOString(),
    },
    {
      status: result.ok ? 200 : 503,
      headers: {
        "Cache-Control": "no-store",
        "Access-Control-Allow-Origin": "*",
      },
    },
  );
});
