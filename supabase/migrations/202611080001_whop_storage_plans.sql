-- Whop checkout ownership and storage tiers. Deploy before enabling new checkout.
-- Do not migrate or terminate existing Paddle/Apple subscriptions.
alter table public.billing_customers drop constraint if exists billing_customers_provider_check;
alter table public.billing_customers add constraint billing_customers_provider_check
  check (provider in ('paddle','apple','whop'));
alter table public.billing_subscriptions drop constraint if exists billing_subscriptions_provider_check;
alter table public.billing_subscriptions add constraint billing_subscriptions_provider_check
  check (provider in ('paddle','apple','whop'));
alter table public.billing_webhook_events drop constraint if exists billing_webhook_events_provider_check;
alter table public.billing_webhook_events add constraint billing_webhook_events_provider_check
  check (provider in ('paddle','apple','whop'));

alter table public.billing_subscriptions add column if not exists storage_plan text;
alter table public.billing_subscriptions drop constraint if exists billing_subscriptions_storage_plan_check;
alter table public.billing_subscriptions add constraint billing_subscriptions_storage_plan_check
  check (storage_plan is null or storage_plan in ('plus','vault'));

-- Every checkout is owned by an authenticated user BEFORE a charge is initiated.
create table if not exists public.billing_checkout_intents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'whop' check (provider='whop'),
  plan_key text not null check (plan_key in ('plus_month','plus_year','vault_month','vault_year')),
  plan_id text not null,
  checkout_id text unique,
  status text not null default 'pending' check (status in ('pending','fulfilled','failed')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now()+interval '30 minutes')
);
create index if not exists billing_checkout_intents_owner_idx on public.billing_checkout_intents(user_id,created_at desc);
alter table public.billing_checkout_intents enable row level security;
create policy "Read own checkout intents" on public.billing_checkout_intents
  for select to authenticated using (auth.uid()=user_id);
revoke all on public.billing_checkout_intents from anon, authenticated;
grant select on public.billing_checkout_intents to authenticated;
grant all on public.billing_checkout_intents to service_role;

-- Entitlements are enforced server-side, not by browser-reported usage.
create or replace function public.account_storage_limit_bytes(target_user_id uuid)
returns bigint language sql stable security definer set search_path=public as $$
  select case
    when exists (
      select 1 from public.billing_subscriptions b
      where b.user_id=target_user_id and b.storage_plan='vault'
        and (b.status in ('active','trialing') or
          (b.status='canceled' and b.current_period_ends_at>now()) or
          (b.status='past_due' and coalesce(b.past_due_at,b.updated_at)+interval '7 days'>now()))
        and (b.current_period_ends_at is null or b.current_period_ends_at>now())
        and b.revoked_at is null
    ) then 107374182400::bigint
    when exists (
      select 1 from public.billing_subscriptions b
      where b.user_id=target_user_id
        and (b.storage_plan='plus' or (b.provider in ('apple','paddle') and b.storage_plan is null))
        and (b.status in ('active','trialing') or
          (b.status='canceled' and b.current_period_ends_at>now()) or
          (b.status='past_due' and coalesce(b.past_due_at,b.updated_at)+interval '7 days'>now()))
        and (b.current_period_ends_at is null or b.current_period_ends_at>now())
        and b.revoked_at is null
    ) or exists (
      select 1 from public.billing_entitlement_grants g
      where g.user_id=target_user_id and g.starts_at<=now() and g.expires_at>now()
    ) then 10737418240::bigint
    else 524288000::bigint
  end
$$;
revoke all on function public.account_storage_limit_bytes(uuid) from public, anon, authenticated;
grant execute on function public.account_storage_limit_bytes(uuid) to service_role;

-- Count only bytes actually published to the user's library.
create or replace function public.account_storage_used_bytes(target_user_id uuid)
returns bigint language sql stable security definer set search_path=public as $$
  select coalesce(sum(byte_size),0)::bigint from public.attachments
  where user_id=target_user_id and deleted_at is null and r2_object_key is not null
$$;
revoke all on function public.account_storage_used_bytes(uuid) from public, anon, authenticated;
grant execute on function public.account_storage_used_bytes(uuid) to service_role;

-- Short-lived upload reservations block concurrent quota bypass.
create table if not exists public.storage_upload_reservations (
  attachment_id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  byte_size bigint not null check (byte_size > 0),
  expires_at timestamptz not null default (now()+interval '30 minutes')
);
create index if not exists storage_upload_reservations_user_idx on public.storage_upload_reservations(user_id,expires_at);
alter table public.storage_upload_reservations enable row level security;
revoke all on public.storage_upload_reservations from anon, authenticated;
grant all on public.storage_upload_reservations to service_role;

create or replace function public.reserve_storage_upload(
  target_user_id uuid, target_attachment_id uuid, requested_bytes bigint
) returns boolean language plpgsql security definer set search_path=public as $$
declare used_bytes bigint; pending_bytes bigint; already_saved bigint;
begin
  if requested_bytes is null or requested_bytes<1 then return false; end if;
  perform pg_advisory_xact_lock(hashtextextended(target_user_id::text, 0));
  select byte_size into already_saved from public.attachments
    where id=target_attachment_id and user_id=target_user_id and deleted_at is null;
  if already_saved is not null then return already_saved=requested_bytes; end if;
  delete from public.storage_upload_reservations where expires_at<=now();
  select coalesce(sum(byte_size),0)::bigint into pending_bytes
    from public.storage_upload_reservations
    where user_id=target_user_id and attachment_id<>target_attachment_id and expires_at>now();
  used_bytes := public.account_storage_used_bytes(target_user_id);
  if used_bytes + pending_bytes + requested_bytes > public.account_storage_limit_bytes(target_user_id) then
    return false;
  end if;
  insert into public.storage_upload_reservations(attachment_id,user_id,byte_size,expires_at)
  values(target_attachment_id,target_user_id,requested_bytes,now()+interval '30 minutes')
  on conflict(attachment_id) do update set
    byte_size=excluded.byte_size,expires_at=excluded.expires_at
    where public.storage_upload_reservations.user_id=excluded.user_id;
  return found;
end;
$$;
revoke all on function public.reserve_storage_upload(uuid,uuid,bigint) from public, anon, authenticated;
grant execute on function public.reserve_storage_upload(uuid,uuid,bigint) to service_role;

create or replace function public.release_storage_upload(
 target_user_id uuid,target_attachment_id uuid
) returns void language sql security definer set search_path=public as $$
 delete from public.storage_upload_reservations
 where user_id=target_user_id and attachment_id=target_attachment_id
$$;
revoke all on function public.release_storage_upload(uuid,uuid) from public, anon, authenticated;
grant execute on function public.release_storage_upload(uuid,uuid) to service_role;
