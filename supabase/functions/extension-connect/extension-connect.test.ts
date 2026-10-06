import { assertEquals } from "jsr:@std/assert";
import { createConnectionHandler } from "./index.ts";

const requestId = "test-connection-request-0001";
const requestSecret = "0123456789abcdef0123456789abcdef";

Deno.test("connection OPTIONS returns an empty successful preflight", async () => {
  const response = await createConnectionHandler()(
    new Request("https://example.test/extension-connect", { method: "OPTIONS" }),
  );

  assertEquals(response.status, 204);
  assertEquals(await response.text(), "");
});

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

Deno.test("status reflects the connection request lifecycle", async () => {
  let row: Record<string, unknown> = {
    user_id: null,
    expires_at: new Date(Date.now() + 60_000).toISOString(),
    used_at: null,
    secret_hash: await sha256Hex(requestSecret),
  };
  const handler = createConnectionHandler({
    supabaseUrl: "https://project.supabase.co",
    serviceRoleKey: "service-role-key",
    fetch: async (input: string | URL | Request) => {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;
      if (url.includes("/rest/v1/extension_connection_requests?select=")) {
        return Response.json([row]);
      }
      return Response.json({}, { status: 500 });
    },
  });

  const status = async (expected: string) => {
    const response = await handler(
      new Request("https://example.test/extension-connect", {
        method: "POST",
        body: JSON.stringify({
          action: "status",
          request_id: requestId,
          request_secret: requestSecret,
        }),
      }),
    );
    assertEquals(response.status, 200);
    assertEquals(await response.json(), { status: expected });
  };

  await status("pending");
  row = { ...row, user_id: "user-1" };
  await status("approved");
  row = { ...row, used_at: new Date().toISOString() };
  await status("used");
});

Deno.test("status rejects an unknown connection request", async () => {
  const handler = createConnectionHandler({
    supabaseUrl: "https://project.supabase.co",
    serviceRoleKey: "service-role-key",
    fetch: async () => Response.json([]),
  });

  const response = await handler(
    new Request("https://example.test/extension-connect", {
      method: "POST",
      body: JSON.stringify({
        action: "status",
        request_id: requestId,
        request_secret: requestSecret,
      }),
    }),
  );

  assertEquals(response.status, 404);
});

Deno.test("entitlement requires valid extension token", async () => {
  const handler = createConnectionHandler({
    supabaseUrl: "https://project.supabase.co",
    serviceRoleKey: "service-role-key",
  });

  const response = await handler(
    new Request("https://example.test/extension-connect", {
      method: "POST",
      body: JSON.stringify({ action: "entitlement" }),
    }),
  );

  assertEquals(response.status, 401);
});

Deno.test("entitlement returns isPro status for valid session", async () => {
  const testToken = "lb_ext_0123456789abcdef0123456789abcdef";
  let proAccess = false;
  const handler = createConnectionHandler({
    supabaseUrl: "https://project.supabase.co",
    serviceRoleKey: "service-role-key",
    hasProAccess: async (userId: string) => userId === "user-pro" && proAccess,
    fetch: async (input: string | URL | Request) => {
      const url =
        typeof input === "string"
          ? input
          : input instanceof URL
            ? input.toString()
            : input.url;
      if (url.includes("/rest/v1/extension_sessions?token_hash=")) {
        return Response.json([
          {
            user_id: "user-pro",
            expires_at: new Date(Date.now() + 60_000).toISOString(),
          },
        ]);
      }
      return Response.json({}, { status: 500 });
    },
  });

  // Test when hasProAccess is false
  const res1 = await handler(
    new Request("https://example.test/extension-connect", {
      method: "POST",
      headers: { authorization: `Bearer ${testToken}` },
      body: JSON.stringify({ action: "entitlement" }),
    }),
  );
  assertEquals(res1.status, 200);
  assertEquals(await res1.json(), { isPro: false, userId: "user-pro" });

  // Test when hasProAccess is true
  proAccess = true;
  const res2 = await handler(
    new Request("https://example.test/extension-connect", {
      method: "POST",
      headers: { authorization: `Bearer ${testToken}` },
      body: JSON.stringify({ action: "entitlement" }),
    }),
  );
  assertEquals(res2.status, 200);
  assertEquals(await res2.json(), { isPro: true, userId: "user-pro" });
});

async function sha256Hex(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest), (byte) =>
    byte.toString(16).padStart(2, "0"),
  ).join("");
}

Deno.test('exchange resumes a lost response but rejects revoked credentials and expiry',async()=>{
 let revoked=false,used=false,expired=false;let insertions=0;
 const handler=createConnectionHandler({supabaseUrl:'https://project.supabase.co',serviceRoleKey:'service',hasProAccess:async()=>true,
 fetch:async(input,init)=>{const url=String(input);if(url.includes('extension_connection_requests') && init?.method==='PATCH'){used=true;return Response.json({});}
 if(url.includes('extension_connection_requests'))return Response.json([{user_id:'owner',secret_hash:await sha256Hex(requestSecret),expires_at:new Date(Date.now()+(expired ? -1000:60000)).toISOString(),used_at:used ? new Date().toISOString():null}]);
 if(init?.method==='POST'){insertions++;return Response.json({}, {status:201});}return Response.json(revoked ? []:[{user_id:'owner'}]);}});
 const exchange=()=>handler(new Request('https://example.test/extension-connect',{method:'POST',body:JSON.stringify({action:'exchange',request_id:requestId,request_secret:requestSecret})}));
 const first=await exchange();assertEquals(first.status,200);const original=await first.json();const retry=await exchange();assertEquals(await retry.json(),original);assertEquals(insertions,1);
 revoked=true;assertEquals((await exchange()).status,409);expired=true;assertEquals((await exchange()).status,410);
});
