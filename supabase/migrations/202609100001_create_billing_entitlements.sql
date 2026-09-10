create table if not exists public.billing_customers (
  provider text not null check (provider in ('paddle', 'apple')),
  customer_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (provider, customer_id),
  unique (provider, user_id)
);

create table if not exists public.billing_subscriptions (
  provider text not null check (provider in ('paddle', 'apple')),
  subscription_id text not null,
  customer_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('active', 'trialing', 'past_due', 'paused', 'canceled')),
  product_id text,
  price_id text,
  trial_ends_at timestamptz,
  current_period_ends_at timestamptz,
  scheduled_change_action text,
  scheduled_change_at timestamptz,
  past_due_at timestamptz,
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (provider, subscription_id),
  foreign key (provider, customer_id)
    references public.billing_customers(provider, customer_id)
    on delete cascade
);

create table if not exists public.billing_webhook_events (
  provider text not null check (provider in ('paddle', 'apple')),
  event_id text not null,
  event_type text not null,
  occurred_at timestamptz not null,
  processed_at timestamptz not null default now(),
  primary key (provider, event_id)
);

create table if not exists public.billing_entitlement_grants (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  tier text not null default 'pro' check (tier in ('pro')),
  reason text not null,
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique (user_id, reason)
);

create index if not exists billing_subscriptions_user_id_idx
  on public.billing_subscriptions(user_id);
create index if not exists billing_subscriptions_status_idx
  on public.billing_subscriptions(status);
create index if not exists billing_grants_user_id_idx
  on public.billing_entitlement_grants(user_id);

alter table public.billing_customers enable row level security;
alter table public.billing_subscriptions enable row level security;
alter table public.billing_webhook_events enable row level security;
alter table public.billing_entitlement_grants enable row level security;

create policy "Users read own billing customer"
  on public.billing_customers for select
  using (auth.uid() = user_id);
create policy "Users read own subscriptions"
  on public.billing_subscriptions for select
  using (auth.uid() = user_id);
create policy "Users read own entitlement grants"
  on public.billing_entitlement_grants for select
  using (auth.uid() = user_id);

revoke all on public.billing_webhook_events from anon, authenticated;
revoke insert, update, delete on public.billing_customers from anon, authenticated;
revoke insert, update, delete on public.billing_subscriptions from anon, authenticated;
revoke insert, update, delete on public.billing_entitlement_grants from anon, authenticated;

insert into public.billing_entitlement_grants (user_id, reason, starts_at, expires_at)
select id, 'billing_launch_grace', now(), now() + interval '30 days'
from auth.users
on conflict (user_id, reason) do nothing;

create or replace function public.get_my_entitlement()
returns table (
  tier text,
  status text,
  provider text,
  trial_ends_at timestamptz,
  access_ends_at timestamptz,
  will_cancel boolean,
  billing_warning text
)
language sql
stable
security invoker
set search_path = public
as $$
  with eligible_subscription as (
    select
      s.status,
      s.provider,
      s.trial_ends_at,
      case
        when s.status = 'past_due' then least(
          coalesce(s.current_period_ends_at, 'infinity'::timestamptz),
          coalesce(s.past_due_at, s.updated_at) + interval '7 days'
        )
        else s.current_period_ends_at
      end as access_ends_at,
      s.scheduled_change_action = 'cancel' as will_cancel,
      case when s.status = 'past_due' then 'payment_past_due' end as billing_warning,
      2 as priority
    from public.billing_subscriptions s
    where s.user_id = auth.uid()
      and (
        s.status in ('active', 'trialing')
        or (s.status = 'past_due' and now() < coalesce(s.past_due_at, s.updated_at) + interval '7 days')
        or (s.status = 'canceled' and now() < s.current_period_ends_at)
      )
    order by coalesce(s.current_period_ends_at, 'infinity'::timestamptz) desc
    limit 1
  ), eligible_grant as (
    select
      'granted'::text as status,
      null::text as provider,
      null::timestamptz as trial_ends_at,
      g.expires_at as access_ends_at,
      false as will_cancel,
      null::text as billing_warning,
      1 as priority
    from public.billing_entitlement_grants g
    where g.user_id = auth.uid()
      and now() >= g.starts_at
      and now() < g.expires_at
    order by g.expires_at desc
    limit 1
  ), entitlement as (
    select * from eligible_subscription
    union all
    select * from eligible_grant
    order by priority desc
    limit 1
  )
  select
    case when e.status is null then 'free' else 'pro' end,
    coalesce(e.status, 'free'),
    e.provider,
    e.trial_ends_at,
    e.access_ends_at,
    coalesce(e.will_cancel, false),
    e.billing_warning
  from (select 1) seed
  left join entitlement e on true;
$$;

grant execute on function public.get_my_entitlement() to authenticated;
