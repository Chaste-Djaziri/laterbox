create table public.item_metadata (
  item_id uuid primary key references public.items(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  domain text,
  site_name text,
  title text,
  description text,
  favicon_url text,
  preview_image_url text,
  status text not null default 'pending'
    check (status in ('pending', 'enriching', 'enriched', 'failed', 'unsupported')),
  attempt_count integer not null default 0,
  last_error text,
  metadata_version integer not null default 1,
  enriched_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index item_metadata_user_updated_at_idx
  on public.item_metadata using btree (user_id, updated_at);

alter table public.item_metadata enable row level security;

create policy "Users can read their own item metadata"
on public.item_metadata for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Users can insert their own item metadata"
on public.item_metadata for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Users can update their own item metadata"
on public.item_metadata for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create policy "Users can delete their own item metadata"
on public.item_metadata for delete to authenticated
using ((select auth.uid()) = user_id);

grant select, insert, update, delete on public.item_metadata to authenticated;