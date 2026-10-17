-- Publish the item and all verified attachment references in one transaction.
create or replace function public.publish_item_attachments(item jsonb, assets jsonb)
returns void language plpgsql security invoker set search_path = public as $$
begin
  if auth.uid() is null or (item->>'user_id')::uuid is distinct from auth.uid() then
    raise exception 'Unauthorized item owner';
  end if;
  if jsonb_array_length(assets) = 0 or exists (
    select 1 from jsonb_array_elements(assets) a
    where (a->>'user_id')::uuid is distinct from auth.uid()
       or (a->>'item_id')::uuid is distinct from (item->>'id')::uuid
       or nullif(a->>'r2_object_key', '') is null
  ) then raise exception 'Incomplete attachments'; end if;

  insert into public.items (id, user_id, title, url, text_content, type, favorite, status, return_at, created_at, updated_at, deleted_at)
  values ((item->>'id')::uuid, auth.uid(), item->>'title', item->>'url', item->>'text_content', item->>'type',
    (item->>'favorite')::boolean, item->>'status', (item->>'return_at')::timestamptz,
    (item->>'created_at')::timestamptz, (item->>'updated_at')::timestamptz, (item->>'deleted_at')::timestamptz)
  on conflict (id) do update set title=excluded.title, url=excluded.url, text_content=excluded.text_content,
    type=excluded.type, favorite=excluded.favorite, status=excluded.status, return_at=excluded.return_at,
    updated_at=excluded.updated_at, deleted_at=excluded.deleted_at;

  insert into public.attachments (id, item_id, user_id, original_file_name, file_extension, mime_type, byte_size, sha256, r2_object_key, created_at, updated_at)
  select id, item_id, user_id, original_file_name, file_extension, mime_type, byte_size, sha256, r2_object_key, created_at, updated_at
  from jsonb_populate_recordset(null::public.attachments, assets)
  on conflict (id) do update set item_id=excluded.item_id, original_file_name=excluded.original_file_name,
    file_extension=excluded.file_extension, mime_type=excluded.mime_type, byte_size=excluded.byte_size,
    sha256=excluded.sha256, r2_object_key=excluded.r2_object_key, updated_at=excluded.updated_at, deleted_at=null;
end;
$$;
revoke all on function public.publish_item_attachments(jsonb, jsonb) from public;
grant execute on function public.publish_item_attachments(jsonb, jsonb) to authenticated;
