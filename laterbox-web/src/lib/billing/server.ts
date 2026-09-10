import { createClient, type User } from '@supabase/supabase-js';

const supabaseUrl =
  process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://ltjisrgldssqskcylcbj.supabase.co';
const supabaseAnonKey =
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ||
  'sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p';

export function getBillingAdminClient() {
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!serviceKey) throw new Error('Billing service is not configured.');
  return createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

export async function getRequestUser(request: Request): Promise<User | null> {
  const header = request.headers.get('authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7).trim() : '';
  if (!token) return null;

  const client = createClient(supabaseUrl, supabaseAnonKey, {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: `Bearer ${token}` } },
  });
  const { data, error } = await client.auth.getUser(token);
  return error ? null : data.user;
}

export async function paddleRequest<T>(path: string, init?: RequestInit): Promise<T> {
  const environment = process.env.NEXT_PUBLIC_PADDLE_ENV || 'sandbox';
  const key = environment === 'production'
    ? process.env.PADDLE_API_KEY
    : process.env.PADDLE_SANDBOX_API_KEY || process.env.PADDLE_API_KEY;
  if (!key) throw new Error(`Paddle ${environment} API key is not configured.`);
  const baseUrl = environment === 'production' ? 'https://api.paddle.com' : 'https://sandbox-api.paddle.com';
  const response = await fetch(`${baseUrl}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${key}`,
      'Content-Type': 'application/json',
      ...init?.headers,
    },
    cache: 'no-store',
  });
  const payload = (await response.json()) as { data?: T; error?: { detail?: string } };
  if (!response.ok || !payload.data) {
    throw new Error(payload.error?.detail || `Paddle request failed (${response.status}).`);
  }
  return payload.data;
}
