-- LaterBox Earn V2: all-account codes, trial reservations, and recurring ledger.
-- Any account can refer; only verified paid renewals earn commissions.
alter table public.affiliate_profiles alter column role drop not null;
alter table public.affiliate_profiles alter column commission_bps set default 1000;
alter table public.affiliate_profiles alter column age_confirmed_at drop not null;
alter table public.affiliate_profiles add column if not exists code_changed_at timestamptz;
create unique index if not exists affiliate_profiles_code_ci_key on public.affiliate_profiles(lower(referral_code));

create or replace function public.ensure_laterbox_referral(target_user uuid)
returns void language plpgsql security definer set search_path=public as $$
begin
  insert into public.affiliate_profiles(user_id,referral_code,role,commission_bps,status,age_confirmed_at)
  values(target_user,'lb_'||substr(replace(gen_random_uuid()::text,'-',''),1,24),null,1000,'active',null)
  on conflict (user_id) do nothing;
end;
$$;
revoke all on function public.ensure_laterbox_referral(uuid) from public,anon,authenticated;
grant execute on function public.ensure_laterbox_referral(uuid) to service_role;

create or replace function public.laterbox_new_user_referral()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  perform public.ensure_laterbox_referral(new.id);
  return new;
end;
$$;
drop trigger if exists after_laterbox_user_created_referral on auth.users;
create trigger after_laterbox_user_created_referral after insert on auth.users
  for each row execute function public.laterbox_new_user_referral();
insert into public.affiliate_profiles(user_id,referral_code,role,commission_bps,status,age_confirmed_at)
select id,'lb_'||substr(replace(gen_random_uuid()::text,'-',''),1,24),null,1000,'active',null
from auth.users on conflict(user_id) do nothing;

alter table public.affiliate_program_settings add column if not exists trial_enabled boolean not null default false;
alter table public.affiliate_program_settings add column if not exists trial_days integer not null default 30
  check(trial_days between 28 and 31);
alter table public.affiliate_program_settings add column if not exists intro_commission_bps integer not null default 1500
  check(intro_commission_bps between 0 and 5000);
alter table public.affiliate_program_settings add column if not exists ongoing_commission_bps integer not null default 1000
  check(ongoing_commission_bps between 0 and 5000);
alter table public.affiliate_program_settings add column if not exists intro_payment_count integer not null default 12
  check(intro_payment_count between 1 and 60);
update public.affiliate_program_settings set enabled=false,automatic_payouts=false,
  trial_enabled=false,intro_commission_bps=1500,ongoing_commission_bps=1000 where id=true;

create table if not exists public.affiliate_trial_claims (
  buyer_user_id uuid primary key references auth.users(id) on delete cascade,
  affiliate_user_id uuid not null references public.affiliate_profiles(user_id) on delete cascade,
  checkout_intent_id uuid not null unique references public.billing_checkout_intents(id) on delete cascade,
  plan_key text not null check(plan_key ~ '^[a-z0-9_]+_(month|year)$'),
  status text not null default 'reserved' check(status in('reserved','trialing','qualified','expired')),
  membership_id text unique,
  started_at timestamptz,
  trial_ends_at timestamptz,
  qualified_at timestamptz,
  created_at timestamptz not null default now(),
  check(buyer_user_id <> affiliate_user_id)
);
create index if not exists affiliate_trial_claims_affiliate_idx
  on public.affiliate_trial_claims(affiliate_user_id,created_at desc);
alter table public.affiliate_trial_claims enable row level security;
revoke all on public.affiliate_trial_claims from anon,authenticated;
grant all on public.affiliate_trial_claims to service_role;
grant select on public.affiliate_trial_claims to authenticated;
create policy "Referrer sees owned trial progress" on public.affiliate_trial_claims
 for select to authenticated using(auth.uid()=affiliate_user_id);
create policy "Buyer sees own referral trial" on public.affiliate_trial_claims
 for select to authenticated using(auth.uid()=buyer_user_id);

alter table public.affiliate_commissions drop constraint if exists affiliate_commissions_referral_id_key;
create index if not exists affiliate_commissions_referral_idx
 on public.affiliate_commissions(referral_id,created_at desc);
alter table public.affiliate_commissions add column if not exists membership_id text;
alter table public.affiliate_commissions add column if not exists billing_cycle integer;
alter table public.affiliate_referrals alter column first_payment_id drop not null;
alter table public.affiliate_referrals add column if not exists membership_id text unique;
alter table public.affiliate_referrals add column if not exists qualified_at timestamptz;
alter table public.affiliate_referrals add column if not exists referred_at timestamptz;
alter table public.affiliate_referrals add column if not exists trial_end_at timestamptz;

create or replace function public.affiliate_reserve_trial(
  buyer uuid, affiliate uuid, checkout uuid, selected_plan text
) returns boolean language plpgsql security definer set search_path=public as $$
begin
  if buyer=affiliate then return false; end if;
  if exists(select 1 from public.billing_subscriptions where user_id=buyer) then return false; end if;
  if exists(select 1 from public.affiliate_trial_claims where buyer_user_id=buyer) then return false; end if;
  insert into public.affiliate_trial_claims(buyer_user_id,affiliate_user_id,checkout_intent_id,plan_key)
    values(buyer,affiliate,checkout,selected_plan) on conflict do nothing;
  return found;
end;
$$;
revoke all on function public.affiliate_reserve_trial(uuid,uuid,uuid,text) from public,anon,authenticated;
grant execute on function public.affiliate_reserve_trial(uuid,uuid,uuid,text) to service_role;
