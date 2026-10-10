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
  toggleRootReaction,
  voteThreadPoll,
  ItemThreadEntry,
  ThreadAttachmentRef,
  POPULAR_REACTIONS,
} from '@/lib/utils/itemThread';
import { fetchAttachmentDownloadUrl } from '@/lib/utils/attachment';
import { VideoPlayerComponent } from '@/components/media/VideoPlayerComponent';
import { AudioPlayerComponent } from '@/components/media/AudioPlayerComponent';
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
  FileText,
  UploadCloud,
  Download,
  HardDrive,
  Loader2,
  ImageIcon,
  PlayCircle,
  Music2,
  ChevronDown,
  ChevronUp,
} from 'lucide-react';

function formatBytes(bytes?: number): string {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}

function ThreadAttachmentCard({
  attachment,
  userId,
}: {
  attachment: ThreadAttachmentRef;
  userId?: string | null;
}) {
  const [downloading, setDownloading] = useState(false);
  const [mediaUrl, setMediaUrl] = useState<string | null>(attachment.url || null);
  const [pdfExpanded, setPdfExpanded] = useState(true);

  const ext = (attachment.extension || attachment.name.split('.').pop() || '').toLowerCase();
  const mime = (attachment.type || '').toLowerCase();
  const isPdf = ext === 'pdf' || mime === 'application/pdf';
  const isImg =
    mime.startsWith('image/') ||
    ['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg', 'heic', 'avif'].includes(ext);
  const isVid =
    mime.startsWith('video/') ||
    ['mp4', 'mov', 'webm', 'mkv', 'm4v', 'ogv'].includes(ext);
  const isAud =
    mime.startsWith('audio/') ||
    ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'].includes(ext);

  useEffect(() => {
    if (attachment.url) {
      setMediaUrl(attachment.url);
      return;
    }
    let active = true;
    fetchAttachmentDownloadUrl(attachment.id, userId ?? null)
      .then((url) => {
        if (active && url) {
          setMediaUrl(url);
        }
      })
      .catch((err) => {
        console.warn('Could not fetch attachment preview URL:', err);
      });

    return () => {
      active = false;
    };
  }, [attachment.id, attachment.url, userId]);

  const handleOpenAttachment = async () => {
    if (downloading) return;
    setDownloading(true);
    try {
      const url = mediaUrl || (await fetchAttachmentDownloadUrl(attachment.id, userId ?? null));
      if (url) {
        const a = document.createElement('a');
        a.href = url;
        a.download = attachment.name;
        a.target = '_blank';
        a.rel = 'noopener noreferrer';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
      } else {
        alert('Could not open document from local storage.');
      }
    } catch {
      alert('Could not open document from local storage.');
    } finally {
      setDownloading(false);
    }
  };

  const isLocal = !mediaUrl || mediaUrl.startsWith('blob:') || mediaUrl.startsWith('data:');

  return (
    <div className="flex flex-col gap-2.5 p-2.5 sm:p-3 rounded-2xl bg-[#faf9f5] border border-[#e4e0d5] hover:border-[#171711]/40 transition-all">
      {/* 1. Live Media Preview Container */}
      {mediaUrl && (
        <div className="w-full">
          {/* A. Proper Image Preview */}
          {isImg && (
            <div className="w-full rounded-xl overflow-hidden bg-white border border-[#e4e0d5] flex items-center justify-center p-1 shadow-2xs group relative">
              <a
                href={mediaUrl}
                target="_blank"
                rel="noopener noreferrer"
                title="Click to view full image in new tab"
                className="block w-full max-h-72 overflow-hidden rounded-lg cursor-zoom-in"
              >
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={mediaUrl}
                  alt={attachment.name}
                  className="w-full h-auto max-h-72 object-contain mx-auto rounded-lg group-hover:scale-[1.01] transition-transform duration-200"
                />
              </a>
              <a
                href={mediaUrl}
                target="_blank"
                rel="noopener noreferrer"
                title="Open image in external tab"
                className="absolute top-2.5 right-2.5 p-1.5 rounded-lg bg-black/60 hover:bg-black/80 text-white opacity-0 group-hover:opacity-100 transition-opacity backdrop-blur-xs shadow-xs"
              >
                <ExternalLink className="w-3.5 h-3.5" />
              </a>
            </div>
          )}

          {/* B. Integrated Video.js 10 Video Player */}
          {isVid && (
            <VideoPlayerComponent
              src={mediaUrl}
              title={attachment.name}
            />
          )}

          {/* C. PDF Preview & Open External Tab */}
          {isPdf && (
            <div className="w-full rounded-xl overflow-hidden bg-white border border-[#e4e0d5] shadow-2xs">
              <div className="p-2 sm:p-2.5 bg-[#fef2f2] border-b border-[#fca5a5]/40 flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5 min-w-0">
                  <FileText className="w-3.5 h-3.5 text-rose-600 shrink-0" />
                  <span className="text-xs font-bold text-rose-900 truncate">
                    PDF Preview
                  </span>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <a
                    href={mediaUrl}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white border border-rose-200 text-xs font-bold text-rose-700 hover:bg-rose-50 hover:text-rose-900 transition-colors shadow-2xs cursor-pointer"
                    title="Open PDF path in external tab"
                  >
                    <ExternalLink className="w-3.5 h-3.5" />
                    <span>Open External Tab</span>
                  </a>
                  <button
                    type="button"
                    onClick={() => setPdfExpanded(!pdfExpanded)}
                    className="text-[11px] font-semibold text-rose-700 hover:text-rose-900 px-1 py-0.5 rounded cursor-pointer"
                  >
                    {pdfExpanded ? (
                      <span className="inline-flex items-center gap-0.5">
                        Collapse <ChevronUp className="w-3 h-3" />
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-0.5">
                        Expand <ChevronDown className="w-3 h-3" />
                      </span>
                    )}
                  </button>
                </div>
              </div>
              {pdfExpanded && (
                <iframe
                  src={`${mediaUrl}#toolbar=1&navpanes=0`}
                  title={attachment.name}
                  className="w-full h-72 sm:h-80 border-0 bg-[#faf8f5]"
                />
              )}
            </div>
          )}

          {/* D. Integrated Video.js 10 Audio Player */}
          {isAud && (
            <AudioPlayerComponent
              src={mediaUrl}
              title={attachment.name}
            />
          )}
        </div>
      )}

      {/* 2. File Metadata & Actions Row */}
      <div className="flex items-center justify-between gap-2 min-w-0">
        <div className="flex items-center gap-2.5 min-w-0">
          <div
            className={`w-8 h-8 rounded-lg flex items-center justify-center shrink-0 border ${
              isPdf
                ? 'bg-rose-50 text-rose-600 border-rose-200'
                : isImg
                ? 'bg-sky-50 text-sky-600 border-sky-200'
                : isVid
                ? 'bg-rose-50 text-rose-600 border-rose-200'
                : isAud
                ? 'bg-emerald-50 text-emerald-600 border-emerald-200'
                : 'bg-white text-[#171711] border-[#e4e0d5]'
            }`}
          >
            {isPdf ? (
              <FileText className="w-4 h-4" />
            ) : isImg ? (
              <ImageIcon className="w-4 h-4" />
            ) : isVid ? (
              <PlayCircle className="w-4 h-4" />
            ) : isAud ? (
              <Music2 className="w-4 h-4" />
            ) : (
              <FileText className="w-4 h-4" />
            )}
          </div>
          <div className="min-w-0">
            <p className="text-xs font-bold text-[#171711] truncate">{attachment.name}</p>
            <div className="flex items-center gap-1.5 text-[10px] text-[#8e8d87] mt-0.5">
              <span>{formatBytes(attachment.size)}</span>
              <span>•</span>
              <span className="inline-flex items-center gap-1 text-[10px] font-medium text-[#6c6b63]">
                {isLocal ? (
                  <>
                    <HardDrive className="w-2.5 h-2.5 text-[#8e8d87]" />
                    Local Storage
                  </>
                ) : (
                  <>
                    <Globe className="w-2.5 h-2.5 text-[#8e8d87]" />
                    Cloud Storage
                  </>
                )}
              </span>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-1.5 shrink-0">
          {mediaUrl && (
            <a
              href={mediaUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="p-1.5 rounded-xl bg-white hover:bg-[#f4f2ec] border border-[#e4e0d5] text-[#171711] transition-colors shadow-2xs"
              title={isPdf ? 'Open PDF in external tab' : 'Open in external tab'}
            >
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          )}
          <button
            type="button"
            onClick={handleOpenAttachment}
            disabled={downloading}
            title="Download or save document"
            className="px-2.5 py-1.5 rounded-xl bg-white hover:bg-[#f4f2ec] border border-[#e4e0d5] text-xs font-bold text-[#171711] flex items-center gap-1.5 shrink-0 shadow-2xs transition-colors cursor-pointer"
          >
            {downloading ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin" />
            ) : (
              <Download className="w-3.5 h-3.5 text-[#171711]" />
            )}
            <span className="hidden sm:inline">Save</span>
          </button>
        </div>
      </div>
    </div>
  );
}

