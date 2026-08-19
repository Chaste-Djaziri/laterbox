-- Phase 10: one-to-one personal notes.

-- item_id is the primary key: one note per item. user_id is kept on the note
-- (not inferred from the item) so ownership is scoped directly. deleted_at is
-- a tombstone: an old device can never resurrect a removed note.
create table public.item_notes (
  item_id uuid primary key references public.items (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index item_notes_user_idx on public.item_notes using btree (user_id);

alter table public.item_notes enable row level security;

create policy "Users can read their own notes"
on public.item_notes for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert their own notes"
on public.item_notes for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own notes"
on public.item_notes for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own notes"
on public.item_notes for delete to authenticated
using ((select auth.uid()) = user_id);