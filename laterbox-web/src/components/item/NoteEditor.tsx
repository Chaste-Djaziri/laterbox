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
    <div className="rounded-2xl bg-zinc-50 border border-zinc-200/80 p-4 sm:p-5 my-4 transition-all">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-2">
          <StickyNote className="w-4 h-4 text-emerald-600" />
          <h3 className="text-xs font-bold uppercase tracking-wider text-zinc-700">Personal Note</h3>
        </div>

        <div className="flex items-center gap-2">
          {saving && (
            <span className="inline-flex items-center gap-1 text-[11px] text-zinc-400 font-medium">
              <Loader2 className="w-3 h-3 animate-spin" />
              Saving…
            </span>
          )}
          {saved && !saving && (
            <span className="inline-flex items-center gap-1 text-[11px] text-emerald-600 font-semibold animate-in fade-in">
              <Check className="w-3 h-3" />
              Saved
            </span>
          )}
          {content.trim().length > 0 && (
            <button
              onClick={handleClear}
              title="Delete Note"
              className="p-1 text-zinc-400 hover:text-red-500 rounded-lg hover:bg-zinc-200/50 transition-colors"
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
        className="w-full bg-white border border-zinc-200/80 rounded-xl p-3 text-sm text-zinc-900 placeholder:text-zinc-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/80 focus:border-transparent transition-all resize-none leading-relaxed"
      />
    </div>
  );
}
