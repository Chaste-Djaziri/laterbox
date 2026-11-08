// laterbox-web/src/lib/utils/prepareCaptureDraft.ts
import type { CaptureKind } from './captureSuggestions';
import { validateTaskChecklist, type TaskChecklistEntry } from './taskChecklist';

export interface PreparedCaptureDraft {
  value: string;
  title?: string;
  type: 'link' | 'file' | 'note' | 'task';
  taskChecklist?: TaskChecklistEntry[];
}

export type CaptureDraftInput = {
  kind: CaptureKind;
  content: string;
  title?: string | null;
  suggestedTitle?: string;
  fileCount?: number;
  taskChecklist?: TaskChecklistEntry[];
};

/**
 * Prepare a creation payload without confusing a task (action + optional details)
 * with a note (writing + optional title). No storage or UI side effects.
 */
export function prepareCaptureDraft(input: CaptureDraftInput): PreparedCaptureDraft | null {
  const text = input.content.trim();
  const title = input.title?.trim() ?? '';
  const files = input.fileCount ?? 0;

  if (input.kind === 'task') {
    if (!title) return null;
    if (input.taskChecklist) {
      const taskChecklist = validateTaskChecklist(input.taskChecklist);
      if (!taskChecklist) return null;
      return { type: 'task', title, value: text || title, taskChecklist };
    }
    return { type: 'task', title, value: text || title };
  }

  if (input.kind === 'note') {
    if (!text) return null;
    return { type: 'note', title: title || input.suggestedTitle?.trim() || text.split(/\r?\n/)[0].slice(0, 100), value: text };
  }

  if (!text && !files) return null;

  if (input.kind === 'file' || files > 0) {
    return { type: 'file', value: text, title: title || undefined };
  }
  return { type: 'link', value: text, title: title || undefined };
}
