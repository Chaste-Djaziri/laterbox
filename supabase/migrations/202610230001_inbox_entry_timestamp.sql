-- Non-breaking schema upgrade for cross-platform Inbox entry timestamps.
-- Older Web/Android clients do not know this column. Leave it nullable, do
-- not rewrite historical rows, and do not change RLS or existing columns.
ALTER TABLE public.items
  ADD COLUMN IF NOT EXISTS inbox_entered_at timestamptz;

COMMENT ON COLUMN public.items.inbox_entered_at IS
  'Last known transition into Inbox. NULL for older items with unknown history.';

-- PostgREST upserts from legacy clients may omit the new field (or send NULL).
-- Preserve a known timestamp, and set a new one when any client moves an item
-- into Inbox. This also covers restores from Recently Deleted.
CREATE OR REPLACE FUNCTION public.preserve_item_inbox_entry_timestamp()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'inbox' AND NEW.deleted_at IS NULL THEN
      NEW.inbox_entered_at := COALESCE(NEW.inbox_entered_at, NEW.created_at);
    END IF;
  ELSE
    IF NEW.status = 'inbox'
       AND NEW.deleted_at IS NULL
       AND (OLD.status IS DISTINCT FROM 'inbox'
            OR (OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL)) THEN
      NEW.inbox_entered_at := COALESCE(NEW.inbox_entered_at, NEW.updated_at, now());
    ELSIF NEW.inbox_entered_at IS NULL AND OLD.inbox_entered_at IS NOT NULL THEN
      NEW.inbox_entered_at := OLD.inbox_entered_at;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS items_preserve_inbox_entry_timestamp ON public.items;
CREATE TRIGGER items_preserve_inbox_entry_timestamp
BEFORE INSERT OR UPDATE ON public.items
FOR EACH ROW
EXECUTE FUNCTION public.preserve_item_inbox_entry_timestamp();
