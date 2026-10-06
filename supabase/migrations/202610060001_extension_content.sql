-- Native content snapshots: independent of enrichment metadata updates.
create table public.item_content (
  item_id uuid primary key references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  capture_id uuid not null,
  kind text not null check (kind in ('page','link','highlight','social')),
  source_url text,
  canonical_url text,
  markdown text not null default '' check (octet_length(markdown) <= 204800),
  author text,
  published_at text,
  truncated boolean not null default false,
  created_at timestamptz not null default now(),
  unique(user_id,capture_id)
);
alter table public.item_content enable row level security;
create policy item_content_owner_read on public.item_content for select to authenticated
using (user_id = auth.uid() and exists(select 1 from public.items i where i.id=item_id and i.user_id=auth.uid() and i.deleted_at is null));
grant select on public.item_content to authenticated;
grant all on public.item_content to service_role;

-- Callable only by the capture endpoint after authentication and entitlement checks.
create function public.save_extension_capture(p_user_id uuid, p_capture_id uuid, p_item jsonb, p_metadata jsonb, p_content jsonb)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id uuid; v_item public.items; v_metadata public.item_metadata;
begin
  if not public.has_pro_entitlement(p_user_id) then raise exception 'Pro required'; end if;
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
  return v_id;
end $$;
revoke all on function public.save_extension_capture(uuid,uuid,jsonb,jsonb,jsonb) from public,anon,authenticated;
grant execute on function public.save_extension_capture(uuid,uuid,jsonb,jsonb,jsonb) to service_role;
