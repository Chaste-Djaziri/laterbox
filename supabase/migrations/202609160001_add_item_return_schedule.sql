-- Add return times before shipping clients that send return_at.
alter table public.items add column if not exists return_at timestamptz;
alter table public.items alter column status set default 'deferred';
update public.items set status = 'deferred', return_at = created_at,
  updated_at = now() where status = 'inbox';
create index if not exists items_return_schedule_idx
  on public.items (user_id, status, return_at) where deleted_at is null;
