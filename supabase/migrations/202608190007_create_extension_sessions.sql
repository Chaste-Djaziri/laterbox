-- Phase 13.0B: scoped credentials for connected browser extensions.

create table public.extension_connection_requests (
  request_id text primary key,
  secret_hash text not null,
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  approved_at timestamptz,
  used_at timestamptz
);

create table public.extension_sessions (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  token_hash text not null unique,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  expires_at timestamptz not null,
  revoked_at timestamptz
);

create index extension_sessions_user_idx
  on public.extension_sessions using btree (user_id);

alter table public.extension_connection_requests enable row level security;
alter table public.extension_sessions enable row level security;

-- These tables are accessed only by the Edge Functions through service_role.
revoke all on public.extension_connection_requests from anon, authenticated;
revoke all on public.extension_sessions from anon, authenticated;
grant all on public.extension_connection_requests to service_role;
grant all on public.extension_sessions to service_role;
