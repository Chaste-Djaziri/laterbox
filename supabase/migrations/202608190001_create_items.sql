create table public.items (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  url text,
  title text,
  text_content text,
  type text not null default 'unknown',
  favorite boolean not null default false,
  archived boolean not null default false,
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz
);

create index items_user_id_idx on public.items using btree (user_id);
create index items_user_updated_at_idx
  on public.items using btree (user_id, updated_at);

alter table public.items enable row level security;

create policy "Users can read their own items"
on public.items for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert their own items"
on public.items for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own items"
on public.items for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own items"
on public.items for delete to authenticated
using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.items to authenticated;
