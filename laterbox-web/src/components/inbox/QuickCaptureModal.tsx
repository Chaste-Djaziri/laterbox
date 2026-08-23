'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useItems } from '@/lib/store/ItemContext';
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
} from 'lucide-react';

interface QuickCaptureModalProps {
  isOpen: boolean;
  onClose: () => void;
}

function formatBytes(bytes: number): string {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}

export function QuickCaptureModal({ isOpen, onClose }: QuickCaptureModalProps) {
  const { saveItem } = useItems();
  const [content, setContent] = useState('');
  const [files, setFiles] = useState<File[]>([]);
  const [isDragging, setIsDragging] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);

  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen) {
      setContent('');
      setFiles([]);
      setIsDragging(false);
      setError(null);
      setSuccess(false);
      setSaving(false);
      setTimeout(() => textareaRef.current?.focus(), 50);
    }
  }, [isOpen]);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (!isOpen) return;
      if (e.key === 'Escape') onClose();
      if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
        handleSubmit();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  });

  if (!isOpen) return null;

  const handleFilesSelected = (newFiles: FileList | File[]) => {
    const arr = Array.from(newFiles);
    if (arr.length === 0) return;
    setFiles((prev) => [...prev, ...arr]);
  };

  const handleRemoveFile = (index: number) => {
    setFiles((prev) => prev.filter((_, i) => i !== index));
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

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    const hasContent = content.trim().length > 0;
    const hasFiles = files.length > 0;

    if (saving || (!hasContent && !hasFiles)) return;

    setSaving(true);
    setError(null);

    try {
      await saveItem(content.trim(), { files });
      setSuccess(true);
      setTimeout(() => {
        onClose();
      }, 500);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Could not save this item. Try again.');
      setSaving(false);
    }
  };

  const hasSubmitData = content.trim().length > 0 || files.length > 0;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/50 backdrop-blur-xs transition-all duration-300 animate-in fade-in"
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      <div
        className={`w-full max-w-lg bg-[#f7f5ee] rounded-t-3xl sm:rounded-3xl shadow-2xl border transition-all duration-200 p-6 sm:p-7 relative scale-100 ${
          isDragging ? 'border-[#171711] ring-4 ring-[#171711]/10 bg-[#ebe7dc]' : 'border-[#e4e0d5]'
        }`}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 text-[#6c6b63] hover:text-[#171711] rounded-full hover:bg-[#ebe7dc]/70 transition-colors cursor-pointer"
          title="Close (Esc)"
        >
          <X className="w-5 h-5" />
        </button>

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

        {/* Header */}
        <div className="flex items-center gap-3 mb-5">
          <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84] shrink-0">
            <Link2 className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-xl font-extrabold text-[#171711] tracking-tight">Save to laterbox</h2>
            <p className="text-xs text-[#6c6b63] font-medium">
              Paste a URL, markdown snippet, or upload attachments
            </p>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="relative">
            <textarea
              ref={textareaRef}
              disabled={saving || success}
              rows={3}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              onPaste={handlePaste}
              placeholder="https://... or notes (you can also drop or paste files)"
              className="w-full px-4 py-3.5 text-sm bg-white border border-[#e4e0d5] rounded-2xl text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-500 transition-all resize-none font-normal leading-relaxed"
            />
          </div>

          {/* Attached Files List */}
          {files.length > 0 && (
            <div className="space-y-2">
              <div className="flex items-center justify-between text-[11px] font-bold text-[#6c6b63] px-1">
                <span>Attached Files ({files.length})</span>
                <span>{formatBytes(files.reduce((acc, f) => acc + f.size, 0))}</span>
              </div>
              <div className="max-h-36 overflow-y-auto space-y-1.5 pr-1">
                {files.map((file, idx) => {
                  const ext = file.name.split('.').pop()?.toLowerCase() || '';
                  const isImg = file.type.startsWith('image/') || ['jpg', 'jpeg', 'png', 'webp', 'gif'].includes(ext);
                  const isPdf = ext === 'pdf' || file.type === 'application/pdf';
                  const isVid = file.type.startsWith('video/');
                  const isAud = file.type.startsWith('audio/');

                  return (
                    <div
                      key={`${file.name}-${idx}`}
                      className="flex items-center justify-between gap-2 p-2.5 rounded-xl bg-white border border-[#e4e0d5] shadow-2xs"
                    >
                      <div className="flex items-center gap-2.5 min-w-0">
                        <div className="w-7 h-7 rounded-lg bg-[#f7f5ee] flex items-center justify-center shrink-0 border border-[#e4e0d5]">
                          {isImg ? (
                            <ImageIcon className="w-3.5 h-3.5 text-[#0284c7]" />
                          ) : isPdf ? (
                            <FileText className="w-3.5 h-3.5 text-red-600" />
                          ) : isVid ? (
                            <PlayCircle className="w-3.5 h-3.5 text-rose-600" />
                          ) : isAud ? (
                            <Music2 className="w-3.5 h-3.5 text-emerald-600" />
                          ) : (
                            <Paperclip className="w-3.5 h-3.5 text-[#6c6b63]" />
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
                        className="p-1 text-[#9e9b92] hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors cursor-pointer shrink-0"
                        title="Remove file"
                      >
                        <X className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {/* Drag & Drop Overlay Info */}
          {isDragging && (
            <div className="p-4 rounded-2xl border-2 border-dashed border-[#171711] bg-white/70 flex items-center justify-center gap-2 text-xs font-bold text-[#171711]">
              <UploadCloud className="w-4 h-4" />
              <span>Drop files here to attach</span>
            </div>
          )}

          {error && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-red-50 text-red-700 text-xs font-semibold border border-red-200">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {success && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-[#e6edb0]/70 text-[#171711] text-xs font-bold border border-[#d0db84]">
              <Check className="w-4 h-4 shrink-0" />
              <span>Saved to your inbox!</span>
            </div>
          )}

          {/* Action Bar */}
          <div className="flex items-center justify-between pt-2">
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={saving || success}
                className="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-bold text-[#171711] bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] rounded-xl shadow-2xs transition-colors cursor-pointer disabled:opacity-50"
                title="Attach files (images, PDFs, documents, audio, videos)"
              >
                <Paperclip className="w-3.5 h-3.5 text-[#6c6b63]" />
                <span>Upload Attachment</span>
              </button>

              <span className="text-[11px] text-[#9e9b92] hidden sm:inline-block">
                Press <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono text-[#171711]">⌘+Enter</kbd>
              </span>
            </div>

            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={onClose}
                className="px-3.5 py-2 text-xs font-semibold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 rounded-xl transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={saving || !hasSubmitData || success}
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 text-xs font-bold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl shadow-xs transition-all duration-150 cursor-pointer"
              >
                {saving ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>{files.length > 0 ? 'Uploading…' : 'Saving…'}</span>
                  </>
                ) : success ? (
                  <>
                    <Check className="w-4 h-4" />
                    <span>Saved</span>
                  </>
                ) : (
                  <span>Save Item</span>
                )}
              </button>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
}
