import type { LaterBoxItem } from '../supabase/types';
export type ReturnPreset = 'now' | 'oneHour' | 'laterToday' | 'tomorrow' | 'weekend' | 'oneWeek' | 'oneMonth' | 'someday';
export type ScheduleView = 'today' | 'upcoming' | 'someday';
export function resolveReturnPreset(preset: ReturnPreset, now = new Date()): string | null {
  const date = new Date(now);
  switch (preset) {
    case 'someday': return null;
    case 'now': return date.toISOString();
    case 'oneHour': return new Date(date.getTime() + 3600000).toISOString();
    case 'laterToday': return new Date(date.getTime() + 3 * 3600000).toISOString();
    case 'tomorrow': date.setDate(date.getDate() + 1); date.setHours(9, 0, 0, 0); break;
    case 'weekend': date.setDate(date.getDate() + ((6 - date.getDay() + 7) % 7 || 7)); date.setHours(9, 0, 0, 0); break;
    case 'oneWeek': date.setDate(date.getDate() + 7); date.setHours(9, 0, 0, 0); break;
    case 'oneMonth': date.setMonth(date.getMonth() + 1); date.setHours(9, 0, 0, 0); break;
  }
  return date.toISOString();
}
export function isActive(item: LaterBoxItem): boolean {
  return !item.deleted_at && (item.status === 'inbox' || item.status === 'deferred');
}
export function isDue(item: LaterBoxItem, now: Date): boolean {
  return isActive(item) && (item.status === 'inbox' || (!!item.return_at && new Date(item.return_at) <= now));
}
/** Calendar-day boundaries use the viewer's local timezone, including DST days. */
export function todayFocusItems(items: LaterBoxItem[], now: Date): { overdue: LaterBoxItem[]; returningToday: LaterBoxItem[] } {
  const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  const nextDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1).getTime();
  const candidates = items.filter(item => {
    if (item.deleted_at || item.status !== 'deferred' || !item.return_at) return false;
    const timestamp = new Date(item.return_at).getTime();
    return Number.isFinite(timestamp) && timestamp < nextDay;
  }).sort((a, b) => new Date(a.return_at!).getTime() - new Date(b.return_at!).getTime());

  return {
    overdue: candidates.filter(item => new Date(item.return_at!).getTime() < dayStart),
    returningToday: candidates.filter(item => new Date(item.return_at!).getTime() >= dayStart),
  };
}

/** Returns null for missing/invalid history rather than inventing an Inbox entry. */
export function formatInboxAge(item: LaterBoxItem, now: Date): string | null {
  if (item.status !== 'inbox' || item.deleted_at || !item.inbox_entered_at) return null;
  const entered = new Date(item.inbox_entered_at).getTime();
  if (!Number.isFinite(entered) || entered > now.getTime()) return null;
  const minutes = Math.floor((now.getTime() - entered) / 60000);
  if (minutes < 1) return 'Just entered Inbox';
  if (minutes < 60) return `In Inbox for ${minutes} min`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `In Inbox for ${hours} hr${hours === 1 ? '' : 's'}${minutes % 60 ? `, ${minutes % 60} min` : ''}`;
  const days = Math.floor(hours / 24);
  return `In Inbox for ${days} day${days === 1 ? '' : 's'}${hours % 24 ? `, ${hours % 24} hr${hours % 24 === 1 ? '' : 's'}` : ''}`;
}

export function scheduleItems(items: LaterBoxItem[], view: ScheduleView, now: Date): LaterBoxItem[] {
  return items.filter(item => {
    if (!isActive(item)) return false;
    if (view === 'someday') return !item.return_at && !isDue(item, now);
    if (!item.return_at) return false;
    const time = new Date(item.return_at);
    if (!Number.isFinite(time.getTime()) || item.status !== 'deferred') return false;
    const nextDay = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    return view === 'today' ? time < nextDay : time >= nextDay;
  }).sort((a, b) => view === 'someday' ? b.created_at.localeCompare(a.created_at)
    : new Date(a.return_at!).getTime() - new Date(b.return_at!).getTime());
}
/** Legacy records must preserve their explicit lifecycle state.
 * Rewriting Inbox/null-return records as Deferred is not a safe migration.
 */
export function migrateSchedule(item: LaterBoxItem): LaterBoxItem {
  return item;
}

/** Centralized lifecycle transition used by web and cloud reconciliation. */
export function transitionItemStatus(
  item: LaterBoxItem,
  status: LaterBoxItem['status'],
  timestamp: string,
): LaterBoxItem {
  const enteringInbox = status === 'inbox' && (item.status !== 'inbox' || !!item.deleted_at);
  return {
    ...item,
    status,
    inbox_entered_at: enteringInbox ? timestamp : (item.inbox_entered_at ?? null),
    updated_at: timestamp,
  };
}

export function moveItemToInbox(item: LaterBoxItem, timestamp: string): LaterBoxItem {
  let metadata = item.metadata;
  if (metadata) {
    try {
      const parsed: unknown = metadata.structured_data ? JSON.parse(metadata.structured_data) : {};
      if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
        metadata = {
          ...metadata,
          structured_data: JSON.stringify({ ...parsed, seen: false }),
          updated_at: timestamp,
        };
      }
    } catch {
      // Keep malformed legacy metadata intact; the item-level flag is still reset.
    }
  }
  return {
    ...transitionItemStatus(item, 'inbox', timestamp),
    metadata,
    return_at: null,
    seen: false,
  };
}

export function restoreItemToInbox(item: LaterBoxItem, timestamp: string): LaterBoxItem {
  return { ...moveItemToInbox(item, timestamp), deleted_at: null };
}

export function scheduleItemReturn(item: LaterBoxItem, returnAt: string | null, timestamp: string): LaterBoxItem {
  return { ...transitionItemStatus(item, 'deferred', timestamp), return_at: returnAt };
}
export function returnLabel(value?: string | null): string {
  return value ? new Date(value).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' }) : 'Someday';
}
