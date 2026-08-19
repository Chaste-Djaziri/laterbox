import { assert, assertEquals } from "jsr:@std/assert";
import { createCaptureHandler } from "./index.ts";

const token = "test-access-token";
const userId = "00000000-0000-4000-8000-000000000001";

Deno.test("capture requires an authenticated user", async () => {
  const handler = createCaptureHandler({
    fetch: () => Promise.reject(new Error("fetch should not be called")),
  });

  const response = await handler(
    new Request("https://example.test/capture", {
      method: "POST",
      body: JSON.stringify({ url: "https://example.com" }),
    }),
  );

  assertEquals(response.status, 401);
});

Deno.test("capture inserts an authenticated browser item", async () => {
  const requests: Request[] = [];
  const handler = createCaptureHandler({
    supabaseUrl: "https://project.supabase.co",
    anonKey: "publishable-key",
    createId: () => "00000000-0000-4000-8000-000000000002",
    now: () => new Date("2026-08-19T12:00:00.000Z"),
    fetch: async (input, init) => {
      const request = new Request(input, init);
      requests.push(request);
      if (request.url.endsWith("/auth/v1/user")) {
        return Response.json({ id: userId });
      }
      return Response.json([{}], { status: 201 });
    },
  });

  const response = await handler(
    new Request("https://example.test/capture", {
      method: "POST",
      headers: {
        authorization: `Bearer ${token}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        url: "https://github.com/flutter/flutter",
        title: "Flutter",
        source: "browserExtension",
      }),
    }),
  );

  assertEquals(response.status, 201);
  assertEquals(await response.json(), {
    id: "00000000-0000-4000-8000-000000000002",
    status: "saved",
    source: "browserExtension",
  });

  const insert = requests.find((request) => request.url.endsWith("/rest/v1/items"));
  assert(insert !== undefined);
  assertEquals(await insert!.json(), {
    id: "00000000-0000-4000-8000-000000000002",
    user_id: userId,
    url: "https://github.com/flutter/flutter",
    title: "Flutter",
    text_content: null,
    type: "link",
    favorite: false,
    status: "inbox",
    created_at: "2026-08-19T12:00:00.000Z",
    updated_at: "2026-08-19T12:00:00.000Z",
  });
});

Deno.test("capture validates source and content", async () => {
  const handler = createCaptureHandler({
    fetch: () => Promise.reject(new Error("fetch should not be called")),
  });

  const response = await handler(
    new Request("https://example.test/capture", {
      method: "POST",
      headers: { authorization: `Bearer ${token}` },
      body: JSON.stringify({ source: "unknown" }),
    }),
  );

  assertEquals(response.status, 400);
});
