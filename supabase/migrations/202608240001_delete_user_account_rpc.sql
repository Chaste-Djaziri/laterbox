-- Migration: Add secure delete_user_account RPC function to delete account and all data

create or replace function public.delete_user_account()
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid;
begin
  -- 1. Verify caller is authenticated
  uid := auth.uid();
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  -- 2. Explicitly clean up all user-owned rows across public tables
  delete from public.collection_items
  where collection_id in (select id from public.collections where user_id = uid)
     or item_id in (select id from public.items where user_id = uid);

  delete from public.item_notes where user_id = uid;
  delete from public.item_metadata where item_id in (select id from public.items where user_id = uid);
  delete from public.attachments where user_id = uid;
  delete from public.items where user_id = uid;
  delete from public.collections where user_id = uid;
  delete from public.extension_sessions where user_id = uid;
  delete from public.extension_connection_requests where user_id = uid;

  -- 3. Delete the user from auth.users (cascades any remaining auth/system references)
  delete from auth.users where id = uid;

  return jsonb_build_object(
    'success', true,
    'user_id', uid,
    'message', 'User account and all associated data permanently deleted'
  );
end;
$$;

-- Grant execution to authenticated users
grant execute on function public.delete_user_account() to authenticated;
