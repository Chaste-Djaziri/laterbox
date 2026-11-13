-- supabase/migrations/20261112085629_support_requests_accept_macos.sql
alter table public.support_requests drop constraint if exists support_requests_platform_check;
alter table public.support_requests add constraint support_requests_platform_check
check (platform in ('ios', 'android', 'web', 'macos'));
