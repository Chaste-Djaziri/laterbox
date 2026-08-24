import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const userId = user.id;
    const adminClient = serviceRoleKey
      ? createClient(supabaseUrl, serviceRoleKey, {
          auth: { persistSession: false, autoRefreshToken: false },
        })
      : userClient;

    // Delete records
    try {
      await adminClient.from("item_collections").delete().match({ user_id: userId });
    } catch {}

    try {
      await adminClient.from("item_metadata").delete().match({ user_id: userId });
    } catch {}

    try {
      await adminClient.from("items").delete().match({ user_id: userId });
    } catch {}

    try {
      await adminClient.from("collections").delete().match({ user_id: userId });
    } catch {}

    try {
      await adminClient.from("tags").delete().match({ user_id: userId });
    } catch {}

    if (serviceRoleKey) {
      const adminAuth = createClient(supabaseUrl, serviceRoleKey, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
      await adminAuth.auth.admin.deleteUser(userId);
    }

    return new Response(
      JSON.stringify({ success: true, message: "Account and data deleted" }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err?.message || "Internal server error" }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
});
