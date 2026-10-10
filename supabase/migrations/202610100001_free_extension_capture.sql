-- Service-owned provenance avoids recursive policies between items and item_content.
create table public.extension_free_items (
  item_id uuid primary key references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade
);
alter table public.extension_free_items enable row level security;
create policy extension_free_items_read on public.extension_free_items for select to authenticated using (user_id=auth.uid());
grant select on public.extension_free_items to authenticated;
grant all on public.extension_free_items to service_role;
create policy free_extension_items_read on public.items for select to authenticated
using (user_id=auth.uid() and id in (select item_id from public.extension_free_items where user_id=auth.uid()));
create policy free_extension_metadata_read on public.item_metadata for select to authenticated
using (user_id=auth.uid() and item_id in (select item_id from public.extension_free_items where user_id=auth.uid()));

-- Preserve free reads of captures made by earlier extension releases.
insert into public.extension_free_items(item_id,user_id)
select c.item_id,c.user_id from public.item_content c join public.item_metadata m on m.item_id=c.item_id
where m.classification_source='browserExtension' on conflict do nothing;

create or replace function public.save_extension_capture(p_user_id uuid, p_capture_id uuid, p_item jsonb, p_metadata jsonb, p_content jsonb)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id uuid; v_item public.items; v_metadata public.item_metadata;
begin
  -- Service-only RPC: the capture endpoint verifies extension sessions or Pro native access.
  -- Same-account concurrent retries serialize without overwriting the first snapshot.
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text || ':' || p_capture_id::text,0));
  select item_id into v_id from public.item_content where user_id=p_user_id and capture_id=p_capture_id;
  if v_id is not null then return v_id; end if;
  v_item := jsonb_populate_record(null::public.items, p_item);
  v_id := v_item.id;
  insert into public.items(id,user_id,url,title,text_content,text_selector,type,favorite,status,return_at,created_at,updated_at,origin_installation_id)
  values(v_id,p_user_id,v_item.url,v_item.title,v_item.text_content,v_item.text_selector,v_item.type,false,v_item.status,v_item.return_at,v_item.created_at,v_item.updated_at,v_item.origin_installation_id);
  if p_metadata is not null then
    v_metadata := jsonb_populate_record(null::public.item_metadata,p_metadata);
    insert into public.item_metadata(item_id,user_id,domain,site_name,title,description,favicon_url,preview_image_url,status,content_type,classification_source,structured_data,created_at,updated_at)
    values(v_id,p_user_id,v_metadata.domain,v_metadata.site_name,v_metadata.title,v_metadata.description,v_metadata.favicon_url,v_metadata.preview_image_url,v_metadata.status,v_metadata.content_type,v_metadata.classification_source,v_metadata.structured_data,v_metadata.created_at,v_metadata.updated_at);
  end if;
  insert into public.item_content(item_id,user_id,capture_id,kind,source_url,canonical_url,markdown,author,published_at,truncated)
  values(v_id,p_user_id,p_capture_id,p_content->>'kind',p_content->>'sourceUrl',p_content->>'canonicalUrl',coalesce(p_content->>'markdown',''),p_content->>'author',p_content->>'publishedAt',coalesce((p_content->>'truncated')::boolean,false));
  if p_content->>'verifiedExtension' = 'true' then
    insert into public.extension_free_items(item_id,user_id) values(v_id,p_user_id) on conflict do nothing;
  end if;
  return v_id;
end $$;
revoke all on function public.save_extension_capture(uuid,uuid,jsonb,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.save_extension_capture(uuid,uuid,jsonb,jsonb,jsonb) to service_role;
