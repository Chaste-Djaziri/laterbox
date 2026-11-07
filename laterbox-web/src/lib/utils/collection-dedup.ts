import type { Collection, LaterBoxItem } from '../supabase/types';

/** One logical collection per owner + case/whitespace-insensitive name. */
export function collectionNameKey(name: string): string {
  return name.trim().toLowerCase();
}

export interface CollectionDuplicate {
  duplicate: Collection;
  canonical: Collection;
}

/**
 * Keep the oldest collection ID so existing links stay stable. Every duplicate
 * ID is mapped to its survivor, allowing memberships to be unioned safely.
 * No records or items are deleted by this pure function.
 */
export function planCollectionMerge(collections: Collection[]) {
  const canonicalById = new Map<string, Collection>();
  const canonicalByName = new Map<string, Collection>();
  const duplicates: CollectionDuplicate[] = [];

  const active = collections.filter(collection => !collection.deleted_at);
  const oldestFirst = [...active].sort((a, b) =>
    a.created_at.localeCompare(b.created_at) || a.id.localeCompare(b.id)
  );

  for (const collection of oldestFirst) {
    if (canonicalById.has(collection.id)) continue;
    const name = collectionNameKey(collection.name);
    const key = name ? `${collection.user_id || 'guest'}:\0${name}` : collection.id;
    const canonical = canonicalByName.get(key);
    if (canonical) {
      canonicalById.set(collection.id, canonical);
      duplicates.push({ duplicate: collection, canonical });
    } else {
      canonicalByName.set(key, collection);
      canonicalById.set(collection.id, collection);
    }
  }

  const seen = new Set<string>();
  const unique = active.filter(collection => {
    const canonical = canonicalById.get(collection.id);
    if (!canonical || seen.has(canonical.id) || collection.id !== canonical.id) return false;
    seen.add(canonical.id);
    return true;
  });
  // Retain canonical collections even when the newest-first input listed aliases first.
  for (const collection of oldestFirst) {
    if (!seen.has(collection.id) && canonicalById.get(collection.id)?.id === collection.id) {
      unique.push(collection);
      seen.add(collection.id);
    }
  }

  return { collections: unique, canonicalById, duplicates };
}

export function remapItemCollections<T extends LaterBoxItem>(
  items: T[],
  canonicalById: Map<string, Collection>,
): T[] {
  return items.map(item => {
    if (!item.collections?.length) return item;
    const seen = new Set<string>();
    const next = item.collections.flatMap(collection => {
      const canonical = canonicalById.get(collection.id) || collection;
      if (seen.has(canonical.id)) return [];
      seen.add(canonical.id);
      return [canonical];
    });
    return { ...item, collections: next };
  });
}
