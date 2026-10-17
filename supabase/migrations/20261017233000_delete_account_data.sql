-- Remove every application-owned record before the authentication identity is deleted.
-- Storage objects are removed by the account deletion endpoint before this RPC runs.
create or replace function public.delete_account_data(target_account_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if target_account_id is null then
    raise exception 'Account id is required';
  end if;

  delete from public.collection_items
  where user_id = target_account_id
     or collection_id in (select id from public.collections where user_id = target_account_id)
     or item_id in (select id from public.items where user_id = target_account_id);

  delete from public.notification_deliveries
  where event_id in (select id from public.notification_events where user_id = target_account_id)
     or installation_id in (select id from public.notification_installations where user_id = target_account_id);
  delete from public.notification_events where user_id = target_account_id;
  delete from public.notification_installations where user_id = target_account_id;

  delete from public.extension_free_items where user_id = target_account_id;
  delete from public.item_content where user_id = target_account_id;
  delete from public.item_notes where user_id = target_account_id;
  delete from public.item_metadata where user_id = target_account_id;
  delete from public.attachments where user_id = target_account_id;
  delete from public.item_deletion_receipts where user_id = target_account_id;
  delete from public.items where user_id = target_account_id;
  delete from public.collections where user_id = target_account_id;

  delete from public.extension_sessions where user_id = target_account_id;
  delete from public.extension_connection_requests where user_id = target_account_id;
  delete from public.support_requests where user_id = target_account_id;

  delete from public.billing_entitlement_grants where user_id = target_account_id;
  delete from public.billing_subscriptions where user_id = target_account_id;
  delete from public.billing_customers where user_id = target_account_id;
  delete from public.billing_apple_purchase_links where user_id = target_account_id;

  delete from public.account_identities where account_id = target_account_id;
  delete from public.accounts where id = target_account_id;
end;
$$;

revoke all on function public.delete_account_data(uuid) from public, anon, authenticated;
grant execute on function public.delete_account_data(uuid) to service_role;
