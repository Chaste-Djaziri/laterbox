'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { X, Link2, Check, AlertCircle, Loader2 } from 'lucide-react';

interface QuickCaptureModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export function QuickCaptureModal({ isOpen, onClose }: QuickCaptureModalProps) {
  const { saveItem } = useItems();
  const [content, setContent] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState(false);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (isOpen) {
      setContent('');
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

  const handleSubmit = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (saving || !content.trim()) return;

    setSaving(true);
    setError(null);

    try {
      await saveItem(content.trim());
      setSuccess(true);
      setTimeout(() => {
        onClose();
      }, 500);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Could not save this item. Try again.');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-0 sm:p-4 bg-black/50 backdrop-blur-xs transition-all duration-300 animate-in fade-in">
      <div
        className="w-full max-w-lg bg-[#f7f5ee] rounded-t-3xl sm:rounded-3xl shadow-2xl border border-[#e4e0d5] p-6 sm:p-7 relative transition-all duration-200 scale-100"
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

        {/* Header */}
        <div className="flex items-center gap-3 mb-5">
          <div className="w-10 h-10 rounded-2xl bg-[#e6edb0] flex items-center justify-center text-[#171711] border border-[#d0db84]">
            <Link2 className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-xl font-extrabold text-[#171711] tracking-tight">Save to laterbox</h2>
            <p className="text-xs text-[#6c6b63] font-medium">
              Paste a URL, markdown snippet, or quick note
            </p>
          </div>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="relative">
            <textarea
              ref={textareaRef}
              disabled={saving || success}
              rows={4}
              value={content}
              onChange={(e) => setContent(e.target.value)}
              placeholder="https://... or type anything to remember"
              className="w-full px-4 py-3.5 text-sm bg-white border border-[#e4e0d5] rounded-2xl text-[#171711] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-500 transition-all resize-none font-normal leading-relaxed"
            />
          </div>

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

          <div className="flex items-center justify-between pt-2">
            <span className="text-xs text-[#9e9b92] hidden sm:inline-block">
              Press <kbd className="px-1.5 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono text-[#171711]">⌘+Enter</kbd> to save
            </span>

            <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2.5 text-xs font-semibold text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc]/60 rounded-xl transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={saving || !content.trim() || success}
                className="inline-flex items-center justify-center gap-2 px-5 py-2.5 text-xs font-bold text-white bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] disabled:opacity-50 disabled:cursor-not-allowed rounded-xl shadow-xs transition-all duration-150 cursor-pointer"
              >
                {saving ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    <span>Saving…</span>
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
