// laterbox-web/src/components/item/TaskGroupChecklist.tsx
'use client';

import { useState, type FormEvent } from 'react';
import { Check, CheckCheck, ListTodo, Pencil, Plus, Trash2, X } from 'lucide-react';
import {
  MAX_TASK_CHECKLIST_ENTRIES, taskChecklistProgress, type TaskChecklistEntry,
} from '@/lib/utils/taskChecklist';

interface TaskGroupChecklistProps {
  entries: TaskChecklistEntry[];
  busy: boolean;
  error: string | null;
  onUpdate: (entries: TaskChecklistEntry[]) => Promise<void>;
}

export function TaskGroupChecklist({ entries, busy, error, onUpdate }: TaskGroupChecklistProps) {
  const progress = taskChecklistProgress(entries);
  const [adding, setAdding] = useState(false);
  const [newTitle, setNewTitle] = useState('');
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editTitle, setEditTitle] = useState('');

  const sendUpdate = (updated: TaskChecklistEntry[]) => {
    // The details page surfaces persistence failures in the checklist error area.
    void onUpdate(updated).catch(() => {});
  };

  const toggle = (id: string) => {
    sendUpdate(entries.map(entry => entry.id === id ? { ...entry, done: !entry.done } : entry));
  };

  const addTask = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const title = newTitle.trim();
    if (!title || busy || entries.length >= MAX_TASK_CHECKLIST_ENTRIES) return;
    try {
      await onUpdate([...entries, { id: crypto.randomUUID(), title, done: false }]);
      setNewTitle('');
      setAdding(false);
    } catch {
      // The parent displays the persistence error and leaves the draft intact.
    }
  };

  const renameTask = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const title = editTitle.trim();
    if (!title || busy || !editingId) return;
    try {
      await onUpdate(entries.map(entry => entry.id === editingId ? { ...entry, title } : entry));
      setEditingId(null);
      setEditTitle('');
    } catch {
      // The parent displays the persistence error.
    }
  };

  return (
    <section aria-label="Task group checklist" className="overflow-hidden rounded-[22px] border border-[#d8e3bd] bg-[#fbfcf6]">
      <div className="border-b border-[#e4e9d9] bg-[#f2f7e7] px-5 py-5 sm:px-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-start gap-3">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#e6edb0] text-[#40552f]">
              <ListTodo className="h-5 w-5" aria-hidden="true" />
            </span>
            <div>
              <h2 className="text-sm font-black text-[#24301e]">Group checklist</h2>
              <p className="mt-1 text-xs font-medium text-[#77856e]">
                {progress.done} of {progress.total} tasks completed
              </p>
            </div>
          </div>
          <button
            type="button"
            disabled={busy}
            onClick={() => sendUpdate(entries.map(entry => ({ ...entry, done: !progress.allDone })))}
            className="inline-flex min-h-10 items-center gap-2 rounded-full border border-[#d2dfb6] bg-white px-4 text-xs font-bold text-[#435d35] transition-colors hover:bg-[#e6edb0] disabled:cursor-not-allowed disabled:opacity-45 focus-visible:outline-2 focus-visible:outline-[#839c57]"
          >
            <CheckCheck className="h-4 w-4" aria-hidden="true" />
            {progress.allDone ? 'Reopen all' : 'Complete all'}
          </button>
        </div>
        <div
          role="progressbar"
          aria-label="Group completion"
          aria-valuemin={0}
          aria-valuemax={progress.total}
          aria-valuenow={progress.done}
          className="mt-5 h-2 overflow-hidden rounded-full bg-[#dce6c9]"
        >
          <div
            className="h-full rounded-full bg-[#779953] transition-[width] duration-300"
            style={{ width: `${progress.total ? progress.done / progress.total * 100 : 0}%` }}
          />
        </div>
      </div>

      <ul className="divide-y divide-[#eef0e8] px-3 sm:px-4">
        {entries.map((entry, index) => (
          <li key={entry.id} className="flex min-h-[70px] items-center gap-3 px-2 py-3">
            <button
              type="button"
              role="checkbox"
              aria-checked={entry.done}
              aria-label={`${entry.done ? 'Reopen' : 'Complete'}: ${entry.title}`}
              disabled={busy}
              onClick={() => toggle(entry.id)}
              className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl border-2 transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#839c57] disabled:cursor-not-allowed disabled:opacity-45 ${
                entry.done
                  ? 'border-[#829d5d] bg-[#e6edb0] text-[#3a5427]'
                  : 'border-[#cbd5bd] bg-white text-transparent hover:border-[#829d5d]'
              }`}
            >
              <Check className="h-5 w-5" strokeWidth={3} aria-hidden="true" />
            </button>
            {editingId === entry.id ? (
              <form onSubmit={renameTask} className="flex min-w-0 flex-1 items-center gap-2">
                <label className="min-w-0 flex-1">
                  <span className="sr-only">Rename task {index + 1}</span>
                  <input
                    type="text"
                    autoFocus
                    maxLength={200}
                    required
                    disabled={busy}
                    value={editTitle}
                    onChange={event => setEditTitle(event.target.value)}
                    onKeyDown={event => { if (event.key === 'Escape') setEditingId(null); }}
                    className="w-full rounded-xl border border-[#cbdab4] bg-white px-3 py-2 text-sm font-semibold text-[#24301e] outline-none focus:border-[#869d5b] focus:ring-2 focus:ring-[#e6edb0]"
                  />
                </label>
                <button type="submit" aria-label="Save task name" disabled={busy || !editTitle.trim()} className="rounded-xl bg-[#e6edb0] p-2 text-[#41552d] disabled:opacity-40"><Check className="h-4 w-4" /></button>
                <button type="button" aria-label="Cancel renaming" onClick={() => setEditingId(null)} className="rounded-xl p-2 text-[#788273]"><X className="h-4 w-4" /></button>
              </form>
            ) : (
              <>
                <span className={`min-w-0 flex-1 break-words text-sm font-semibold leading-6 ${
                  entry.done ? 'text-[#94a08e] line-through decoration-[#aebca4]' : 'text-[#283425]'
                }`}>{entry.title}</span>
                <button
                  type="button"
                  title="Rename task"
                  aria-label={`Rename ${entry.title}`}
                  disabled={busy}
                  onClick={() => { setEditingId(entry.id); setEditTitle(entry.title); }}
                  className="shrink-0 rounded-lg p-2 text-[#9ba599] transition-colors hover:bg-[#edf3e3] hover:text-[#435936] disabled:opacity-40 focus-visible:outline-2 focus-visible:outline-[#839c57]"
                >
                  <Pencil className="h-4 w-4" aria-hidden="true" />
                </button>
                <button
                  type="button"
                  title="Remove task"
                  aria-label={`Remove ${entry.title}`}
                  disabled={busy || entries.length <= 2}
                  onClick={() => sendUpdate(entries.filter(row => row.id !== entry.id))}
                  className="shrink-0 rounded-lg p-2 text-[#a7a9a0] transition-colors hover:bg-red-50 hover:text-red-600 disabled:cursor-not-allowed disabled:opacity-25 focus-visible:outline-2 focus-visible:outline-[#839c57]"
                >
                  <Trash2 className="h-4 w-4" aria-hidden="true" />
                </button>
              </>
            )}
          </li>
        ))}
      </ul>

      <div className="border-t border-[#e7ebdc] bg-white/70 p-4 sm:p-5">
        {adding ? (
          <form onSubmit={addTask} className="flex flex-wrap items-center gap-2">
            <label className="min-w-[150px] flex-1">
              <span className="sr-only">New task name</span>
              <input
                autoFocus
                type="text"
                maxLength={200}
                required
                disabled={busy}
                value={newTitle}
                onChange={event => setNewTitle(event.target.value)}
                placeholder="What else needs doing?"
                className="w-full rounded-xl border border-[#d9e2d0] bg-white px-3.5 py-2.5 text-sm text-[#263223] outline-none focus:border-[#8ca660] focus:ring-2 focus:ring-[#e6edb0]"
              />
            </label>
            <button type="submit" disabled={busy || !newTitle.trim()} className="min-h-10 rounded-xl bg-[#23301e] px-4 text-xs font-bold text-white disabled:opacity-40">Add</button>
            <button type="button" onClick={() => { setAdding(false); setNewTitle(''); }} className="min-h-10 rounded-xl px-3 text-xs font-bold text-[#849079]">Cancel</button>
          </form>
        ) : (
          <button
            type="button"
            disabled={busy || entries.length >= MAX_TASK_CHECKLIST_ENTRIES}
            onClick={() => setAdding(true)}
            className="inline-flex min-h-10 items-center gap-2 rounded-full bg-[#e6edb0] px-4 text-xs font-bold text-[#394c2c] transition-colors hover:bg-[#dce8a0] disabled:opacity-40 focus-visible:outline-2 focus-visible:outline-[#839c57]"
          >
            <Plus className="h-4 w-4" aria-hidden="true" /> Add a task
          </button>
        )}
        {progress.allDone && (
          <p className="mt-3 text-xs font-semibold text-[#607c48]">All done. This group is now completed.</p>
        )}
        {error && <p role="alert" className="mt-3 text-xs font-semibold text-red-700">{error}</p>}
      </div>
    </section>
  );
}
