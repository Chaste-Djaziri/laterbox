-- Only installation IDs (never credentials) are attached to items.
alter table public.items add column if not exists origin_installation_id uuid;
alter table public.items add column if not exists notification_revision uuid not null default gen_random_uuid();

create table public.notification_installations (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('ios','android','macos','windows','linux','web')),
  transport text not null check (transport in ('apns','fcm','web','poll')),
  token text,
  subscription jsonb,
  enabled boolean not null default false,
  scheduled_returns boolean not null default true,
  remote_saves boolean not null default true,
  enabled_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.notification_installations enable row level security;
create policy "Read own notification installations" on public.notification_installations for select to authenticated using (user_id = auth.uid());
create policy "Remove own notification installations" on public.notification_installations for delete to authenticated using (user_id = auth.uid());
grant select, delete on public.notification_installations to authenticated;

-- Registration goes through an RPC: clients cannot backdate the baseline or change ownership.
create function public.register_notification_installation(installation_id uuid, device_platform text,
  delivery_transport text, device_token text default null, web_subscription jsonb default null,
  notifications_enabled boolean default false, returns_enabled boolean default true, saves_enabled boolean default true)
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null or not public.has_pro_entitlement(auth.uid()) then raise exception 'Cloud sync required'; end if;
  if exists(select 1 from notification_installations where id=installation_id and user_id<>auth.uid()) then raise exception 'Installation belongs to another account'; end if;
  insert into notification_installations(id,user_id,platform,transport,token,subscription,enabled,scheduled_returns,remote_saves)
  values(installation_id,auth.uid(),device_platform,delivery_transport,device_token,web_subscription,notifications_enabled,returns_enabled,saves_enabled)
  on conflict(id) do update set platform=excluded.platform,transport=excluded.transport,token=excluded.token,
    subscription=excluded.subscription,enabled=excluded.enabled,scheduled_returns=excluded.scheduled_returns,
    remote_saves=excluded.remote_saves,updated_at=now(),
    enabled_at=case when not notification_installations.enabled and excluded.enabled then now() else notification_installations.enabled_at end;
end $$;
revoke all on function public.register_notification_installation(uuid,text,text,text,jsonb,boolean,boolean,boolean) from public;
grant execute on function public.register_notification_installation(uuid,text,text,text,jsonb,boolean,boolean,boolean) to authenticated;

create table public.notification_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  kind text not null check(kind in ('save','return')),
  revision uuid not null,
  origin_installation_id uuid,
  due_at timestamptz not null,
  created_at timestamptz not null default now(),
  unique(item_id,kind,revision)
);
create index notification_events_due on public.notification_events(due_at);
alter table public.notification_events enable row level security;
create table public.notification_deliveries (
  event_id uuid not null references public.notification_events(id) on delete cascade,
  installation_id uuid not null references public.notification_installations(id) on delete cascade,
  state text not null default 'pending' check(state in ('pending','sending','sent','discarded')),
  attempts integer not null default 0,
  retry_at timestamptz not null default now(),
  lease_id uuid,
  last_error text,
  primary key(event_id,installation_id)
);
alter table public.notification_deliveries enable row level security;
-- Clients have no access to another installation's outbox or provider credentials.
grant all on public.notification_installations, public.notification_events, public.notification_deliveries to service_role;

create function public.capture_notification_events() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if TG_OP='UPDATE' then
    new.origin_installation_id := old.origin_installation_id;
    if new.return_at is distinct from old.return_at or new.status is distinct from old.status or new.deleted_at is distinct from old.deleted_at then
      new.notification_revision := gen_random_uuid();
    else new.notification_revision := old.notification_revision;
    end if;
  end if;
  return new;
end $$;
create trigger notification_revision before update on public.items for each row execute function public.capture_notification_events();
create function public.enqueue_item_notifications() returns trigger language plpgsql security definer set search_path=public as $$
begin
  if new.deleted_at is not null or new.status not in ('inbox','deferred') then return new; end if;
  -- Imported history never produces arrival alerts. Future reminders still work.
  if TG_OP='INSERT' and new.created_at >= now()-interval '2 minutes' and
      (new.status='inbox' or new.return_at <= now()) then
    insert into notification_events(user_id,item_id,kind,revision,origin_installation_id,due_at)
      values(new.user_id,new.id,'save',new.notification_revision,new.origin_installation_id,now()) on conflict do nothing;
  elsif new.return_at > now() then
    insert into notification_events(user_id,item_id,kind,revision,origin_installation_id,due_at)
      values(new.user_id,new.id,'return',new.notification_revision,new.origin_installation_id,new.return_at) on conflict do nothing;
  end if;
  return new;
