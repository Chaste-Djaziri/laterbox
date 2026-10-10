create table public.account_deletion_jobs (
  account_id uuid primary key,
  clerk_subject text,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.account_deletion_jobs enable row level security;
revoke all on public.account_deletion_jobs from anon,authenticated;
grant all on public.account_deletion_jobs to service_role;
-- Deletion must revoke both providers and remove R2 files before cascading data.
create or replace function public.delete_user_account() returns jsonb
language plpgsql security definer set search_path = '' as $$
begin
  raise exception 'Use the account deletion endpoint';
end $$;
