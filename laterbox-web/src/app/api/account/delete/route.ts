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

    // Use admin client if service role key is available, or user client with user's JWT
    const client = SUPABASE_SERVICE_ROLE_KEY
      ? createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
          auth: { persistSession: false, autoRefreshToken: false },
        })
      : createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
          global: { headers: { Authorization: `Bearer ${token}` } },
          auth: { persistSession: false },
        });

    // 1. Delete all user data from tables
    try {
      await client.from('item_collections').delete().match({ user_id: userId });
    } catch {}

    try {
      await client.from('item_metadata').delete().match({ user_id: userId });
    } catch {}

    try {
      await client.from('items').delete().match({ user_id: userId });
    } catch {}

    try {
      await client.from('collections').delete().match({ user_id: userId });
    } catch {}

    try {
      await client.from('tags').delete().match({ user_id: userId });
    } catch {}

    // 2. If admin client is available, delete the user from Supabase auth
    if (SUPABASE_SERVICE_ROLE_KEY) {
      const adminClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
        auth: { persistSession: false, autoRefreshToken: false },
      });
      await adminClient.auth.admin.deleteUser(userId);
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
