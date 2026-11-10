-- supabase/migrations/20261110180500_platform_operations.sql
-- Platform-wide safety switches and scheduled maintenance (service-role only).
create table if not exists public.platform_operations (
  id boolean primary key default true check (id),
  features jsonb not null default '{"referrals":false,"checkout":true,"support":true,"ai":true}'::jsonb,
  maintenance_mode text not null default 'off' check (maintenance_mode in ('off','scheduled','active')),
  maintenance_starts_at timestamptz,
  maintenance_ends_at timestamptz,
  maintenance_message text not null default 'We are improving LaterBox. Please check back shortly.',
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users(id) on delete set null,
  constraint platform_maintenance_valid_window check (
    maintenance_ends_at is null or maintenance_starts_at is null
    or maintenance_ends_at > maintenance_starts_at
  )
);
insert into public.platform_operations(id) values (true) on conflict (id) do nothing;
create table if not exists public.platform_operations_audit (
  id bigint generated always as identity primary key,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target text,
  previous jsonb,
  next jsonb,
  created_at timestamptz not null default now()
);
create index if not exists platform_operations_audit_created on public.platform_operations_audit(created_at desc);
alter table public.platform_operations enable row level security;
alter table public.platform_operations_audit enable row level security;
revoke all on public.platform_operations from anon, authenticated;
revoke all on public.platform_operations_audit from anon, authenticated;
revoke all on sequence public.platform_operations_audit_id_seq from anon, authenticated;
