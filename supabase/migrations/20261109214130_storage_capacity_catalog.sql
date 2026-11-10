-- LaterBox storage quotas, enforced via the existing upload reservation RPC.
-- Apply after 202611080001_whop_storage_plans.sql and before publishing expanded checkout.
-- Existing subscriptions keep the original 10 GiB / 100 GiB limits.
alter table public.billing_checkout_intents
  drop constraint if exists billing_checkout_intents_plan_key_check;
alter table public.billing_checkout_intents
  add constraint billing_checkout_intents_plan_key_check
  check (plan_key ~ '^[a-z0-9_]+_(month|year)$');

create table if not exists public.billing_storage_skus (
  provider_price_id text primary key check (provider_price_id ~ '^plan_[A-Za-z0-9_-]+$'),
  sku_key text not null unique check (sku_key ~ '^[a-z0-9_]+$'),
  family text not null check (family in ('plus','vault')),
  quota_bytes bigint not null check (quota_bytes between 10737418240 and 2199023255552),
  trial_days integer not null default 0 check (trial_days in (0,30)),
  created_at timestamptz not null default now()
);
alter table public.billing_storage_skus enable row level security;
revoke all on public.billing_storage_skus from anon, authenticated;
grant all on public.billing_storage_skus to service_role;

-- Whop trials have a disclosed 10 GiB trial upload quota even for larger plans.
-- The full purchased capacity unlocks on an active subscription.
create or replace function public.account_storage_limit_bytes(target_user_id uuid)
returns bigint language sql stable security definer set search_path = public as $$
  with eligible as (
    select b.provider,b.price_id,b.status,b.storage_plan,
           s.quota_bytes,s.trial_days
    from public.billing_subscriptions b
    left join public.billing_storage_skus s on
      b.provider = 'whop' and b.price_id = s.provider_price_id
    where b.user_id = target_user_id
      and b.revoked_at is null
      and (b.current_period_ends_at is null or b.current_period_ends_at > now())
      and (
        b.status in ('active','trialing') or
        (b.status='canceled' and b.current_period_ends_at > now()) or
        (b.status='past_due' and coalesce(b.past_due_at,b.updated_at) + interval '7 days' > now())
      )
  )
  select greatest(
    coalesce((
      select max(
        case
          when b.provider='whop' and b.status='trialing' then
            least(coalesce(b.quota_bytes,case when b.storage_plan='vault'
              then 107374182400::bigint else 10737418240::bigint end),
              10737418240::bigint)
          when b.provider='whop' then
            coalesce(b.quota_bytes,case when b.storage_plan='vault'
              then 107374182400::bigint else 10737418240::bigint end)
          when b.storage_plan='vault' then 107374182400::bigint
          else 10737418240::bigint
        end
      ) from eligible b
    ),0),
    case when exists (
      select 1 from public.billing_entitlement_grants g
      where g.user_id=target_user_id and g.starts_at<=now() and g.expires_at>now()
    ) then 10737418240::bigint else 524288000::bigint end
  )
$$;
revoke all on function public.account_storage_limit_bytes(uuid) from public, anon, authenticated;
grant execute on function public.account_storage_limit_bytes(uuid) to service_role;

-- Server-reviewed production Whop catalog snapshot, verified Nov 9, 2026.
insert into public.billing_storage_skus (provider_price_id,sku_key,family,quota_bytes,trial_days)
values
  ('plan_xHUtJJyIKLpLU','plus_month','plus',10::bigint * 1073741824,0),
  ('plan_e52tpQuj8D86e','plus_year','plus',10::bigint * 1073741824,0),
  ('plan_eqKzcvPxQeNjC','plus50_month','plus',50::bigint * 1073741824,0),
  ('plan_PAr2qgdyrrGGJ','plus50_year','plus',50::bigint * 1073741824,0),
  ('plan_zedik0IB8wVaz','vault_month','vault',100::bigint * 1073741824,0),
  ('plan_BJQnA897vsZpY','vault_year','vault',100::bigint * 1073741824,0),
  ('plan_GwxkaSjb7bmTT','vault250_month','vault',250::bigint * 1073741824,0),
  ('plan_HeIkWcvPqrpgh','vault250_year','vault',250::bigint * 1073741824,0),
  ('plan_mvAhgWv9Jxfsm','vault500_month','vault',500::bigint * 1073741824,0),
  ('plan_354JRUA2vhDlC','vault500_year','vault',500::bigint * 1073741824,0),
  ('plan_C1Qbsh7wX2Njr','vault1tb_month','vault',1024::bigint * 1073741824,0),
  ('plan_4mF2Q4DlERgQE','vault1tb_year','vault',1024::bigint * 1073741824,0),
  ('plan_Pu4NVn48HX3Vt','vault2tb_month','vault',2048::bigint * 1073741824,0),
  ('plan_Ar6OXWGUEvYNa','vault2tb_year','vault',2048::bigint * 1073741824,0)
on conflict (provider_price_id) do update set
  sku_key=excluded.sku_key,family=excluded.family,
  quota_bytes=excluded.quota_bytes,trial_days=excluded.trial_days;
