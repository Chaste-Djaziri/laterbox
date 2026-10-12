-- Anonymous StoreKit tokens are not auth.users IDs. Linking requires an explicit,
-- authenticated server action; it never changes an existing purchase owner.
create table public.billing_apple_purchase_links (
  environment text not null check (environment in ('Sandbox', 'Production')),
  original_transaction_id text not null,
  app_account_token uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (environment, original_transaction_id)
);
alter table public.billing_apple_purchase_links enable row level security;
revoke all on public.billing_apple_purchase_links from public, anon, authenticated;
grant all on public.billing_apple_purchase_links to service_role;

create or replace function public.resolve_apple_purchase_owner(p_original_id text, p_environment text, p_token uuid)
returns uuid language plpgsql stable security definer set search_path = public as $$
declare
  linked public.billing_apple_purchase_links;
  owner uuid;
begin
  select * into linked from public.billing_apple_purchase_links
    where environment = p_environment and original_transaction_id = p_original_id;
  if found then
    if p_token is not null and p_token <> linked.app_account_token and p_token <> linked.user_id then
      raise exception 'Apple purchase account token mismatch';
    end if;
    return linked.user_id;
  end if;
  select user_id into owner from public.billing_subscriptions
    where provider = 'apple' and subscription_id = p_original_id
      and (apple_environment = p_environment or apple_environment is null);
  if owner is not null then
    if p_token is not null and p_token <> owner then raise exception 'Apple purchase account token mismatch'; end if;
    return owner;
  end if;
  -- Preserve purchases made while signed into a real LaterBox account.
  select id into owner from auth.users where id = p_token;
  return owner;
end;
$$;
revoke all on function public.resolve_apple_purchase_owner(text,text,uuid) from public, anon, authenticated;
grant execute on function public.resolve_apple_purchase_owner(text,text,uuid) to service_role;

create or replace function public.claim_apple_purchase(p_original_id text, p_environment text, p_token uuid, p_user uuid, p_subscription jsonb)
returns void language plpgsql security definer set search_path = public as $$
declare owner uuid;
begin
  if p_environment not in ('Sandbox','Production') or p_environment is null or p_token is null or p_user is null
    or p_original_id is null or p_subscription->>'subscription_id' is distinct from p_original_id
    or p_subscription->>'apple_environment' is distinct from p_environment
    or p_subscription->>'user_id' is distinct from p_user::text then
    raise exception 'Invalid Apple account connection';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('apple:' || p_original_id, 0));
  owner := public.resolve_apple_purchase_owner(p_original_id, p_environment, p_token);
  if owner is not null and owner <> p_user then raise exception 'Apple purchase already belongs to another account'; end if;
  insert into public.billing_apple_purchase_links(environment,original_transaction_id,app_account_token,user_id)
    values(p_environment,p_original_id,p_token,p_user)
    on conflict (environment,original_transaction_id) do nothing;
  perform public.apply_apple_subscription(p_subscription, true);
end;
$$;
revoke all on function public.claim_apple_purchase(text,text,uuid,uuid,jsonb) from public, anon, authenticated;
grant execute on function public.claim_apple_purchase(text,text,uuid,uuid,jsonb) to service_role;
