create or replace function public.has_pro_entitlement(target_user_id uuid default auth.uid())
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select target_user_id = auth.uid() and (
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

revoke all on function public.has_pro_entitlement(uuid) from public;
grant execute on function public.has_pro_entitlement(uuid) to authenticated;

do $$
declare
  table_name text;
  policy_name text;
begin
  foreach table_name in array array['items', 'item_metadata', 'item_notes', 'collections', 'collection_items', 'attachments']
  loop
    for policy_name in
      select policyname from pg_policies where schemaname = 'public' and tablename = table_name
    loop
      execute format('drop policy %I on public.%I', policy_name, table_name);
    end loop;

    execute format(
      'create policy %I on public.%I for select to authenticated using (auth.uid() = user_id and public.has_pro_entitlement(user_id))',
      'Pro users read own ' || table_name,
      table_name
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (auth.uid() = user_id and public.has_pro_entitlement(user_id))',
      'Pro users insert own ' || table_name,
      table_name
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using (auth.uid() = user_id and public.has_pro_entitlement(user_id)) with check (auth.uid() = user_id and public.has_pro_entitlement(user_id))',
      'Pro users update own ' || table_name,
      table_name
    );
    execute format(
      'create policy %I on public.%I for delete to authenticated using (auth.uid() = user_id and public.has_pro_entitlement(user_id))',
      'Pro users delete own ' || table_name,
      table_name
    );
  end loop;
end;
$$;
