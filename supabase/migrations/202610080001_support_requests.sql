-- Support is available to guests and all plans through the server API.
-- Clients cannot read other people's reports or insert directly.
create table public.support_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  email text not null check (length(email) between 3 and 254),
  category text not null check (category in ('problem', 'help', 'feedback', 'other')),
  subject text not null check (length(subject) between 3 and 160),
  message text not null check (length(message) between 10 and 5000),
  platform text not null check (platform in ('ios', 'android', 'web')),
  app_version text not null default '' check (length(app_version) <= 100),
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved')),
  rate_key text not null,
  created_at timestamptz not null default now()
);
create index support_requests_queue on public.support_requests(status, created_at desc);
create index support_requests_rate on public.support_requests(rate_key, created_at desc);
alter table public.support_requests enable row level security;
revoke all on public.support_requests from anon, authenticated;
grant select, insert, update, delete on public.support_requests to service_role;

-- Serialize checks for the same sender to prevent concurrent rate-limit bypass.
create function public.submit_support_request(sender_id uuid, reply_email text, request_category text,
  request_subject text, request_message text, device_platform text, client_version text, sender_rate_key text)
returns uuid language plpgsql security definer set search_path = public as $$
declare request_id uuid;
begin
  if sender_rate_key is null or length(sender_rate_key) <> 64 then raise exception 'Invalid rate key'; end if;
  perform pg_advisory_xact_lock(hashtextextended(sender_rate_key, 0));
  if (select count(*) from public.support_requests where rate_key = sender_rate_key and created_at > now() - interval '1 hour') >= 5 then
    raise exception 'support_rate_limit' using errcode = 'P0001';
  end if;
  insert into public.support_requests(user_id, email, category, subject, message, platform, app_version, rate_key)
  values(sender_id, reply_email, request_category, request_subject, request_message, device_platform, client_version, sender_rate_key)
  returning id into request_id;
  return request_id;
end $$;
revoke all on function public.submit_support_request(uuid,text,text,text,text,text,text,text) from public, anon, authenticated;
grant execute on function public.submit_support_request(uuid,text,text,text,text,text,text,text) to service_role;
