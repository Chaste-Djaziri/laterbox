# LaterBox cross-platform cloud contract and rollout

**Audit date:** 2026-10-23. This documents repository state, **not** a claim
that the hosted Supabase instance has already run the migration.

## Contract status

Source of truth: [platform-sync-contract.json](platform-sync-contract.json).
Run `python3 scripts/check_platform_sync.py` at the repository root to compare
declared cloud-field support with current iOS, Web and Android source files.
The checker deliberately reports older clients as `not yet`: this is an
upgrade backlog, not a reason to block current users. CI runs the same checker
when relevant schemas or client sync code change. If a client is upgraded,
update its declared field status and contract version in the JSON manifest. A passing checker does
**not** verify migration deployment or end-to-end sync.

| Data field / behavior | iOS current | Web current | Android current | Supabase |
| --- | --- | --- | --- | --- |
| `return_at` / schedules | Read + write | Read + write | Read + write | Existing |
| `text_selector` / captured highlights | Read + write (fixed) | Read + write | Reads; not written in Android item upload | Existing |
| `inbox_entered_at` / exact Inbox-entry time | Read + write (fixed) | Not handled | Not handled | **New nullable migration** |
| `isSyncPending` / offline queue | Device-only | Device-specific queue | Device-specific queue | Intentionally not a shared field |
| AI/capture suggestions | Implemented | Audit separately | Audit separately | Existing classification JSON; no new column |
| Today's focused review | Implemented | UX parity review needed | UX parity review needed | Existing `return_at`; no new column |
| Encrypted `.laterbox` archive | iOS-only format currently | Compatibility not established | Compatibility not established | Not stored in shared DB |

The encrypted backup format and AI models are not automatically shared by
adding a PostgreSQL column; any new web/Android readers need a separate,
explicitly tested implementation. The feature inventory is in the JSON
contract. Do not advertise parity merely because a backend field exists.

## Migration and compatibility

`supabase/migrations/202610230001_inbox_entry_timestamp.sql`:

- Adds **nullable** `public.items.inbox_entered_at timestamptz`. No other
  existing columns, constraints, indexes, RLS policies, or privilege grants change.
- Leaves historic rows **NULL**, because their true entry time was never
  recorded. UI may fall back to the saved/created date but must not present
  that estimate as a historical Inbox-entry timestamp.
- For new rows inserted directly into Inbox without this field, the timestamp
  is derived from `created_at`.
- For old web/Android clients that change an item's status into Inbox (or
  restore it from deleted), a trigger derives the timestamp from the
  supplied `updated_at`; for legacy upserts that omit the field, the trigger
  preserves an existing known value.
- For modern iOS writes, the explicitly supplied timestamp wins. Older clients
  can still read and write their known columns.
- No migration automatically reconstructs timestamp history or upgrades
  Android Room / web localStorage.

**Important rollout order:**

1. Snapshot or back up your hosted Supabase database. Apply the migration
   to a staging environment; verify table, trigger and existing client writes.
2. Test Web and Android **unchanged** against staging: create an item, update
   its title, schedule it, return it to Inbox, and restore from Trash.
   Verify older upserts don't erase a known Inbox timestamp.
3. Deploy **this additive migration to production first** (via your ordinary
   approved Supabase migration workflow), and confirm the recorded version.
   Do not release the new iOS cloud-payload client before that.
4. Release/update iOS, then verify Pro-user push/pull between two devices.
   Free/local-only mode should remain unaffected by the remote change.
5. Bring Web and Android up to cloud contract v2 in subsequent releases:
   add an optional field to their models, storage migrations, pull mapping,
   status transitions, and push serialization; add round-trip tests.
6. Retain backward-compatible SQL while old clients remain in the wild.
   Never retroactively edit an already-applied migration; use another
   timestamped migration for future changes.

**Read-only post-deploy verification (Supabase SQL editor):**

```sql
select version
from supabase_migrations.schema_migrations
where version = '202610230001';

select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'public' and table_name = 'items'
  and column_name = 'inbox_entered_at';

select tgname, tgenabled
from pg_trigger
where tgrelid = 'public.items'::regclass
  and tgname = 'items_preserve_inbox_entry_timestamp';
```

### Platform upgrade checklist

**Web (not changed in this release):**
Add `inbox_entered_at?: string | null` to `LaterBoxItem`, preserve it in
local cache and pending queue, read it in the remote mapping, include it in
`itemRow`, set it when restoring or moving an item into Inbox, and use it for
the Inbox-age display. Test the old and new payloads side by side.

**Android (not changed in this release):**
Add the optional timestamp to `ItemEntity`, increment Room's schema version,
write a non-destructive Room migration, map it in both pull and push in
`SyncCoordinator.kt`, and mark it when an item returns to Inbox. Add
`text_selector` to Android push to avoid losing captured highlight context
from iOS/Web. Test Android upgrades with existing local items.

**iOS:** Both timestamps are now mapped in cloud snapshots and upload
payloads. Continue preserving local Inbox entry when a legacy remote snapshot
omits the field without changing its Inbox status. Regression-test cloud
round-trips and old client overwrites.

### Release gates for future shared fields

- Every new shared field gets a nullable/defaulted **expand** migration first.
- Update the platform contract manifest and this checklist in the same change.
- Update each active client's read/write mapping or mark it explicitly
  as a legacy contract; test older-client upserts before deploying.
- Only after old clients are retired may a **contract** migration remove an
  obsolete field or tighten a constraint.
- A source-file parity checker is not a substitute for staging / production
  migration verification. Do not claim the hosted DB has been updated without
  checking its migration history.
