// laterbox-web/src/lib/billing/storage-write-guard.ts
import { getAccessToken } from '@/lib/auth/tokens';
import type { Entitlement } from './types';

export class StorageFullError extends Error {
  constructor() {
    super('Storage full. Delete stored files or upgrade your plan on the LaterBox website before saving more.');
    this.name = 'StorageFullError';
  }
}

export function assertStorageWritable(
  used: number | null | undefined,
  limit: number | null | undefined,
  additionalBytes = 0,
): void {
  if (typeof used !== 'number' || !Number.isFinite(used) || used < 0 ||
      typeof limit !== 'number' || !Number.isFinite(limit) || limit <= 0) return;
  if (used >= limit || used + Math.max(0, additionalBytes) > limit) {
    throw new StorageFullError();
  }
}

/// Refresh account usage before an explicit write. If offline, rely on the
/// last known entitlement; the database still blocks over-quota cloud writes.
export async function requireStorageCapacity(
  cached: Pick<Entitlement, 'storageUsedBytes' | 'storageLimitBytes'>,
  additionalBytes = 0,
): Promise<void> {
  try {
    let token = await getAccessToken();
    if (!token) {
      assertStorageWritable(cached.storageUsedBytes, cached.storageLimitBytes, additionalBytes);
      return;
    }
    let response = await fetch('/api/billing/entitlement', {
      headers: { Authorization: `Bearer ${token}` }, cache: 'no-store',
    });
    if (response.status === 401) {
      token = await getAccessToken(true);
      if (token) response = await fetch('/api/billing/entitlement', {
        headers: { Authorization: `Bearer ${token}` }, cache: 'no-store',
      });
    }
    if (!response.ok) throw new Error('Storage usage could not be refreshed.');
    const latest = await response.json() as Pick<Entitlement, 'storageUsedBytes' | 'storageLimitBytes'>;
    assertStorageWritable(latest.storageUsedBytes, latest.storageLimitBytes, additionalBytes);
  } catch (error) {
    if (error instanceof StorageFullError) throw error;
    // Offline operations remain locally available only when the last known
    // account quota does not say full. Cloud quota enforcement is server-side.
    assertStorageWritable(cached.storageUsedBytes, cached.storageLimitBytes, additionalBytes);
  }
}
