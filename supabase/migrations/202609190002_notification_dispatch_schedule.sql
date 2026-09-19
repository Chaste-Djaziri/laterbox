create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

-- Vault values are provisioned separately. Missing configuration is a no-op,
-- so deploying this migration never breaks captures or leaks credentials.
create function public.wake_notification_dispatcher() returns void
language plpgsql security definer set search_path=public,extensions as $$
declare endpoint text; secret text;
begin
  select decrypted_secret into endpoint from vault.decrypted_secrets where name='notification_dispatch_url' limit 1;
  select decrypted_secret into secret from vault.decrypted_secrets where name='notification_dispatch_secret' limit 1;
  if endpoint is null or secret is null then return; end if;
  perform net.http_post(url:=endpoint,headers:=jsonb_build_object('Content-Type','application/json','Authorization','Bearer '||secret),body:='{}'::jsonb,timeout_milliseconds:=60000);
end $$;
revoke all on function public.wake_notification_dispatcher() from public,anon,authenticated;
grant execute on function public.wake_notification_dispatcher() to service_role;
create function public.wake_on_inbox_arrival() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.due_at<=now() then perform public.wake_notification_dispatcher(); end if;
  return new;
end $$;
create trigger wake_on_inbox_arrival after insert on public.notification_events for each row execute function public.wake_on_inbox_arrival();
select cron.schedule('laterbox-inbox-notifications','* * * * *','select public.wake_notification_dispatcher()');
select cron.schedule('laterbox-notification-retention','17 3 * * *',
  $$delete from public.notification_events where due_at < now()-interval '7 days';$$);

alter table public.extension_connection_requests add column origin_installation_id uuid;
alter table public.extension_sessions add column origin_installation_id uuid;
