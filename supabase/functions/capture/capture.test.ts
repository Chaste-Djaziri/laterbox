import { assert, assertEquals } from "jsr:@std/assert";
import { createCaptureHandler } from "./index.ts";

const token = "test-access-token";
const userId = "00000000-0000-4000-8000-000000000001";

Deno.test("capture OPTIONS returns an empty successful preflight", async () => {
  const response = await createCaptureHandler()(
    new Request("https://example.test/capture", { method: "OPTIONS" }),
  );

  assertEquals(response.status, 204);
  assertEquals(await response.text(), "");
});

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
    hasProAccess: () => Promise.resolve(true),
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
    text_selector: null,
    type: "link",
    favorite: false,
    status: "deferred",
      return_at: null,
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

Deno.test("capture inserts scoped extension sessions with service role", async () => {
  const requests: Request[] = [];
  const extensionToken = "lb_ext_test-token";
  const handler = createCaptureHandler({
    supabaseUrl: "http://127.0.0.1:54321",
    anonKey: "anon-key",
    serviceRoleKey: "service-role-key",
    createId: () => "00000000-0000-4000-8000-000000000003",
    now: () => new Date("2026-08-20T00:00:00.000Z"),
    hasProAccess: () => Promise.resolve(true),
    fetch: async (input, init) => {
      const request = new Request(input, init);
      requests.push(request);
      if (request.url.includes("/extension_sessions?select=")) {
        return Response.json([{ user_id: userId }]);
      }
      if (request.method === "PATCH") return new Response(null, { status: 204 });
      return Response.json([{}], { status: 201 });
    },
  });

  const response = await handler(
    new Request("https://example.test/capture", {
      method: "POST",
      headers: {
        authorization: `Bearer ${extensionToken}`,
        "content-type": "application/json",
      },
      body: JSON.stringify({
        url: "https://example.com/post",
        source: "browserExtension",
      }),
    }),
  );

  assertEquals(response.status, 201);
  const insert = requests.find((request) => request.url.endsWith("/rest/v1/items"));
  assert(insert !== undefined);
  assertEquals(insert!.headers.get("authorization"), "Bearer service-role-key");
});

Deno.test("capture rejects connected capture without Pro", async () => {
  const handler = createCaptureHandler({
    supabaseUrl: "https://project.supabase.co",
    anonKey: "publishable-key",
    hasProAccess: () => Promise.resolve(false),
    fetch: async (input) => {
      const request = new Request(input);
      if (request.url.endsWith("/auth/v1/user")) return Response.json({ id: userId });
      throw new Error("capture insert should not be called");
    },
  });

  const response = await handler(
    new Request("https://example.test/capture", {
      method: "POST",
      headers: { authorization: `Bearer ${token}`, "content-type": "application/json" },
      body: JSON.stringify({ url: "https://example.com", source: "browserExtension" }),
    }),
  );

  assertEquals(response.status, 403);
  assertEquals(await response.json(), {
    error: "LaterBox Pro is required for connected capture",
  });
});

Deno.test('rich captures require atomic RPC acknowledgement and preserve snapshots',async()=>{
 let rpcBody:Record<string,unknown>={};let fail=false;
 const handler=createCaptureHandler({supabaseUrl:'https://project.supabase.co',anonKey:'anon',serviceRoleKey:'service',hasProAccess:async()=>true,
 fetch:async(input,init)=>{const url=String(input);if(url.endsWith('/auth/v1/user'))return Response.json({id:userId});assert(url.endsWith('/rpc/save_extension_capture'));rpcBody=JSON.parse(String(init?.body));return fail ? Response.json({}, {status:500}):Response.json('00000000-0000-4000-8000-000000000099');}});
 const send=()=>handler(new Request('https://example.test/capture',{method:'POST',headers:{authorization:`Bearer ${token}`},body:JSON.stringify({captureId:'00000000-0000-4000-8000-000000000010',kind:'social',url:'https://example.com/post',markdown:'# Post',author:'Writer',text:'Visible post',source:'browserExtension'})}));
 assertEquals((await send()).status,201);assertEquals((rpcBody.p_content as Record<string,unknown>).markdown,'# Post');assertEquals((rpcBody.p_item as Record<string,unknown>).url,'https://example.com/post');fail=true;assertEquals((await send()).status,502);
});
Deno.test('capture validates UTF-8 content limits before network writes',async()=>{
 const {validateCaptureBody}=await import('./index.ts');
 assertEquals(validateCaptureBody({url:'https://example.com',markdown:'é'.repeat(102401)}),null);
 assertEquals(validateCaptureBody({url:'https://example.com',text:'é'.repeat(5001),kind:'highlight'}),null);
 assertEquals(validateCaptureBody({url:'https://example.com/'+ 'é'.repeat(4100)}),null);
 assert(validateCaptureBody({url:'https://example.com',markdown:'x'.repeat(204800),kind:'page'}));
});
