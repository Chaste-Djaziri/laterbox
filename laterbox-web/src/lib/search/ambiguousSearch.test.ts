import test from 'node:test';
import assert from 'node:assert/strict';
import { parseAmbiguousQuery, filterAndRankAmbiguousItems } from './ambiguousSearch';
import type { LaterBoxItem } from '@/lib/supabase/types';

test('parses typo video and month in "a cideo i saved in october"', () => {
  const ref = new Date('2026-10-15T12:00:00Z');
  const parsed = parseAmbiguousQuery('a cideo i saved in october', ref);

  assert.equal(parsed.contentType, 'video');
  assert.ok(parsed.dateRange);
  assert.equal(parsed.dateRange?.start?.getUTCMonth(), 9); // October is index 9
  assert.equal(parsed.dateRange?.start?.getUTCFullYear(), 2026);
  assert.equal(parsed.hasAmbiguousFilters, true);
  assert.match(parsed.explanation, /Type: VIDEO/);
});

test('parses month date ranges "between May and August"', () => {
  const ref = new Date('2026-10-15T12:00:00Z');
  const parsed = parseAmbiguousQuery('between May and August', ref);

  assert.ok(parsed.dateRange);
  assert.equal(parsed.dateRange?.start?.getUTCMonth(), 4); // May is index 4
  assert.equal(parsed.dateRange?.end?.getUTCMonth(), 7); // August is index 7
  assert.match(parsed.dateRange?.label || '', /Between May and August/);
});

test('parses relative dates like "last week" and content typo "artical"', () => {
  const ref = new Date('2026-10-15T12:00:00Z');
  const parsed = parseAmbiguousQuery('artical saved last week about react', ref);

  assert.equal(parsed.contentType, 'article');
  assert.ok(parsed.dateRange);
  assert.equal(parsed.cleanedKeywords, 'react');
});

test('filterAndRankAmbiguousItems matches items by typo format and date range', () => {
  const ref = new Date('2026-10-15T12:00:00Z');
  const items: LaterBoxItem[] = [
    {
      id: 'item-1',
      title: 'Next.js 16 Tutorial',
      url: 'https://youtube.com/watch?v=123',
      type: 'video',
      status: 'inbox',
      favorite: false,
      created_at: '2026-10-04T12:00:00Z',
      updated_at: '2026-10-04T12:00:00Z',
      metadata: { item_id: 'item-1', content_type: 'video', title: 'Next.js 16 Tutorial', created_at: '2026-10-04T12:00:00Z', updated_at: '2026-10-04T12:00:00Z', status: 'enriched', attempt_count: 1 },
    },
    {
      id: 'item-2',
      title: 'CSS Grid Guide',
      url: 'https://css-tricks.com/guide',
      type: 'link',
      status: 'inbox',
      favorite: false,
      created_at: '2026-05-01T12:00:00Z',
      updated_at: '2026-05-01T12:00:00Z',
      metadata: { item_id: 'item-2', content_type: 'article', title: 'CSS Grid Guide', created_at: '2026-05-01T12:00:00Z', updated_at: '2026-05-01T12:00:00Z', status: 'enriched', attempt_count: 1 },
    },
  ];

  const parsed = parseAmbiguousQuery('a cideo i saved in october', ref);
  const results = filterAndRankAmbiguousItems(items, parsed);

  assert.equal(results.length, 1);
  assert.equal(results[0].item.id, 'item-1');
  assert.ok(results[0].matchedFields.includes('format'));
  assert.ok(results[0].matchedFields.includes('date'));
});
