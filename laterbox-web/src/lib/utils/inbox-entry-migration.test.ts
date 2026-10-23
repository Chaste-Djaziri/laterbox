import assert from 'node:assert/strict';
import test from 'node:test';
import { readFileSync } from 'node:fs';
import { PGlite } from '@electric-sql/pglite';

// Execute the actual migrations inside an isolated PostgreSQL-compatible database.
const migration1 = readFileSync(new URL('../../../../supabase/migrations/202610230001_inbox_entry_timestamp.sql', import.meta.url), 'utf8');
const migration2 = readFileSync(new URL('../../../../supabase/migrations/202610230002_correct_inbox_entry_transitions.sql', import.meta.url), 'utf8');

test('legacy and modern clients agree on actual Inbox-entry timestamps', async () => {
  const db = new PGlite();
  try {
    await db.exec('CREATE TABLE public.items (id text PRIMARY KEY, status text NOT NULL, deleted_at timestamptz, created_at timestamptz NOT NULL, updated_at timestamptz NOT NULL)');
    await db.exec(migration1);
    await db.exec(migration2);

    const assertEntry = async (id: string, expected: string) => {
      const result = await db.query<{ matches: boolean }>(
        'SELECT inbox_entered_at IS NOT DISTINCT FROM $2::timestamptz AS matches FROM public.items WHERE id = $1',
        [id, expected],
      );
      assert.equal(result.rows[0]?.matches, true, 'Wrong Inbox-entry timestamp for ' + id);
    };

    // Legacy client inserts without the new field.
    await db.exec("INSERT INTO public.items (id,status,created_at,updated_at) VALUES ('legacy','inbox','2026-10-01T09:00:00Z','2026-10-01T09:00:00Z')");
    await assertEntry('legacy', '2026-10-01T09:00:00Z');

    // Ordinary updates (even explicit NULL writes) preserve known history.
    await db.exec("UPDATE public.items SET inbox_entered_at = NULL, updated_at = '2026-10-02T09:00:00Z' WHERE id = 'legacy'");
    await assertEntry('legacy', '2026-10-01T09:00:00Z');

    await db.exec("UPDATE public.items SET status = 'deferred', updated_at = '2026-10-03T09:00:00Z' WHERE id = 'legacy'");
    await assertEntry('legacy', '2026-10-01T09:00:00Z');

    // Old UPSERT does not name inbox_entered_at; it must still reset on re-entry.
    await db.exec("INSERT INTO public.items (id,status,created_at,updated_at) VALUES ('legacy','inbox','2026-10-01T09:00:00Z','2026-10-04T09:00:00Z') ON CONFLICT (id) DO UPDATE SET status=EXCLUDED.status, updated_at=EXCLUDED.updated_at");
    await assertEntry('legacy', '2026-10-04T09:00:00Z');

    await db.exec("UPDATE public.items SET updated_at = '2026-10-05T09:00:00Z' WHERE id = 'legacy'");
    await assertEntry('legacy', '2026-10-04T09:00:00Z');

    // iOS can supply a distinct timestamp explicitly on a new transition.
    await db.exec("UPDATE public.items SET status = 'deferred', updated_at = '2026-10-06T09:00:00Z' WHERE id = 'legacy'");
    await db.exec("UPDATE public.items SET status = 'inbox', inbox_entered_at = '2026-10-07T08:30:00Z', updated_at = '2026-10-07T09:00:00Z' WHERE id = 'legacy'");
    await assertEntry('legacy', '2026-10-07T08:30:00Z');

    // Restoring a deleted Inbox item counts as a new entry.
    await db.exec("UPDATE public.items SET deleted_at = '2026-10-08T09:00:00Z', updated_at = '2026-10-08T09:00:00Z' WHERE id = 'legacy'");
    await db.exec("UPDATE public.items SET deleted_at = NULL, updated_at = '2026-10-09T09:00:00Z' WHERE id = 'legacy'");
    await assertEntry('legacy', '2026-10-09T09:00:00Z');

    // Never invent historical dates for older deferred records.
    await db.exec("INSERT INTO public.items (id,status,created_at,updated_at) VALUES ('historical','deferred','2026-09-01T09:00:00Z','2026-09-01T09:00:00Z')");
    const unknown = await db.query<{ unknown: boolean }>("SELECT inbox_entered_at IS NULL AS unknown FROM public.items WHERE id = 'historical'");
    assert.equal(unknown.rows[0].unknown, true);
    await db.exec("UPDATE public.items SET status = 'inbox', updated_at = '2026-10-10T09:00:00Z' WHERE id = 'historical'");
    await assertEntry('historical', '2026-10-10T09:00:00Z');
  } finally {
    await db.close();
  }
});
