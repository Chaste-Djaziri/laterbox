create table public.attachments (
  id uuid primary key,
  item_id uuid not null references public.items(id),
  user_id uuid not null references auth.users(id) on delete cascade,
  original_file_name text not null,
  file_extension text not null
    check (
      file_extension <> ''
      and file_extension = lower(file_extension)
      and file_extension not like '.%'
    ),
  mime_type text not null,
  byte_size bigint not null check (byte_size between 1 and 104857600),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  r2_object_key text unique,
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  created_at timestamptz not null,
  updated_at timestamptz not null,
  deleted_at timestamptz,
  check (deleted_at is not null or r2_object_key is not null)
);

create index attachments_item_id_idx
  on public.attachments using btree (item_id);
create index attachments_user_id_idx
  on public.attachments using btree (user_id);
create index attachments_sha256_idx
  on public.attachments using btree (sha256);
create index attachments_updated_at_idx
  on public.attachments using btree (user_id, updated_at);

alter table public.attachments enable row level security;

create policy "Users can read their own attachments"
on public.attachments for select to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.items i
    where i.id = item_id and i.user_id = user_id
  )
);

create policy "Users can insert their own attachments"
on public.attachments for insert to authenticated
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.items i
    where i.id = item_id and i.user_id = user_id
  )
);

create policy "Users can update their own attachments"
on public.attachments for update to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.items i
    where i.id = item_id and i.user_id = user_id
  )
)
with check (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.items i
    where i.id = item_id and i.user_id = user_id
  )
);

create policy "Users can delete their own attachments"
on public.attachments for delete to authenticated
using (
  (select auth.uid()) = user_id
  and exists (
    select 1 from public.items i
    where i.id = item_id and i.user_id = user_id
  )
);

grant select, insert, update, delete on public.attachments to authenticated;
