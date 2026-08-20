-- Edge Functions use service_role only after validating a scoped extension
-- credential. Keep the client roles protected by the existing RLS policies.
grant select, insert, update, delete on public.items to service_role;
