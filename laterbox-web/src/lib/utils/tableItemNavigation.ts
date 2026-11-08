// laterbox-web/src/lib/utils/tableItemNavigation.ts
/** URL helpers for the full-detail reading view inside the email-style item table. */
export function readEmailTableItemId(search: string): string | null {
  const id = new URLSearchParams(search).get('item')?.trim();
  return id || null;
}

export function emailTableItemHref(currentHref: string, itemId: string | null): string {
  const url = new URL(currentHref);
  if (itemId) url.searchParams.set('item', itemId);
  else url.searchParams.delete('item');
  return url.toString();
}
