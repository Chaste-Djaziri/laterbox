-- laterbox/supabase/migrations/202611090001_pause_writes_when_storage_full.sql
-- Freeze new cloud library writes when an account reaches its provider-backed
-- quota. Keep reads, exports, soft deletions and hard deletions available.
-- This is a final server guard; app-side checks handle friendly UI.
create or replace function public.block_library_writes_when_storage_full()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    storage_used bigint;
    storage_limit bigint;
    deletion_is_requested boolean;
begin
    -- Do not stop a customer from deleting content to recover space.
    if tg_op = 'UPDATE' then
        deletion_is_requested :=
            (to_jsonb(new)->>'deleted_at') is not null
            and (to_jsonb(old)->>'deleted_at') is null;
        if deletion_is_requested then return new; end if;
    end if;

    storage_used := public.account_storage_used_bytes(new.user_id);
    storage_limit := public.account_storage_limit_bytes(new.user_id);
    if storage_limit is not null and storage_limit > 0
       and storage_used >= storage_limit then
        raise exception 'Storage full. Delete stored files or increase your plan limit before making changes.'
            using errcode = 'P0001';
    end if;
    return new;
end;
$$;

-- Item mutations cover new captures, rescheduling, metadata sync and edits.
-- Collection edits are frozen too, but deletion/tombstones remain available.
do $$
declare target_table text;
begin
    foreach target_table in array array['items', 'collections', 'collection_items'] loop
        execute format('drop trigger if exists block_writes_when_storage_full on public.%I', target_table);
        execute format(
            'create trigger block_writes_when_storage_full before insert or update on public.%I for each row execute function public.block_library_writes_when_storage_full()',
            target_table
        );
    end loop;
end $$;
