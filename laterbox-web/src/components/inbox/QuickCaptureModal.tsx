'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import Link from 'next/link';
import { resolveReturnPreset, returnLabel, type ReturnPreset } from '@/lib/utils/schedule';
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
  const [activePreset, setActivePreset] = useState<ReturnPreset | 'custom'>('tomorrow');
  const [customDateTime, setCustomDateTime] = useState<string>('');
  const [isCustomOpen, setIsCustomOpen] = useState(false);

  const [kind, setKind] = useState<'link' | 'note' | 'task' | 'file'>('link');
  const [duplicateId, setDuplicateId] = useState<string | null>(null);
  const { saveItem } = useItems();
  const [content, setContent] = useState('');
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [customTagInput, setCustomTagInput] = useState('');
  const [showAddTag, setShowAddTag] = useState(false);

  const [files, setFiles] = useState<File[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Initialize on modal open
  useEffect(() => {
    if (isOpen) {
      setStep(1);
      setContent('');
      setFiles(initialFiles || []);
      const defaultReturn = resolveReturnPreset('tomorrow');
      setReturnAt(defaultReturn);
      setActivePreset('tomorrow');
      setIsCustomOpen(false);
      setCustomDateTime('');
      setSelectedTags([]);
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

  // Auto-detect link or text patterns
  const handleContentChange = (text: string) => {
    setContent(text);
    const trimmed = text.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('www.')) {
      setKind('link');
    } else if (trimmed.startsWith('- [ ]') || trimmed.startsWith('TODO:') || trimmed.startsWith('Todo:')) {
      setKind('task');
    } else if (trimmed.length > 0 && kind === 'link' && !trimmed.includes('.') && files.length === 0) {
      setKind('note');
    }
  };

  if (!isOpen) return null;

  const handleFilesSelected = (newFiles: FileList | File[]) => {
    const arr = Array.from(newFiles);
    if (arr.length === 0) return;
    setFiles((prev) => [...prev, ...arr]);
    setKind('file');
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
    if (!dateTimeString) {
      setReturnAt(null);
      return;
    }
    const date = new Date(dateTimeString);
    if (!Number.isFinite(date.getTime()) || date <= new Date()) {
      setError('Choose a future return time, or select Now.');
      return;
    }
    setError(null);
    setActivePreset('custom');
    setReturnAt(date.toISOString());
  };

  const toggleTag = (tag: string) => {
    setSelectedTags((prev) =>
      prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag]
    );
  };

  const handleAddCustomTag = () => {
    const trimmed = customTagInput.trim().replace(/^#/, '');
    if (trimmed && !selectedTags.includes(trimmed)) {
      setSelectedTags((prev) => [...prev, trimmed]);
      setCustomTagInput('');
      setShowAddTag(false);
    }
  };

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const hasContent = content.trim().length > 0;
    const hasFiles = files.length > 0;

    if (saving || (!hasContent && !hasFiles)) return;

    setSaving(true);
    setError(null);

    try {
      const id = crypto.randomUUID();
      let payloadContent = content.trim();

      // Append tags as clean tags if present and content is text
      if (selectedTags.length > 0) {
        const tagLine = selectedTags.map((t) => `#${t}`).join(' ');
        if (payloadContent.length > 0) {
          payloadContent = `${payloadContent}\n\n${tagLine}`;
        } else {
          payloadContent = tagLine;
        }
      }

      const item = await saveItem(payloadContent, {
        id,
        files,
        returnAt,
        type: files.length ? 'file' : kind === 'task' ? 'task' : kind === 'note' ? 'note' : 'link',
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

  const hasSubmitData = content.trim().length > 0 || files.length > 0;

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
        className={`relative w-full max-w-[560px] rounded-[28px] sm:rounded-[34px] bg-white border-2 border-[#171711] shadow-[0_24px_70px_rgba(0,0,0,0.22),0_8px_24px_rgba(230,237,176,0.35)] overflow-hidden transition-all duration-200 ${
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
        <div className="p-6 sm:p-7 min-h-[260px] flex flex-col justify-between">
          {/* STEP 1: CAPTURE */}
          {step === 1 && (
            <div className="space-y-4 animate-in fade-in duration-200">
              {/* Prompt Label */}
              <div>
                <p className="text-[11px] sm:text-xs font-semibold text-[#8c897f] select-none tracking-wide">
                  What do you want to deal with later?
                </p>
              </div>

              {/* Main Prominent Input */}
              <div className="relative min-h-[100px]">
                <textarea
                  ref={textareaRef}
                  disabled={saving || success}
                  rows={3}
                  value={content}
                  onChange={(e) => handleContentChange(e.target.value)}
                  onPaste={handlePaste}
                  placeholder="Paste a link, note, task, or drop files..."
                  className="w-full text-xl sm:text-2xl font-bold tracking-tight text-[#171711] placeholder:text-[#b4b1a7] bg-transparent border-none outline-none focus:ring-0 resize-none leading-snug p-0"
                />
              </div>

              {/* Type Switcher Pills & File Attachment Status */}
              <div className="flex flex-wrap items-center justify-between gap-2 pt-2 border-t border-[#f4f3ed]">
                <div className="flex flex-wrap items-center gap-1.5">
                  {(
                    [
                      { id: 'link', label: 'Link', icon: Link2 },
                      { id: 'note', label: 'Note', icon: FileText },
                      { id: 'task', label: 'Task', icon: CheckSquare },
                      { id: 'file', label: 'File', icon: Paperclip },
                    ] as const
                  ).map((t) => {
                    const isSelected = kind === t.id;
                    const IconComponent = t.icon;
                    return (
                      <button
                        key={t.id}
                        type="button"
                        onClick={() => {
                          setKind(t.id);
                          if (t.id === 'file') {
                            fileInputRef.current?.click();
                          }
                        }}
                        className={`inline-flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                          isSelected
                            ? 'bg-[#e6edb0] text-[#171711] shadow-xs border border-[#171711]/25 scale-102'
                            : 'bg-[#f4f3ed] text-[#4a4940] hover:bg-[#e9e7df] border border-transparent'
                        }`}
                      >
                        <IconComponent className="w-3.5 h-3.5" />
                        <span>{t.label}</span>
                      </button>
                    );
                  })}
                </div>

                {/* Quick File Attach Trigger */}
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  className="inline-flex items-center gap-1.5 text-xs font-semibold px-3 py-1.5 rounded-full bg-white border border-[#e4e0d5] text-[#171711] hover:bg-[#f4f3ed] transition-colors cursor-pointer"
                >
                  <Paperclip className="w-3.5 h-3.5 text-[#6c6b63]" />
                  <span>
                    {files.length > 0 ? `${files.length} attached` : 'Attach file'}
                  </span>
                </button>
              </div>
            </div>
          )}

          {/* STEP 2: SCHEDULE */}
          {step === 2 && (
            <div className="space-y-4 animate-in fade-in duration-200">
              {/* Prompt Label */}
              <div>
                <p className="text-[11px] sm:text-xs font-semibold text-[#8c897f] select-none tracking-wide">
                  When should LaterBox bring this back?
                </p>
              </div>

              {/* Friendly Schedule Preview Banner */}
              <div className="p-4 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-[#e6edb0] border border-[#171711]/20 flex items-center justify-center text-[#171711] shrink-0">
                    <Clock className="w-4 h-4" />
                  </div>
                  <div>
                    <p className="text-xs font-bold text-[#171711]">
                      {returnAt ? `Returning ${returnLabel(returnAt)}` : 'Someday (no deadline)'}
                    </p>
                    <p className="text-[11px] text-[#6c6b63]">
                      {returnAt
                        ? 'Will reappear at the top of your inbox on schedule'
                        : 'Saved to your Someday archive until you decide'}
                    </p>
                  </div>
                </div>
                <span className="text-[11px] font-mono font-bold px-2.5 py-1 rounded-lg bg-white border border-[#e4e0d5] text-[#171711]">
                  {activePreset === 'custom' ? 'Custom' : activePreset}
                </span>
              </div>

              {/* Schedule Options Pills (matching One Shortcut Away Section) */}
              <div className="flex flex-wrap items-center gap-2 pt-2">
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
                  Add tags or manage attachments (optional)
                </p>
              </div>

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

                <div className="flex flex-wrap items-center gap-1.5">
                  {SUGGESTED_TAGS.map((tag) => {
                    const isSelected = selectedTags.includes(tag);
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
                  {selectedTags
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
        <div className="flex items-center justify-between px-6 py-4 border-t border-[#f4f3ed] bg-[#faf9f5]">
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
                <span>Save to LaterBox</span>
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
            {returnAt ? `Returning ${returnLabel(returnAt)}` : 'Stored in Someday Vault'}
          </p>
        </div>
      </div>
    </div>
  );
}
