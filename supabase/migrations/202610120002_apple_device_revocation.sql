-- Accept a newer Apple-signed device refund without losing webhook ordering.
create or replace function public.apply_apple_subscription(p_subscription jsonb, p_notification boolean default false)
returns void language plpgsql security definer set search_path = public as $$
declare
  incoming public.billing_subscriptions;
  current_row public.billing_subscriptions;
begin
  incoming := jsonb_populate_record(null::public.billing_subscriptions, p_subscription);
  if incoming.provider <> 'apple' or incoming.apple_environment not in ('Sandbox', 'Production')
     or incoming.user_id is null or incoming.apple_transaction_id is null then
    raise exception 'Invalid verified Apple subscription';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('apple:' || incoming.subscription_id, 0));
  select * into current_row from public.billing_subscriptions
    where provider = 'apple' and subscription_id = incoming.subscription_id for update;
  if found then
    if current_row.user_id <> incoming.user_id or (current_row.apple_environment is not null
       and current_row.apple_environment <> incoming.apple_environment) then
      raise exception 'Apple subscription ownership or environment mismatch';
    end if;
    if incoming.current_period_starts_at < current_row.current_period_starts_at then return; end if;
    if p_notification then
      if incoming.apple_notification_at <= current_row.apple_notification_at then return; end if;
      if current_row.revoked_at is not null and incoming.revoked_at is null
         and incoming.apple_transaction_id = current_row.apple_transaction_id
         and incoming.apple_notification_at <= current_row.occurred_at then return; end if;
    elsif incoming.apple_transaction_id = current_row.apple_transaction_id then
      if incoming.occurred_at <= current_row.occurred_at then return; end if;
      if incoming.revoked_at is null and (current_row.apple_notification_at is not null
         or current_row.revoked_at is not null) then return; end if;
    end if;
  end if;
  insert into public.billing_customers(provider, customer_id, user_id, updated_at)
    values ('apple', incoming.customer_id, incoming.user_id, now())
    on conflict (provider, customer_id) do update set updated_at = excluded.updated_at;
  insert into public.billing_subscriptions (
    provider, subscription_id, customer_id, user_id, status, product_id, price_id,
    trial_ends_at, current_period_starts_at, current_period_ends_at,
    scheduled_change_action, scheduled_change_at, past_due_at, occurred_at,
    apple_environment, apple_transaction_id, apple_notification_at, revoked_at
  ) values (
    'apple', incoming.subscription_id, incoming.customer_id, incoming.user_id, incoming.status,
    incoming.product_id, incoming.price_id, incoming.trial_ends_at,
    incoming.current_period_starts_at, incoming.current_period_ends_at,
    incoming.scheduled_change_action, incoming.scheduled_change_at,
    incoming.past_due_at, incoming.occurred_at, incoming.apple_environment,
    incoming.apple_transaction_id, incoming.apple_notification_at, incoming.revoked_at
  ) on conflict (provider, subscription_id) do update set
    status = excluded.status, product_id = excluded.product_id, price_id = excluded.price_id,
    trial_ends_at = excluded.trial_ends_at,
    current_period_starts_at = excluded.current_period_starts_at,
    current_period_ends_at = excluded.current_period_ends_at,
    scheduled_change_action = case when (p_subscription->>'renewal_known')::boolean then excluded.scheduled_change_action else current_row.scheduled_change_action end,
    scheduled_change_at = case when (p_subscription->>'renewal_known')::boolean then excluded.scheduled_change_at
      when current_row.scheduled_change_action = 'cancel' then excluded.current_period_ends_at else null end,
    past_due_at = case when excluded.status = 'past_due' then coalesce(current_row.past_due_at, excluded.past_due_at) else null end,
    occurred_at = excluded.occurred_at, updated_at = now(),
    apple_environment = excluded.apple_environment, apple_transaction_id = excluded.apple_transaction_id,
    apple_notification_at = case when not p_notification and excluded.apple_transaction_id = current_row.apple_transaction_id
      then current_row.apple_notification_at else excluded.apple_notification_at end,
    revoked_at = excluded.revoked_at;
end;
$$;
revoke all on function public.apply_apple_subscription(jsonb, boolean) from public, anon, authenticated;
grant execute on function public.apply_apple_subscription(jsonb, boolean) to service_role;
