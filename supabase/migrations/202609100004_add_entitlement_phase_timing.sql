alter table public.billing_subscriptions
  add column if not exists current_period_starts_at timestamptz;

drop function if exists public.get_my_entitlement();

create or replace function public.get_my_entitlement()
returns table (
  tier text,
  status text,
  provider text,
  trial_ends_at timestamptz,
  access_ends_at timestamptz,
  will_cancel boolean,
  billing_warning text,
  phase_starts_at timestamptz,
  phase_ends_at timestamptz
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
      case
        when s.status = 'past_due' then coalesce(s.past_due_at, s.updated_at)
        else coalesce(s.current_period_starts_at, s.created_at)
      end as phase_starts_at,
      case
        when s.status = 'trialing' then coalesce(s.trial_ends_at, s.current_period_ends_at)
        when s.status = 'past_due' then least(
          coalesce(s.current_period_ends_at, 'infinity'::timestamptz),
          coalesce(s.past_due_at, s.updated_at) + interval '7 days'
        )
        else s.current_period_ends_at
      end as phase_ends_at,
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
      g.starts_at as phase_starts_at,
      g.expires_at as phase_ends_at,
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
    e.billing_warning,
    e.phase_starts_at,
    e.phase_ends_at
  from (select 1) seed
  left join entitlement e on true;
$$;

grant execute on function public.get_my_entitlement() to authenticated;
