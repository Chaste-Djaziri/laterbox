'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { useAuth } from '@/lib/store/AuthContext';
import {
  HelpCircle,
  AlertCircle,
  CheckCircle2,
  Clock,
  Send,
  Search,
  MessageSquare,
  Bug,
  Lightbulb,
  HelpCircle as QuestionIcon,
  ChevronDown,
  ChevronUp,
  RefreshCw,
  Inbox,
  Check,
  Copy,
} from 'lucide-react';

interface SupportTicket {
  id: string;
  email: string;
  category: 'problem' | 'help' | 'feedback' | 'other';
  subject: string;
  message: string;
  platform: 'web' | 'ios' | 'android';
  app_version?: string;
  status: 'open' | 'in_progress' | 'resolved';
  created_at: string;
}

interface SimpleFaq {
  id: string;
  question: string;
  answer: string;
}

const STREAMLINED_FAQS: SimpleFaq[] = [
  {
    id: 'faq-1',
    question: 'How do I save links, articles, and text into LaterBox?',
    answer:
      'Click "Save Item" in the top header or press Cmd/Ctrl + N to open the capture modal. You can also paste any link directly, or install the official LaterBox browser extension for Chrome and Safari to save any page in 1 click.',
  },
  {
    id: 'faq-2',
    question: 'How does the email-style inbox table work?',
    answer:
      'LaterBox presents saved items like actionable email rows with domain avatars, subject titles, and preview snippets. Click any row to open the split reading pane for distraction-free reading without losing your place in the list.',
  },
  {
    id: 'faq-3',
    question: 'What is the difference between Today, Upcoming, and Someday?',
    answer:
      '• Today: Items scheduled for immediate attention today.\n• Upcoming: Items deferred to a specific future date or scheduled reminder.\n• Someday: A low-pressure holding vault for long-term reads and backlog ideas without deadlines.',
  },
  {
    id: 'faq-4',
    question: 'How do Starred, Kept, Archived, and Recently Deleted work?',
    answer:
      '• Starred: Favorite items you want pinned for quick access.\n• Kept: Items you have read and want preserved permanently in your library.\n• Archived: Completed items kept for search history without appearing in active inbox.\n• Recently Deleted: Trash bin where deleted items stay before permanent deletion.',
  },
  {
    id: 'faq-5',
    question: 'How do Collections work and how do I create them?',
    answer:
      'Collections work like Gmail labels. Click the "+" button next to COLLECTIONS in the sidebar to create a collection. You can then use the collection button on any table row, card, or detail pane to add or remove items.',
  },
  {
    id: 'faq-6',
    question: 'How does the AI Assistant organize my items?',
    answer:
      'Click "AI Organize" in the top header to analyze your unfiled items. Gemini AI clusters related topics into smart collections (e.g. Design Systems, Research, Recipes) and proposes clean organization without duplicates.',
  },
  {
    id: 'faq-7',
    question: 'How does the browser extension capture webpage snapshots?',
    answer:
      'The LaterBox extension extracts clean article text and media, strips paywall popups and ads, and saves offline-ready DOM snapshots directly to your vault. Capturing is free for all users and works locally even without internet.',
  },
  {
    id: 'faq-8',
    question: 'What keyboard shortcuts are available?',
    answer:
      '• Cmd/Ctrl + K: Fast search omnibar\n• Cmd/Ctrl + N: Quick capture modal\n• J / K: Navigate down/up through table rows\n• E: Archive item\n• S: Star / unstar\n• Delete: Move to trash\n• Esc: Close reading pane or modal',
  },
  {
    id: 'faq-9',
    question: 'Can I use LaterBox offline?',
    answer:
      'Yes! LaterBox works offline using local IndexedDB storage. You can view previously saved items and queue new captures; everything syncs automatically once you reconnect.',
  },
  {
    id: 'faq-10',
    question: 'What features are included in LaterBox Pro vs. Free?',
    answer:
      'Free includes local offline storage, browser extension captures, full reader mode, and custom collections. Pro unlocks encrypted multi-device cloud synchronization, unlimited Gemini AI organization, and scheduled reminders.',
  },
];

const LOCAL_STORAGE_TICKETS_KEY = 'laterbox_support_ticket_ids';

