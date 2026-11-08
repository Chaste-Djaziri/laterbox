'use client';

import React, { useState, useEffect, useRef, useMemo } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import Link from 'next/link';
import { resolveReturnPreset, returnLabel, type ReturnPreset } from '@/lib/utils/schedule';
import { suggestCapture, captureSummary, type CaptureKind } from '@/lib/utils/captureSuggestions';
import { prepareCaptureDraft } from '@/lib/utils/prepareCaptureDraft';
import {
  X,
  Link2,
  Check,
  AlertCircle,
  Loader2,
  Paperclip,
  FileText,
  ImageIcon,
  PlayCircle,
  Music2,
  UploadCloud,
  CheckSquare,
  ArrowRight,
  ArrowLeft,
  Calendar,
  Clock,
  Tag,
  Plus,
  Sparkles,
} from 'lucide-react';

interface QuickCaptureModalProps {
  isOpen: boolean;
  onClose: () => void;
  initialFiles?: File[];
  browseFiles?: boolean;
}

function formatBytes(bytes: number): string {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}

const PRESET_OPTIONS: { key: ReturnPreset; label: string }[] = [
  { key: 'laterToday', label: 'Later Today' },
  { key: 'tomorrow', label: 'Tomorrow' },
  { key: 'weekend', label: 'Weekend' },
  { key: 'someday', label: 'Someday' },
  { key: 'now', label: 'Now' },
];

const SUGGESTED_TAGS = ['Work', 'Reading', 'Personal', 'Finance', 'Inspiration', 'Urgent'];

