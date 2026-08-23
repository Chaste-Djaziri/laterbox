'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useItems } from '@/lib/store/ItemContext';
import { StickyNote, Check, Loader2, Trash2 } from 'lucide-react';

interface NoteEditorProps {
  itemId: string;
  initialContent?: string | null;
}

export function NoteEditor({ itemId, initialContent }: NoteEditorProps) {
  const { saveNote } = useItems();
  const [content, setContent] = useState(initialContent || '');
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const timeoutRef = useRef<NodeJS.Timeout | null>(null);

  useEffect(() => {
    setContent(initialContent || '');
  }, [initialContent]);

  const handleChange = (e: React.ChangeEvent<HTMLTextAreaElement>) => {
    const value = e.target.value;
    setContent(value);
    setSaved(false);

    if (timeoutRef.current) {
      clearTimeout(timeoutRef.current);
    }

    timeoutRef.current = setTimeout(async () => {
      setSaving(true);
      try {
        await saveNote(itemId, value);
        setSaved(true);
        setTimeout(() => setSaved(false), 2000);
      } finally {
        setSaving(false);
      }
    }, 600);
  };

  const handleClear = async () => {
    setContent('');
    setSaving(true);
    try {
      await saveNote(itemId, '');
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] p-4 sm:p-5 my-4 transition-all">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <StickyNote className="w-4 h-4 text-[#171711]" />
          <h3 className="text-xs font-bold uppercase tracking-wider text-[#171711]">Personal Note</h3>
        </div>

        <div className="flex items-center gap-2">
          {saving && (
            <span className="inline-flex items-center gap-1 text-[11px] text-[#9e9b92] font-medium">
              <Loader2 className="w-3 h-3 animate-spin" />
              Saving…
            </span>
          )}
          {saved && !saving && (
            <span className="inline-flex items-center gap-1 text-[11px] text-[#171711] font-semibold animate-in fade-in">
              <Check className="w-3 h-3" />
              Saved
            </span>
          )}
          {content.trim().length > 0 && (
            <button
              onClick={handleClear}
              title="Delete Note"
              className="p-1 text-[#9e9b92] hover:text-red-500 rounded-lg hover:bg-[#ebe7dc]/60 transition-colors cursor-pointer"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </button>
          )}
        </div>
      </div>

      <textarea
        value={content}
        onChange={handleChange}
        placeholder="Add thoughts, key quotes, or action items..."
        rows={4}
        className="w-full bg-white border border-[#e4e0d5] rounded-xl p-3 text-sm text-[#171711] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-zinc-900/10 focus:border-zinc-500 transition-all resize-none leading-relaxed"
      />
    </div>
  );
}
