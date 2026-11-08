// laterbox-web/src/lib/utils/tableItemNavigation.test.ts
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { emailTableItemHref, readEmailTableItemId } from './tableItemNavigation';

describe('email table item details navigation', () => {
  it('opens an item without losing the current table route, filters or hash', () => {
    const href = emailTableItemHref(
      'https://app.laterbox.dev/library/saved?filter=starred#recent',
      'item-42',
    );
    assert.equal(href, 'https://app.laterbox.dev/library/saved?filter=starred&item=item-42#recent');
    assert.equal(readEmailTableItemId(new URL(href).search), 'item-42');
  });

  it('navigates between items without duplicating the query parameter', () => {
    const href = emailTableItemHref('https://app.laterbox.dev/inbox?item=old&filter=all', 'new');
    const url = new URL(href);
    assert.deepEqual(url.searchParams.getAll('item'), ['new']);
    assert.equal(url.searchParams.get('filter'), 'all');
  });

  it('removes only the detail parameter when returning to the table', () => {
    const href = emailTableItemHref('https://app.laterbox.dev/inbox?filter=media&item=abc', null);
    assert.equal(href, 'https://app.laterbox.dev/inbox?filter=media');
  });

  it('treats blank or missing item parameters as the table view', () => {
    assert.equal(readEmailTableItemId('?item=%20'), null);
    assert.equal(readEmailTableItemId('?filter=starred'), null);
    assert.equal(readEmailTableItemId('?item=abc-123'), 'abc-123');
  });
});
