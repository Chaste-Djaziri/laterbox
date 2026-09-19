import type { LaterBoxItem } from '../supabase/types';
export type ReturnPreset = 'now' | 'laterToday' | 'tomorrow' | 'weekend' | 'someday';
export type ScheduleView = 'today' | 'upcoming' | 'someday';
export function resolveReturnPreset(preset: ReturnPreset, now = new Date()): string | null {
  const date = new Date(now);
  switch (preset) {
    case 'someday': return null;
    case 'now': return date.toISOString();
    case 'laterToday': return new Date(date.getTime() + 3 * 3600000).toISOString();
    case 'tomorrow': date.setDate(date.getDate() + 1); date.setHours(9, 0, 0, 0); break;
    case 'weekend': date.setDate(date.getDate() + ((6 - date.getDay() + 7) % 7 || 7)); date.setHours(9, 0, 0, 0); break;
  }
  return date.toISOString();
}
export function isActive(item: LaterBoxItem): boolean {
  return !item.deleted_at && (item.status === 'inbox' || item.status === 'deferred');
}
export function isDue(item: LaterBoxItem, now: Date): boolean {
  return isActive(item) && (item.status === 'inbox' || (!!item.return_at && new Date(item.return_at) <= now));
}
export function scheduleItems(items: LaterBoxItem[], view: ScheduleView, now: Date): LaterBoxItem[] {
  return items.filter(item => {
    if (!isActive(item)) return false;
    if (view === 'someday') return !item.return_at && !isDue(item, now);
    if (!item.return_at) return false;
    const time = new Date(item.return_at);
    return view === 'upcoming' ? time > now : time.toDateString() === now.toDateString();
  }).sort((a, b) => view === 'someday' ? b.created_at.localeCompare(a.created_at)
    : new Date(a.return_at!).getTime() - new Date(b.return_at!).getTime());
}
export function migrateSchedule(item: LaterBoxItem): LaterBoxItem {
  if (item.status === 'inbox' && !item.return_at) {
    return { ...item, status: 'deferred', return_at: item.created_at };
  }
  return item;
}
export function returnLabel(value?: string | null): string {
  return value ? new Date(value).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' }) : 'Someday';
}
