-- Correct Inbox-entry timestamps for legacy upserts and item restoration.
-- Apply AFTER 202610230001. This is safe whether that migration already ran
-- or is applied later in the same deployment. No existing rows are rewritten.
--
-- Rule: a new transition into Inbox should receive a NEW timestamp. Ordinary
-- updates must retain the current timestamp, even when an older client omits it.
-- Modern clients may provide a distinct, explicit transition timestamp.
CREATE OR REPLACE FUNCTION public.preserve_item_inbox_entry_timestamp()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'inbox' AND NEW.deleted_at IS NULL THEN
      NEW.inbox_entered_at := COALESCE(NEW.inbox_entered_at, NEW.created_at, now());
    END IF;
  ELSE
    IF NEW.status = 'inbox'
       AND NEW.deleted_at IS NULL
       AND (OLD.status IS DISTINCT FROM 'inbox'
            OR (OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL)) THEN
      -- Older clients send NULL, omit the field or reuse the last known entry
      -- time. None of those should carry the previous Inbox visit forward.
      IF NEW.inbox_entered_at IS NULL
         OR NEW.inbox_entered_at IS NOT DISTINCT FROM OLD.inbox_entered_at THEN
        NEW.inbox_entered_at := COALESCE(NEW.updated_at, now());
      END IF;
    ELSIF NEW.inbox_entered_at IS NULL AND OLD.inbox_entered_at IS NOT NULL THEN
      -- Preserve known historical entry time on ordinary edits/deletions.
      NEW.inbox_entered_at := OLD.inbox_entered_at;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- The trigger created in 202610230001 continues to call this function.
