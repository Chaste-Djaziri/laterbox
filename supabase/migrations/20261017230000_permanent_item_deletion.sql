-- Only the storage service may finish deleting an item after R2 cleanup succeeds.
create or replace function public.finish_permanent_item_deletion(target_item_id uuid, owner_id uuid)
returns void language plpgsql security invoker set search_path = public as $$
begin
  if exists(select 1 from public.items where id = target_item_id and user_id <> owner_id) then
    raise exception 'Unauthorized item ownership';
  end if;
  delete from public.attachments where item_id = target_item_id and user_id = owner_id;
  delete from public.items where id = target_item_id and user_id = owner_id;
end;
$$;
revoke all on function public.finish_permanent_item_deletion(uuid, uuid) from public, anon, authenticated;
grant execute on function public.finish_permanent_item_deletion(uuid, uuid) to service_role;
