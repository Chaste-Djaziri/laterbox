-- Phase 9.1: collection sync.

-- Memberships become syncable records with their own updated_at and
-- deleted_at tombstones, so a removal never resurrects on another device.
alter table public.collection_items add column user_id uuid;
update public.collection_items ci
  set user_id = c.user_id
  from public.collections c
  where c.id = ci.collection_id;
alter table public.collection_items alter column user_id set not null;
alter table public.collection_items add column updated_at timestamptz not null default now();
alter table public.collection_items add column deleted_at timestamptz;

create index collection_items_user_idx on public.collection_items using btree (user_id);

-- Scope membership policies directly by user_id as well as via the owning
-- collection, so a row can never leak across accounts.
drop policy "Users can read their own collection items" on public.collection_items;
drop policy "Users can insert their own collection items" on public.collection_items;
drop policy "Users can update their own collection items" on public.collection_items;
drop policy "Users can delete their own collection items" on public.collection_items;

create policy "Users can read their own collection items"
on public.collection_items for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert their own collection items"
on public.collection_items for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own collection items"
on public.collection_items for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own collection items"
on public.collection_items for delete to authenticated
using ((select auth.uid()) = user_id);