export function QuickCaptureModal({
  isOpen,
  onClose,
  initialFiles,
  browseFiles = false,
}: QuickCaptureModalProps) {
  const [step, setStep] = useState<1 | 2 | 3>(1);
  const [returnAt, setReturnAt] = useState<string | null>(null);
  const [activePreset, setActivePreset] = useState<ReturnPreset | 'custom' | 'auto'>('auto');
  const [customDateTime, setCustomDateTime] = useState<string>('');
  const [isCustomOpen, setIsCustomOpen] = useState(false);

  const [kind, setKind] = useState<CaptureKind>('link');
  const [duplicateId, setDuplicateId] = useState<string | null>(null);
  const { saveItem } = useItems();
  const [content, setContent] = useState('');
  const [titleOverride, setTitleOverride] = useState<string | null>(null);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [tagsTouched, setTagsTouched] = useState(false);
  const [customTagInput, setCustomTagInput] = useState('');
  const [showAddTag, setShowAddTag] = useState(false);

  const [files, setFiles] = useState<File[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const suggestion = useMemo(
    () => suggestCapture(kind === 'task' ? [titleOverride, content].filter(Boolean).join('\n') : content, kind, files.map(file => file.name)),
    [content, kind, titleOverride, files]
  );
  const effectiveReturnAt = activePreset === 'auto' ? suggestion.returnAt : returnAt;
  const effectiveTitle = titleOverride ?? suggestion.title;
  const effectiveTags = tagsTouched ? selectedTags : suggestion.tags;
  const contentSummary = captureSummary(
    kind === 'task' ? [titleOverride?.trim(), content.trim()].filter(Boolean).join(' — ')
      : kind === 'note' && titleOverride?.trim() ? [titleOverride.trim(), content.trim()].filter(Boolean).join(' — ')
      : content,
    files.map(file => file.name)
  );
  const preparedDraft = prepareCaptureDraft({kind, content, title: titleOverride, suggestedTitle: suggestion.title, fileCount: files.length});

  // Initialize on modal open
  useEffect(() => {
    if (isOpen) {
      setStep(1);
      setContent('');
      setTitleOverride(null);
      setFiles(initialFiles || []);
      setReturnAt(null);
      setActivePreset('auto');
      setIsCustomOpen(false);
      setCustomDateTime('');
      setSelectedTags([]);
      setTagsTouched(false);
      setCustomTagInput('');
      setShowAddTag(false);

      const hasFiles = Boolean(initialFiles && initialFiles.length > 0);
      setKind(hasFiles ? 'file' : 'link');
      setDuplicateId(null);
      setIsDragging(false);
      setError(null);
      setSuccess(false);
      setSaving(false);

      if (browseFiles) {
        setTimeout(() => fileInputRef.current?.click(), 50);
      }
      setTimeout(() => textareaRef.current?.focus(), 60);
    }
  }, [isOpen, initialFiles, browseFiles]);

  // Global keyboard shortcuts (Escape to close, Cmd/Ctrl+Enter to save)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!isOpen) return;
      if (e.key === 'Escape') {
        onClose();
      }
      if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
        e.preventDefault();
        handleSubmit();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  });

  // The selected capture type is explicit: typing or pasting won't change a
  // Task into a Note, or a Note into a Link.
  const handleContentChange = (text: string) => setContent(text);

  const selectKind = (next: CaptureKind) => {
    setKind(next);
    setError(null);
    if (next === 'file') fileInputRef.current?.click();
  };

  if (!isOpen) return null;

  const handleFilesSelected = (newFiles: FileList | File[]) => {
    const arr = Array.from(newFiles);
    if (arr.length === 0) return;
    setFiles((prev) => [...prev, ...arr]);
    if (kind !== 'task' && kind !== 'note') setKind('file');
  };

  const handleRemoveFile = (index: number) => {
    setFiles((prev) => {
      const next = prev.filter((_, i) => i !== index);
      if (next.length === 0 && kind === 'file') {
        setKind(content.trim().startsWith('http') ? 'link' : 'note');
      }
      return next;
    });
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    if (e.clipboardData.files && e.clipboardData.files.length > 0) {
      e.preventDefault();
      handleFilesSelected(e.clipboardData.files);
    }
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

  const handlePresetSelect = (presetKey: ReturnPreset) => {
    setActivePreset(presetKey);
    setIsCustomOpen(false);
    setError(null);
    setReturnAt(resolveReturnPreset(presetKey));
  };

  const handleCustomDateSubmit = (dateTimeString: string) => {
    setCustomDateTime(dateTimeString);
    setActivePreset('custom');
    if (!dateTimeString) {
      setReturnAt(null);
      setError('Choose a future return time, or pick a preset.');
      return;
    }
    const date = new Date(dateTimeString);
    if (!Number.isFinite(date.getTime()) || date <= new Date()) {
      setReturnAt(null);
      setError('Choose a future return time, or select Now.');
      return;
    }
    setError(null);
    setReturnAt(date.toISOString());
  };

  const toggleTag = (tag: string) => {
    setSelectedTags(effectiveTags.includes(tag)
      ? effectiveTags.filter(t => t !== tag)
      : [...effectiveTags, tag]);
    setTagsTouched(true);
  };

  const handleAddCustomTag = () => {
    const trimmed = customTagInput.trim().replace(/^#/, '');
    if (trimmed && !effectiveTags.includes(trimmed)) {
      setSelectedTags([...effectiveTags, trimmed]);
      setTagsTouched(true);
      setCustomTagInput('');
      setShowAddTag(false);
    }
  };

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (saving || success) return;
    if (!preparedDraft) {
      setError(kind === 'task' ? 'Give your task an action title.'
        : kind === 'note' ? 'Write a note before saving.'
        : 'Add a link, some text, or an attachment to save.');
      return;
    }
    if (activePreset === 'custom' && !returnAt) {
      setError('Choose a valid return time or select an automatic suggestion.');
      return;
    }

    setSaving(true);
    setError(null);

    try {
      const id = crypto.randomUUID();
      const item = await saveItem(preparedDraft.value, {
        id,
        files,
        returnAt: effectiveReturnAt,
        type: preparedDraft.type,
        title: preparedDraft.title,
        tags: effectiveTags,
      });

      if (item.id !== id) {
        setDuplicateId(item.id);
        setSaving(false);
        setError('This item is already in LaterBox.');
        return;
      }

      // Trigger celebratory slide-up green card animation!
      setSuccess(true);
      setTimeout(() => {
        onClose();
      }, 950);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Could not save this item. Try again.');
      setSaving(false);
    }
  };

  const hasSubmitData = Boolean(preparedDraft);

  const steps = [
    { id: 1 as const, label: 'Capture' },
    { id: 2 as const, label: 'Schedule' },
    { id: 3 as const, label: 'Details' },
  ];

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-6 bg-black/60 backdrop-blur-xs transition-all duration-300 animate-in fade-in"
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
      onClick={onClose}
    >
      {/* Signature One Shortcut Away Card Container */}
      <div
        className={`relative w-full max-w-[560px] max-h-[calc(100dvh-2rem)] flex flex-col rounded-[28px] sm:rounded-[34px] bg-white border-2 border-[#171711] shadow-[0_24px_70px_rgba(0,0,0,0.22),0_8px_24px_rgba(230,237,176,0.35)] overflow-hidden transition-all duration-200 ${
          isDragging ? 'ring-4 ring-[#171711]/20 bg-[#f7f5ee]' : 'bg-white'
        }`}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Hidden File Input */}
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

        {/* Top Header: Step Indicators & Close Button */}
        <div className="flex items-center justify-between px-6 pt-5 pb-3 border-b border-[#f4f3ed]">
          <div className="flex items-center gap-1.5 sm:gap-2">
            {steps.map((s) => {
              const isActive = step === s.id;
              const isPast = step > s.id;
              return (
                <button
                  key={s.id}
                  type="button"
                  onClick={() => setStep(s.id)}
                  disabled={saving || success}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer select-none ${
                    isActive
                      ? 'bg-[#171711] text-white shadow-xs'
                      : isPast
                      ? 'bg-[#e6edb0] text-[#171711] hover:bg-[#d8e09f]'
                      : 'bg-[#f4f3ed] text-[#8c897f] hover:text-[#171711] hover:bg-[#e9e7df]'
                  }`}
                >
                  <span className="opacity-70">{s.id}.</span>
                  <span>{s.label}</span>
                </button>
              );
            })}
          </div>

          <button
            type="button"
            onClick={onClose}
            disabled={saving || success}
            className="p-1.5 text-[#8c897f] hover:text-[#171711] hover:bg-[#f4f3ed] rounded-full transition-colors cursor-pointer"
            title="Close (Esc)"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Duplicate Item Notice */}
        {duplicateId && (
          <div className="mx-6 mt-4 p-3 rounded-2xl bg-amber-50 border border-amber-200 flex items-center justify-between text-xs text-amber-900">
            <span>This item already exists in your LaterBox.</span>
            <Link
              href={`/item/${duplicateId}`}
              onClick={onClose}
              className="font-bold underline hover:text-black"
            >
              View & Reschedule
            </Link>
          </div>
        )}

        {/* Modal Body: Multi-Step Staging */}
        <div className="p-6 sm:p-7 min-h-0 overflow-y-auto flex-1 flex flex-col justify-between">
          {/* STEP 1: CAPTURE — explicit type-specific creation */} 
          {step === 1 && (
            <div className="space-y-5 animate-in fade-in duration-200">
              <div>
                <p className="text-[11px] font-black uppercase tracking-[0.15em] text-[#8c897f]">
                  What are you saving?
                </p>
                <div role="group" aria-label="Choose item type" className="mt-3 grid grid-cols-4 gap-2">
                  {([
                    { id: 'link', label: 'Link', icon: Link2 },
                    { id: 'note', label: 'Note', icon: FileText },
                    { id: 'task', label: 'Task', icon: CheckSquare },
                    { id: 'file', label: 'File', icon: Paperclip },
                  ] as const).map(type => {
                    const Icon = type.icon;
                    const active = kind === type.id;
                    return (
                      <button
                        key={type.id}
                        type="button"
                        aria-pressed={active}
                        disabled={saving || success}
                        onClick={() => selectKind(type.id)}
                        className={`flex min-h-[74px] flex-col items-center justify-center gap-1.5 rounded-2xl border px-2 py-3 text-xs font-bold transition-all focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7b8e4e] ${
                          active
                            ? 'border-[#cbd88c] bg-[#e6edb0] text-[#26311d] shadow-sm'
                            : 'border-[#e8e7df] bg-[#faf9f5] text-[#777b70] hover:border-[#c8d0af] hover:bg-[#f2f5e9]'
                        }`}
                      >
                        <Icon className="h-5 w-5" strokeWidth={active ? 2.3 : 1.9} aria-hidden="true" />
                        <span>{type.label}</span>
                      </button>
                    );
                  })}
                </div>
              </div>

              {(kind === 'task' || kind === 'note') && (
                <div className={`flex items-start gap-3 rounded-2xl border p-4 ${
                  kind === 'task' ? 'border-[#d7e29e] bg-[#f2f7df]' : 'border-[#e6e6df] bg-[#f7f7f2]'
                }`}>
                  <span className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-xl ${
                    kind === 'task' ? 'bg-[#e6edb0] text-[#35452d]' : 'bg-white text-[#586b4d]'
                  }`}>
                    {kind === 'task' ? <CheckSquare className="h-5 w-5" aria-hidden="true" /> : <FileText className="h-5 w-5" aria-hidden="true" />}
                  </span>
                  <div>
                    <h3 className="text-sm font-black text-[#26311d]">{kind === 'task' ? 'A task to complete' : 'A note to remember'}</h3>
                    <p className="mt-1 text-xs leading-5 text-[#6c7466]">
                      {kind === 'task'
                        ? 'Write an action you need to do. Schedule when it should come back, then mark it done.'
                        : 'Capture thoughts, ideas, or information. Notes stay available for reference, without needing a deadline.'}
                    </p>
                  </div>
                </div>
              )}

              {kind === 'task' && (
                <label className="block space-y-2">
                  <span className="flex items-center gap-2 text-xs font-bold text-[#2a3126]">
                    <CheckSquare className="h-4 w-4 text-[#7c934d]" aria-hidden="true" />
                    Task name <span className="text-red-600">*</span>
                  </span>
                  <input
                    type="text"
                    maxLength={200}
                    required
                    value={titleOverride ?? ''}
                    onChange={event => setTitleOverride(event.target.value)}
                    placeholder="e.g. Finish the project presentation"
                    disabled={saving || success}
                    className="w-full rounded-2xl border border-[#d9e3c9] bg-white px-4 py-3.5 text-base font-bold text-[#171711] outline-none transition-colors placeholder:font-medium placeholder:text-[#a5ada0] focus:border-[#869d5b] focus:ring-2 focus:ring-[#e6edb0]"
                  />
                </label>
              )}

              {kind === 'note' && (
                <label className="block space-y-2">
                  <span className="flex items-center gap-2 text-xs font-bold text-[#2a3126]">Note title <span className="font-normal text-[#92958c]">(optional)</span></span>
                  <input
                    type="text"
                    maxLength={200}
                    value={titleOverride ?? ''}
                    onChange={event => setTitleOverride(event.target.value)}
                    placeholder="Give your note a name"
                    disabled={saving || success}
                    className="w-full rounded-2xl border border-[#e4e0d5] bg-white px-4 py-3 text-sm font-semibold text-[#171711] outline-none placeholder:font-medium placeholder:text-[#a5ada0] focus:border-[#869d5b] focus:ring-2 focus:ring-[#e6edb0]"
                  />
                </label>
              )}

              <label className="block space-y-2">
                <span className="flex items-center justify-between text-xs font-bold text-[#2a3126]">
                  <span>
                    {kind === 'task' ? 'Task details' : kind === 'note' ? 'Write your note' : kind === 'file' ? 'Add a description' : 'Link or URL'}
                    {kind === 'task' || kind === 'file' ? <span className="ml-1 font-normal text-[#92958c]">(optional)</span> : null}
                    {kind === 'note' ? <span className="ml-1 text-red-600">*</span> : null}
                  </span>
                  {kind === 'note' && <span className="text-[10px] font-medium text-[#93988f]">Plain text</span>}
                </span>
                <textarea
                  ref={textareaRef}
                  disabled={saving || success}
                  rows={kind === 'note' ? 6 : kind === 'task' ? 3 : 4}
                  value={content}
                  onChange={event => handleContentChange(event.target.value)}
                  onPaste={handlePaste}
                  placeholder={kind === 'task'
                    ? 'Add extra context, steps, or anything you need to remember…'
                    : kind === 'note'
                      ? 'Write down your thoughts, ideas, or anything worth keeping…'
                      : kind === 'file'
                        ? 'Describe the files you are saving…'
                        : 'https://example.com/an-interesting-article'}
                  className={`w-full resize-y rounded-2xl border border-[#e4e0d5] bg-[#fbfbf8] px-4 py-3.5 text-sm leading-6 text-[#171711] outline-none transition-colors placeholder:text-[#afb2a8] focus:border-[#91a768] focus:ring-2 focus:ring-[#e6edb0] ${
                    kind === 'note' ? 'min-h-[150px]' : 'min-h-[96px]'
                  }`}
                />
              </label>

              <div className="flex flex-wrap items-center justify-between gap-3">
                <p className="max-w-[315px] text-[11px] leading-5 text-[#8b9086]">
                  {kind === 'task' ? 'Tasks stay actionable until completed.'
                    : kind === 'note' ? 'Your note is saved as writing, not a to-do.'
                      : kind === 'file' ? 'Attach files to keep with your capture.'
                        : 'Save a URL to revisit whenever you are ready.'}
                </p>
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={saving || success}
                  className="inline-flex items-center gap-1.5 rounded-full border border-[#e4e0d5] bg-white px-3 py-2 text-xs font-semibold text-[#30372a] transition-colors hover:bg-[#e6edb0] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#7b8e4e]"
                >
                  <Paperclip className="h-4 w-4" aria-hidden="true" />
                  {files.length > 0 ? `${files.length} attached` : 'Attach file'}
                </button>
              </div>

              {hasSubmitData && activePreset === 'auto' && (
                <div className="flex items-start gap-3 rounded-2xl border border-[#e4e0d5] bg-[#f7f5ee] px-4 py-3">
                  <Sparkles className="mt-0.5 h-4 w-4 shrink-0 text-[#6c752b]" aria-hidden="true" />
                  <div className="min-w-0">
                    <p className="text-xs font-bold text-[#171711]">
                      {kind === 'task' ? 'Suggested reminder' : 'Suggested return'}: {suggestion.returnAt ? returnLabel(suggestion.returnAt) : 'Someday'}
                    </p>
                    <p className="mt-1 text-[11px] leading-relaxed text-[#6c6b63]">
                      {suggestion.reason} Choose Schedule to change it.
                    </p>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* STEP 2: SCHEDULE */}
          {step === 2 && (
            <div className="space-y-4 animate-in fade-in duration-200">
              {/* Prompt Label */}
              <div>
                <p className="text-[11px] sm:text-xs font-semibold text-[#8c897f] select-none tracking-wide">
                  {kind === 'task' ? 'When should LaterBox remind you about this task?' : kind === 'note' ? 'Would you like this note to resurface?' : 'When should LaterBox bring this back?'}
                </p>
              </div>

              <div className="rounded-xl bg-[#f7f5ee] px-3 py-2.5 text-xs text-[#6c6b63]">
                <span className="font-bold text-[#171711]">Saving: </span>
                <span className="break-words">{contentSummary}</span>
              </div>

              {/* Friendly Schedule Preview Banner */}
              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-[#e6edb0] border border-[#171711]/20 flex items-center justify-center text-[#171711] shrink-0">
                    <Clock className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-bold text-[#171711]">
                      {effectiveReturnAt ? `Returning ${returnLabel(effectiveReturnAt)}` : 'Someday (no deadline)'}
                    </p>
                    <p className="text-[11px] text-[#6c6b63]">
                      {activePreset === 'auto' ? suggestion.reason
                        : effectiveReturnAt
                          ? 'Will reappear in your inbox on the selected date'
                          : 'Saved to Someday until you decide'}
                    </p>
                  </div>
                </div>
                <span className="text-[11px] font-mono font-bold px-2.5 py-1 rounded-lg bg-white border border-[#e4e0d5] text-[#171711]">
                  {activePreset === 'auto' ? 'Suggested' : activePreset === 'custom' ? 'Custom' : activePreset}
                </span>
              </div>

              {/* Schedule Options Pills (matching One Shortcut Away Section) */}
              <div className="flex flex-wrap items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => {
                    setActivePreset('auto');
                    setReturnAt(null);
                    setIsCustomOpen(false);
                    setCustomDateTime('');
                    setError(null);
                  }}
                  className={activePreset === 'auto'
                    ? 'inline-flex items-center gap-1.5 text-xs font-bold px-4 py-2 rounded-full border bg-[#e6edb0] border-[#171711]/25'
                    : 'inline-flex items-center gap-1.5 text-xs font-semibold px-4 py-2 rounded-full border bg-[#f4f3ed] text-[#4a4940] hover:bg-[#e9e7df] border-transparent'}
                >
                  <Sparkles className="h-3.5 w-3.5" />
                  Suggested
                </button>
                {PRESET_OPTIONS.map((opt) => {
                  const isSelected = activePreset === opt.key;
                  return (
                    <button
                      key={opt.key}
                      type="button"
                      onClick={() => handlePresetSelect(opt.key)}
                      className={`text-xs font-semibold px-4 py-2 rounded-full transition-all duration-200 cursor-pointer ${
                        isSelected
                          ? 'bg-[#e6edb0] text-[#171711] font-bold shadow-xs scale-102 border border-[#171711]/25'
                          : 'bg-[#f4f3ed] text-[#4a4940] hover:bg-[#e9e7df] border border-transparent'
                      }`}
                    >
                      {opt.label}
                    </button>
                  );
                })}

                <button
                  type="button"
                  onClick={() => setIsCustomOpen(!isCustomOpen)}
                  className={`inline-flex items-center gap-1.5 text-xs font-semibold px-4 py-2 rounded-full transition-all duration-200 cursor-pointer ${
                    activePreset === 'custom' || isCustomOpen
                      ? 'bg-[#171711] text-white font-bold'
                      : 'bg-[#f4f3ed] text-[#4a4940] hover:bg-[#e9e7df] border border-transparent'
                  }`}
                >
                  <Calendar className="w-3.5 h-3.5" />
                  <span>Custom…</span>
                </button>
              </div>

              {/* Custom Date & Time Picker */}
              {isCustomOpen && (
                <div className="p-4 rounded-2xl bg-white border-2 border-[#171711] space-y-2 mt-2 animate-in fade-in">
                  <label className="block text-xs font-bold text-[#171711]">
                    Choose custom date and return time:
                  </label>
                  <input
                    type="datetime-local"
                    value={customDateTime}
                    onChange={(e) => handleCustomDateSubmit(e.target.value)}
                    className="block w-full px-3 py-2 rounded-xl border border-[#e4e0d5] text-xs font-medium text-[#171711] focus:outline-hidden focus:border-[#171711]"
                  />
                </div>
              )}
            </div>
          )}

          {/* STEP 3: DETAILS & CONTEXT */}
          {step === 3 && (
            <div className="space-y-4 animate-in fade-in duration-200">
              {/* Prompt Label */}
              <div>
                <p className="text-[11px] sm:text-xs font-semibold text-[#8c897f] select-none tracking-wide">
                  {kind === 'task' ? 'Organize your task (optional)' : kind === 'note' ? 'Organize your note (optional)' : 'Add tags or manage attachments (optional)'}
                </p>
              </div>

              <div className="rounded-xl bg-[#f7f5ee] px-3 py-2.5 text-xs text-[#6c6b63]">
                <span className="font-bold text-[#171711]">Captured: </span>
                <span className="break-words">{contentSummary}</span>
              </div>
              <label className="block space-y-1.5">
                <span className="text-xs font-bold text-[#171711]">{kind === 'task' ? 'Task name' : kind === 'note' ? 'Note title' : 'Title'}</span>
                <input
                  type="text"
                  maxLength={200}
                  value={effectiveTitle}
                  disabled={saving || success}
                  onChange={event => setTitleOverride(event.target.value)}
                  placeholder="Give this item a title (optional)"
                  className="w-full rounded-xl border border-[#e4e0d5] bg-white px-3 py-2.5 text-sm font-semibold text-[#171711] focus:outline-hidden focus:border-[#171711]"
                />
                <span className="block text-[11px] text-[#8c897f]">
                  {kind === 'task' ? 'This is the action you will complete. Details stay in the description.' : kind === 'note' ? 'A short title makes this note easier to find.' : 'Prefilled from your capture. Rename it without changing the original content.'}
                </span>
              </label>

              {/* Tags Section */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs font-bold text-[#171711]">
                  <span className="flex items-center gap-1.5">
                    <Tag className="w-3.5 h-3.5 text-[#6c6b63]" />
                    <span>Tags & Collections</span>
                  </span>
                  {!showAddTag && (
                    <button
                      type="button"
                      onClick={() => setShowAddTag(true)}
                      className="text-[11px] text-[#6c6b63] hover:text-[#171711] font-semibold inline-flex items-center gap-1 cursor-pointer"
                    >
                      <Plus className="w-3 h-3" />
                      <span>Custom Tag</span>
                    </button>
                  )}
                </div>

                {suggestion.tags.length > 0 && !tagsTouched && (
                  <p className="text-[11px] text-[#6c6b63]">
                    <Sparkles className="inline h-3 w-3 align-text-bottom" /> Suggested tags are selected. Tap any to change.
                  </p>
                )}
                <div className="flex flex-wrap items-center gap-1.5">
                  {SUGGESTED_TAGS.map((tag) => {
                    const isSelected = effectiveTags.includes(tag);
                    return (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => toggleTag(tag)}
                        className={`text-xs px-3 py-1 rounded-full font-semibold transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-[#e6edb0] text-[#171711] font-bold border border-[#171711]/25'
                            : 'bg-[#f4f3ed] text-[#6c6b63] hover:bg-[#e9e7df] border border-transparent'
                        }`}
                      >
                        #{tag}
                      </button>
                    );
                  })}

                  {/* Any custom selected tags not in suggested */}
                  {effectiveTags
                    .filter((t) => !SUGGESTED_TAGS.includes(t))
                    .map((tag) => (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => toggleTag(tag)}
                        className="text-xs px-3 py-1 rounded-full font-bold bg-[#e6edb0] text-[#171711] border border-[#171711]/25 cursor-pointer"
                      >
                        #{tag}
                      </button>
                    ))}
                </div>

                {showAddTag && (
                  <div className="flex items-center gap-2 pt-1">
                    <input
                      type="text"
                      value={customTagInput}
                      onChange={(e) => setCustomTagInput(e.target.value)}
                      onKeyDown={(e) => {
                        if (e.key === 'Enter') {
                          e.preventDefault();
                          handleAddCustomTag();
                        }
                      }}
                      placeholder="Type tag name and press enter..."
                      className="flex-1 px-3 py-1.5 rounded-xl border border-[#e4e0d5] text-xs font-medium text-[#171711] focus:outline-hidden focus:border-[#171711]"
                      autoFocus
                    />
                    <button
                      type="button"
                      onClick={handleAddCustomTag}
                      className="px-3 py-1.5 text-xs font-bold bg-[#171711] text-white rounded-xl cursor-pointer"
                    >
                      Add
                    </button>
                    <button
                      type="button"
                      onClick={() => setShowAddTag(false)}
                      className="text-xs font-semibold text-[#8c897f] hover:text-[#171711] cursor-pointer"
                    >
                      Cancel
                    </button>
                  </div>
                )}
              </div>

              {/* Attached Files List */}
              <div className="space-y-2 pt-2 border-t border-[#f4f3ed]">
                <div className="flex items-center justify-between text-[11px] font-bold text-[#6c6b63]">
                  <span>Attached Files ({files.length})</span>
                  {files.length > 0 && (
                    <span>{formatBytes(files.reduce((acc, f) => acc + f.size, 0))}</span>
                  )}
                </div>

                {files.length === 0 ? (
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="w-full p-4 rounded-2xl border-2 border-dashed border-[#e4e0d5] hover:border-[#171711] bg-[#faf9f5] flex items-center justify-center gap-2 text-xs font-semibold text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                  >
                    <UploadCloud className="w-4 h-4" />
                    <span>Click to attach files (or drop here)</span>
                  </button>
                ) : (
                  <div className="max-h-28 overflow-y-auto space-y-1.5 pr-1">
                    {files.map((file, idx) => {
                      const ext = file.name.split('.').pop()?.toLowerCase() || '';
                      const isImg =
                        file.type.startsWith('image/') ||
                        ['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(ext);
                      const isPdf = ext === 'pdf' || file.type === 'application/pdf';
                      const isVid = file.type.startsWith('video/');
                      const isAud = file.type.startsWith('audio/');

                      return (
                        <div
                          key={`${file.name}-${idx}`}
                          className="flex items-center justify-between gap-2 p-2 rounded-xl bg-[#faf9f5] border border-[#e4e0d5]"
                        >
                          <div className="flex items-center gap-2 min-w-0">
                            <div className="w-6 h-6 rounded-lg bg-white flex items-center justify-center shrink-0 border border-[#e4e0d5]">
                              {isImg ? (
                                <ImageIcon className="w-3 h-3 text-[#0284c7]" />
                              ) : isPdf ? (
                                <FileText className="w-3 h-3 text-red-600" />
                              ) : isVid ? (
                                <PlayCircle className="w-3 h-3 text-rose-600" />
                              ) : isAud ? (
                                <Music2 className="w-3 h-3 text-emerald-600" />
                              ) : (
                                <Paperclip className="w-3 h-3 text-[#6c6b63]" />
                              )}
                            </div>
                            <div className="min-w-0">
                              <p className="text-xs font-bold text-[#171711] truncate">{file.name}</p>
                              <p className="text-[10px] text-[#9e9b92]">{formatBytes(file.size)}</p>
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => handleRemoveFile(idx)}
                            disabled={saving || success}
                            className="p-1 text-[#9e9b92] hover:text-red-600 rounded-md transition-colors cursor-pointer shrink-0"
                            title="Remove file"
                          >
                            <X className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Drag Overlay Status */}
          {isDragging && (
            <div className="mt-3 p-3 rounded-2xl border-2 border-dashed border-[#171711] bg-white flex items-center justify-center gap-2 text-xs font-bold text-[#171711]">
              <UploadCloud className="w-4 h-4 animate-bounce" />
              <span>Drop files here to attach</span>
            </div>
          )}

          {/* Error Message */}
          {error && (
            <div className="mt-3 flex items-center gap-2 p-3 rounded-xl bg-red-50 text-red-700 text-xs font-semibold border border-red-200">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}
        </div>

        {/* Footer Action Bar */}
        <div className="shrink-0 flex items-center justify-between gap-2 px-4 sm:px-6 py-4 border-t border-[#f4f3ed] bg-[#faf9f5]">
          <div className="flex items-center gap-2">
            {step > 1 ? (
              <button
                type="button"
                onClick={() => setStep((s) => (s > 1 ? ((s - 1) as 1 | 2) : 1))}
                disabled={saving || success}
                className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-bold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 rounded-xl transition-colors cursor-pointer"
              >
                <ArrowLeft className="w-3.5 h-3.5" />
                <span>Back</span>
              </button>
            ) : (
              <span className="text-[11px] text-[#9e9b92] hidden sm:inline-block">
                Press{' '}
                <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono text-[#171711]">
                  ⌘+Enter
                </kbd>{' '}
                to save
              </span>
            )}
          </div>

          <div className="flex items-center gap-2">
            {step < 3 && (
              <button
                type="button"
                onClick={() => setStep((s) => (s < 3 ? ((s + 1) as 2 | 3) : 3))}
                disabled={saving || success}
                className="inline-flex items-center gap-1 px-3.5 py-2 text-xs font-bold text-[#171711] bg-[#f4f3ed] hover:bg-[#e9e7df] rounded-xl transition-all cursor-pointer"
              >
                <span>{step === 1 ? 'Schedule' : 'Details'}</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            )}

            <button
              type="button"
              onClick={() => handleSubmit()}
              disabled={saving || !hasSubmitData || success}
              className="inline-flex items-center justify-center gap-2 px-5 py-2.5 text-xs font-bold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl shadow-xs transition-all duration-150 cursor-pointer"
            >
              {saving ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  <span>{files.length > 0 ? 'Uploading…' : 'Saving…'}</span>
                </>
              ) : (
                <span>{kind === 'task' ? 'Create task' : kind === 'note' ? 'Save note' : kind === 'file' ? 'Save files' : 'Save link'}</span>
              )}
            </button>
          </div>
        </div>

        {/* Slide-Up Green Color Fill Overlay (Revealing "SAVED.") */}
        <div
          className={`absolute inset-0 bg-[#e6edb0] flex flex-col items-center justify-center transition-transform duration-500 ease-out z-30 pointer-events-none select-none ${
            success ? 'translate-y-0' : 'translate-y-full'
          }`}
        >
          <div className="w-12 h-12 rounded-full bg-[#171711] text-[#e6edb0] flex items-center justify-center mb-3 shadow-md">
            <Check className="w-6 h-6 stroke-[3]" />
          </div>
          <span className="text-2xl font-black tracking-widest text-[#171711]">
            SAVED.
          </span>
          <p className="text-xs font-semibold text-[#4a4940] mt-1">
            {effectiveReturnAt ? `Returning ${returnLabel(effectiveReturnAt)}` : 'Stored in Someday Vault'}
          </p>
        </div>
      </div>
    </div>
  );
}
