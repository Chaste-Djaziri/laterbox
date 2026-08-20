drop policy "Users can read their own attachments" on public.attachments;
drop policy "Users can insert their own attachments" on public.attachments;
drop policy "Users can update their own attachments" on public.attachments;
drop policy "Users can delete their own attachments" on public.attachments;

create policy "Users can read their own attachments"
on public.attachments for select to authenticated
using (
  (select auth.uid()) = attachments.user_id
  and exists (
    select 1 from public.items i
    where i.id = attachments.item_id
      and i.user_id = attachments.user_id
  )
);

create policy "Users can insert their own attachments"
on public.attachments for insert to authenticated
with check (
  (select auth.uid()) = attachments.user_id
  and exists (
    select 1 from public.items i
    where i.id = attachments.item_id
      and i.user_id = attachments.user_id
  )
);

create policy "Users can update their own attachments"
on public.attachments for update to authenticated
using (
  (select auth.uid()) = attachments.user_id
  and exists (
    select 1 from public.items i
    where i.id = attachments.item_id
      and i.user_id = attachments.user_id
  )
)
with check (
  (select auth.uid()) = attachments.user_id
  and exists (
    select 1 from public.items i
    where i.id = attachments.item_id
      and i.user_id = attachments.user_id
  )
);

create policy "Users can delete their own attachments"
on public.attachments for delete to authenticated
using (
  (select auth.uid()) = attachments.user_id
  and exists (
    select 1 from public.items i
    where i.id = attachments.item_id
      and i.user_id = attachments.user_id
  )
);
