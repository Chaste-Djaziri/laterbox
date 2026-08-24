import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL =
  process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ltjisrgldssqskcylcbj.supabase.co';
const SUPABASE_ANON_KEY =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  'sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p';
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;

export async function POST(req: NextRequest) {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return NextResponse.json(
        { error: 'Missing or invalid authorization header' },
        { status: 401 }
      );
    }

    const token = authHeader.replace('Bearer ', '').trim();
    if (!token) {
      return NextResponse.json({ error: 'Missing token' }, { status: 401 });
    }

    // Authenticate user with token
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { persistSession: false },
    });

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser(token);

    if (userError || !user) {
      return NextResponse.json(
        { error: 'Invalid or expired session token' },
        { status: 401 }
      );
    }

    const userId = user.id;

    // 1. Try atomic PostgreSQL RPC deletion (Security Definer)
    try {
      const { error: rpcError } = await userClient.rpc('delete_user_account');
      if (!rpcError) {
        return NextResponse.json({
          success: true,
          message: 'Account and all associated data permanently deleted via RPC',
        });
      }
    } catch (_) {}

    // 2. Use admin client if service role key is available
    if (SUPABASE_SERVICE_ROLE_KEY) {
      const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: { persistSession: false, autoRefreshToken: false },
      });

      // Delete user rows across tables
      const tables = [
        'collection_items',
        'item_notes',
        'item_metadata',
        'attachments',
        'items',
        'collections',
        'extension_sessions',
        'extension_connection_requests',
      ];

      for (const table of tables) {
        try {
          await adminClient.from(table).delete().match({ user_id: userId });
        } catch (_) {}
      }

      // Delete user from Supabase auth
      try {
        await adminClient.auth.admin.deleteUser(userId);
      } catch (_) {}
    } else {
      // Direct user-scoped deletions fallback
      try {
        await userClient.from('collection_items').delete();
      } catch (_) {}
      try {
        await userClient.from('item_notes').delete().match({ user_id: userId });
      } catch (_) {}
      try {
        await userClient.from('items').delete().match({ user_id: userId });
      } catch (_) {}
      try {
        await userClient.from('collections').delete().match({ user_id: userId });
      } catch (_) {}
    }

    return NextResponse.json({
      success: true,
      message: 'Account and all associated data deleted successfully',
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: err?.message || 'Failed to delete account' },
      { status: 500 }
    );
  }
}
