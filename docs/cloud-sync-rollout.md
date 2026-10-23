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
| `inbox_entered_at` / exact Inbox-entry time | Read + write | Read + write (contract v2; UI pending) | Not handled | **Nullable + corrective migrations; deployment unverified** |
| `isSyncPending` / offline queue | Device-only | Device-specific queue | Device-specific queue | Intentionally not a shared field |
| AI/capture suggestions | Implemented | Audit separately | Audit separately | Existing classification JSON; no new column |
| Today's focused review | Implemented | UX parity review needed | UX parity review needed | Existing `return_at`; no new column |
| Encrypted `.laterbox` archive | iOS-only format currently | Compatibility not established | Compatibility not established | Not stored in shared DB |

The encrypted backup format and AI models are not automatically shared by
adding a PostgreSQL column; any new web/Android readers need a separate,
explicitly tested implementation. The feature inventory is in the JSON
contract. Do not advertise parity merely because a backend field exists.

## Migration and compatibility

`supabase/migrations/202610230001_inbox_entry_timestamp.sql` followed by
`supabase/migrations/202610230002_correct_inbox_entry_transitions.sql`:

- Adds **nullable** `public.items.inbox_entered_at timestamptz`. No other
  existing columns, constraints, indexes, RLS policies, or privilege grants change.
- Leaves historic rows **NULL**, because their true entry time was never
  recorded. UI may fall back to the saved/created date but must not present
  that estimate as a historical Inbox-entry timestamp.
- For new rows inserted directly into Inbox without this field, the timestamp
  is derived from `created_at`.
- The corrective migration replaces only the trigger function (the trigger
  stays installed). When an older client transitions a deferred/deleted item
  into Inbox, a reused/omitted timestamp is replaced with `updated_at`.
  Ordinary title edits, reschedules and deletes preserve the known value.
  Distinct, explicitly provided timestamps from modern clients are respected.
- For modern iOS writes, the explicitly supplied timestamp wins. Older clients
  can still read and write their known columns.
- No migration automatically reconstructs timestamp history or upgrades
  Android Room / web localStorage.

**Important rollout order:**

1. Snapshot or back up your hosted Supabase database. Apply migrations
   **202610230001 then 202610230002** to staging; verify table, trigger and
   existing client writes. The repository PGlite regression test executes
   both migrations but does not replace a full hosted staging test.
2. Test an **older pre-v2 web client and Android unchanged** against
   staging, then test the updated v2 web client: create, edit, reschedule,
   return to Inbox, restore from Trash and sync an iOS-created item.
   Verify older upserts never erase or reuse an obsolete Inbox timestamp.
3. Deploy **both migrations to production before shipping web contract v2 or
   the new iOS cloud-payload client** (using the approved Supabase migration
   workflow), and confirm both recorded versions. No hosted deployment has
   been performed as part of this repository update.
4. Release/update iOS, then verify Pro-user push/pull between two devices.
   Free/local-only mode should remain unaffected by the remote change.
5. Web contract v2 is now implemented in repository source and unit-tested:
   additively typed, locally cached, serialized, reconciled and updated on
   explicit Inbox transitions. Release it only after the backend upgrade.
   Then bring Android to v2 in a later release.
6. Retain backward-compatible SQL while old clients remain in the wild.
   Never retroactively edit an already-applied migration; use another
   timestamped migration for future changes.

**Read-only post-deploy verification (Supabase SQL editor):**

```sql
select version
from supabase_migrations.schema_migrations
where version in ('202610230001', '202610230002')
order by version;

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

**Web (contract v2 implemented locally; production not deployed):**
The optional `inbox_entered_at` now survives local cache, pending queue,
cloud pull/push and explicit status transitions. A legacy Inbox/null schedule
is no longer silently transformed into a deferred item. The web currently
has **no Inbox-age UI** and still treats due deferred items as Inbox-visible
without eagerly transitioning their persisted status. Implement the focused
Today/overdue review and Inbox-age display in the next UI phase, with careful
timezone and already-due-item handling. Keep historical unknown dates NULL.

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
