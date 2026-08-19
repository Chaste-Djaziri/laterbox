-- Phase 9: item lifecycle status + collections (many-to-many).

-- Items move through a lifecycle: inbox -> saved (kept) -> archived.
alter table public.items add column status text not null default 'inbox';
update public.items set status = 'archived' where archived = true;
alter table public.items drop column archived;

create table public.collections (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create index collections_user_idx on public.collections using btree (user_id);

create table public.collection_items (
  collection_id uuid not null references public.collections(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  created_at timestamptz not null,
  primary key (collection_id, item_id)
);

create index collection_items_item_idx on public.collection_items using btree (item_id);

alter table public.collections enable row level security;
alter table public.collection_items enable row level security;

create policy "Users can read their own collections"
on public.collections for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert their own collections"
on public.collections for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own collections"
on public.collections for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own collections"
on public.collections for delete to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can read their own collection items"
on public.collection_items for select to authenticated
using (
  exists (
    select 1 from public.collections c
    where c.id = collection_id and (select auth.uid()) = c.user_id
  )
);

create policy "Users can insert their own collection items"
on public.collection_items for insert to authenticated
with check (
  exists (
    select 1 from public.collections c
    where c.id = collection_id and (select auth.uid()) = c.user_id
  )
);

create policy "Users can update their own collection items"
on public.collection_items for update to authenticated
using (
  exists (
    select 1 from public.collections c
    where c.id = collection_id and (select auth.uid()) = c.user_id
  )
)
with check (
  exists (
    select 1 from public.collections c
    where c.id = collection_id and (select auth.uid()) = c.user_id
  )
);

create policy "Users can delete their own collection items"
on public.collection_items for delete to authenticated
using (
  exists (
    select 1 from public.collections c
    where c.id = collection_id and (select auth.uid()) = c.user_id
  )
);

grant select, insert, update, delete on public.collections to authenticated;
grant select, insert, update, delete on public.collection_items to authenticated;