'use client';

import React, { useState } from 'react';
import {
  BookOpen,
  Code2,
  FileCode,
  Copy,
  Check,
  Clock,
  User,
  Calendar,
  ExternalLink,
} from 'lucide-react';

interface ArticleReaderProps {
  markdown?: string | null;
  htmlContent?: string | null;
  rawText?: string | null;
  author?: string | null;
  publishedTime?: string | null;
  readingTimeMinutes?: number | null;
  sourceUrl?: string | null;
}

export function ArticleReader({
  markdown,
  htmlContent,
  rawText,
  author,
  publishedTime,
  readingTimeMinutes,
  sourceUrl,
}: ArticleReaderProps) {
  const [activeTab, setActiveTab] = useState<'formatted' | 'markdown' | 'html'>('formatted');
  const [copied, setCopied] = useState(false);

  const effectiveMarkdown = markdown || rawText || '';
  const effectiveHtml = htmlContent || '';

  if (!effectiveMarkdown && !effectiveHtml) {
    return null;
  }

  const handleCopy = () => {
    let textToCopy = '';
    if (activeTab === 'markdown') {
      textToCopy = effectiveMarkdown;
    } else if (activeTab === 'html') {
      textToCopy = effectiveHtml;
    } else {
      textToCopy = effectiveMarkdown || rawText || '';
    }

    if (textToCopy) {
      void navigator.clipboard.writeText(textToCopy);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  // Format published time nicely
  const formattedDate = publishedTime
    ? (() => {
        try {
          const d = new Date(publishedTime);
          return isNaN(d.getTime()) ? null : d.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
        } catch {
          return null;
        }
      })()
    : null;

  return (
    <section className="mt-8 pt-8 border-t border-[#e4e0d5]/80 space-y-5">
      {/* Reader Mode Header Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-xl bg-[#e6edb0] border border-[#171711]/20 flex items-center justify-center text-[#171711]">
            <BookOpen className="w-4 h-4" />
          </div>
          <div>
            <h2 className="text-sm font-bold text-[#171711]">Article Reader</h2>
            <div className="flex flex-wrap items-center gap-2 text-[11px] text-[#8c897f]">
              {readingTimeMinutes && (
                <span className="flex items-center gap-1 font-medium">
                  <Clock className="w-3 h-3" />
                  <span>{readingTimeMinutes} min read</span>
                </span>
              )}
              {author && (
                <>
                  <span>•</span>
                  <span className="flex items-center gap-1 font-medium">
                    <User className="w-3 h-3" />
                    <span>{author}</span>
                  </span>
                </>
              )}
              {formattedDate && (
                <>
                  <span>•</span>
                  <span className="flex items-center gap-1 font-medium">
                    <Calendar className="w-3 h-3" />
                    <span>{formattedDate}</span>
                  </span>
                </>
              )}
            </div>
          </div>
        </div>

        {/* View Mode Switcher and Copy Button */}
        <div className="flex items-center gap-2 self-start sm:self-auto">
          <div className="inline-flex items-center p-1 rounded-xl bg-[#f4f3ed] border border-[#e4e0d5]">
            <button
              type="button"
              onClick={() => setActiveTab('formatted')}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                activeTab === 'formatted'
                  ? 'bg-white text-[#171711] shadow-2xs'
                  : 'text-[#8c897f] hover:text-[#171711]'
              }`}
            >
              <BookOpen className="w-3.5 h-3.5" />
              <span>Formatted</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('markdown')}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                activeTab === 'markdown'
                  ? 'bg-white text-[#171711] shadow-2xs'
                  : 'text-[#8c897f] hover:text-[#171711]'
              }`}
            >
              <FileCode className="w-3.5 h-3.5" />
              <span>Markdown</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveTab('html')}
              className={`flex items-center gap-1.5 px-3 py-1 rounded-lg text-xs font-bold transition-all cursor-pointer ${
                activeTab === 'html'
                  ? 'bg-white text-[#171711] shadow-2xs'
                  : 'text-[#8c897f] hover:text-[#171711]'
              }`}
            >
              <Code2 className="w-3.5 h-3.5" />
              <span>HTML</span>
            </button>
          </div>

          <button
            type="button"
            onClick={handleCopy}
            title={`Copy ${activeTab === 'markdown' ? 'Markdown' : activeTab === 'html' ? 'HTML' : 'Text'}`}
            className="flex items-center gap-1 px-3 py-1.5 rounded-xl bg-white hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs font-bold text-[#171711] shadow-2xs transition-colors cursor-pointer"
          >
            {copied ? <Check className="w-3.5 h-3.5 text-emerald-600" /> : <Copy className="w-3.5 h-3.5 text-[#8c897f]" />}
            <span className="hidden sm:inline">{copied ? 'Copied' : 'Copy'}</span>
          </button>
        </div>
      </div>

      {/* Reader Content Body */}
      <div className="rounded-2xl border border-[#e4e0d5] bg-[#fbfaf6] p-6 sm:p-8 overflow-hidden">
        {/* VIEW 1: Formatted Reader */}
        {activeTab === 'formatted' && (
          <div className="space-y-4 max-w-none text-[#171711] font-serif leading-relaxed text-base sm:text-lg">
            {effectiveHtml ? (
              <div
                className="prose prose-neutral max-w-none [&_h1]:text-2xl [&_h1]:font-black [&_h1]:font-sans [&_h1]:text-[#171711] [&_h1]:mb-4 [&_h2]:text-xl [&_h2]:font-bold [&_h2]:font-sans [&_h2]:text-[#171711] [&_h2]:mt-6 [&_h2]:mb-3 [&_h3]:text-lg [&_h3]:font-bold [&_h3]:font-sans [&_h3]:mt-4 [&_h3]:mb-2 [&_p]:mb-4 [&_p]:leading-relaxed [&_p]:text-[#2c2b28] [&_ul]:list-disc [&_ul]:pl-6 [&_ul]:mb-4 [&_ol]:list-decimal [&_ol]:pl-6 [&_ol]:mb-4 [&_li]:mb-1 [&_blockquote]:border-l-4 [&_blockquote]:border-[#171711]/30 [&_blockquote]:pl-4 [&_blockquote]:italic [&_blockquote]:my-4 [&_pre]:p-4 [&_pre]:rounded-xl [&_pre]:bg-[#171711] [&_pre]:text-[#fbfaf6] [&_pre]:font-mono [&_pre]:text-xs [&_pre]:overflow-x-auto [&_code]:font-mono [&_code]:text-xs [&_code]:bg-[#ebe7dc] [&_code]:px-1 [&_code]:py-0.5 [&_code]:rounded-sm [&_a]:text-[#0369a1] [&_a]:underline [&_figure]:my-6 [&_img]:rounded-xl [&_img]:max-w-full [&_img]:border [&_img]:border-[#e4e0d5] [&_figcaption]:text-xs [&_figcaption]:text-[#8c897f] [&_figcaption]:mt-1 [&_figcaption]:text-center"
                dangerouslySetInnerHTML={{ __html: effectiveHtml }}
              />
            ) : (
              <div className="whitespace-pre-wrap font-sans text-sm sm:text-base leading-relaxed text-[#2c2b28]">
                {effectiveMarkdown}
              </div>
            )}
          </div>
        )}

        {/* VIEW 2: Raw Markdown View */}
        {activeTab === 'markdown' && (
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs text-[#8c897f]">
              <span className="font-mono">Clean Markdown representation</span>
              <span>{effectiveMarkdown.length} characters</span>
            </div>
            <pre className="p-4 rounded-xl bg-[#171711] text-[#f4f3ed] font-mono text-xs sm:text-sm leading-relaxed overflow-x-auto whitespace-pre-wrap max-h-[600px] overflow-y-auto selection:bg-[#e6edb0] selection:text-[#171711]">
              <code>{effectiveMarkdown}</code>
            </pre>
          </div>
        )}

        {/* VIEW 3: Clean HTML Source View */}
        {activeTab === 'html' && (
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs text-[#8c897f]">
              <span className="font-mono">Sanitized Reader HTML</span>
              <span>{effectiveHtml.length || effectiveMarkdown.length} characters</span>
            </div>
            <pre className="p-4 rounded-xl bg-[#171711] text-[#7dd3fc] font-mono text-xs sm:text-sm leading-relaxed overflow-x-auto whitespace-pre-wrap max-h-[600px] overflow-y-auto selection:bg-[#e6edb0] selection:text-[#171711]">
              <code>{effectiveHtml || `<p>${effectiveMarkdown}</p>`}</code>
            </pre>
          </div>
        )}
      </div>

      {sourceUrl && (
        <div className="flex items-center justify-end text-xs text-[#8c897f] pt-1">
          <a
            href={sourceUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-1 text-[#0369a1] hover:underline font-medium"
          >
            <span>Read full original article at source</span>
            <ExternalLink className="w-3 h-3" />
          </a>
        </div>
      )}
    </section>
  );
}
