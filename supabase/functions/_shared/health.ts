export function handleInternalHealthCheck(
  request: Request,
  service: string,
): Response | null {
  const url = new URL(request.url);
  const isHealthCheck =
    request.method === "GET" && url.searchParams.get("__health") === "1";

  if (!isHealthCheck) {
    return null;
  }

  return Response.json(
    {
      status: "ok",
      service,
      marker: "laterbox-internal-health-ok",
    },
    {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
      },
    },
  );
}
