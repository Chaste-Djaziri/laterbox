'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { DOCS_SECTIONS, ALL_DOCS, DocItem, getDocBySlug } from '@/lib/docs-data';
import {
  Search,
  BookOpen,
  Sparkles,
  Layers,
  Laptop,
  Database,
  Code2,
  ChevronRight,
  ChevronDown,
  Copy,
  Check,
  ExternalLink,
  ArrowLeft,
  ArrowRight,
  Menu,
  X,
  FileText,
  ShieldCheck,
  Command,
  HelpCircle,
  Clock,
  Download,
} from 'lucide-react';

interface DocsReaderProps {
  currentSlug?: string;
}

export function DocsReader({ currentSlug = 'introduction' }: DocsReaderProps) {
  const [activeSlug, setActiveSlug] = useState<string>(currentSlug);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isSearchOpen, setIsSearchOpen] = useState<boolean>(false);
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState<boolean>(false);
  const [copiedCodeIndex, setCopiedCodeIndex] = useState<number | null>(null);

  useEffect(() => {
    if (currentSlug) {
      setActiveSlug(currentSlug);
    }
  }, [currentSlug]);

  // Global Keyboard Shortcuts (⌘K / Ctrl+K for search)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsSearchOpen((prev) => !prev);
      } else if (e.key === 'Escape' && isSearchOpen) {
        setIsSearchOpen(false);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isSearchOpen]);

  const activeDoc: DocItem = useMemo(() => {
    return getDocBySlug(activeSlug) || ALL_DOCS[0];
  }, [activeSlug]);

  // Find previous & next docs
  const currentIndex = ALL_DOCS.findIndex((d) => d.slug === activeDoc.slug);
  const prevDoc = currentIndex > 0 ? ALL_DOCS[currentIndex - 1] : null;
  const nextDoc = currentIndex < ALL_DOCS.length - 1 ? ALL_DOCS[currentIndex + 1] : null;

  // Search Results
  const searchResults = useMemo(() => {
    if (!searchQuery.trim()) return [];
    const q = searchQuery.toLowerCase();
    return ALL_DOCS.filter(
      (d) =>
        d.title.toLowerCase().includes(q) ||
        d.description.toLowerCase().includes(q) ||
        d.category.toLowerCase().includes(q) ||
        d.content.toLowerCase().includes(q)
    );
  }, [searchQuery]);

  const handleCopy = (text: string, idx: number) => {
    navigator.clipboard.writeText(text);
    setCopiedCodeIndex(idx);
    setTimeout(() => setCopiedCodeIndex(null), 2000);
  };

  const selectDoc = (slug: string) => {
    setActiveSlug(slug);
    setIsMobileSidebarOpen(false);
    setIsSearchOpen(false);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  // Section icons
  const getSectionIcon = (id: string) => {
    switch (id) {
      case 'getting-started':
        return <Sparkles className="w-3.5 h-3.5 text-[#6c6b63]" />;
      case 'architecture':
        return <Layers className="w-3.5 h-3.5 text-[#6c6b63]" />;
      case 'platforms':
        return <Laptop className="w-3.5 h-3.5 text-[#6c6b63]" />;
      case 'backend':
        return <Database className="w-3.5 h-3.5 text-[#6c6b63]" />;
      case 'developer':
        return <Code2 className="w-3.5 h-3.5 text-[#6c6b63]" />;
      default:
        return <FileText className="w-3.5 h-3.5 text-[#6c6b63]" />;
    }
  };

  // Helper function to render inline markdown (bold, code, links, italic)
  const renderInlineMarkdown = (text: string): React.ReactNode => {
    if (!text) return text;

    const tokens: React.ReactNode[] = [];
    const pattern = /(`[^`]+`|\*\*[^*]+\*\*|\[[^\]]+\]\([^)]+\)|\*[^*]+\*)/g;

    let lastIndex = 0;
    let match: RegExpExecArray | null;

    while ((match = pattern.exec(text)) !== null) {
      if (match.index > lastIndex) {
        tokens.push(text.slice(lastIndex, match.index));
      }

      const matchedStr = match[0];
      const key = `${match.index}-${matchedStr}`;

      if (matchedStr.startsWith('`') && matchedStr.endsWith('`')) {
        tokens.push(
          <code
            key={key}
            className="px-1.5 py-0.5 mx-0.5 rounded-md bg-[#ebe7dc] text-[#171711] font-mono text-xs font-bold border border-[#d8d4c9]"
          >
            {matchedStr.slice(1, -1)}
          </code>
        );
      } else if (matchedStr.startsWith('**') && matchedStr.endsWith('**')) {
        tokens.push(
          <strong key={key} className="font-extrabold text-[#171711]">
            {matchedStr.slice(2, -2)}
          </strong>
        );
      } else if (matchedStr.startsWith('[') && matchedStr.includes('](')) {
        const linkMatch = matchedStr.match(/^\[(.*?)\]\((.*?)\)$/);
        if (linkMatch) {
          const [, label, url] = linkMatch;
          const isExternal = url.startsWith('http') || url.startsWith('mailto:');
          if (isExternal) {
            tokens.push(
              <a
                key={key}
                href={url}
                target="_blank"
                rel="noopener noreferrer"
                className="text-[#171711] font-bold underline decoration-[#171711]/40 hover:decoration-[#171711] underline-offset-2 transition-colors inline-flex items-center gap-0.5"
              >
                <span>{label}</span>
                <ExternalLink className="w-3 h-3 inline" />
              </a>
            );
          } else {
            tokens.push(
              <Link
                key={key}
                href={url}
                className="text-[#171711] font-bold underline decoration-[#171711]/40 hover:decoration-[#171711] underline-offset-2 transition-colors"
              >
                {label}
              </Link>
            );
          }
        } else {
          tokens.push(matchedStr);
        }
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*')) {
        tokens.push(
          <em key={key} className="italic text-[#383733]">
            {matchedStr.slice(1, -1)}
          </em>
        );
      } else {
        tokens.push(matchedStr);
      }

      lastIndex = pattern.lastIndex;
    }

    if (lastIndex < text.length) {
      tokens.push(text.slice(lastIndex));
    }

    return tokens.length === 1 ? tokens[0] : <React.Fragment>{tokens}</React.Fragment>;
  };

  return (
    <div className="min-h-screen bg-[#faf8f2] text-[#171711] flex flex-col selection:bg-[#171711] selection:text-white">
      {/* Docs Dedicated Top Navigation Bar */}
      <div className="border-b border-[#e4e0d5] bg-white sticky top-0 z-30 shadow-2xs">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-3 flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={() => setIsMobileSidebarOpen(!isMobileSidebarOpen)}
              className="lg:hidden p-2 rounded-xl text-[#171711] hover:bg-[#ebe7dc] transition-colors"
              aria-label="Toggle Docs Sidebar"
            >
              <Menu className="w-5 h-5" />
            </button>

            <Link href="/" className="flex items-center gap-2 font-black text-sm text-[#171711] group">
              <div className="w-7 h-7 relative rounded-lg overflow-hidden bg-[#e6edb0] p-1 flex items-center justify-center transition-transform group-hover:scale-105">
                <Image src="/branding/laterbox-icon.png" alt="laterbox logo" width={22} height={22} className="object-contain" />
              </div>
              <div className="flex items-center gap-1.5">
                <span className="tracking-tight">laterbox</span>
                <span className="text-[#9e9b92] font-semibold">/</span>
                <span className="font-bold text-[#6c6b63]">docs</span>
              </div>
              <span className="px-2 py-0.5 rounded-full bg-[#ebe7dc] text-[10px] font-mono font-bold text-[#6c6b63] hidden sm:inline">
                docs.laterbox.dev
              </span>
            </Link>
          </div>

          {/* Quick Search Bar Trigger */}
          <button
            type="button"
            onClick={() => setIsSearchOpen(true)}
            className="flex items-center justify-between w-full max-w-xs sm:max-w-sm px-3.5 py-1.5 rounded-xl bg-[#f7f5ee] hover:bg-[#ebe7dc] border border-[#e4e0d5] text-xs text-[#6c6b63] transition-all cursor-pointer shadow-2xs"
          >
            <div className="flex items-center gap-2">
              <Search className="w-3.5 h-3.5 text-[#9e9b92]" />
              <span>Search docs...</span>
            </div>
            <kbd className="hidden sm:inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded bg-white border border-[#d8d4c9] text-[10px] font-mono font-bold text-[#171711]">
              ⌘K
            </kbd>
          </button>

          {/* Right Links */}
          <div className="hidden sm:flex items-center gap-3">
            <a
              href="https://github.com/Chaste-Djaziri/laterbox"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6c6b63] hover:text-[#171711] px-3 py-1.5 rounded-lg hover:bg-[#f7f5ee] transition-colors"
            >
              <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
              </svg>
              <span>GitHub</span>
            </a>
            <Link
              href="/download"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#171711] text-white text-xs font-bold shadow-2xs hover:bg-[#282723] transition-all"
            >
              <Download className="w-3 h-3" />
              <span>Get App</span>
            </Link>
          </div>
        </div>
      </div>

      {/* Main Docs Reader Container */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 w-full flex-1 flex gap-8 relative">
        {/* Left Sidebar Navigation (Desktop) */}
        <aside className="hidden lg:block w-60 shrink-0 space-y-6 sticky top-20 self-start max-h-[calc(100vh-6rem)] overflow-y-auto pr-2">
          {DOCS_SECTIONS.map((section) => (
            <div key={section.id} className="space-y-1">
              <div className="flex items-center gap-1.5 text-[11px] font-black uppercase tracking-wider text-[#9e9b92] px-2.5 py-1">
                {getSectionIcon(section.id)}
                <span>{section.title}</span>
              </div>
              <ul className="space-y-0.5">
                {section.items.map((item) => {
                  const isActive = item.slug === activeDoc.slug;
                  const displayTitle = item.navTitle || item.title;
                  return (
                    <li key={item.slug}>
                      <button
                        type="button"
                        onClick={() => selectDoc(item.slug)}
                        className={`w-full text-left px-2.5 py-1.5 rounded-lg text-xs transition-all flex items-center justify-between cursor-pointer ${
                          isActive
                            ? 'bg-[#e6edb0] text-[#171711] font-bold shadow-2xs'
                            : 'text-[#6c6b63] font-medium hover:text-[#171711] hover:bg-[#ebe7dc]/60'
                        }`}
                      >
                        <span className="truncate">{displayTitle}</span>
                        {isActive && (
                          <span className="w-1.5 h-1.5 rounded-full bg-[#171711] shrink-0 ml-1.5" />
                        )}
                      </button>
                    </li>
                  );
                })}
              </ul>
            </div>
          ))}
        </aside>

        {/* Center Article Content Canvas */}
        <main className="flex-1 min-w-0 max-w-3xl space-y-8">
          {/* Breadcrumbs & Badge */}
          <div className="flex flex-wrap items-center justify-between gap-3 text-xs">
            <div className="flex items-center gap-2 text-[#6c6b63]">
              <Link href="/docs" className="hover:text-[#171711]">Docs</Link>
              <span>/</span>
              <span className="font-semibold text-[#171711]">{activeDoc.category}</span>
              <span>/</span>
              <span className="font-bold text-[#171711]">{activeDoc.title}</span>
            </div>

            <div className="flex items-center gap-2">
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-[#ebe7dc] text-[11px] font-mono text-[#171711] font-semibold">
                <Clock className="w-3 h-3 text-[#9e9b92]" />
                <span>3 min read</span>
              </span>
              <span className="px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 text-[11px] font-bold">
                v1.0.64
              </span>
            </div>
          </div>

          {/* Article Header */}
          <div className="space-y-3 pb-6 border-b border-[#e4e0d5]">
            <h1 className="text-3xl sm:text-4xl font-black text-[#171711] tracking-tight">
              {activeDoc.title}
            </h1>
            <p className="text-base text-[#6c6b63] leading-relaxed">
              {activeDoc.description}
            </p>
          </div>

          {/* Markdown / Content Body */}
          <div className="prose prose-neutral max-w-none space-y-6 text-sm text-[#383733] leading-relaxed">
            {activeDoc.content.split('\n\n').map((paragraph, pIdx) => {
              const trimmed = paragraph.trim();
              if (!trimmed) return null;

              // Horizontal Rule
              if (trimmed === '---') {
                return <hr key={pIdx} className="border-t border-[#e4e0d5] my-8" />;
              }

              // Headings H2
              if (trimmed.startsWith('## ')) {
                const headingText = trimmed.replace('## ', '');
                const headingId = headingText
                  .toLowerCase()
                  .replace(/[^a-z0-9]+/g, '-')
                  .replace(/(^-|-$)/g, '');
                return (
                  <h2
                    key={pIdx}
                    id={headingId}
                    className="text-xl sm:text-2xl font-black text-[#171711] tracking-tight pt-6 border-t border-[#f0ede4] flex items-center gap-2 group"
                  >
                    <span>{renderInlineMarkdown(headingText)}</span>
                    <a
                      href={`#${headingId}`}
                      className="opacity-0 group-hover:opacity-100 text-[#9e9b92] hover:text-[#171711] transition-opacity text-base font-normal"
                    >
                      #
                    </a>
                  </h2>
                );
              }

              // Headings H3
              if (trimmed.startsWith('### ')) {
                const headingText = trimmed.replace('### ', '');
                return (
                  <h3 key={pIdx} className="text-base font-extrabold text-[#171711] pt-2">
                    {renderInlineMarkdown(headingText)}
                  </h3>
                );
              }

              // Code Blocks
              if (trimmed.startsWith('```')) {
                const lines = trimmed.split('\n');
                const lang = lines[0].replace('```', '') || 'code';
                const codeBody = lines.slice(1, -1).join('\n');

                return (
                  <div key={pIdx} className="rounded-2xl bg-[#171711] text-[#fbf9f4] border border-[#282723] overflow-hidden shadow-md my-4">
                    <div className="flex items-center justify-between px-4 py-2 bg-[#21201b] border-b border-[#2e2d27] text-xs font-mono text-[#9e9b92]">
                      <span className="uppercase font-bold tracking-wider">{lang}</span>
                      <button
                        type="button"
                        onClick={() => handleCopy(codeBody, pIdx)}
                        className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded bg-[#2e2d27] hover:bg-[#3d3b34] text-[#fbf9f4] text-[11px] transition-colors cursor-pointer"
                      >
                        {copiedCodeIndex === pIdx ? (
                          <>
                            <Check className="w-3 h-3 text-[#E7FF57]" />
                            <span className="text-[#E7FF57]">Copied!</span>
                          </>
                        ) : (
                          <>
                            <Copy className="w-3 h-3" />
                            <span>Copy</span>
                          </>
                        )}
                      </button>
                    </div>
                    <pre className="p-4 text-xs font-mono overflow-x-auto leading-relaxed text-[#e5e2d9]">
                      <code>{codeBody}</code>
                    </pre>
                  </div>
                );
              }

              // Blockquotes / Callout notes
              if (trimmed.startsWith('> ')) {
                const blockquoteLines = trimmed.split('\n').map((l) => l.replace(/^>\s*/, '')).join(' ');
                return (
                  <div key={pIdx} className="p-4 rounded-2xl bg-[#e6edb0]/50 border border-[#d0db84] text-xs leading-relaxed text-[#171711] my-4 flex items-start gap-3">
                    <Sparkles className="w-4 h-4 text-[#171711] shrink-0 mt-0.5" />
                    <div className="space-y-1">
                      {renderInlineMarkdown(blockquoteLines)}
                    </div>
                  </div>
                );
              }

              // Table
              if (trimmed.startsWith('|') && trimmed.includes('|')) {
                const rows = trimmed.split('\n').filter((r) => r.trim() && !r.includes('---'));
                if (rows.length > 0) {
                  const headerCols = rows[0].split('|').filter((c) => c.trim());
                  const bodyRows = rows.slice(1);

                  return (
                    <div key={pIdx} className="overflow-x-auto my-4 rounded-2xl border border-[#e4e0d5] bg-white shadow-2xs">
                      <table className="w-full text-left text-xs border-collapse">
                        <thead className="bg-[#f7f5ee] border-b border-[#e4e0d5] font-bold text-[#171711]">
                          <tr>
                            {headerCols.map((col, cIdx) => (
                              <th key={cIdx} className="p-3">
                                {renderInlineMarkdown(col.trim())}
                              </th>
                            ))}
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-[#f0ede4]">
                          {bodyRows.map((r, rIdx) => {
                            const cols = r.split('|').filter((c) => c.trim());
                            return (
                              <tr key={rIdx} className="hover:bg-[#faf8f2]/60 transition-colors">
                                {cols.map((c, colIdx) => (
                                  <td key={colIdx} className="p-3 text-[#6c6b63]">
                                    {renderInlineMarkdown(c.trim())}
                                  </td>
                                ))}
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  );
                }
              }

              // Ordered Numbered List
              const numberedLines = trimmed.split('\n').map((l) => l.trim()).filter(Boolean);
              const isNumberedList = numberedLines.length > 0 && numberedLines.every((l) => /^\d+\.\s/.test(l));
              if (isNumberedList) {
                return (
                  <ol key={pIdx} className="space-y-3 list-decimal pl-6 my-4 text-[#383733]">
                    {numberedLines.map((item, iIdx) => (
                      <li key={iIdx} className="leading-relaxed pl-1">
                        {renderInlineMarkdown(item.replace(/^\d+\.\s+/, ''))}
                      </li>
                    ))}
                  </ol>
                );
              }

              // Unordered Bullet List
              const bulletLines = trimmed.split('\n').map((l) => l.trim()).filter(Boolean);
              const isBulletList = bulletLines.length > 0 && bulletLines.every((l) => l.startsWith('- ') || l.startsWith('* '));
              if (isBulletList) {
                return (
                  <ul key={pIdx} className="space-y-3 list-disc pl-6 my-4 text-[#383733]">
                    {bulletLines.map((item, iIdx) => (
                      <li key={iIdx} className="leading-relaxed pl-1">
                        {renderInlineMarkdown(item.replace(/^[-*]\s+/, ''))}
                      </li>
                    ))}
                  </ul>
                );
              }

              // Standard Paragraph
              return (
                <p key={pIdx} className="leading-relaxed text-[#383733]">
                  {renderInlineMarkdown(trimmed)}
                </p>
              );
            })}
          </div>

          {/* Previous / Next Navigation Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 pt-10 border-t border-[#e4e0d5]">
            {prevDoc ? (
              <button
                type="button"
                onClick={() => selectDoc(prevDoc.slug)}
                className="p-4 rounded-2xl bg-white hover:bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all text-left group shadow-2xs flex flex-col justify-between"
              >
                <div className="flex items-center gap-1 text-[11px] font-bold text-[#9e9b92] mb-1">
                  <ArrowLeft className="w-3 h-3 group-hover:-translate-x-0.5 transition-transform" />
                  <span>Previous</span>
                </div>
                <span className="text-sm font-bold text-[#171711] group-hover:underline">
                  {prevDoc.title}
                </span>
              </button>
            ) : <div />}

            {nextDoc ? (
              <button
                type="button"
                onClick={() => selectDoc(nextDoc.slug)}
                className="p-4 rounded-2xl bg-white hover:bg-[#f7f5ee] border border-[#e4e0d5] hover:border-[#171711] transition-all text-right group shadow-2xs flex flex-col justify-between items-end"
              >
                <div className="flex items-center gap-1 text-[11px] font-bold text-[#9e9b92] mb-1">
                  <span>Next</span>
                  <ArrowRight className="w-3 h-3 group-hover:translate-x-0.5 transition-transform" />
                </div>
                <span className="text-sm font-bold text-[#171711] group-hover:underline">
                  {nextDoc.title}
                </span>
              </button>
            ) : <div />}
          </div>

          {/* GitHub Edit & Community Links Footer */}
          <div className="p-5 rounded-2xl bg-white border border-[#e4e0d5] flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-[#6c6b63]">
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-[#171711]" />
              <span>Questions or suggestions for this documentation?</span>
            </div>
            <div className="flex items-center gap-4">
              <a
                href={`https://github.com/Chaste-Djaziri/laterbox/tree/main/docs`}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1 font-bold text-[#171711] hover:underline"
              >
                <span>Edit on GitHub</span>
                <ExternalLink className="w-3 h-3" />
              </a>
              <a
                href="https://github.com/Chaste-Djaziri/laterbox/discussions"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1 font-bold text-[#171711] hover:underline"
              >
                <span>Join Community</span>
                <ExternalLink className="w-3 h-3" />
              </a>
            </div>
          </div>
        </main>

        {/* Right Sidebar: On This Page Table of Contents (Desktop) */}
        <aside className="hidden xl:block w-52 shrink-0 space-y-6 sticky top-20 self-start max-h-[calc(100vh-6rem)] overflow-y-auto">
          <div className="space-y-2">
            <p className="text-[11px] font-black uppercase tracking-wider text-[#9e9b92] px-1">
              On This Page
            </p>
            <ul className="space-y-1 text-xs">
              {activeDoc.headings.map((heading) => (
                <li key={heading.id} className={heading.level === 3 ? 'pl-2' : ''}>
                  <a
                    href={`#${heading.id}`}
                    className="text-[#6c6b63] hover:text-[#171711] transition-colors block py-1 px-1 rounded hover:bg-[#ebe7dc]/50 line-clamp-1"
                  >
                    {heading.text}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          <div className="pt-4 border-t border-[#e4e0d5] space-y-2">
            <p className="text-[11px] font-black uppercase tracking-wider text-[#9e9b92] px-1">
              Resources
            </p>
            <div className="space-y-1 text-xs font-medium">
              <Link href="/download" className="flex items-center gap-1.5 px-1 py-1 text-[#6c6b63] hover:text-[#171711] transition-colors">
                <Download className="w-3.5 h-3.5" />
                <span>Download Hub</span>
              </Link>
              <Link href="/inbox" className="flex items-center gap-1.5 px-1 py-1 text-[#6c6b63] hover:text-[#171711] transition-colors">
                <Sparkles className="w-3.5 h-3.5" />
                <span>Web App Sandbox</span>
              </Link>
              <a
                href="https://github.com/Chaste-Djaziri/laterbox"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center gap-1.5 px-1 py-1 text-[#6c6b63] hover:text-[#171711] transition-colors"
              >
                <ExternalLink className="w-3.5 h-3.5" />
                <span>GitHub Repository</span>
              </a>
            </div>
          </div>
        </aside>
      </div>

      {/* Mobile Drawer Sidebar */}
      {isMobileSidebarOpen && (
        <div className="fixed inset-0 z-50 lg:hidden flex">
          <div
            className="fixed inset-0 bg-black/40 backdrop-blur-xs"
            onClick={() => setIsMobileSidebarOpen(false)}
          />
          <div className="relative w-72 max-w-full bg-[#faf8f2] border-r border-[#e4e0d5] p-5 space-y-6 overflow-y-auto z-10 animate-in slide-in-from-left duration-200">
            <div className="flex items-center justify-between pb-3 border-b border-[#e4e0d5]">
              <div className="flex items-center gap-2 font-black text-sm text-[#171711]">
                <BookOpen className="w-4 h-4" />
                <span>Documentation</span>
              </div>
              <button
                type="button"
                onClick={() => setIsMobileSidebarOpen(false)}
                className="p-1 rounded-lg hover:bg-[#ebe7dc] text-[#6c6b63] hover:text-[#171711]"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {DOCS_SECTIONS.map((section) => (
              <div key={section.id} className="space-y-1">
                <div className="flex items-center gap-1.5 text-[11px] font-black uppercase tracking-wider text-[#9e9b92] px-2.5 py-1">
                  {getSectionIcon(section.id)}
                  <span>{section.title}</span>
                </div>
                <ul className="space-y-0.5">
                  {section.items.map((item) => {
                    const isActive = item.slug === activeDoc.slug;
                    const displayTitle = item.navTitle || item.title;
                    return (
                      <li key={item.slug}>
                        <button
                          type="button"
                          onClick={() => selectDoc(item.slug)}
                          className={`w-full text-left px-2.5 py-1.5 rounded-lg text-xs transition-all flex items-center justify-between cursor-pointer ${
                            isActive
                              ? 'bg-[#e6edb0] text-[#171711] font-bold shadow-2xs'
                              : 'text-[#6c6b63] font-medium hover:text-[#171711] hover:bg-[#ebe7dc]/60'
                          }`}
                        >
                          <span className="truncate">{displayTitle}</span>
                          {isActive && (
                            <span className="w-1.5 h-1.5 rounded-full bg-[#171711] shrink-0 ml-1.5" />
                          )}
                        </button>
                      </li>
                    );
                  })}
                </ul>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Global Search Dialog Modal */}
      {isSearchOpen && (
        <div className="fixed inset-0 z-50 flex items-start justify-center pt-20 px-4">
          <div
            className="fixed inset-0 bg-black/50 backdrop-blur-xs animate-in fade-in duration-150"
            onClick={() => setIsSearchOpen(false)}
          />
          <div className="relative w-full max-w-xl bg-white border border-[#e4e0d5] rounded-3xl shadow-2xl overflow-hidden z-10 animate-in zoom-in-95 duration-150">
            <div className="p-4 border-b border-[#e4e0d5] flex items-center gap-3">
              <Search className="w-4 h-4 text-[#9e9b92] shrink-0" />
              <input
                type="text"
                autoFocus
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search all documentation, guides & code samples..."
                className="w-full text-sm text-[#171711] placeholder:text-[#9e9b92] focus:outline-none bg-transparent"
              />
              <button
                type="button"
                onClick={() => setIsSearchOpen(false)}
                className="p-1 rounded-lg text-[#9e9b92] hover:text-[#171711]"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="max-h-96 overflow-y-auto p-2">
              {searchQuery.trim() && searchResults.length === 0 ? (
                <div className="p-8 text-center text-xs text-[#9e9b92]">
                  No documentation found matching &ldquo;{searchQuery}&rdquo;
                </div>
              ) : (
                <div className="space-y-1">
                  {(searchQuery.trim() ? searchResults : ALL_DOCS).map((item) => {
                    const displayTitle = item.navTitle || item.title;
                    return (
                      <button
                        key={item.slug}
                        type="button"
                        onClick={() => selectDoc(item.slug)}
                        className="w-full p-3 rounded-2xl hover:bg-[#f7f5ee] text-left transition-colors flex items-start justify-between group"
                      >
                        <div className="space-y-1">
                          <span className="text-[10px] font-bold uppercase tracking-wider text-[#9e9b92]">
                            {item.category}
                          </span>
                          <h4 className="text-xs font-bold text-[#171711] group-hover:underline">
                            {displayTitle}
                          </h4>
                          <p className="text-[11px] text-[#6c6b63] line-clamp-1">
                            {item.description}
                          </p>
                        </div>
                        <ChevronRight className="w-4 h-4 text-[#9e9b92] group-hover:text-[#171711] shrink-0 mt-2" />
                      </button>
                    );
                  })}
                </div>
              )}
            </div>

            <div className="p-3 bg-[#f7f5ee] border-t border-[#e4e0d5] flex items-center justify-between text-[11px] text-[#9e9b92]">
              <span>Navigate with mouse or arrow keys</span>
              <span>Press <kbd className="px-1.5 py-0.5 bg-white rounded border border-[#d8d4c9] font-mono text-[#171711]">ESC</kbd> to exit</span>
            </div>
          </div>
        </div>
      )}

      {/* Minimal Docs Reader Footer */}
      <footer className="border-t border-[#e4e0d5] bg-white py-6 mt-16 text-xs text-[#9e9b92]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <span className="font-bold text-[#171711]">LaterBox Documentation</span>
            <span>•</span>
            <span>PolyForm Noncommercial 1.0.0</span>
          </div>
          <div className="flex items-center gap-4 text-xs font-semibold text-[#6c6b63]">
            <a
              href="https://github.com/Chaste-Djaziri/laterbox"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-[#171711] transition-colors"
            >
              GitHub
            </a>
            <Link href="/download" className="hover:text-[#171711] transition-colors">
              Downloads
            </Link>
            <Link href="/privacy" className="hover:text-[#171711] transition-colors">
              Privacy
            </Link>
            <Link href="/terms" className="hover:text-[#171711] transition-colors">
              Terms
            </Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
