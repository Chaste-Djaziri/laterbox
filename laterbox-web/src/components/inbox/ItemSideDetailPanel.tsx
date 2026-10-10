'use client';

import React, { useState, useMemo, useRef, useEffect } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { LaterBoxItem } from '@/lib/supabase/types';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { getEmailSender, formatEmailDate } from '@/lib/utils/emailFormatters';
import {
  parseItemThread,
  serializeItemThread,
  addThreadEntry,
  editThreadEntry,
  deleteThreadEntry,
  toggleThreadReaction,
  voteThreadPoll,
  ItemThreadEntry,
  POPULAR_REACTIONS,
} from '@/lib/utils/itemThread';
import {
  X,
  ExternalLink,
  Star,
  Archive,
  Trash2,
  Paperclip,
  Send,
  Plus,
  BarChart2,
  Smile,
  Pencil,
  CornerDownRight,
  MessageSquare,
  Check,
  Globe,
  MoreVertical,
  Calendar,
  Sparkles,
} from 'lucide-react';

interface ItemSideDetailPanelProps {
  item: LaterBoxItem;
  onClose: () => void;
}

export function ItemSideDetailPanel({ item, onClose }: ItemSideDetailPanelProps) {
  const router = useRouter();
  const { setFavorite, archiveItem, deleteItem, saveNote } = useItems();
  const { userName, user } = useAuth();

  const authorName = userName || user?.user_metadata?.full_name || 'You';

  // Thread entries parsed from item note
  const threadEntries = useMemo(() => {
    return parseItemThread(item.note?.content);
  }, [item.note?.content]);

  // Input state
  const [inputText, setInputText] = useState('');
  const [attachedEntry, setAttachedEntry] = useState<ItemThreadEntry | null>(null);
  const [plusMenuOpen, setPlusMenuOpen] = useState(false);
  const [pollCreatorOpen, setPollCreatorOpen] = useState(false);
  const [editingEntryId, setEditingEntryId] = useState<string | null>(null);
  const [editText, setEditText] = useState('');
  const [reactionMenuForId, setReactionMenuForId] = useState<string | null>(null);

  // Poll creator state
  const [pollQuestion, setPollQuestion] = useState('');
  const [pollOptions, setPollOptions] = useState<string[]>(['Option 1', 'Option 2']);

  const plusMenuRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const threadBottomRef = useRef<HTMLDivElement>(null);

  // Close menus on outside click
  useEffect(() => {
    const handleClick = (e: MouseEvent) => {
      if (plusMenuRef.current && !plusMenuRef.current.contains(e.target as Node)) {
        setPlusMenuOpen(false);
      }
    };
    window.addEventListener('mousedown', handleClick);
    return () => window.removeEventListener('mousedown', handleClick);
  }, []);

  const persistThread = async (updated: ItemThreadEntry[]) => {
    const serialized = serializeItemThread(updated);
    await saveNote(item.id, serialized);
  };

  const handleSendMessage = async () => {
    const text = inputText.trim();
    if (!text) return;

    const newEntries = addThreadEntry(threadEntries, {
      type: 'message',
      authorName,
      content: text,
      attachedToId: attachedEntry?.id,
      attachedSnippet: attachedEntry
        ? attachedEntry.content.slice(0, 80)
        : undefined,
    });

    await persistThread(newEntries);
    setInputText('');
    setAttachedEntry(null);
    setTimeout(() => {
      threadBottomRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const handleCreatePoll = async () => {
    const question = pollQuestion.trim();
    const validOptions = pollOptions.map((o) => o.trim()).filter(Boolean);

    if (!question || validOptions.length < 2) return;

    const newEntries = addThreadEntry(threadEntries, {
      type: 'poll',
      authorName,
      content: question,
      attachedToId: attachedEntry?.id,
      attachedSnippet: attachedEntry
        ? attachedEntry.content.slice(0, 80)
        : undefined,
      poll: {
        question,
        options: validOptions.map((opt, i) => ({
          id: `opt-${i}-${Date.now()}`,
          text: opt,
          votes: 0,
        })),
      },
    });

    await persistThread(newEntries);
    setPollQuestion('');
    setPollOptions(['Option 1', 'Option 2']);
    setPollCreatorOpen(false);
    setAttachedEntry(null);
    setTimeout(() => {
      threadBottomRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const handleSaveEdit = async (id: string) => {
    if (!editText.trim()) return;
    const updated = editThreadEntry(threadEntries, id, editText.trim());
    await persistThread(updated);
    setEditingEntryId(null);
    setEditText('');
  };

  const handleDeleteEntry = async (id: string) => {
    const updated = deleteThreadEntry(threadEntries, id);
    await persistThread(updated);
  };

  const handleToggleReaction = async (id: string, emoji: string) => {
    const updated = toggleThreadReaction(threadEntries, id, emoji);
    await persistThread(updated);
    setReactionMenuForId(null);
  };

  const handleVotePoll = async (entryId: string, optionId: string) => {
    const updated = voteThreadPoll(threadEntries, entryId, optionId);
    await persistThread(updated);
  };

  const sender = getEmailSender(item);
  const title = item.metadata?.title || item.title || 'Saved Item';
  const description = item.metadata?.description || item.text_content || '';
  const isStarred = Boolean(item.favorite);

  return (
    <div className="flex flex-col h-full bg-white relative overflow-hidden select-none">
      {/* 1. TOP HEADER: Title, Sender info & Actions */}
      <div className="shrink-0 p-4 border-b border-[#e4e0d5] bg-white space-y-3">
        {/* Top actions toolbar */}
        <div className="flex items-center justify-between gap-2">
          {/* External link / Full page */}
          <Link
            href={`/item/${item.id}`}
            title="Open full page"
            className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f5] transition-colors"
          >
            <ExternalLink className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Open in full</span>
          </Link>

          {/* Quick Action Buttons */}
          <div className="flex items-center gap-1 text-[#6c6b63]">
            {/* Star button */}
            <button
              type="button"
              onClick={() => setFavorite(item.id, !isStarred)}
              title={isStarred ? 'Unstar' : 'Star'}
              className="p-1.5 rounded-lg hover:bg-[#faf8f5] hover:text-amber-500 transition-colors cursor-pointer"
            >
              <Star
                className={`w-4 h-4 ${
                  isStarred ? 'fill-amber-400 text-amber-400' : ''
                }`}
              />
            </button>

            {/* Archive button */}
            <button
              type="button"
              onClick={() => {
                archiveItem(item.id);
                onClose();
              }}
              title="Archive"
              className="p-1.5 rounded-lg hover:bg-[#faf8f5] hover:text-[#171711] transition-colors cursor-pointer"
            >
              <Archive className="w-4 h-4" />
            </button>

            {/* Delete button */}
            <button
              type="button"
              onClick={() => {
                deleteItem(item.id);
                onClose();
              }}
              title="Delete"
              className="p-1.5 rounded-lg hover:bg-rose-50 hover:text-rose-600 transition-colors cursor-pointer"
            >
              <Trash2 className="w-4 h-4" />
            </button>

            <div className="h-4 w-px bg-[#e4e0d5] mx-1" />

            {/* Close side split button */}
            <button
              type="button"
              onClick={onClose}
              title="Close details (Esc)"
              className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Item Title & Domain */}
        <div>
          <h2 className="text-base sm:text-lg font-black text-[#171711] tracking-tight line-clamp-2 leading-snug">
            {title}
          </h2>

          {/* Sender meta bar */}
          <div className="flex items-center gap-2.5 mt-2 text-xs text-[#6c6b63]">
            <div className="w-6 h-6 rounded-full bg-[#171711] text-[#e6edb0] font-black text-[10px] flex items-center justify-center shrink-0">
              {sender.slice(0, 2).toUpperCase()}
            </div>
            <div className="min-w-0 flex-1 truncate">
              <span className="font-bold text-[#171711]">{sender}</span>
              {item.metadata?.domain && (
                <span className="text-[#8e8d87] ml-1.5">• {item.metadata.domain}</span>
              )}
            </div>
            <span className="shrink-0 text-[11px] text-[#8e8d87] font-medium">
              {formatEmailDate(item.created_at)}
            </span>
          </div>
        </div>
      </div>

      {/* 2. SCROLLABLE CONTENT BODY & THREAD STREAM */}
      <div className="flex-1 overflow-y-auto p-4 sm:p-5 space-y-5 bg-[#faf8f5]/40 select-text">
        {/* Main Content Card */}
        <div className="bg-white border border-[#e4e0d5] rounded-2xl p-4 shadow-2xs space-y-3">
          {/* OpenGraph Preview Image Banner */}
          {item.metadata?.preview_image_url && (
            <div className="relative w-full h-44 sm:h-52 rounded-xl overflow-hidden bg-[#faf8f5] border border-[#e4e0d5]/60">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={item.metadata.preview_image_url}
                alt=""
                className="w-full h-full object-cover"
                onError={(e) => {
                  (e.currentTarget as HTMLElement).style.display = 'none';
                }}
              />
            </div>
          )}

          {/* Text snippet / content */}
          {description && (
            <p className="text-xs sm:text-sm text-[#45443f] leading-relaxed whitespace-pre-wrap">
              {description}
            </p>
          )}

          {/* Attachments List */}
          {item.attachments && item.attachments.length > 0 && (
            <div className="pt-2 border-t border-[#f0ede4] flex flex-wrap gap-2">
              {item.attachments.map((att) => (
                <div
                  key={att.id}
                  className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-[#faf8f5] border border-[#e4e0d5] text-xs font-semibold text-[#171711]"
                >
                  <Paperclip className="w-3.5 h-3.5 text-[#6c6b63]" />
                  <span className="truncate max-w-[200px]">
                    {att.original_file_name}
                  </span>
                </div>
              ))}
            </div>
          )}

          {/* External link button */}
          {item.url && (
            <div className="pt-2 flex items-center justify-between">
              <a
                href={item.url}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1 text-xs font-bold text-[#171711] hover:underline"
              >
                <Globe className="w-3.5 h-3.5 text-[#6c6b63]" />
                <span className="truncate max-w-xs">{item.url}</span>
              </a>
            </div>
          )}
        </div>

        {/* Interactive Thread Stream Header */}
        <div className="flex items-center gap-2 pt-2">
          <MessageSquare className="w-3.5 h-3.5 text-[#8e8d87]" />
          <span className="text-[11px] font-bold uppercase tracking-wider text-[#8e8d87]">
            Notes, Follow-ups & Polls ({threadEntries.length})
          </span>
          <div className="flex-1 h-px bg-[#e4e0d5]" />
        </div>

        {/* Thread Stream Entries */}
        {threadEntries.length === 0 ? (
          <div className="text-center py-6 px-4 bg-white/60 border border-dashed border-[#e4e0d5] rounded-2xl">
            <Sparkles className="w-6 h-6 mx-auto text-[#8e8d87] stroke-[1.5]" />
            <p className="text-xs font-bold text-[#171711] mt-2">
              No follow-ups added yet
            </p>
            <p className="text-[11px] text-[#8e8d87] mt-0.5">
              Use the prompt below to add notes, create polls, or attach thoughts.
            </p>
          </div>
        ) : (
          <div className="space-y-3">
            {threadEntries.map((entry) => {
              const totalVotes =
                entry.poll?.options.reduce((acc, curr) => acc + (curr.votes || 0), 0) || 0;

              return (
                <div
                  key={entry.id}
                  className="bg-white border border-[#e4e0d5] rounded-2xl p-3.5 shadow-2xs space-y-2.5 group transition-all"
                >
                  {/* Top: Author & Timestamp */}
                  <div className="flex items-center justify-between text-xs text-[#6c6b63]">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-[#171711]">
                        {entry.authorName || 'Note'}
                      </span>
                      {entry.type === 'poll' && (
                        <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-[#e6edb0] text-[#171711]">
                          Poll
                        </span>
                      )}
                      <span className="text-[10px] text-[#9e9b92]">
                        {formatEmailDate(entry.createdAt)}
                      </span>
                    </div>

                    {/* Entry Action buttons */}
                    <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                      {/* Attach / Reply to this */}
                      <button
                        type="button"
                        onClick={() => {
                          setAttachedEntry(entry);
                          inputRef.current?.focus();
                        }}
                        title="Attach as context"
                        className="p-1 rounded text-[#8e8d87] hover:text-[#171711] hover:bg-[#faf8f5] transition-colors"
                      >
                        <CornerDownRight className="w-3 h-3" />
                      </button>

                      {/* Edit button */}
                      {entry.type !== 'poll' && (
                        <button
                          type="button"
                          onClick={() => {
                            setEditingEntryId(entry.id);
                            setEditText(entry.content);
                          }}
                          title="Edit note"
                          className="p-1 rounded text-[#8e8d87] hover:text-[#171711] hover:bg-[#faf8f5] transition-colors"
                        >
                          <Pencil className="w-3 h-3" />
                        </button>
                      )}

                      {/* Delete button */}
                      <button
                        type="button"
                        onClick={() => handleDeleteEntry(entry.id)}
                        title="Delete entry"
                        className="p-1 rounded text-[#8e8d87] hover:text-rose-600 hover:bg-rose-50 transition-colors"
                      >
                        <Trash2 className="w-3 h-3" />
                      </button>
                    </div>
                  </div>

                  {/* Attached Previous Message Quote Preview */}
                  {entry.attachedSnippet && (
                    <div className="flex items-start gap-2 px-2.5 py-1.5 bg-[#faf8f5] border-l-2 border-[#171711] rounded text-[11px] text-[#6c6b63]">
                      <Paperclip className="w-3 h-3 shrink-0 text-[#8e8d87] mt-0.5" />
                      <span className="truncate italic">
                        Attached: &ldquo;{entry.attachedSnippet}&rdquo;
                      </span>
                    </div>
                  )}

                  {/* Entry Body Content */}
                  {editingEntryId === entry.id ? (
                    <div className="space-y-2">
                      <textarea
                        value={editText}
                        onChange={(e) => setEditText(e.target.value)}
                        className="w-full text-xs p-2.5 border border-[#171711] rounded-xl focus:outline-none bg-[#faf8f5]/40"
                        rows={3}
                      />
                      <div className="flex justify-end gap-1.5">
                        <button
                          type="button"
                          onClick={() => setEditingEntryId(null)}
                          className="px-2.5 py-1 text-xs font-bold text-[#6c6b63] hover:text-[#171711]"
                        >
                          Cancel
                        </button>
                        <button
                          type="button"
                          onClick={() => handleSaveEdit(entry.id)}
                          className="px-3 py-1 text-xs font-bold bg-[#171711] text-[#e6edb0] rounded-lg shadow-2xs cursor-pointer"
                        >
                          Save
                        </button>
                      </div>
                    </div>
                  ) : entry.type === 'poll' && entry.poll ? (
                    /* Interactive Poll View */
                    <div className="space-y-2 pt-1">
                      <p className="text-xs sm:text-sm font-bold text-[#171711]">
                        {entry.poll.question}
                      </p>
                      <div className="space-y-1.5">
                        {entry.poll.options.map((option) => {
                          const isVoted = entry.poll?.userVotedOptionId === option.id;
                          const percent =
                            totalVotes > 0 ? Math.round((option.votes / totalVotes) * 100) : 0;

                          return (
                            <button
                              key={option.id}
                              type="button"
                              onClick={() => handleVotePoll(entry.id, option.id)}
                              className={`w-full relative text-left p-2.5 rounded-xl border text-xs font-semibold overflow-hidden transition-all cursor-pointer ${
                                isVoted
                                  ? 'border-[#171711] bg-[#faf8f5]'
                                  : 'border-[#e4e0d5] bg-white hover:border-[#171711]/50'
                              }`}
                            >
                              {/* Progress bar background fill */}
                              <div
                                className={`absolute left-0 top-0 bottom-0 transition-all ${
                                  isVoted ? 'bg-[#e6edb0]/70' : 'bg-[#f0ede4]/60'
                                }`}
                                style={{ width: `${percent}%` }}
                              />

                              {/* Option label & vote count */}
                              <div className="relative z-10 flex items-center justify-between">
                                <span className="flex items-center gap-1.5 font-bold text-[#171711]">
                                  {isVoted && <Check className="w-3.5 h-3.5 text-[#171711]" />}
                                  {option.text}
                                </span>
                                <span className="text-[11px] text-[#6c6b63] font-mono">
                                  {percent}% ({option.votes})
                                </span>
                              </div>
                            </button>
                          );
                        })}
                      </div>
                      <p className="text-[10px] text-[#9e9b92] pt-0.5">
                        {totalVotes} {totalVotes === 1 ? 'vote' : 'votes'} total • Click option to vote
                      </p>
                    </div>
                  ) : (
                    <p className="text-xs sm:text-sm text-[#171711] whitespace-pre-wrap leading-relaxed">
                      {entry.content}
                    </p>
                  )}

                  {/* Reaction Bar */}
                  <div className="flex flex-wrap items-center gap-1 pt-1">
                    {/* Active reactions */}
                    {Object.entries(entry.reactions || {}).map(([emoji, count]) => {
                      if (count <= 0) return null;
                      const hasUserReacted = entry.userReactions?.includes(emoji);
                      return (
                        <button
                          key={emoji}
                          type="button"
                          onClick={() => handleToggleReaction(entry.id, emoji)}
                          className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold border transition-all cursor-pointer ${
                            hasUserReacted
                              ? 'bg-[#171711] text-[#e6edb0] border-[#171711]'
                              : 'bg-white text-[#171711] border-[#e4e0d5] hover:bg-[#faf8f5]'
                          }`}
                        >
                          <span>{emoji}</span>
                          <span className="text-[10px] font-bold">{count}</span>
                        </button>
                      );
                    })}

                    {/* Quick Reaction Picker Toggle */}
                    <div className="relative">
                      <button
                        type="button"
                        onClick={() =>
                          setReactionMenuForId(
                            reactionMenuForId === entry.id ? null : entry.id
                          )
                        }
                        title="Add reaction"
                        className="p-1 rounded-full text-[#8e8d87] hover:text-[#171711] hover:bg-[#faf8f5] transition-colors cursor-pointer"
                      >
                        <Smile className="w-3.5 h-3.5" />
                      </button>

                      {reactionMenuForId === entry.id && (
                        <div className="absolute left-0 bottom-full mb-1 bg-white border border-[#e4e0d5] rounded-full shadow-lg px-2 py-1 flex items-center gap-1.5 z-40 animate-in fade-in zoom-in-95">
                          {POPULAR_REACTIONS.map((emoji) => (
                            <button
                              key={emoji}
                              type="button"
                              onClick={() => handleToggleReaction(entry.id, emoji)}
                              className="hover:scale-125 transition-transform text-sm cursor-pointer p-0.5"
                            >
                              {emoji}
                            </button>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

        <div ref={threadBottomRef} />
      </div>

      {/* 3. CHATGPT-STYLE FLOATING BOTTOM PILL INPUT BAR */}
      <div className="shrink-0 p-3 sm:p-4 bg-gradient-to-t from-white via-white to-white/90 border-t border-[#e4e0d5]">
        {/* Attached Entry Preview Banner */}
        {attachedEntry && (
          <div className="mb-2 flex items-center justify-between px-3 py-1.5 bg-[#f0ede4] border border-[#e4e0d5] rounded-xl text-xs text-[#171711] animate-in fade-in">
            <div className="flex items-center gap-1.5 truncate">
              <CornerDownRight className="w-3.5 h-3.5 text-[#6c6b63] shrink-0" />
              <span className="font-bold shrink-0">Attaching context:</span>
              <span className="truncate text-[#6c6b63]">
                &ldquo;{attachedEntry.content.slice(0, 60)}...&rdquo;
              </span>
            </div>
            <button
              type="button"
              onClick={() => setAttachedEntry(null)}
              className="p-0.5 text-[#8e8d87] hover:text-[#171711] rounded"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        )}

        {/* Poll Creator Modal / Box */}
        {pollCreatorOpen && (
          <div className="mb-3 p-3.5 bg-white border border-[#e4e0d5] rounded-2xl shadow-xl space-y-2.5 animate-in fade-in zoom-in-95">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-[#171711] flex items-center gap-1.5">
                <BarChart2 className="w-3.5 h-3.5 text-[#171711]" />
                Create a Poll
              </span>
              <button
                type="button"
                onClick={() => setPollCreatorOpen(false)}
                className="text-[#8e8d87] hover:text-[#171711]"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            </div>

            <input
              type="text"
              value={pollQuestion}
              onChange={(e) => setPollQuestion(e.target.value)}
              placeholder="Ask a question (e.g. Is this urgent?)..."
              className="w-full text-xs p-2 rounded-xl border border-[#e4e0d5] focus:border-[#171711] focus:outline-none"
            />

            <div className="space-y-1.5">
              {pollOptions.map((opt, idx) => (
                <div key={idx} className="flex items-center gap-1.5">
                  <input
                    type="text"
                    value={opt}
                    onChange={(e) => {
                      const next = [...pollOptions];
                      next[idx] = e.target.value;
                      setPollOptions(next);
                    }}
                    placeholder={`Option ${idx + 1}`}
                    className="flex-1 text-xs p-1.5 rounded-lg border border-[#e4e0d5] focus:border-[#171711] focus:outline-none"
                  />
                  {pollOptions.length > 2 && (
                    <button
                      type="button"
                      onClick={() => setPollOptions(pollOptions.filter((_, i) => i !== idx))}
                      className="p-1 text-[#8e8d87] hover:text-rose-600"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  )}
                </div>
              ))}
            </div>

            <div className="flex items-center justify-between pt-1">
              <button
                type="button"
                onClick={() => setPollOptions([...pollOptions, `Option ${pollOptions.length + 1}`])}
                className="text-xs font-bold text-[#6c6b63] hover:text-[#171711] inline-flex items-center gap-1"
              >
                <Plus className="w-3 h-3" />
                <span>Add option</span>
              </button>

              <div className="flex gap-1.5">
                <button
                  type="button"
                  onClick={() => setPollCreatorOpen(false)}
                  className="px-2.5 py-1 text-xs font-bold text-[#6c6b63] hover:text-[#171711]"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={handleCreatePoll}
                  className="px-3.5 py-1 text-xs font-bold bg-[#171711] text-[#e6edb0] rounded-lg shadow-2xs cursor-pointer"
                >
                  Publish Poll
                </button>
              </div>
            </div>
          </div>
        )}

        {/* The Main ChatGPT-style Pill Bar */}
        <div className="relative flex items-center bg-[#171711] text-white rounded-full px-2.5 py-1.5 shadow-md">
          {/* Left Plus Action Button */}
          <div className="relative shrink-0" ref={plusMenuRef}>
            <button
              type="button"
              onClick={() => setPlusMenuOpen(!plusMenuOpen)}
              title="Add options"
              className="w-7 h-7 rounded-full bg-white/10 hover:bg-white/20 text-white flex items-center justify-center transition-colors cursor-pointer"
            >
              <Plus className="w-4 h-4" />
            </button>

            {/* Plus Popover Menu */}
            {plusMenuOpen && (
              <div className="absolute left-0 bottom-full mb-2 w-48 bg-white border border-[#e4e0d5] rounded-2xl shadow-xl py-1.5 z-50 text-xs text-[#171711] animate-in fade-in zoom-in-95">
                <button
                  type="button"
                  onClick={() => {
                    setPollCreatorOpen(true);
                    setPlusMenuOpen(false);
                  }}
                  className="w-full text-left px-3.5 py-2 hover:bg-[#faf8f5] flex items-center gap-2 cursor-pointer"
                >
                  <BarChart2 className="w-4 h-4 text-[#171711]" />
                  <span>Create Poll & Voting</span>
                </button>

                {threadEntries.length > 0 && (
                  <button
                    type="button"
                    onClick={() => {
                      const latest = threadEntries[threadEntries.length - 1];
                      setAttachedEntry(latest);
                      setPlusMenuOpen(false);
                      inputRef.current?.focus();
                    }}
                    className="w-full text-left px-3.5 py-2 hover:bg-[#faf8f5] flex items-center gap-2 cursor-pointer"
                  >
                    <CornerDownRight className="w-4 h-4 text-[#171711]" />
                    <span>Attach Earlier Note</span>
                  </button>
                )}
              </div>
            )}
          </div>

          {/* Center Text Input */}
          <input
            ref={inputRef}
            type="text"
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                handleSendMessage();
              }
            }}
            placeholder="Add follow-up, thought, or note..."
            className="flex-1 min-w-0 bg-transparent px-3 py-1.5 text-xs sm:text-sm text-white placeholder:text-[#8e8d87] focus:outline-none"
          />

          {/* Right Action: Send Circular Button */}
          <button
            type="button"
            onClick={handleSendMessage}
            disabled={!inputText.trim()}
            title="Send"
            className="w-7 h-7 rounded-full bg-[#e6edb0] text-[#171711] hover:bg-white flex items-center justify-center transition-all cursor-pointer disabled:opacity-40 disabled:cursor-not-allowed shrink-0 ml-1 shadow-2xs"
          >
            <Send className="w-3.5 h-3.5 fill-[#171711]" />
          </button>
        </div>
      </div>
    </div>
  );
}
