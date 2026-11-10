-- supabase/migrations/20261110110831_platform_roles_admin.sql
-- Server-only platform authorization, distinct from Whop's external business roles.
create table if not exists public.platform_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('owner','admin','support','analyst')),
  granted_by uuid references auth.users(id) on delete set null,
  granted_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.platform_role_audit (
  id bigint generated always as identity primary key,
  actor_user_id uuid references auth.users(id) on delete set null,
  target_user_id uuid not null references auth.users(id) on delete cascade,
  previous_role text,
  next_role text,
  created_at timestamptz not null default now(),
  constraint platform_role_audit_next_role_check check (next_role is null or next_role in ('owner','admin','support','analyst'))
);
create index if not exists platform_role_audit_recent on public.platform_role_audit (created_at desc);
alter table public.platform_roles enable row level security;
alter table public.platform_role_audit enable row level security;
revoke all on public.platform_roles from anon, authenticated;
revoke all on public.platform_role_audit from anon, authenticated;
revoke all on sequence public.platform_role_audit_id_seq from anon, authenticated;
-- Bootstrap only this verified LaterBox user ID after matching verified Whop account and email.
insert into public.platform_roles(user_id,role,granted_by)
select u.id,'owner',u.id from auth.users u
join public.affiliate_profiles ap on ap.user_id=u.id
where u.id='c64e5f63-1a87-46d9-a8a6-6a5f846d2356'::uuid
  and lower(u.email)='habimanahirwa@gmail.com'
  and u.email_confirmed_at is not null
  and ap.verified_whop_user_id is not null
on conflict (user_id) do nothing;
