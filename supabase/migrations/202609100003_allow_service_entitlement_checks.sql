create or replace function public.has_pro_entitlement(target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select (target_user_id = auth.uid() or auth.role() = 'service_role') and (
    exists (
      select 1 from public.billing_entitlement_grants g
      where g.user_id = target_user_id
        and now() >= g.starts_at and now() < g.expires_at
    ) or exists (
      select 1 from public.billing_subscriptions s
      where s.user_id = target_user_id and (
        s.status in ('active', 'trialing')
        or (s.status = 'past_due' and now() < coalesce(s.past_due_at, s.updated_at) + interval '7 days')
        or (s.status = 'canceled' and now() < s.current_period_ends_at)
      )
    )
  );
$$;