interface ItemSideDetailPanelProps {
  item: LaterBoxItem;
  onClose: () => void;
}

export function ItemSideDetailPanel({ item, onClose }: ItemSideDetailPanelProps) {
  const router = useRouter();
  const { setFavorite, archiveItem, deleteItem, saveNote, attachFilesToItem } = useItems();
  const { userName, user } = useAuth();

  const authorName = userName || user?.user_metadata?.full_name || 'You';

  // Thread entries & root reactions parsed from item note
  const parsedThread = useMemo(() => {
    return parseItemThread(item.note?.content);
  }, [item.note?.content]);

  const threadEntries = parsedThread.entries;
  const rootReactions = parsedThread.rootReactions;
  const rootUserReactions = parsedThread.rootUserReactions;

  // Input state
  const [inputText, setInputText] = useState('');
  const [attachedEntry, setAttachedEntry] = useState<ItemThreadEntry | null>(null);
  const [plusMenuOpen, setPlusMenuOpen] = useState(false);
  const [pollCreatorOpen, setPollCreatorOpen] = useState(false);
  const [editingEntryId, setEditingEntryId] = useState<string | null>(null);
  const [editText, setEditText] = useState('');
  const [reactionMenuForId, setReactionMenuForId] = useState<string | null>(null);

  // Document attachment state
  const [stagedFiles, setStagedFiles] = useState<File[]>([]);
  const [isUploading, setIsUploading] = useState(false);
  const [isDragging, setIsDragging] = useState(false);

  // Poll creator state
  const [pollQuestion, setPollQuestion] = useState('');
  const [pollOptions, setPollOptions] = useState<string[]>(['Option 1', 'Option 2']);

  const plusMenuRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
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

  const persistThread = async (
    updatedEntries: ItemThreadEntry[] = threadEntries,
    updatedRootReactions: Record<string, number> = rootReactions,
    updatedRootUserReactions: string[] = rootUserReactions
  ) => {
    const serialized = serializeItemThread(
      updatedEntries,
      updatedRootReactions,
      updatedRootUserReactions
    );
    await saveNote(item.id, serialized);
  };

  const handleFilesSelected = (newFiles: FileList | File[]) => {
    const arr = Array.from(newFiles);
    if (arr.length === 0) return;
    setStagedFiles((prev) => [...prev, ...arr]);
  };

  const handleRemoveStagedFile = (index: number) => {
    setStagedFiles((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSendMessage = async () => {
    const text = inputText.trim();
    if (!text && stagedFiles.length === 0) return;

    setIsUploading(true);
    try {
      let threadAttachments: ThreadAttachmentRef[] | undefined = undefined;

      if (stagedFiles.length > 0) {
        // Save file bytes in local storage (IndexedDB) and persist attachment reference
        const savedAttachments = await attachFilesToItem(item.id, stagedFiles);
        threadAttachments = savedAttachments.map((att) => ({
          id: att.id,
          name: att.original_file_name,
          size: att.byte_size,
          type: att.mime_type,
          extension: att.file_extension,
        }));
      }

      const entryType =
        threadAttachments && threadAttachments.length > 0 ? 'document' : 'message';
      const defaultContent =
        threadAttachments && threadAttachments.length > 0
          ? threadAttachments.length === 1
            ? threadAttachments[0].name
            : `${threadAttachments.length} documents attached`
          : '';

      const newEntries = addThreadEntry(threadEntries, {
        type: entryType,
        authorName,
        content: text || defaultContent,
        attachedToId: attachedEntry?.id,
        attachedSnippet: attachedEntry
          ? attachedEntry.content.slice(0, 80)
          : undefined,
        attachments: threadAttachments,
      });

      await persistThread(newEntries);
      setInputText('');
      setStagedFiles([]);
      setAttachedEntry(null);
      setTimeout(() => {
        threadBottomRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
    } catch (err) {
      console.error('Failed to attach documents or persist thread entry:', err);
    } finally {
      setIsUploading(false);
    }
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

  const handleToggleRootReaction = async (emoji: string) => {
    const result = toggleRootReaction(rootReactions, rootUserReactions, emoji);
    await persistThread(threadEntries, result.reactions, result.userReactions);
    setReactionMenuForId(null);
  };

  const handleToggleReaction = async (id: string, emoji: string) => {
    if (id === 'root-content') {
      await handleToggleRootReaction(emoji);
      return;
    }
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

  const handleAttachRootContent = () => {
    const rawSnippet = description || title;
    const cleanSnippet =
      rawSnippet.length > 80 ? rawSnippet.slice(0, 80) + '...' : rawSnippet;
    setAttachedEntry({
      id: 'root-content',
      type: 'note',
      authorName: sender,
      content: cleanSnippet,
      createdAt: item.created_at,
    });
    inputRef.current?.focus();
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      handleFilesSelected(e.dataTransfer.files);
    }
  };

  return (
    <div
      className="flex flex-col h-full bg-white relative overflow-hidden select-none"
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      {/* Hidden File Input for document upload */}
      <input
        ref={fileInputRef}
        type="file"
        multiple
        className="hidden"
        onChange={(e) => {
          if (e.target.files) {
            handleFilesSelected(e.target.files);
            e.target.value = '';
          }
        }}
      />

      {/* Drag & Drop Visual Overlay */}
      {isDragging && (
        <div className="absolute inset-0 bg-[#f7f5ee]/95 border-2 border-dashed border-[#171711] z-50 flex flex-col items-center justify-center p-6 text-center animate-in fade-in">
          <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] border border-[#171711] flex items-center justify-center text-[#171711] mb-2 shadow-xs">
            <UploadCloud className="w-6 h-6" />
          </div>
          <p className="text-sm font-bold text-[#171711]">Drop documents to attach</p>
          <p className="text-xs text-[#6c6b63] mt-0.5">
            Files will be stored locally in your browser storage
          </p>
        </div>
      )}
      {/* 2. SCROLLABLE CONTENT BODY & THREAD STREAM (UNIFIED VIEW WITH SCROLLING HEADER) */}
      <div className="flex-1 overflow-y-auto bg-white select-text">
        {/* 1. TOP HEADER: Sender Info & Actions on Top Row, Title Underneath (No bottom border, scrolls with content) */}
        <div className="px-4 sm:px-5 pt-4 sm:pt-5 pb-2 bg-white space-y-2.5">
          {/* Top actions toolbar: sender avatar & domain on left, action icons on right */}
          <div className="flex items-center justify-between gap-2">
            {/* Left: Sender Profile Pic, Name, Link Domain & Timestamp */}
            <div className="flex items-center gap-2.5 min-w-0 text-xs text-[#6c6b63]">
              <div className="w-6 h-6 rounded-full bg-[#171711] text-[#e6edb0] font-black text-[10px] flex items-center justify-center shrink-0 shadow-2xs">
                {sender.slice(0, 2).toUpperCase()}
              </div>
              <div className="min-w-0 flex items-center gap-1.5 truncate">
                <span className="font-bold text-[#171711] truncate">{sender}</span>
                {item.metadata?.domain && (
                  <span className="text-[#8e8d87] truncate">
                    • {item.metadata.domain}
                  </span>
                )}
              </div>
              <span className="shrink-0 text-[11px] text-[#8e8d87] font-medium hidden sm:inline">
                {formatEmailDate(item.created_at)}
              </span>
            </div>

            {/* Right: Quick Action Buttons */}
            <div className="flex items-center gap-1 text-[#6c6b63] shrink-0">
              {/* Open in full page button */}
              <Link
                href={`/item/${item.id}`}
                title="Open in full"
                className="p-1.5 rounded-lg hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
              >
                <ExternalLink className="w-4 h-4" />
              </Link>

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

          {/* Item Title directly underneath */}
          <div>
            <h2 className="text-base sm:text-lg font-black text-[#171711] tracking-tight line-clamp-2 leading-snug">
              {title}
            </h2>
          </div>
        </div>

        {/* Content Stream Cards */}
        <div className="px-4 sm:px-5 pt-2 pb-6 space-y-4">
          {/* Main Saved Content Card (Root of stream with reply and reaction support) */}
          <div className="bg-white border border-[#e4e0d5] rounded-2xl p-4 shadow-2xs space-y-3 group transition-all">
          {/* Card header: Sender info and Reply/Attach button */}
          <div className="flex items-center justify-between text-xs text-[#6c6b63]">
            <div className="flex items-center gap-2 min-w-0">
              <span className="font-bold text-[#171711] truncate">{sender}</span>
              <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-[#e6edb0] text-[#171711] shrink-0">
                Saved Content
              </span>
              <span className="text-[10px] text-[#9e9b92] shrink-0">
                {formatEmailDate(item.created_at)}
              </span>
            </div>

            {/* Attach / Reply to this main saved content */}
            <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                type="button"
                onClick={handleAttachRootContent}
                title="Reply / Attach as context"
                className="inline-flex items-center gap-1 px-2 py-1 rounded text-xs font-semibold text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f5] transition-colors cursor-pointer"
              >
                <CornerDownRight className="w-3.5 h-3.5" />
                <span>Reply</span>
              </button>
            </div>
          </div>

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
            <div className="pt-2 border-t border-[#f0ede4] space-y-2">
              <div className="flex items-center gap-1.5 text-xs font-bold text-[#171711]">
                <Paperclip className="w-3.5 h-3.5 text-[#6c6b63]" />
                <span>Attachments ({item.attachments.length})</span>
              </div>
              <div className="space-y-2">
                {item.attachments.map((att) => (
                  <ThreadAttachmentCard
                    key={att.id}
                    attachment={{
                      id: att.id,
                      name: att.original_file_name,
                      size: att.byte_size,
                      type: att.mime_type,
                      extension: att.file_extension,
                      url: att.local_path || undefined,
                    }}
                    userId={item.user_id}
                  />
                ))}
              </div>
            </div>
          )}

          {/* External link button */}
          {item.url && (
            <div className="pt-1 flex items-center justify-between">
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

          {/* Reaction Bar for Main Saved Content */}
          <div className="flex flex-wrap items-center gap-1 pt-1.5 border-t border-[#f0ede4]">
            {/* Active reactions */}
            {Object.entries(rootReactions || {}).map(([emoji, count]) => {
              if (count <= 0) return null;
              const hasUserReacted = rootUserReactions?.includes(emoji);
              return (
                <button
                  key={emoji}
                  type="button"
                  onClick={() => handleToggleRootReaction(emoji)}
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

            {/* Quick Reaction Picker Toggle for Root */}
            <div className="relative">
              <button
                type="button"
                onClick={() =>
                  setReactionMenuForId(
                    reactionMenuForId === 'root-content' ? null : 'root-content'
                  )
                }
                title="Add reaction"
                className="p-1 rounded-full text-[#8e8d87] hover:text-[#171711] hover:bg-[#faf8f5] transition-colors cursor-pointer"
              >
                <Smile className="w-3.5 h-3.5" />
              </button>

              {reactionMenuForId === 'root-content' && (
                <div className="absolute left-0 bottom-full mb-1 bg-white border border-[#e4e0d5] rounded-full shadow-lg px-2 py-1 flex items-center gap-1.5 z-40 animate-in fade-in zoom-in-95">
                  {POPULAR_REACTIONS.map((emoji) => (
                    <button
                      key={emoji}
                      type="button"
                      onClick={() => handleToggleRootReaction(emoji)}
                      className="hover:scale-125 transition-transform text-sm cursor-pointer p-0.5"
                    >
                      {emoji}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Reply action button on right side of reactions */}
            <button
              type="button"
              onClick={handleAttachRootContent}
              className="ml-auto inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] hover:bg-[#faf8f5] transition-colors cursor-pointer"
            >
              <CornerDownRight className="w-3 h-3" />
              <span>Reply</span>
            </button>
          </div>
        </div>

        {/* Interactive Thread Stream Header */}
        <div className="flex items-center gap-2 pt-1">
          <MessageSquare className="w-3.5 h-3.5 text-[#8e8d87]" />
          <span className="text-[11px] font-bold uppercase tracking-wider text-[#8e8d87]">
            Follow-ups & Notes ({threadEntries.length})
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
                        {entry.attachedToId === 'root-content'
                          ? 'Replying to saved content: '
                          : 'Attached: '}
                        &ldquo;{entry.attachedSnippet}&rdquo;
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
                    <div className="space-y-2">
                      {/* Note or caption text */}
                      {entry.content &&
                        (!entry.attachments ||
                          entry.attachments.length !== 1 ||
                          entry.content !== entry.attachments[0].name) && (
                          <p className="text-xs sm:text-sm text-[#171711] whitespace-pre-wrap leading-relaxed">
                            {entry.content}
                          </p>
                        )}

                      {/* Document Attachments */}
                      {entry.attachments && entry.attachments.length > 0 && (
                        <div className="space-y-1.5 pt-0.5">
                          {entry.attachments.map((att) => (
                            <ThreadAttachmentCard
                              key={att.id}
                              attachment={att}
                              userId={item.user_id}
                            />
                          ))}
                        </div>
                      )}
                    </div>
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

        </div>

        <div ref={threadBottomRef} />
      </div>

      {/* 3. CHATGPT-STYLE FIXED BOTTOM PILL INPUT BAR */}
      <div className="shrink-0 sticky bottom-0 z-20 p-3 sm:p-4 bg-white border-t border-[#e4e0d5]">
        {/* Attached Entry Preview Banner */}
        {attachedEntry && (
          <div className="mb-2 flex items-center justify-between px-3 py-1.5 bg-[#f0ede4] border border-[#e4e0d5] rounded-xl text-xs text-[#171711] animate-in fade-in">
            <div className="flex items-center gap-1.5 truncate">
              <CornerDownRight className="w-3.5 h-3.5 text-[#6c6b63] shrink-0" />
              <span className="font-bold shrink-0">
                {attachedEntry.id === 'root-content'
                  ? 'Replying to Saved Content:'
                  : 'Attaching context:'}
              </span>
              <span className="truncate text-[#6c6b63]">
                &ldquo;{attachedEntry.content.slice(0, 60)}...&rdquo;
              </span>
            </div>
            <button
              type="button"
              onClick={() => setAttachedEntry(null)}
              className="p-0.5 text-[#8e8d87] hover:text-[#171711] rounded cursor-pointer"
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

        {/* Staged Document Attachments Chips Banner */}
        {stagedFiles.length > 0 && (
          <div className="mb-2.5 p-2 bg-[#faf8f5] border border-[#e4e0d5] rounded-2xl space-y-1.5 animate-in fade-in slide-in-from-bottom-1">
            <div className="flex items-center justify-between text-[11px] font-bold text-[#6c6b63] px-1">
              <span>Attached Documents ({stagedFiles.length})</span>
              <span className="text-[10px] text-[#8e8d87]">Saved locally</span>
            </div>
            <div className="flex flex-wrap items-center gap-1.5">
              {stagedFiles.map((file, idx) => {
                const ext = file.name.split('.').pop()?.toLowerCase() || '';
                const isPdf = ext === 'pdf' || file.type === 'application/pdf';
                const isImg = file.type.startsWith('image/');
                return (
                  <div
                    key={`${file.name}-${idx}`}
                    className="flex items-center gap-2 bg-white border border-[#e4e0d5] rounded-xl px-2.5 py-1 text-xs shadow-2xs"
                  >
                    <div className="w-5 h-5 rounded-md bg-[#faf8f5] flex items-center justify-center shrink-0">
                      {isPdf ? (
                        <FileText className="w-3 h-3 text-rose-600" />
                      ) : isImg ? (
                        <ImageIcon className="w-3 h-3 text-sky-600" />
                      ) : (
                        <FileText className="w-3 h-3 text-[#171711]" />
                      )}
                    </div>
                    <div className="min-w-0 max-w-[130px] truncate">
                      <span className="font-semibold text-[#171711] truncate block text-[11px]">
                        {file.name}
                      </span>
                      <span className="text-[10px] text-[#8e8d87]">
                        {formatBytes(file.size)}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => handleRemoveStagedFile(idx)}
                      className="p-0.5 rounded-full text-[#8e8d87] hover:text-[#171711] hover:bg-[#faf8f5] cursor-pointer"
                      title="Remove document"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* The Main ChatGPT-style Pill Bar (White themed) */}
        <div className="relative flex items-center bg-white border border-[#e4e0d5] hover:border-[#171711]/40 focus-within:border-[#171711] focus-within:ring-2 focus-within:ring-[#171711]/5 text-[#171711] rounded-full px-2.5 py-1.5 shadow-xs transition-all">
          {/* Left Plus Action Button */}
          <div className="relative shrink-0" ref={plusMenuRef}>
            <button
              type="button"
              onClick={() => setPlusMenuOpen(!plusMenuOpen)}
              title="Add options"
              className="w-7 h-7 rounded-full bg-[#faf8f5] hover:bg-[#f0ede4] text-[#171711] border border-[#e4e0d5] flex items-center justify-center transition-colors cursor-pointer"
            >
              <Plus className="w-4 h-4" />
            </button>

            {/* Plus Popover Menu */}
            {plusMenuOpen && (
              <div className="absolute left-0 bottom-full mb-2 w-52 bg-white border border-[#e4e0d5] rounded-2xl shadow-xl py-1.5 z-50 text-xs text-[#171711] animate-in fade-in zoom-in-95">
                {/* 1. Upload Document */}
                <button
                  type="button"
                  onClick={() => {
                    fileInputRef.current?.click();
                    setPlusMenuOpen(false);
                  }}
                  className="w-full text-left px-3.5 py-2 hover:bg-[#faf8f5] flex items-center gap-2 cursor-pointer"
                >
                  <FileText className="w-4 h-4 text-[#171711]" />
                  <span>Upload Document</span>
                </button>

                {/* 2. Create Poll */}
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

                {/* 3. Attach Earlier Note */}
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
            placeholder={
              stagedFiles.length > 0
                ? 'Add an optional note with documents...'
                : 'Add follow-up, thought, or note...'
            }
            className="flex-1 min-w-0 bg-transparent px-3 py-1.5 text-xs sm:text-sm text-[#171711] placeholder:text-[#8e8d87] focus:outline-none"
          />

          {/* Right Action: Send Circular Button */}
          <button
            type="button"
            onClick={handleSendMessage}
            disabled={(!inputText.trim() && stagedFiles.length === 0) || isUploading}
            title="Send"
            className="w-7 h-7 rounded-full bg-[#171711] text-[#e6edb0] hover:bg-[#2e2d24] flex items-center justify-center transition-all cursor-pointer disabled:opacity-25 disabled:cursor-not-allowed shrink-0 ml-1 shadow-2xs"
          >
            {isUploading ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin text-[#e6edb0]" />
            ) : (
              <Send className="w-3.5 h-3.5 fill-[#e6edb0]" />
            )}
          </button>
        </div>
      </div>
    </div>
  );
}
