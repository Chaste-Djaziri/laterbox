// laterbox-web/src/lib/billing/storage-usage.ts
// Shared quota presentation for authenticated accounts. Never infer usage from local bookmarks.
export type StorageUsageLevel = 'unknown' | 'normal' | 'warning' | 'critical' | 'full';

export interface StorageUsageState {
  level: StorageUsageLevel;
  percent: number | null;
  usedBytes: number | null;
  limitBytes: number | null;
  title: string;
  description: string;
}

export function getStorageUsage(used: number | null | undefined, limit: number | null | undefined): StorageUsageState {
  const validLimit = typeof limit === 'number' && Number.isFinite(limit) && limit > 0;
  const validUsed = typeof used === 'number' && Number.isFinite(used) && used >= 0;
  if (!validLimit || !validUsed) {
    return {
      level: 'unknown',
      percent: null,
      usedBytes: null,
      limitBytes: validLimit ? limit : null,
      title: 'Storage usage unavailable',
      description: 'We could not retrieve your current cloud storage usage.',
    };
  }
  const percent = (used / limit) * 100;
  if (percent >= 100) return {
    level: 'full', percent, usedBytes: used, limitBytes: limit,
    title: 'Storage full',
    description: 'Your storage limit has been reached. Upgrade your plan or remove stored files to free up space.',
  };
  if (percent >= 95) return {
    level: 'critical', percent, usedBytes: used, limitBytes: limit,
    title: 'Storage nearly full',
    description: 'Less than 5% of your cloud space remains. Upgrade or clear unused files soon.',
  };
  if (percent >= 80) return {
    level: 'warning', percent, usedBytes: used, limitBytes: limit,
    title: 'Storage almost full',
    description: 'You have used over 80% of your cloud space. Consider freeing space or upgrading.',
  };
  return {
    level: 'normal', percent, usedBytes: used, limitBytes: limit,
    title: 'Cloud storage',
    description: 'Your cloud storage is within its plan limit.',
  };
}

export function formatStorageBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes < 0) return 'Unavailable';
  if (bytes === 0) return '0 MB';
  if (bytes < 1_000_000) return `${Math.ceil(bytes / 1_000)} KB`;
  if (bytes < 1_000_000_000) return `${Number((bytes / 1_000_000).toFixed(1))} MB`;
  return `${Number((bytes / 1_000_000_000).toFixed(2))} GB`;
}