end $$;
create trigger enqueue_item_notifications after insert or update on public.items for each row execute function public.enqueue_item_notifications();
-- Backfill only future reminders, never the overdue inbox.
insert into public.notification_events(user_id,item_id,kind,revision,origin_installation_id,due_at)
select user_id,id,'return',notification_revision,origin_installation_id,return_at from public.items
where deleted_at is null and status in ('inbox','deferred') and return_at>now() on conflict do nothing;

-- Leases prevent concurrent workers from claiming the same delivery. Re-evaluate
-- status, preferences, ownership, entitlement and revision on every retry.
create function public.claim_notification_deliveries(p_installation uuid default null)
returns table(event_id uuid, installation_id uuid, lease_id uuid, item_id uuid, user_id uuid, kind text,
  platform text, transport text, token text, subscription jsonb, attempts integer)
language plpgsql security definer set search_path=public as $$
begin
  if coalesce(auth.role(),'')<>'service_role' and (p_installation is null or not exists(
    select 1 from notification_installations n where n.id=p_installation and n.user_id=auth.uid() and n.transport='poll')) then
    raise exception 'Not authorized';
  end if;
  insert into notification_deliveries(event_id,installation_id)
  select e.id,n.id from notification_events e join notification_installations n on n.user_id=e.user_id
  join items i on i.id=e.item_id
  where e.due_at<=now() and e.due_at>now()-interval '24 hours' and n.enabled
    and e.due_at>=n.enabled_at and i.notification_revision=e.revision and i.deleted_at is null
    and i.status in ('inbox','deferred') and public.has_pro_entitlement(n.user_id)
    and ((p_installation is null and n.transport<>'poll') or n.id=p_installation)
    and ((e.kind='return' and n.scheduled_returns) or (e.kind='save' and n.remote_saves and n.id is distinct from e.origin_installation_id))
  on conflict do nothing;
  update notification_deliveries d set state='discarded'
  where d.state in ('pending','sending') and exists(
    select 1 from notification_events e join items i on i.id=e.item_id join notification_installations n on n.id=d.installation_id
    where e.id=d.event_id and (i.notification_revision<>e.revision or i.deleted_at is not null or i.status not in ('inbox','deferred')
      or not n.enabled or not public.has_pro_entitlement(n.user_id) or e.due_at<n.enabled_at or e.due_at<now()-interval '24 hours'
      or (e.kind='return' and not n.scheduled_returns) or (e.kind='save' and not n.remote_saves)))
    and (coalesce(auth.role(),'')='service_role' or d.installation_id=p_installation);
  return query
  with candidates as (
    select d.event_id,d.installation_id from notification_deliveries d join notification_installations n on n.id=d.installation_id
    where d.state in ('pending','sending') and d.retry_at<=now() and d.attempts<8
      and ((p_installation is null and n.transport<>'poll') or n.id=p_installation)
    order by d.retry_at limit 100 for update of d skip locked
  ), claimed as (
    update notification_deliveries d set state='sending',attempts=d.attempts+1,retry_at=now()+interval '2 minutes',lease_id=gen_random_uuid()
    from candidates c where d.event_id=c.event_id and d.installation_id=c.installation_id returning d.*
  ) select c.event_id,c.installation_id,c.lease_id,e.item_id,e.user_id,e.kind,n.platform,n.transport,n.token,n.subscription,c.attempts
  from claimed c join notification_events e on e.id=c.event_id join notification_installations n on n.id=c.installation_id;
end $$;
revoke all on function public.claim_notification_deliveries(uuid) from public;
grant execute on function public.claim_notification_deliveries(uuid) to authenticated,service_role;
create function public.ack_notification_delivery(p_event uuid,p_installation uuid,p_lease uuid)
returns void language sql security definer set search_path=public as $$
  update notification_deliveries d set state='sent',last_error=null
  where d.event_id=p_event and d.installation_id=p_installation and d.lease_id=p_lease
  and exists(select 1 from notification_installations n where n.id=p_installation and n.user_id=auth.uid() and n.transport='poll');
$$;
revoke all on function public.ack_notification_delivery(uuid,uuid,uuid) from public;
grant execute on function public.ack_notification_delivery(uuid,uuid,uuid) to authenticated;
