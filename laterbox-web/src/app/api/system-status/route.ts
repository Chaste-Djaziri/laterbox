import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
  const token =
    process.env.BETTERSTACK_UPTIME_TOKEN ||
    process.env.BETTER_STACK_API_TOKEN ||
    process.env.BETTERSTACK_API_TOKEN;

  // If Better Stack API token is configured, fetch live monitor statuses
  if (token) {
    try {
      const response = await fetch("https://uptime.betterstack.com/api/v2/monitors", {
        headers: {
          Authorization: `Bearer ${token}`,
        },
        next: { revalidate: 60 },
        signal: AbortSignal.timeout(5000),
      });

      if (response.ok) {
        const json = (await response.json()) as {
          data?: Array<{
            id: string;
            attributes?: {
              pronounceable_name?: string;
              status?: string;
              paused?: boolean;
            };
          }>;
        };
        const monitors = json?.data || [];

        const activeMonitors = monitors.filter((m) => !m.attributes?.paused);
        const downMonitors = activeMonitors.filter((m) => m.attributes?.status === "down");
        const degradedMonitors = activeMonitors.filter((m) => m.attributes?.status === "degraded");

        if (downMonitors.length > 0) {
          return NextResponse.json(
            {
              status: "outage",
              label: `${downMonitors.length} Service Disruption${downMonitors.length > 1 ? "s" : ""}`,
              indicator: "rose",
              totalMonitors: activeMonitors.length,
              downCount: downMonitors.length,
              statusPageUrl: "https://status.laterbox.dev",
              timestamp: new Date().toISOString(),
            },
            {
              headers: {
                "Cache-Control": "public, s-maxage=60, stale-while-revalidate=120",
              },
            },
          );
        }

        if (degradedMonitors.length > 0) {
          return NextResponse.json(
            {
              status: "degraded",
              label: "Degraded Performance",
              indicator: "amber",
              totalMonitors: activeMonitors.length,
              degradedCount: degradedMonitors.length,
              statusPageUrl: "https://status.laterbox.dev",
              timestamp: new Date().toISOString(),
            },
            {
              headers: {
                "Cache-Control": "public, s-maxage=60, stale-while-revalidate=120",
              },
            },
          );
        }

        return NextResponse.json(
          {
            status: "operational",
            label: "All Systems Operational",
            indicator: "emerald",
            totalMonitors: activeMonitors.length,
            statusPageUrl: "https://status.laterbox.dev",
            timestamp: new Date().toISOString(),
          },
          {
            headers: {
              "Cache-Control": "public, s-maxage=60, stale-while-revalidate=120",
            },
          },
        );
      }
    } catch {
      // Fallback below
    }
  }

  // Default healthy status fallback
  return NextResponse.json(
    {
      status: "operational",
      label: "All Systems Operational",
      indicator: "emerald",
      statusPageUrl: "https://status.laterbox.dev",
      timestamp: new Date().toISOString(),
    },
    {
      headers: {
        "Cache-Control": "public, s-maxage=60, stale-while-revalidate=120",
      },
    },
  );
}
