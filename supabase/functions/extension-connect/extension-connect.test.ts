import { assertEquals } from "jsr:@std/assert";
import { createConnectionHandler } from "./index.ts";

const requestId = "test-connection-request-0001";
const requestSecret = "0123456789abcdef0123456789abcdef";

Deno.test("connection request can start without a user token", async () => {
  const handler = createConnectionHandler({
    fetch: async () => Response.json({}, { status: 201 }),
    supabaseUrl: "https://project.supabase.co",
    serviceRoleKey: "service-role-key",
  });

  const response = await handler(
    new Request("https://example.test/extension-connect", {
      method: "POST",
      body: JSON.stringify({
        action: "request",
        request_id: requestId,
        request_secret: requestSecret,
      }),
    }),
  );

  assertEquals(response.status, 201);
  assertEquals(await response.json(), { status: "pending" });
});

Deno.test("approval requires the LaterBox user session", async () => {
  const handler = createConnectionHandler({
    fetch: () => Promise.reject(new Error("fetch should not be called")),
  });

  const response = await handler(
    new Request("https://example.test/extension-connect", {
      method: "POST",
      body: JSON.stringify({
        action: "approve",
        request_id: requestId,
        request_secret: requestSecret,
      }),
    }),
  );

  assertEquals(response.status, 401);
});
