-- LaterBox Earn: server-verified affiliate referrals, commissions and Whop transfers.
-- Deploy after 202611080001_whop_storage_plans.sql. No payment is sent by this migration.
create table if not exists public.affiliate_program_settings (
  id boolean primary key default true check (id = true),
  enabled boolean not null default false,
  automatic_payouts boolean not null default false,
  plus_commission_bps integer not null default 1000 check (plus_commission_bps between 0 and 5000),
  vault_commission_bps integer not null default 1500 check (vault_commission_bps between 0 and 5000),
  hold_days integer not null default 30 check (hold_days between 14 and 180),
  minimum_payout_cents integer not null default 1000 check (minimum_payout_cents between 100 and 100000),
  updated_at timestamptz not null default now()
);
insert into public.affiliate_program_settings(id) values(true) on conflict do nothing;

create table if not exists public.affiliate_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  referral_code text not null unique check (referral_code ~ '^[A-Za-z0-9_-]{8,32}$'),
  role text not null check (role in ('plus_partner','vault_ambassador')),
  commission_bps integer not null check (commission_bps between 0 and 5000),
  status text not null default 'active' check(status in ('active','suspended')),
  verified_whop_user_id text unique check(verified_whop_user_id is null or verified_whop_user_id ~ '^user_[A-Za-z0-9_-]+$'),
  age_confirmed_at timestamptz not null,
  approved_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index if not exists affiliate_profiles_status_idx on public.affiliate_profiles(status);

create table if not exists public.affiliate_paid_receipts (
  whop_payment_id text primary key check(whop_payment_id ~ '^pay_[A-Za-z0-9_-]+$'),
  buyer_user_id uuid not null references auth.users(id) on delete cascade,
  membership_id text not null,
  paid_at timestamptz not null,
  refunded_at timestamptz,
  amount_cents bigint not null check(amount_cents >= 0),
  created_at timestamptz not null default now()
);
create index if not exists affiliate_paid_receipts_user_idx on public.affiliate_paid_receipts(buyer_user_id,paid_at);

alter table public.billing_checkout_intents
  add column if not exists affiliate_user_id uuid references public.affiliate_profiles(user_id) on delete set null;

create table if not exists public.affiliate_referrals (
  id uuid primary key default gen_random_uuid(),
  affiliate_user_id uuid not null references public.affiliate_profiles(user_id) on delete cascade,
  buyer_user_id uuid not null unique references auth.users(id) on delete cascade,
  first_payment_id text not null unique,
  created_at timestamptz not null default now(),
  constraint affiliate_no_self_referral check (affiliate_user_id <> buyer_user_id)
);
create index if not exists affiliate_referrals_owner_idx on public.affiliate_referrals(affiliate_user_id,created_at desc);

create table if not exists public.affiliate_commissions (
  id uuid primary key default gen_random_uuid(),
  referral_id uuid not null unique references public.affiliate_referrals(id) on delete cascade,
  affiliate_user_id uuid not null references public.affiliate_profiles(user_id) on delete cascade,
  payment_id text not null unique,
  net_amount_cents bigint not null check(net_amount_cents > 0),
  commission_cents bigint not null check(commission_cents > 0),
  commission_bps integer not null check(commission_bps between 0 and 5000),
  currency text not null default 'usd' check(currency='usd'),
  status text not null default 'pending' check(status in ('pending','available','processing','paid','reversed')),
  hold_until timestamptz not null,
  payout_id uuid,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);
create index if not exists affiliate_commissions_owner_idx on public.affiliate_commissions(affiliate_user_id,created_at desc);
create index if not exists affiliate_commissions_settle_idx on public.affiliate_commissions(status,hold_until);

create table if not exists public.affiliate_payouts (
  id uuid primary key default gen_random_uuid(),
  affiliate_user_id uuid not null references public.affiliate_profiles(user_id) on delete cascade,
  amount_cents bigint not null check(amount_cents > 0),
  currency text not null default 'usd' check(currency='usd'),
  idempotence_key text not null unique,
  whop_transfer_id text unique,
  status text not null default 'processing' check(status in ('processing','paid','failed')),
  failure_message text,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);
