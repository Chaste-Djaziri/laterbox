-- Recovery is privileged and bound to server-written metadata, never an email match.
create function public.find_clerk_provisioned_account(p_subject text) returns uuid
language sql stable security definer set search_path = '' as $$
  select u.id from auth.users u join public.accounts a on a.id=u.id and a.state='active'
  where u.raw_user_meta_data->>'clerk_provisioned_subject'=p_subject
  limit 1
$$;
revoke all on function public.find_clerk_provisioned_account(text) from public,anon,authenticated;
grant execute on function public.find_clerk_provisioned_account(text) to service_role;
