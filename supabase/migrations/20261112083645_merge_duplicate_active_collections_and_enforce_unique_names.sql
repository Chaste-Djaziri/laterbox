-- supabase/migrations/20261112083645_merge_duplicate_active_collections_and_enforce_unique_names.sql
-- Match the migration already applied to LaterBox production.
-- Keep the earliest active folder for each owner/name, retain all unique
-- active memberships, and soft-delete redundant folder records for sync.
create temporary table _laterbox_collection_merge on commit drop as
select id, first_value(id) over (
  partition by user_id, lower(btrim(name))
  order by created_at asc, id asc
) as canonical_id
from public.collections
where deleted_at is null;

insert into public.collection_items
  (collection_id, item_id, user_id, created_at, updated_at, deleted_at)
select distinct on (m.canonical_id, ci.item_id)
  m.canonical_id, ci.item_id, ci.user_id, ci.created_at, now(), null
from _laterbox_collection_merge m
join public.collection_items ci on ci.collection_id=m.id
where m.id <> m.canonical_id and ci.deleted_at is null
order by m.canonical_id, ci.item_id, ci.created_at asc
on conflict (collection_id, item_id) do update
set deleted_at=null,
    updated_at=now();

update public.collection_items ci
set deleted_at=coalesce(ci.deleted_at, now()), updated_at=now()
from _laterbox_collection_merge m
where ci.collection_id=m.id and m.id <> m.canonical_id
  and ci.deleted_at is null;

update public.collections c
set deleted_at=now(), updated_at=now()
from _laterbox_collection_merge m
where c.id=m.id and m.id <> m.canonical_id
  and c.deleted_at is null;

create unique index if not exists collections_active_user_normalized_name_unique
on public.collections (user_id, lower(btrim(name)))
where deleted_at is null;