alter table public.affiliate_commissions
  add constraint affiliate_commissions_payout_fk foreign key (payout_id)
  references public.affiliate_payouts(id) on delete set null;

-- Financial rows are viewable by their owners, but only trusted backend/service
-- role may modify them. No client-supplied commission, recipient or payout values.
alter table public.affiliate_program_settings enable row level security;
alter table public.affiliate_profiles enable row level security;
alter table public.affiliate_paid_receipts enable row level security;
alter table public.affiliate_referrals enable row level security;
alter table public.affiliate_commissions enable row level security;
alter table public.affiliate_payouts enable row level security;

revoke all on public.affiliate_program_settings, public.affiliate_profiles,
  public.affiliate_paid_receipts, public.affiliate_referrals,
  public.affiliate_commissions, public.affiliate_payouts from anon, authenticated;
grant all on public.affiliate_program_settings, public.affiliate_profiles,
  public.affiliate_paid_receipts, public.affiliate_referrals,
  public.affiliate_commissions, public.affiliate_payouts to service_role;
grant select on public.affiliate_profiles,public.affiliate_referrals,
  public.affiliate_commissions,public.affiliate_payouts to authenticated;

create policy "Affiliate sees own profile" on public.affiliate_profiles
  for select to authenticated using (auth.uid()=user_id);
create policy "Affiliate sees own referrals" on public.affiliate_referrals
  for select to authenticated using (auth.uid()=affiliate_user_id);
create policy "Affiliate sees own commissions" on public.affiliate_commissions
  for select to authenticated using (auth.uid()=affiliate_user_id);
create policy "Affiliate sees own payouts" on public.affiliate_payouts
  for select to authenticated using (auth.uid()=affiliate_user_id);

-- Atomic claim avoids double-queuing the same earnings if two cron workers race.
create or replace function public.affiliate_claim_payout(
  target_affiliate uuid, payout_minimum bigint
) returns uuid language plpgsql security definer set search_path=public as $$
declare total_cents bigint; result_id uuid;
begin
  perform pg_advisory_xact_lock(hashtextextended('affiliate:'||target_affiliate::text,0));
  if exists (select 1 from public.affiliate_payouts where affiliate_user_id=target_affiliate and status in ('processing','failed')) then
    return null;
  end if;
  select coalesce(sum(commission_cents),0) into total_cents
    from public.affiliate_commissions where affiliate_user_id=target_affiliate and status='available';
  if total_cents < payout_minimum then return null; end if;
  insert into public.affiliate_payouts(affiliate_user_id,amount_cents,idempotence_key)
    values(target_affiliate,total_cents,'laterbox-affiliate-'||gen_random_uuid()::text)
    returning id into result_id;
  update public.affiliate_commissions set status='processing',payout_id=result_id
    where affiliate_user_id=target_affiliate and status='available';
  return result_id;
end;
$$;
revoke all on function public.affiliate_claim_payout(uuid,bigint) from public,anon,authenticated;
grant execute on function public.affiliate_claim_payout(uuid,bigint) to service_role;

-- Aggregate ALL earnings, independently of the activity-history page size.
create or replace function public.affiliate_balance_totals(target_user_id uuid)
returns table(pending_cents bigint,available_cents bigint,processing_cents bigint,
              paid_cents bigint,reversed_cents bigint)
language sql stable security definer set search_path=public as $$
  select
    coalesce(sum(commission_cents) filter (where status='pending'),0)::bigint,
    coalesce(sum(commission_cents) filter (where status='available'),0)::bigint,
    coalesce(sum(commission_cents) filter (where status='processing'),0)::bigint,
    coalesce(sum(commission_cents) filter (where status='paid'),0)::bigint,
    coalesce(sum(commission_cents) filter (where status='reversed'),0)::bigint
  from public.affiliate_commissions
  where affiliate_user_id=target_user_id
$$;
revoke all on function public.affiliate_balance_totals(uuid) from public,anon,authenticated;
grant execute on function public.affiliate_balance_totals(uuid) to service_role;
