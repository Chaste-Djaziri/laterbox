// laterbox-web/src/components/item/NoteEditor.tsx
'use client';

import React, { useEffect, useRef, useState } from 'react';
import {
  Check, CornerDownRight, FileText, Loader2, MessageSquareText,
  Pencil, Send, Smile, Trash2, X,
} from 'lucide-react';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { fetchAttachmentDownloadUrl } from '@/lib/utils/attachment';
import {
  addThreadEntry,
  deleteThreadEntry,
  editThreadEntry,
  parseItemThread,
  POPULAR_REACTIONS,
  serializeItemThread,
  toggleThreadReaction,
  voteThreadPoll,
  type ItemThreadEntry,
  type ParsedItemThread,
  type ThreadAttachmentRef,
} from '@/lib/utils/itemThread';

interface NoteEditorProps {
  itemId: string;
  initialContent?: string | null;
}

function noteTime(value: string): string {
  const date = new Date(value);
  return Number.isNaN(date.getTime())
    ? 'Recently'
    : date.toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });
}

/**
 * Item notes use the SAME version:1 JSON thread format as the iOS detail
 * screen and web Inbox side panel. Never display or edit the raw JSON string.
 */
export function NoteEditor({ itemId, initialContent }: NoteEditorProps) {
  const { saveNote } = useItems();
  const { user } = useAuth();

  const [thread, setThread] = useState<ParsedItemThread>(() => parseItemThread(initialContent));
  const [draft, setDraft] = useState('');
  const [quotedEntry, setQuotedEntry] = useState<ItemThreadEntry | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [editingText, setEditingText] = useState('');
  const [reactionPickerId, setReactionPickerId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const savingRef = useRef(false);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Another device or the side panel may update the thread while this page
    // is open. Ignore prop echoes only during this component's own save.
    if (!savingRef.current) {
      setThread(parseItemThread(initialContent));
    }
  }, [initialContent, itemId]);

  async function persist(next: ParsedItemThread): Promise<boolean> {
    if (savingRef.current) return false;
    const previous = thread;
    savingRef.current = true;
    setSaving(true);
    setSaved(false);
    setError(null);
    setThread(next);
    try {
      await saveNote(
        itemId,
        serializeItemThread(next.entries, next.rootReactions, next.rootUserReactions),
      );
      setSaved(true);
      return true;
    } catch (cause) {
      setThread(previous);
      setError(cause instanceof Error ? cause.message : 'Could not save this note. Try again.');
      return false;
    } finally {
      savingRef.current = false;
      setSaving(false);
    }
  }

  async function send() {
    const text = draft.trim();
    if (!text || savingRef.current) return;

    const next: ParsedItemThread = {
      ...thread,
      entries: addThreadEntry(thread.entries, {
        type: 'message',
        authorName: 'Me',
        content: text,
        attachedToId: quotedEntry?.id,
        attachedSnippet: quotedEntry?.content.slice(0, 80),
      }),
    };

    if (await persist(next)) {
      setDraft('');
      setQuotedEntry(null);
      requestAnimationFrame(() => bottomRef.current?.scrollIntoView({
        behavior: 'smooth',
        block: 'nearest',
      }));
    }
  }

  async function updateEntry(entryId: string) {
    const text = editingText.trim();
    if (!text) return;
    if (await persist({
      ...thread,
      entries: editThreadEntry(thread.entries, entryId, text),
    })) {
      setEditingId(null);
      setEditingText('');
    }
  }

  async function removeEntry(entryId: string) {
    if (!window.confirm('Delete this follow-up?')) return;
    await persist({
      ...thread,
      entries: deleteThreadEntry(thread.entries, entryId),
    });
    if (quotedEntry?.id === entryId) setQuotedEntry(null);
  }

  async function react(entryId: string, emoji: string) {
    await persist({
      ...thread,
      entries: toggleThreadReaction(thread.entries, entryId, emoji),
    });
    setReactionPickerId(null);
  }

  async function vote(entryId: string, optionId: string) {
    await persist({
      ...thread,
      entries: voteThreadPoll(thread.entries, entryId, optionId),
    });
  }

  async function openAttachment(attachment: ThreadAttachmentRef) {
    const url = attachment.url
      || await fetchAttachmentDownloadUrl(attachment.id, user?.id ?? null);
    if (!url) {
      setError(`Could not open ${attachment.name}.`);
      return;
    }
    window.open(url, '_blank', 'noopener,noreferrer');
  }

  return (
    <section aria-label="Notes and follow-ups" className="my-4 rounded-2xl border border-[#e4e0d5] bg-[#f7f5ee] shadow-2xs">
      <div className="flex items-center justify-between gap-3 px-4 pt-4 pb-3 sm:px-5">
        <div className="flex min-w-0 items-center gap-2.5">
          <MessageSquareText aria-hidden="true" className="h-4 w-4 shrink-0 text-[#171711]" />
          <h2 className="truncate text-xs font-black uppercase tracking-[0.08em] text-[#171711]">
            Notes &amp; Follow-ups
          </h2>
          <span className="rounded-full bg-white px-2 py-0.5 text-[11px] font-bold text-[#6c6b63]">
            {thread.entries.length}
          </span>
        </div>
        <div className="text-[11px] font-medium text-[#6c6b63]" aria-live="polite">
          {saving ? (
            <span className="inline-flex items-center gap-1"><Loader2 className="h-3 w-3 animate-spin" /> Saving…</span>
          ) : saved ? (
            <span className="inline-flex items-center gap-1"><Check className="h-3 w-3" /> Saved</span>
          ) : null}
        </div>
      </div>

      <div className="space-y-3 px-4 pb-4 sm:px-5">
        {thread.entries.length === 0 ? (
          <div className="rounded-xl border border-dashed border-[#e4e0d5] bg-white/70 px-4 py-7 text-center">
            <MessageSquareText className="mx-auto h-6 w-6 text-[#9e9b92]" />
            <p className="mt-2 text-sm font-bold text-[#171711]">No follow-ups yet</p>
            <p className="mt-1 text-xs text-[#6c6b63]">Keep your thoughts and replies together in one conversation.</p>
          </div>
        ) : thread.entries.map((entry) => {
          const totalVotes = entry.poll?.options.reduce((sum, option) => sum + (option.votes || 0), 0) || 0;
          return (
            <article key={entry.id} className="group rounded-xl border border-[#e4e0d5] bg-white px-3.5 py-3 shadow-2xs sm:px-4">
              <div className="flex items-center gap-2">
                <div className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-[#171711] text-[11px] font-black text-[#e6edb0]" aria-hidden="true">
                  {(entry.authorName || 'Me').slice(0, 1).toUpperCase()}
                </div>
                <span className="min-w-0 truncate text-xs font-bold text-[#171711]">{entry.authorName || 'Me'}</span>
                <time dateTime={entry.createdAt} className="shrink-0 text-[10px] text-[#8e8d87]">
                  {noteTime(entry.createdAt)}
                </time>
                {entry.updatedAt && <span className="text-[10px] text-[#9e9b92]">Edited</span>}
                <div className="ml-auto flex shrink-0 items-center gap-0.5">
                  <button
                    type="button"
                    onClick={() => { setQuotedEntry(entry); inputRef.current?.focus(); }}
                    aria-label="Reply to note"
                    title="Reply"
                    className="rounded-lg p-1.5 text-[#6c6b63] hover:bg-[#f7f5ee] hover:text-[#171711]"
                  ><CornerDownRight className="h-3.5 w-3.5" /></button>
                  <button
                    type="button"
                    disabled={saving}
                    onClick={() => { setEditingId(entry.id); setEditingText(entry.content); }}
                    aria-label="Edit note"
                    title="Edit"
                    className="rounded-lg p-1.5 text-[#6c6b63] hover:bg-[#f7f5ee] hover:text-[#171711] disabled:opacity-40"
                  ><Pencil className="h-3.5 w-3.5" /></button>
                  <button
                    type="button"
                    disabled={saving}
                    onClick={() => void removeEntry(entry.id)}
                    aria-label="Delete note"
                    title="Delete"
                    className="rounded-lg p-1.5 text-[#6c6b63] hover:bg-rose-50 hover:text-rose-600 disabled:opacity-40"
                  ><Trash2 className="h-3.5 w-3.5" /></button>
                </div>
              </div>

              {entry.attachedSnippet && (
                <blockquote className="mt-3 border-l-2 border-[#b0b99d] bg-[#f7f5ee] px-3 py-2 text-xs italic text-[#6c6b63]">
                  {entry.attachedSnippet}
                </blockquote>
              )}

              {editingId === entry.id ? (
                <div className="mt-3 space-y-2">
                  <textarea
                    value={editingText}
                    onChange={(event) => setEditingText(event.target.value)}
                    rows={3}
                    aria-label="Edit note content"
                    className="w-full resize-y rounded-xl border border-[#d8d4c9] bg-white p-3 text-sm text-[#171711] focus:border-[#171711] focus:outline-none"
                  />
                  <div className="flex justify-end gap-2">
                    <button type="button" onClick={() => setEditingId(null)} className="rounded-lg px-3 py-1.5 text-xs font-semibold text-[#6c6b63]">Cancel</button>
                    <button type="button" disabled={!editingText.trim() || saving} onClick={() => void updateEntry(entry.id)} className="rounded-lg bg-[#171711] px-3 py-1.5 text-xs font-bold text-[#e6edb0] disabled:opacity-40">Save</button>
                  </div>
                </div>
              ) : entry.type === 'poll' && entry.poll ? (
                <div className="mt-3 space-y-2">
                  <p className="text-sm font-semibold text-[#171711]">{entry.poll.question}</p>
                  {entry.poll.options.map((option) => {
                    const percent = totalVotes ? Math.round((option.votes / totalVotes) * 100) : 0;
                    const isSelected = entry.poll?.userVotedOptionId === option.id;
                    return (
                      <button
                        key={option.id}
                        type="button"
                        disabled={saving}
                        onClick={() => void vote(entry.id, option.id)}
                        className={`relative flex w-full items-center justify-between overflow-hidden rounded-lg border px-3 py-2 text-left text-xs text-[#171711] disabled:opacity-50 ${isSelected ? 'border-[#82985c]' : 'border-[#e4e0d5]'}`}
                      >
                        <span className="absolute inset-y-0 left-0 bg-[#e6edb0]/65" style={{ width: `${percent}%` }} />
                        <span className="relative font-semibold">{isSelected ? '✓ ' : ''}{option.text}</span>
                        <span className="relative text-[#6c6b63]">{percent}%</span>
                      </button>
                    );
                  })}
                </div>
              ) : (
                <div className="mt-3 space-y-2">
                  {entry.content && !(entry.attachments?.length === 1 && entry.content === entry.attachments[0].name) && (
                    <p className="whitespace-pre-wrap break-words text-sm leading-relaxed text-[#171711]">{entry.content}</p>
                  )}
                  {entry.attachments?.map((attachment) => (
                    <button
                      key={attachment.id}
                      type="button"
                      onClick={() => void openAttachment(attachment)}
                      className="flex max-w-full items-center gap-2 rounded-lg border border-[#e4e0d5] bg-[#faf9f5] px-3 py-2 text-left text-xs font-semibold text-[#171711] hover:border-[#919b83]"
                    >
                      <FileText className="h-4 w-4 shrink-0" />
                      <span className="truncate">{attachment.name}</span>
                    </button>
                  ))}
                </div>
              )}

              <div className="mt-3 flex flex-wrap items-center gap-1">
                {Object.entries(entry.reactions || {}).filter(([, count]) => count > 0).map(([emoji, count]) => (
                  <button
                    key={emoji}
                    type="button"
                    disabled={saving}
                    onClick={() => void react(entry.id, emoji)}
                    className={`rounded-full border px-2 py-0.5 text-[11px] ${entry.userReactions?.includes(emoji) ? 'border-[#cdd9a4] bg-[#f0f4df]' : 'border-[#e4e0d5] bg-[#f7f5ee]'}`}
                    aria-label={`React ${emoji}, ${count}`}
                  >{emoji} {count}</button>
                ))}
                <div className="relative">
                  <button
                    type="button"
                    onClick={() => setReactionPickerId(reactionPickerId === entry.id ? null : entry.id)}
                    aria-label="Add reaction"
                    className="rounded-full p-1 text-[#9e9b92] hover:bg-[#f7f5ee] hover:text-[#171711]"
                  ><Smile className="h-4 w-4" /></button>
                  {reactionPickerId === entry.id && (
                    <div className="absolute bottom-full left-0 z-20 mb-2 flex gap-1 rounded-full border border-[#e4e0d5] bg-white px-2 py-1.5 shadow-lg">
                      {POPULAR_REACTIONS.map((emoji) => (
                        <button key={emoji} type="button" disabled={saving} onClick={() => void react(entry.id, emoji)} className="p-1 text-sm hover:scale-110">{emoji}</button>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </article>
          );
        })}
        <div ref={bottomRef} />
      </div>

      <div className="sticky bottom-0 z-10 rounded-b-2xl border-t border-[#e4e0d5] bg-[#f7f5ee]/95 px-4 py-3 backdrop-blur-sm sm:px-5">
        {quotedEntry && (
          <div className="mb-2 flex items-center gap-2 rounded-lg bg-[#eeeadd] px-3 py-2 text-xs text-[#6c6b63]">
            <CornerDownRight className="h-3.5 w-3.5 shrink-0" />
            <span className="min-w-0 flex-1 truncate">Replying to “{quotedEntry.content.slice(0, 75)}”</span>
            <button type="button" onClick={() => setQuotedEntry(null)} aria-label="Cancel reply"><X className="h-3.5 w-3.5" /></button>
          </div>
        )}
        <div className="flex items-end gap-2 rounded-2xl border border-[#d9d5ca] bg-white px-2.5 py-2 shadow-xs focus-within:border-[#8c9879] focus-within:ring-2 focus-within:ring-[#e6edb0]/60">
          <textarea
            ref={inputRef}
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' && !event.shiftKey && !event.nativeEvent.isComposing) {
                event.preventDefault();
                void send();
              }
            }}
            rows={1}
            placeholder="Add a follow-up, thought, or note..."
            aria-label="Write a follow-up"
            className="max-h-40 min-h-9 flex-1 resize-y bg-transparent px-1 py-2 text-sm text-[#171711] placeholder:text-[#9e9b92] focus:outline-none"
          />
          <button
            type="button"
            onClick={() => void send()}
            disabled={saving || !draft.trim()}
            aria-label="Send follow-up"
            title="Send"
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#171711] text-[#e6edb0] disabled:cursor-not-allowed disabled:opacity-30"
          >
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
          </button>
        </div>
        {error && <p role="alert" className="mt-2 text-xs font-semibold text-red-700">{error}</p>}
        <p className="mt-1.5 text-[10px] text-[#8e8d87]">Enter to send · Shift + Enter for a new line</p>
      </div>
    </section>
  );
}
