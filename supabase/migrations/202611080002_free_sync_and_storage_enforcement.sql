-- Make the library usable across authenticated devices on Free.
-- Client changes must ship AFTER this migration. Never remove owner RLS.
do $$
declare table_name text; operation text; check_expression text;
begin
  foreach table_name in array array[
    'items','item_metadata','item_notes','collections','collection_items','attachments'
  ] loop
    execute format('drop policy if exists %I on public.%I', 'Pro users read own '||table_name, table_name);
    execute format('drop policy if exists %I on public.%I', 'Pro users insert own '||table_name, table_name);
    execute format('drop policy if exists %I on public.%I', 'Pro users update own '||table_name, table_name);
    execute format('drop policy if exists %I on public.%I', 'Pro users delete own '||table_name, table_name);
    check_expression := '(user_id = (select auth.uid()))';
    if table_name in ('item_metadata','item_notes','attachments','collection_items') then
      check_expression := check_expression || ' and exists (select 1 from public.items i where i.id = item_id and i.user_id = (select auth.uid()))';
    end if;
    if table_name = 'collection_items' then
      check_expression := check_expression || ' and exists (select 1 from public.collections c where c.id = collection_id and c.user_id = (select auth.uid()))';
    end if;
    execute format(
      'create policy %I on public.%I for select to authenticated using (%s)',
      'Owner read '||table_name, table_name, check_expression
    );
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (%s)',
      'Owner insert '||table_name, table_name, check_expression
    );
    execute format(
      'create policy %I on public.%I for update to authenticated using (%s) with check (%s)',
      'Owner update '||table_name, table_name, check_expression,check_expression
    );
    execute format(
      'create policy %I on public.%I for delete to authenticated using (%s)',
      'Owner delete '||table_name, table_name, check_expression
    );
  end loop;
end $$;

-- The DB is the final quota boundary, even when a client bypasses the
-- attachment-storage Edge Function. The reservation is service-owned and
-- is only issued after validating the signed upload against account space.
create or replace function public.enforce_attachment_storage_quota()
returns trigger language plpgsql security definer set search_path=public as $$
declare current_bytes bigint; is_service boolean; needs_reservation boolean;
begin
  if new.deleted_at is not null then return new; end if;
  perform pg_advisory_xact_lock(hashtextextended(new.user_id::text,0));
  is_service := current_setting('request.jwt.claim.role',true)='service_role';
  if tg_op='INSERT' then
    needs_reservation := true;
  else
    needs_reservation := old.r2_object_key is distinct from new.r2_object_key
      or old.byte_size is distinct from new.byte_size;
  end if;
  if not is_service and needs_reservation and not exists (
    select 1 from public.storage_upload_reservations r
    where r.attachment_id=new.id and r.user_id=new.user_id and r.byte_size=new.byte_size and r.expires_at>now()
  ) then
    raise exception 'Cloud file upload must be verified before publication';
  end if;
  select coalesce(sum(byte_size),0)::bigint into current_bytes
    from public.attachments
    where user_id=new.user_id and id<>new.id and deleted_at is null and r2_object_key is not null;
  if current_bytes + new.byte_size > public.account_storage_limit_bytes(new.user_id) then
    raise exception 'Cloud storage quota exceeded';
  end if;
  return new;
end
$$;
drop trigger if exists enforce_attachment_storage_quota on public.attachments;
create trigger enforce_attachment_storage_quota
before insert or update of byte_size, r2_object_key, deleted_at on public.attachments
for each row execute function public.enforce_attachment_storage_quota();

create or replace function public.release_published_storage_reservation()
returns trigger language plpgsql security definer set search_path=public as $$
begin
  delete from public.storage_upload_reservations where attachment_id=new.id and user_id=new.user_id;
  return new;
end
$$;
drop trigger if exists release_published_storage_reservation on public.attachments;
create trigger release_published_storage_reservation
after insert or update of r2_object_key on public.attachments
for each row execute function public.release_published_storage_reservation();
