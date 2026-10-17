-- Only identity and deletion time remain; item content and attachment rows are removed.
create table public.item_deletion_receipts (
  item_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  deleted_at timestamptz not null default now(),
  primary key (user_id, item_id)
);
alter table public.item_deletion_receipts enable row level security;
create policy "Read own permanent deletion receipts" on public.item_deletion_receipts
  for select to authenticated using (user_id = (select auth.uid()));
grant select on public.item_deletion_receipts to authenticated;
revoke insert, update, delete on public.item_deletion_receipts from anon, authenticated;

create or replace function public.finish_permanent_item_deletion(target_item_id uuid, owner_id uuid)
returns void language plpgsql security invoker set search_path = public as $$
begin
  if exists(select 1 from public.items where id = target_item_id and user_id <> owner_id) then
    raise exception 'Unauthorized item ownership';
  end if;
  if not exists(select 1 from public.items where id = target_item_id and user_id = owner_id) then return; end if;
  insert into public.item_deletion_receipts(item_id, user_id) values(target_item_id, owner_id)
    on conflict (user_id, item_id) do nothing;
  delete from public.attachments where item_id = target_item_id and user_id = owner_id;
  delete from public.items where id = target_item_id and user_id = owner_id;
end;
$$;

create function public.reject_permanently_deleted_item() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if exists(select 1 from public.item_deletion_receipts where item_id = new.id and user_id = new.user_id) then
    raise exception 'This item was permanently deleted on another device';
  end if;
  return new;
end;
$$;
create trigger reject_permanently_deleted_item before insert or update on public.items
  for each row execute function public.reject_permanently_deleted_item();
