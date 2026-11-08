// laterbox-web/src/lib/utils/taskChecklist.ts
import type { ItemMetadata, LaterBoxItem } from '../supabase/types';
import { moveItemToInbox, transitionItemStatus } from './schedule';

/** A task group is one saved task containing an ordered checklist in item metadata. */
export interface TaskChecklistEntry {
  id: string;
  title: string;
  done: boolean;
}

export const MAX_TASK_CHECKLIST_ENTRIES = 40;
const MAX_TASK_TITLE_LENGTH = 200;
const CHECKLIST_VERSION = 1;

function record(value: unknown): Record<string, unknown> | null {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

export function readStructuredData(metadata?: ItemMetadata | null): Record<string, unknown> {
  if (!metadata?.structured_data) return {};
  try {
    const parsed = typeof metadata.structured_data === 'string'
      ? JSON.parse(metadata.structured_data)
      : metadata.structured_data;
    return record(parsed) || {};
  } catch {
    return {};
  }
}

export function readTaskChecklist(item: Pick<LaterBoxItem, 'type' | 'metadata'>): TaskChecklistEntry[] | null {
  if (item.type !== 'task') return null;
  const raw = record(readStructuredData(item.metadata).taskChecklist);
  if (raw?.version !== CHECKLIST_VERSION || !Array.isArray(raw.entries)) return null;

  const seen = new Set<string>();
  const entries: TaskChecklistEntry[] = [];
  for (const candidate of raw.entries.slice(0, MAX_TASK_CHECKLIST_ENTRIES)) {
    const field = record(candidate);
    if (!field || typeof field.id !== 'string' || typeof field.title !== 'string') continue;
    const id = field.id.trim();
    const title = field.title.trim().slice(0, MAX_TASK_TITLE_LENGTH);
    if (!id || !title || seen.has(id)) continue;
    seen.add(id);
    entries.push({ id, title, done: field.done === true });
  }
  return entries.length ? entries : null;
}

export function validateTaskChecklist(entries: readonly TaskChecklistEntry[]): TaskChecklistEntry[] | null {
  if (entries.length < 2 || entries.length > MAX_TASK_CHECKLIST_ENTRIES) return null;
  const validated: TaskChecklistEntry[] = [];
  const seen = new Set<string>();
  for (const entry of entries) {
    const title = entry.title.trim();
    const id = entry.id.trim();
    if (!id || !title || title.length > MAX_TASK_TITLE_LENGTH || seen.has(id)) return null;
    seen.add(id);
    validated.push({ id, title, done: entry.done === true });
  }
  return validated;
}

export function taskChecklistProgress(entries: readonly TaskChecklistEntry[]): { done: number; total: number; allDone: boolean } {
  const done = entries.filter(entry => entry.done).length;
  return { done, total: entries.length, allDone: entries.length > 0 && done === entries.length };
}

export function withTaskChecklist(
  item: LaterBoxItem,
  entries: readonly TaskChecklistEntry[],
  timestamp: string,
): LaterBoxItem {
  if (item.type !== 'task') throw new Error('Only tasks can have checklists.');
  if (!readTaskChecklist(item)) throw new Error('This task is not a checklist.');
  const normalized = validateTaskChecklist(entries);
  if (!normalized) throw new Error('A checklist needs at least two uniquely identified, named tasks.');
  const progress = taskChecklistProgress(normalized);
  const state = progress.allDone
    ? transitionItemStatus(item, 'archived', timestamp)
    : item.status === 'archived'
      ? moveItemToInbox(item, timestamp)
      : item;
  // Merge after the status transition so reopening an archived group also
  // preserves moveItemToInbox's seen=false marker in structured_data.
  const current = readStructuredData(state.metadata);
  const metadata: ItemMetadata = {
    ...(state.metadata || {
      item_id: item.id,
      user_id: item.user_id,
      status: 'pending' as const,
      attempt_count: 0,
      created_at: timestamp,
    }),
    structured_data: JSON.stringify({
      ...current,
      taskChecklist: { version: CHECKLIST_VERSION, entries: normalized },
    }),
    updated_at: timestamp,
  };
  return { ...state, metadata, updated_at: timestamp };
}

/** Complete or reopen an entire task group in one consistent state transition. */
export function setTaskChecklistComplete(
  item: LaterBoxItem,
  done: boolean,
  timestamp: string,
): LaterBoxItem {
  const entries = readTaskChecklist(item);
  if (!entries) return item;
  return withTaskChecklist(item, entries.map(entry => ({ ...entry, done })), timestamp);
}

export function newTaskChecklistData(entries: readonly TaskChecklistEntry[]): { version: 1; entries: TaskChecklistEntry[] } {
  const normalized = validateTaskChecklist(entries);
  if (!normalized) throw new Error('A task group requires at least two valid tasks.');
  return { version: 1, entries: normalized };
}
