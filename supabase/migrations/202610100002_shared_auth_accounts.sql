-- Keep application UUIDs independent of the authentication provider.
begin;
create table public.accounts (
  id uuid primary key default gen_random_uuid(),
  email text,
  display_name text,
  state text not null default 'active' check (state in ('active', 'deleting')),
  profile_updated_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.account_identities (
  provider text not null check (provider in ('supabase', 'clerk')),
  subject text not null,
  account_id uuid not null references public.accounts(id) on delete cascade,
  primary key (provider, subject),
  unique (provider, account_id)
);
create table public.auth_provider_issuers (
  issuer text primary key,
  provider text not null check (provider in ('supabase', 'clerk'))
);
insert into public.auth_provider_issuers values
  ('https://ltjisrgldssqskcylcbj.supabase.co/auth/v1', 'supabase'),
  ('http://127.0.0.1:54321/auth/v1', 'supabase'),
  ('http://localhost:54321/auth/v1', 'supabase'),
  ('https://clerk.laterbox.dev', 'clerk'),
  ('https://powerful-rooster-1708.clerk.accounts.dev', 'clerk')
on conflict (issuer) do nothing;
create table public.auth_webhook_events (
  event_id text primary key,
  processed_at timestamptz not null default now()
);
alter table public.accounts enable row level security;
alter table public.account_identities enable row level security;
alter table public.auth_provider_issuers enable row level security;
alter table public.auth_webhook_events enable row level security;
revoke all on public.accounts, public.account_identities, public.auth_provider_issuers, public.auth_webhook_events from anon, authenticated;
grant all on public.accounts, public.account_identities, public.auth_provider_issuers, public.auth_webhook_events to service_role;

insert into public.accounts(id,email,display_name,created_at)
select id,email,coalesce(raw_user_meta_data->>'display_name',raw_user_meta_data->>'name'),created_at from auth.users;
insert into public.account_identities(provider,subject,account_id)
select 'supabase',id::text,id from auth.users;

create function public.current_account_id() returns uuid
language sql stable security definer set search_path = '' as $$
  select i.account_id from public.account_identities i
  join public.auth_provider_issuers p on p.provider=i.provider
  join public.accounts a on a.id=i.account_id and a.state='active'
  where p.issuer=auth.jwt()->>'iss' and i.subject=auth.jwt()->>'sub'
$$;
revoke all on function public.current_account_id() from public;
grant execute on function public.current_account_id() to authenticated, service_role;

create function public.register_supabase_account() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  insert into public.accounts(id,email,display_name,created_at)
  values(new.id,new.email,new.raw_user_meta_data->>'display_name',new.created_at)
  on conflict(id) do nothing;
  insert into public.account_identities(provider,subject,account_id)
  values('supabase',new.id::text,new.id) on conflict do nothing;
  return new;
end $$;
create trigger register_application_account after insert on auth.users
for each row execute function public.register_supabase_account();

-- Preserve each foreign key's column, delete action, and deferrability.
do $$ declare fk record; definition text;
begin
  for fk in select c.conname,c.conrelid::regclass as relation,pg_get_constraintdef(c.oid) as definition
    from pg_constraint c join pg_class r on r.oid=c.conrelid join pg_namespace n on n.oid=r.relnamespace
    where c.contype='f' and c.confrelid='auth.users'::regclass and n.nspname='public'
  loop
    definition := replace(fk.definition,'REFERENCES auth.users','REFERENCES public.accounts');
    execute format('alter table %s drop constraint %I',fk.relation,fk.conname);
    execute format('alter table %s add constraint %I %s',fk.relation,fk.conname,definition);
  end loop;
end $$;

-- Rewrite the current policy/function definitions, rather than historical migrations.
do $$ declare r record; definition text; clause text;
begin
  for r in select p.oid from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.prokind='f' and
      (p.prosrc like '%auth.uid()%' or pg_get_function_arguments(p.oid) like '%auth.uid()%')
  loop
    definition := replace(pg_get_functiondef(r.oid),'auth.uid()','public.current_account_id()');
    execute definition;
  end loop;
  for r in select p.polname,p.polrelid::regclass as relation,
    pg_get_expr(p.polqual,p.polrelid) as qual,pg_get_expr(p.polwithcheck,p.polrelid) as check_expr
    from pg_policy p join pg_class c on c.oid=p.polrelid join pg_namespace n on n.oid=c.relnamespace
    where n.nspname in ('public','storage')
  loop
    clause := '';
    if r.qual like '%auth.uid()%' then
      clause := clause || ' using (' || replace(r.qual,'auth.uid()','public.current_account_id()') || ')';
    end if;
    if r.check_expr like '%auth.uid()%' then
      clause := clause || ' with check (' || replace(r.check_expr,'auth.uid()','public.current_account_id()') || ')';
    end if;
    if clause <> '' then execute format('alter policy %I on %s%s',r.polname,r.relation,clause); end if;
  end loop;
end $$;

-- One RPC transaction prevents two Clerk identities from claiming one account.
create function public.link_clerk_identity(p_account_id uuid,p_subject text) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform 1 from public.accounts where id=p_account_id and state='active' for update;
  if not found then raise exception 'Account unavailable'; end if;
  insert into public.account_identities(provider,subject,account_id)
  values('clerk',p_subject,p_account_id) on conflict(provider,subject) do nothing;
  if not exists(select 1 from public.account_identities where provider='clerk' and subject=p_subject and account_id=p_account_id) then
    raise exception 'Identity conflict';
  end if;
end $$;
revoke all on function public.link_clerk_identity(uuid,text) from public,anon,authenticated;
grant execute on function public.link_clerk_identity(uuid,text) to service_role;

-- A linked account must revoke Clerk too; old clients cannot bypass server cleanup.
create or replace function public.delete_user_account() returns jsonb
language plpgsql security definer set search_path = '' as $$
declare uid uuid := public.current_account_id();
begin
  if uid is null then raise exception 'Not authenticated'; end if;
  if exists(select 1 from public.account_identities where account_id=uid and provider='clerk') then
    raise exception 'Use the account deletion endpoint for linked accounts';
  end if;
  delete from public.accounts where id=uid;
  delete from auth.users where id=uid;
  return jsonb_build_object('success',true,'user_id',uid);
end $$;
commit;