export default function HelpPage() {
  const { user, session } = useAuth();

  // Active navigation tab: faq, report (form only), or tickets (my requests)
  const [activeTab, setActiveTab] = useState<'faq' | 'report' | 'tickets'>('faq');

  // FAQ state
  const [faqSearch, setFaqSearch] = useState('');
  const [expandedFaqs, setExpandedFaqs] = useState<Record<string, boolean>>({
    'faq-1': true,
  });

  // Report Form state
  const [category, setCategory] = useState<'problem' | 'help' | 'feedback' | 'other'>('problem');
  const [email, setEmail] = useState(user?.email || '');
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [includeDiagnostics, setIncludeDiagnostics] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);
  const [submittedTicketId, setSubmittedTicketId] = useState<string | null>(null);

  // Tickets Table state
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [isLoadingTickets, setIsLoadingTickets] = useState(false);
  const [ticketsError, setTicketsError] = useState<string | null>(null);
  const [selectedTicket, setSelectedTicket] = useState<SupportTicket | null>(null);
  const [copiedTicketId, setCopiedTicketId] = useState<string | null>(null);

  // Sync email when user loads
  useEffect(() => {
    if (user?.email && !email) {
      setEmail(user.email);
    }
  }, [user?.email, email]);

  // Load tracked ticket IDs from localStorage
  const getStoredTicketIds = useCallback((): string[] => {
    if (typeof window === 'undefined') return [];
    try {
      const raw = localStorage.getItem(LOCAL_STORAGE_TICKETS_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }, []);

  // Save new ticket ID to localStorage
  const saveStoredTicketId = useCallback(
    (id: string) => {
      if (typeof window === 'undefined' || !id) return;
      try {
        const existing = getStoredTicketIds();
        if (!existing.includes(id)) {
          const updated = [id, ...existing].slice(0, 50);
          localStorage.setItem(LOCAL_STORAGE_TICKETS_KEY, JSON.stringify(updated));
        }
      } catch {
        // Ignore storage errors
      }
    },
    [getStoredTicketIds]
  );

  // Fetch support tickets from database via /api/support
  const fetchTickets = useCallback(async () => {
    setIsLoadingTickets(true);
    setTicketsError(null);
    try {
      const storedIds = getStoredTicketIds();
      const queryParam = storedIds.length > 0 ? `?ids=${storedIds.join(',')}` : '';
      const headers: Record<string, string> = {};
      if (session?.access_token) {
        headers['Authorization'] = `Bearer ${session.access_token}`;
      }

      const res = await fetch(`/api/support${queryParam}`, {
        method: 'GET',
        headers,
      });

      if (!res.ok) {
        throw new Error('Failed to load support tickets');
      }

      const data = (await res.json().catch(() => ({}))) as { tickets?: SupportTicket[] };
      if (Array.isArray(data.tickets)) {
        setTickets(data.tickets);
      }
    } catch (err) {
      setTicketsError(err instanceof Error ? err.message : 'Error fetching tickets');
    } finally {
      setIsLoadingTickets(false);
    }
  }, [session?.access_token, getStoredTicketIds]);

  // Fetch tickets on mount and when session changes
  useEffect(() => {
    fetchTickets();
  }, [fetchTickets]);

  // Submit report to DB
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (isSubmitting) return;

    setFormError(null);
    setSubmittedTicketId(null);
    setIsSubmitting(true);

    try {
      const trimmedEmail = email.trim();
      const trimmedSubject = subject.trim();
      const trimmedMessage = message.trim();

      if (!trimmedEmail || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmedEmail)) {
        throw new Error('Please enter a valid reply email address.');
      }
      if (trimmedSubject.length < 3 || trimmedSubject.length > 160) {
        throw new Error('Subject must be between 3 and 160 characters.');
      }
      if (trimmedMessage.length < 10 || trimmedMessage.length > 5000) {
        throw new Error('Message description must be between 10 and 5,000 characters.');
      }

      const appVersion = includeDiagnostics
        ? `LaterBox Web 1.0.0 (${typeof navigator !== 'undefined' ? navigator.userAgent.slice(0, 60) : 'Browser'})`
        : 'LaterBox Web 1.0.0';

      const payload = {
        email: trimmedEmail,
        category,
        subject: trimmedSubject,
        message: trimmedMessage,
        platform: 'web',
        appVersion,
      };

      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
      };
      if (session?.access_token) {
        headers['Authorization'] = `Bearer ${session.access_token}`;
      }

      const res = await fetch('/api/support', {
        method: 'POST',
        headers,
        body: JSON.stringify(payload),
      });

      const result = (await res.json().catch(() => ({}))) as { id?: unknown; error?: unknown };

      if (!res.ok || typeof result.id !== 'string') {
        throw new Error(
          typeof result.error === 'string' && result.error
            ? result.error
            : 'Could not submit your report. Please verify all fields and try again.'
        );
      }

      const newId = result.id;
      setSubmittedTicketId(newId);
      saveStoredTicketId(newId);

      // Reset form fields
      setSubject('');
      setMessage('');

      // Refresh tickets table from DB
      await fetchTickets();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Submission failed. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  }

  // Toggle FAQ item
  const toggleFaq = (id: string) => {
    setExpandedFaqs((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  // Filtered FAQs
  const filteredFaqs = useMemo(() => {
    const q = faqSearch.toLowerCase().trim();
    if (!q) return STREAMLINED_FAQS;
    return STREAMLINED_FAQS.filter(
      (item) => item.question.toLowerCase().includes(q) || item.answer.toLowerCase().includes(q)
    );
  }, [faqSearch]);

  const copyTicketId = (id: string) => {
    if (typeof navigator !== 'undefined') {
      navigator.clipboard.writeText(id);
      setCopiedTicketId(id);
      setTimeout(() => setCopiedTicketId(null), 2000);
    }
  };

  const getStatusBadge = (status: SupportTicket['status']) => {
    switch (status) {
      case 'resolved':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#eef7ec] text-[#246328] border border-[#d2ebd1]">
            <CheckCircle2 className="w-3 h-3 text-[#246328]" />
            <span>Resolved</span>
          </span>
        );
      case 'in_progress':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#eff6ff] text-[#1d4ed8] border border-[#bfdbfe]">
            <Clock className="w-3 h-3 text-[#1d4ed8]" />
            <span>In Review</span>
          </span>
        );
      case 'open':
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#fefce8] text-[#854d0e] border border-[#fef08a]">
            <AlertCircle className="w-3 h-3 text-[#854d0e]" />
            <span>Open</span>
          </span>
        );
    }
  };

  const getCategoryBadge = (cat: SupportTicket['category']) => {
    switch (cat) {
      case 'problem':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-[#fef2f2] text-[#991b1b] border border-[#fecaca]">
            <Bug className="w-2.5 h-2.5" />
            <span>Bug</span>
          </span>
        );
      case 'help':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-[#eff6ff] text-[#1e40af] border border-[#dbeafe]">
            <QuestionIcon className="w-2.5 h-2.5" />
            <span>Help</span>
          </span>
        );
      case 'feedback':
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-[#f5f3ff] text-[#5b21b6] border border-[#ddd6fe]">
            <Lightbulb className="w-2.5 h-2.5" />
            <span>Feedback</span>
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold uppercase tracking-wider bg-[#f3f4f6] text-[#374151] border border-[#e5e7eb]">
            <MessageSquare className="w-2.5 h-2.5" />
            <span>Other</span>
          </span>
        );
    }
  };

  return (
    <div className="flex-1 w-full bg-[#fbfaf7] min-h-[calc(100vh-65px)] flex flex-col p-4 md:p-6 lg:p-8 space-y-6 overflow-y-auto">
      {/* Clean Minimal Header */}
      <div className="space-y-1">
        <h1 className="text-2xl font-black text-[#171711] tracking-tight">Help &amp; FAQs</h1>
        <p className="text-xs sm:text-sm text-[#6c6b63]">
          Find quick answers to common questions or report an issue directly to our team.
        </p>
      </div>

      {/* Main Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-[#e4e0d5] pb-3 overflow-x-auto">
        <button
          type="button"
          onClick={() => setActiveTab('faq')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer ${
            activeTab === 'faq'
              ? 'bg-[#171711] text-[#e6edb0] shadow-xs'
              : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] hover:bg-[#f7f5ee]'
          }`}
        >
          <HelpCircle className="w-3.5 h-3.5" />
          <span>Frequently Asked Questions</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('report')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer ${
            activeTab === 'report'
              ? 'bg-[#171711] text-[#e6edb0] shadow-xs'
              : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] hover:bg-[#f7f5ee]'
          }`}
        >
          <Bug className="w-3.5 h-3.5" />
          <span>Report a Problem</span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('tickets')}
          className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer relative ${
            activeTab === 'tickets'
              ? 'bg-[#171711] text-[#e6edb0] shadow-xs'
              : 'bg-white border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711] hover:bg-[#f7f5ee]'
          }`}
        >
          <Inbox className="w-3.5 h-3.5" />
          <span>My Requests</span>
          {tickets.length > 0 && (
            <span
              className={`px-1.5 py-0.2 rounded-full text-[10px] font-black ${
                activeTab === 'tickets' ? 'bg-[#e6edb0] text-[#171711]' : 'bg-[#171711] text-white'
              }`}
            >
              {tickets.length}
            </span>
          )}
        </button>
      </div>

      {/* TAB 1: Simplified FAQs */}
      {activeTab === 'faq' && (
        <div className="max-w-3xl space-y-4">
          {/* Search bar */}
          <div className="relative">
            <Search className="w-4 h-4 text-[#9e9b92] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              value={faqSearch}
              onChange={(e) => setFaqSearch(e.target.value)}
              placeholder="Search questions or keywords..."
              className="w-full pl-10 pr-4 py-2.5 rounded-xl border border-[#e4e0d5] bg-white text-xs sm:text-sm text-[#171711] placeholder:text-[#9e9b92] focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all shadow-2xs"
            />
            {faqSearch && (
              <button
                type="button"
                onClick={() => setFaqSearch('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-[#9e9b92] hover:text-[#171711]"
              >
                Clear
              </button>
            )}
          </div>

          {/* Clean FAQ Accordion */}
          <div className="space-y-2.5">
            {filteredFaqs.length === 0 ? (
              <div className="rounded-2xl border border-[#e4e0d5] bg-white p-8 text-center space-y-2">
                <Search className="w-5 h-5 text-[#9e9b92] mx-auto" />
                <p className="text-xs font-bold text-[#171711]">No matching questions found</p>
                <button
                  type="button"
                  onClick={() => setFaqSearch('')}
                  className="text-xs font-bold text-[#171711] underline cursor-pointer"
                >
                  Reset search
                </button>
              </div>
            ) : (
              filteredFaqs.map((faq, index) => {
                const isExpanded = !!expandedFaqs[faq.id];

                return (
                  <div
                    key={faq.id}
                    className="rounded-2xl border border-[#e4e0d5] bg-white overflow-hidden shadow-2xs transition-all"
                  >
                    <button
                      type="button"
                      onClick={() => toggleFaq(faq.id)}
                      className="w-full text-left p-4 flex items-center justify-between gap-4 hover:bg-[#fbfaf7] transition-colors cursor-pointer"
                    >
                      <div className="flex items-center gap-3">
                        <span className="w-5 h-5 rounded-md bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center shrink-0 font-bold text-[11px] text-[#171711]">
                          {index + 1}
                        </span>
                        <h3 className="text-xs sm:text-sm font-bold text-[#171711] leading-snug">
                          {faq.question}
                        </h3>
                      </div>
                      <div className="shrink-0 text-[#9e9b92]">
                        {isExpanded ? (
                          <ChevronUp className="w-4 h-4 text-[#171711]" />
                        ) : (
                          <ChevronDown className="w-4 h-4" />
                        )}
                      </div>
                    </button>

                    {isExpanded && (
                      <div className="px-5 pb-4 pt-1 text-xs text-[#6c6b63] leading-relaxed border-t border-[#e4e0d5]/60 bg-[#fdfdfc] whitespace-pre-line pl-12">
                        {faq.answer}
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>

          {/* Quick link to problem report */}
          <div className="p-4 rounded-2xl border border-[#e4e0d5] bg-white flex items-center justify-between gap-3 text-xs">
            <span className="text-[#6c6b63]">Could not find what you were looking for?</span>
            <button
              type="button"
              onClick={() => setActiveTab('report')}
              className="font-bold text-[#171711] hover:underline cursor-pointer flex items-center gap-1"
            >
              <span>Submit a report</span>
              <Bug className="w-3 h-3" />
            </button>
          </div>
        </div>
      )}

      {/* TAB 2: Report a Problem (FORM ONLY!) */}
      {activeTab === 'report' && (
        <div className="max-w-2xl">
          <div className="rounded-3xl border border-[#e4e0d5] bg-white p-6 md:p-8 shadow-xs space-y-5">
            <div>
              <h2 className="text-base font-black text-[#171711] flex items-center gap-2">
                <Bug className="w-4 h-4 text-[#171711]" />
                <span>Report a Problem or Inquiry</span>
              </h2>
              <p className="text-xs text-[#6c6b63] mt-1">
                Describe the issue or feedback below. Submissions are saved directly to our support queue.
              </p>
            </div>

            {/* Success Confirmation inside Form Tab */}
            {submittedTicketId && (
              <div className="rounded-2xl border border-[#d2ebd1] bg-[#eef7ec] p-4 space-y-2 animate-in fade-in duration-200">
                <div className="flex items-center gap-2 text-sm font-bold text-[#246328]">
                  <Check className="w-4 h-4" />
                  <span>Report submitted successfully!</span>
                </div>
                <p className="text-xs text-[#246328]/90">
                  Ticket reference: <span className="font-mono font-bold">#{submittedTicketId.slice(0, 8)}</span>.
                  You can track its status in the{' '}
                  <button
                    type="button"
                    onClick={() => setActiveTab('tickets')}
                    className="font-bold underline cursor-pointer"
                  >
                    My Requests
                  </button>{' '}
                  tab.
                </p>
                <button
                  type="button"
                  onClick={() => setSubmittedTicketId(null)}
                  className="text-[11px] font-bold text-[#246328] hover:underline pt-1 block"
                >
                  Submit another report
                </button>
              </div>
            )}

            {!submittedTicketId && (
              <form onSubmit={handleSubmit} className="space-y-4">
                {/* Issue Category */}
                <div>
                  <label className="block text-xs font-bold text-[#171711] uppercase tracking-wider mb-2">
                    Category
                  </label>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                    {[
                      { id: 'problem', label: 'Bug / Problem', icon: <Bug className="w-3.5 h-3.5" /> },
                      { id: 'help', label: 'Need Help', icon: <QuestionIcon className="w-3.5 h-3.5" /> },
                      { id: 'feedback', label: 'Feedback', icon: <Lightbulb className="w-3.5 h-3.5" /> },
                      { id: 'other', label: 'Other', icon: <MessageSquare className="w-3.5 h-3.5" /> },
                    ].map((tab) => (
                      <button
                        key={tab.id}
                        type="button"
                        onClick={() => setCategory(tab.id as any)}
                        className={`p-2.5 rounded-xl border text-xs font-bold flex items-center gap-2 justify-center transition-all cursor-pointer ${
                          category === tab.id
                            ? 'bg-[#171711] text-[#e6edb0] border-[#171711] shadow-2xs'
                            : 'bg-[#f7f5ee] border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711]'
                        }`}
                      >
                        {tab.icon}
                        <span>{tab.label}</span>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Reply Email */}
                <div>
                  <label className="block text-xs font-bold text-[#171711] uppercase tracking-wider mb-1.5">
                    Reply Email <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="email"
                    required
                    maxLength={254}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="name@example.com"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-[#e4e0d5] bg-[#fbfaf7] text-xs sm:text-sm text-[#171711] placeholder:text-[#9e9b92] focus:bg-white focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all"
                  />
                </div>

                {/* Subject */}
                <div>
                  <label className="block text-xs font-bold text-[#171711] uppercase tracking-wider mb-1.5">
                    Subject <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    minLength={3}
                    maxLength={160}
                    value={subject}
                    onChange={(e) => setSubject(e.target.value)}
                    placeholder="Brief description of the issue"
                    className="w-full px-3.5 py-2.5 rounded-xl border border-[#e4e0d5] bg-[#fbfaf7] text-xs sm:text-sm text-[#171711] placeholder:text-[#9e9b92] focus:bg-white focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all"
                  />
                </div>

                {/* Description */}
                <div>
                  <label className="block text-xs font-bold text-[#171711] uppercase tracking-wider mb-1.5">
                    Description <span className="text-red-500">*</span>
                  </label>
                  <textarea
                    required
                    minLength={10}
                    maxLength={5000}
                    rows={5}
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    placeholder="Please include details or steps to reproduce the problem..."
                    className="w-full px-3.5 py-2.5 rounded-xl border border-[#e4e0d5] bg-[#fbfaf7] text-xs sm:text-sm text-[#171711] placeholder:text-[#9e9b92] focus:bg-white focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all resize-y"
                  />
                </div>

                {/* Diagnostics Toggle */}
                <div className="p-3 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-between">
                  <div className="space-y-0.5 pr-4">
                    <p className="text-xs font-bold text-[#171711]">Include browser &amp; client info</p>
                    <p className="text-[11px] text-[#6c6b63]">Attaches browser name and web version to assist debugging</p>
                  </div>
                  <input
                    type="checkbox"
                    checked={includeDiagnostics}
                    onChange={(e) => setIncludeDiagnostics(e.target.checked)}
                    className="w-4 h-4 rounded border-[#e4e0d5] text-[#171711] focus:ring-[#171711] cursor-pointer"
                  />
                </div>

                {formError && (
                  <div className="p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-700 flex items-center gap-2">
                    <AlertCircle className="w-4 h-4 shrink-0" />
                    <span>{formError}</span>
                  </div>
                )}

                <div className="pt-2 flex items-center justify-end">
                  <button
                    type="submit"
                    disabled={isSubmitting}
                    className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#171711] text-[#e6edb0] font-bold text-xs hover:bg-[#2c2b22] transition-colors disabled:opacity-50 cursor-pointer shadow-xs"
                  >
                    {isSubmitting ? (
                      <>
                        <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                        <span>Submitting...</span>
                      </>
                    ) : (
                      <>
                        <Send className="w-3.5 h-3.5" />
                        <span>Submit Report</span>
                      </>
                    )}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}

      {/* TAB 3: My Support Requests Table */}
      {activeTab === 'tickets' && (
        <div className="space-y-4">
          <div className="rounded-3xl border border-[#e4e0d5] bg-white p-5 md:p-6 shadow-xs space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-2 border-b border-[#e4e0d5]/60">
              <div>
                <h2 className="text-base font-black text-[#171711] flex items-center gap-2">
                  <Inbox className="w-4 h-4 text-[#171711]" />
                  <span>My Support Requests</span>
                </h2>
                <p className="text-xs text-[#6c6b63] mt-0.5">
                  Live status of tickets submitted from this account and device.
                </p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={fetchTickets}
                  disabled={isLoadingTickets}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#e4e0d5] bg-[#f7f5ee] hover:bg-[#ebe7dc] text-xs font-bold text-[#171711] transition-colors disabled:opacity-50 cursor-pointer"
                  title="Refresh from database"
                >
                  <RefreshCw className={`w-3.5 h-3.5 ${isLoadingTickets ? 'animate-spin' : ''}`} />
                  <span>Refresh</span>
                </button>
                <button
                  type="button"
                  onClick={() => setActiveTab('report')}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#171711] text-[#e6edb0] text-xs font-bold hover:bg-[#2c2b22] transition-colors cursor-pointer"
                >
                  <Bug className="w-3.5 h-3.5" />
                  <span>New Report</span>
                </button>
              </div>
            </div>

            {ticketsError && (
              <div className="p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-700 flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{ticketsError}</span>
              </div>
            )}

            {isLoadingTickets && tickets.length === 0 ? (
              <div className="py-10 flex flex-col items-center justify-center space-y-2 text-center">
                <RefreshCw className="w-5 h-5 animate-spin text-[#9e9b92]" />
                <p className="text-xs font-bold text-[#6c6b63]">Loading tickets from database...</p>
              </div>
            ) : tickets.length === 0 ? (
              <div className="py-10 flex flex-col items-center justify-center space-y-2 text-center max-w-sm mx-auto">
                <div className="w-10 h-10 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
                  <Inbox className="w-5 h-5" />
                </div>
                <h3 className="text-xs font-bold text-[#171711]">No Support Requests Found</h3>
                <p className="text-[11px] text-[#6c6b63]">
                  Have a question or encountered a bug? Submit a report anytime.
                </p>
                <button
                  type="button"
                  onClick={() => setActiveTab('report')}
                  className="mt-2 inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#171711] text-[#e6edb0] text-xs font-bold cursor-pointer"
                >
                  <Bug className="w-3 h-3" />
                  <span>Report a Problem</span>
                </button>
              </div>
            ) : (
              <div className="overflow-x-auto rounded-2xl border border-[#e4e0d5]">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="bg-[#f7f5ee] border-b border-[#e4e0d5] text-[#9e9b92] uppercase font-black text-[10px] tracking-wider">
                      <th className="py-2.5 px-3">Ticket</th>
                      <th className="py-2.5 px-3">Category</th>
                      <th className="py-2.5 px-3">Subject</th>
                      <th className="py-2.5 px-3">Status</th>
                      <th className="py-2.5 px-3">Date</th>
                      <th className="py-2.5 px-3 text-right">Details</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#e4e0d5]">
                    {tickets.map((ticket) => {
                      const dateStr = new Date(ticket.created_at).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                      });
                      const isSelected = selectedTicket?.id === ticket.id;

                      return (
                        <tr
                          key={ticket.id}
                          className={`hover:bg-[#fbfaf7] transition-colors ${
                            isSelected ? 'bg-[#e6edb0]/20' : ''
                          }`}
                        >
                          <td className="py-2.5 px-3 font-mono font-bold text-[#171711] whitespace-nowrap">
                            <div className="flex items-center gap-1">
                              <span>#{ticket.id.slice(0, 8)}</span>
                              <button
                                type="button"
                                onClick={() => copyTicketId(ticket.id)}
                                title="Copy ID"
                                className="text-[#9e9b92] hover:text-[#171711] cursor-pointer"
                              >
                                {copiedTicketId === ticket.id ? (
                                  <Check className="w-3 h-3 text-[#246328]" />
                                ) : (
                                  <Copy className="w-3 h-3" />
                                )}
                              </button>
                            </div>
                          </td>
                          <td className="py-2.5 px-3 whitespace-nowrap">
                            {getCategoryBadge(ticket.category)}
                          </td>
                          <td className="py-2.5 px-3 max-w-xs truncate font-medium text-[#171711]">
                            {ticket.subject}
                          </td>
                          <td className="py-2.5 px-3 whitespace-nowrap">
                            {getStatusBadge(ticket.status)}
                          </td>
                          <td className="py-2.5 px-3 text-[#6c6b63] whitespace-nowrap text-[11px]">
                            {dateStr}
                          </td>
                          <td className="py-2.5 px-3 text-right whitespace-nowrap">
                            <button
                              type="button"
                              onClick={() => setSelectedTicket(isSelected ? null : ticket)}
                              className="px-2 py-0.5 rounded-lg border border-[#e4e0d5] bg-white hover:bg-[#f7f5ee] text-[11px] font-bold text-[#171711] transition-colors cursor-pointer"
                            >
                              {isSelected ? 'Hide' : 'View'}
                            </button>
                          </td>
                        </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          {/* Ticket Detail Drawer Card */}
          {selectedTicket && (
            <div className="rounded-2xl border border-[#e4e0d5] bg-white p-5 shadow-xs space-y-3 animate-in fade-in duration-150">
              <div className="flex items-center justify-between pb-2 border-b border-[#e4e0d5]">
                <div className="flex items-center gap-2">
                  <span className="font-mono font-bold text-xs text-[#171711]">
                    Ticket #{selectedTicket.id}
                  </span>
                  {getStatusBadge(selectedTicket.status)}
                  {getCategoryBadge(selectedTicket.category)}
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedTicket(null)}
                  className="text-xs font-bold text-[#6c6b63] hover:text-[#171711] cursor-pointer"
                >
                  Close
                </button>
              </div>

              <div className="space-y-2 text-xs">
                <div>
                  <span className="font-bold text-[#9e9b92] text-[10px] uppercase">Subject</span>
                  <p className="font-bold text-[#171711] text-sm">{selectedTicket.subject}</p>
                </div>

                <div>
                  <span className="font-bold text-[#9e9b92] text-[10px] uppercase">Message</span>
                  <div className="p-3 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] text-[#171711] whitespace-pre-wrap font-mono text-[11px] mt-0.5">
                    {selectedTicket.message}
                  </div>
                </div>

                <div className="flex items-center gap-4 text-[11px] text-[#6c6b63] pt-1">
                  <span>Reply email: <strong className="text-[#171711]">{selectedTicket.email}</strong></span>
                  <span>•</span>
                  <span>Submitted: {new Date(selectedTicket.created_at).toLocaleString()}</span>
                </div>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
