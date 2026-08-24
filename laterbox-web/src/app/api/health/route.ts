import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

const headers = {
  "Cache-Control": "no-store, no-cache, must-revalidate",
};

export async function GET() {
  return NextResponse.json(
    {
      status: "ok",
      service: "laterbox-web",
      marker: "laterbox-health-ok",
      timestamp: new Date().toISOString(),
    },
    {
      status: 200,
      headers,
    },
  );
}

export async function HEAD() {
  return new Response(null, {
    status: 200,
    headers,
  });
}
