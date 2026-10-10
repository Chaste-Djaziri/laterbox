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
  ExternalLink,
  Shield,
  BookOpen,
  Sparkles,
  Inbox,
  Calendar,
  Layers,
  ArrowRight,
  Filter,
  Check,
  Copy,
  Info,
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

interface FaqItem {
  id: string;
  category: 'getting-started' | 'triage' | 'ai-features' | 'collections' | 'pro-billing' | 'privacy-offline';
  question: string;
  answer: string;
  tags: string[];
}

const FAQ_CATEGORIES = [
  { id: 'all', label: 'All FAQs' },
  { id: 'getting-started', label: 'Getting Started & Capture' },
  { id: 'triage', label: 'Triage & Email Table' },
  { id: 'ai-features', label: 'AI Organize & Reader' },
  { id: 'collections', label: 'Collections & Labels' },
  { id: 'pro-billing', label: 'Pro Plan & Sync' },
  { id: 'privacy-offline', label: 'Privacy & Offline Mode' },
] as const;

const FAQ_LIST: FaqItem[] = [
  {
    id: 'faq-1',
    category: 'getting-started',
    question: 'What is LaterBox and how is it different from traditional browser bookmarks?',
    answer: 'LaterBox is an intelligent temporal read-it-later vault designed around an email-inspired triage workflow. Unlike static browser bookmarks that pile up and get forgotten, LaterBox treats saved links, notes, and media as actionable communications. You can defer items to Today, Upcoming, or Someday, organize them with AI, annotate them with interactive notes, and read distraction-free snapshots without ads or tracking.',
    tags: ['overview', 'bookmarks', 'concept', 'triage'],
  },
  {
    id: 'faq-2',
    category: 'getting-started',
    question: 'How do I save links, articles, and text snippets into LaterBox?',
    answer: 'You can save content in several convenient ways:\n1. Click "Save Item" in the top header or press the keyboard shortcut Cmd/Ctrl + N.\n2. Paste any webpage URL, article link, or markdown note snippet directly into the quick capture modal.\n3. Install the official LaterBox browser extension for Chrome or Safari to capture any page in 1 click or with Cmd+Shift+S.\n4. Use the mobile share sheet or web share target on supported devices.',
    tags: ['save', 'capture', 'extension', 'shortcuts'],
  },
  {
    id: 'faq-3',
    category: 'getting-started',
    question: 'How does the LaterBox browser extension capture full webpage snapshots?',
    answer: 'The LaterBox extension extracts clean Article DOM structures, removes paywall clutter, popups, and ads, and saves offline-ready text, reader formatting, and metadata directly into your vault. Capturing is 100% free for all users and works locally even without a network connection.',
    tags: ['extension', 'snapshots', 'offline', 'reader'],
  },
  {
    id: 'faq-4',
    category: 'triage',
    question: 'How does the email-style Inbox table work?',
    answer: 'LaterBox mirrors a high-performance email client. The main table presents your items with sender/domain avatars, subject titles, preview snippets, and attachment indicators. You can batch-select items with checkboxes, switch category tabs (Primary, Articles, Media, Updates), and click any row to open the split reading pane for reading and replying without losing your place in the list.',
    tags: ['inbox', 'table', 'email', 'reading-pane', 'batch'],
  },
  {
    id: 'faq-5',
    category: 'triage',
    question: 'What is the difference between Today, Upcoming, and Someday deferral buckets?',
    answer: '• Today: Items you specifically scheduled to review today, or items that resurfaced from a past deferral.\n• Upcoming: Items scheduled for a specific date or time in the future (e.g. tomorrow, this weekend, next week, or custom date).\n• Someday: A low-pressure holding vault for long-term reference, ideas, and backlogged reading that you do not want cluttering your immediate triage view.',
    tags: ['today', 'upcoming', 'someday', 'deferral', 'schedule'],
  },
  {
    id: 'faq-6',
    category: 'triage',
    question: 'How do Starred, Kept, Archived, and Recently Deleted states differ?',
    answer: '• Starred: High-priority favorites you want at your fingertips (accessible in the Starred tab).\n• Kept: Items you have read and want preserved in your permanent personal library.\n• Archived: Completed items kept for historical search without appearing in your active inbox.\n• Recently Deleted: A safety bin where deleted items stay. You can restore them anytime or click "Empty Trash Now" to permanently purge them.',
    tags: ['starred', 'kept', 'archived', 'trash', 'deleted'],
  },
  {
    id: 'faq-7',
    category: 'triage',
    question: 'What keyboard shortcuts are available in the web app?',
    answer: '• Cmd/Ctrl + K: Open Fast Search & Command Omnibar\n• Cmd/Ctrl + N or C: Open Quick Save / Capture modal\n• J / K or Down / Up: Navigate next or previous item in the table\n• X: Toggle selection checkbox on the highlighted item\n• E: Archive selected item\n• S: Star or unstar selected item\n• # or Delete: Move selected item to Recently Deleted\n• Esc: Close reading pane or open modal',
    tags: ['shortcuts', 'keyboard', 'navigation', 'speed'],
  },
  {
    id: 'faq-8',
    category: 'ai-features',
    question: 'How does the AI Assistant organize and auto-tag my saved items?',
    answer: 'When you click "AI Organize" in the top header, LaterBox uses Gemini AI to analyze your unorganized inbox items. It suggests relevant thematic collections (e.g., Design Systems, Machine Learning, Recipes), groups related links together, and prevents duplicate collections. You can preview all AI suggestions with a single click before applying them.',
    tags: ['ai', 'organize', 'gemini', 'collections', 'tags'],
  },
  {
    id: 'faq-9',
    category: 'ai-features',
    question: 'How does the built-in media player and reader work?',
    answer: 'For video and audio links or uploaded attachments, LaterBox features integrated Video.js 10 media players with customizable speed controls, keyboard shortcuts, and background audio streaming. PDF files and documents display clean inline preview frames with external download options.',
    tags: ['video', 'audio', 'player', 'pdf', 'media'],
  },
  {
    id: 'faq-10',
    category: 'ai-features',
    question: 'Why is an article or video failing to parse correctly?',
    answer: 'Some websites use strict paywalls, aggressive anti-scraping protections, or complex single-page client rendering that blocks server-side article extractors. In these cases, we recommend using the LaterBox browser extension on the live page tab to capture the exact rendered DOM snapshot.',
    tags: ['troubleshooting', 'parsing', 'paywalls', 'extractor'],
  },
  {
    id: 'faq-11',
    category: 'collections',
    question: 'How do Custom Collections work and how do I create them?',
    answer: 'Collections function like Gmail labels or folders. In the sidebar, look for the "COLLECTIONS" group and click the "+" button to create a new collection with a custom name and color badge. You can drag items or use the bulk selection toolbar to assign items to one or multiple collections.',
    tags: ['collections', 'labels', 'folders', 'sidebar'],
  },
  {
    id: 'faq-12',
    category: 'pro-billing',
    question: 'What features are included in LaterBox Pro vs. Free?',
    answer: '• Free: Unlimited local offline storage, browser extension captures, full reader mode, instant search, and custom collections.\n• Pro: Encrypted multi-device cloud synchronization, unlimited Gemini AI organization, automated scheduled return reminders, and priority support. You can manage or upgrade your subscription anytime under Plans.',
    tags: ['pro', 'pricing', 'billing', 'cloud-sync', 'paddle'],
  },
  {
    id: 'faq-13',
    category: 'pro-billing',
    question: 'How do I cancel or update my LaterBox Pro subscription?',
    answer: 'You can manage your subscription at any time by navigating to Settings -> Subscription or visiting the Plans page. Clicking "Manage Subscription" securely opens the Paddle Customer Portal where you can update payment methods, view invoices, or cancel renewal without penalty.',
    tags: ['subscription', 'cancel', 'paddle', 'portal', 'invoices'],
  },
  {
    id: 'faq-14',
    category: 'privacy-offline',
    question: 'Can I use LaterBox completely offline?',
    answer: 'Yes! LaterBox features an offline-first architecture with local cache and IndexedDB storage. You can view previously opened items, read saved notes, and queue new captures while offline. Once you reconnect to the internet, pending changes automatically sync to your cloud vault.',
    tags: ['offline', 'cache', 'indexeddb', 'sync'],
  },
  {
    id: 'faq-15',
    category: 'privacy-offline',
    question: 'Is my saved content private and secure?',
    answer: 'Absolutely. LaterBox utilizes Supabase with Row Level Security (RLS) policies. Your items, notes, and attachments are strictly isolated and encrypted. We do not sell data to third parties, inject advertising, or track your browsing activity across other sites.',
    tags: ['privacy', 'security', 'encryption', 'rls'],
  },
  {
    id: 'faq-16',
    category: 'privacy-offline',
    question: 'How can I export my data or delete my account?',
    answer: 'Navigate to Settings (/settings). Under the Data Management section, you can export your entire vault as JSON or CSV spreadsheets. Under Security & Account, you can trigger a permanent account deletion which wipes your profile, cloud database records, and entitlements via a cryptographic RPC.',
    tags: ['export', 'delete-account', 'gdpr', 'backup'],
  },
];

const LOCAL_STORAGE_TICKETS_KEY = 'laterbox_support_ticket_ids';

export default function HelpPage() {
  const { user, session } = useAuth();

  // Active section tab
  const [activeTab, setActiveTab] = useState<'faq' | 'report' | 'tickets'>('report');

  // FAQ filters & state
  const [faqSearch, setFaqSearch] = useState('');
  const [faqCategory, setFaqCategory] = useState<string>('all');
  const [expandedFaqs, setExpandedFaqs] = useState<Record<string, boolean>>({
    'faq-1': true,
    'faq-2': true,
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
  const saveStoredTicketId = useCallback((id: string) => {
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
  }, [getStoredTicketIds]);

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

      // Switch view to tickets or show banner
      setActiveTab('tickets');
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Submission failed. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  }

  // Toggle FAQ expansion
  const toggleFaq = (id: string) => {
    setExpandedFaqs(prev => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  // Filtered FAQs
  const filteredFaqs = useMemo(() => {
    return FAQ_LIST.filter(item => {
      const matchesCategory = faqCategory === 'all' || item.category === faqCategory;
      const qLower = faqSearch.toLowerCase().trim();
      if (!qLower) return matchesCategory;

      const matchesText =
        item.question.toLowerCase().includes(qLower) ||
        item.answer.toLowerCase().includes(qLower) ||
        item.tags.some(tag => tag.toLowerCase().includes(qLower));

      return matchesCategory && matchesText;
    });
  }, [faqCategory, faqSearch]);

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
            <span>Idea</span>
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
      {/* Top Banner / Hero */}
      <div className="rounded-3xl border border-[#e4e0d5] bg-white p-6 md:p-8 shadow-xs relative overflow-hidden">
        <div className="absolute right-0 top-0 translate-x-12 -translate-y-8 w-64 h-64 bg-[#e6edb0]/30 rounded-full blur-3xl pointer-events-none" />
        <div className="relative z-10 max-w-3xl space-y-3">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e6edb0] border border-[#d0db84] text-xs font-black text-[#171711] tracking-wide">
            <Sparkles className="w-3.5 h-3.5 text-[#171711]" />
            <span>LATERBOX SUPPORT &amp; KNOWLEDGE BASE</span>
          </div>
          <h1 className="text-2xl md:text-3xl font-black text-[#171711] tracking-tight">
            How can we help you today?
          </h1>
          <p className="text-sm md:text-base text-[#6c6b63] leading-relaxed">
            Search our comprehensive guides, report a problem or bug directly to our team,
            and monitor the status of all your support tickets in real-time.
          </p>

          {/* Quick Metrics / Status Cards */}
          <div className="pt-3 grid grid-cols-1 sm:grid-cols-3 gap-3">
            <div className="p-3.5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]/80 flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-white border border-[#e4e0d5] flex items-center justify-center shrink-0 text-[#171711] shadow-2xs">
                <CheckCircle2 className="w-4 h-4 text-[#246328]" />
              </div>
              <div>
                <p className="text-[11px] font-bold text-[#9e9b92] uppercase tracking-wider">System Status</p>
                <p className="text-xs font-bold text-[#171711]">All Services Operational</p>
              </div>
            </div>

            <div className="p-3.5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]/80 flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-white border border-[#e4e0d5] flex items-center justify-center shrink-0 text-[#171711] shadow-2xs">
                <Clock className="w-4 h-4 text-[#171711]" />
              </div>
              <div>
                <p className="text-[11px] font-bold text-[#9e9b92] uppercase tracking-wider">Response Time</p>
                <p className="text-xs font-bold text-[#171711]">Under 24 Hours</p>
              </div>
            </div>

            <div className="p-3.5 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5]/80 flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-white border border-[#e4e0d5] flex items-center justify-center shrink-0 text-[#171711] shadow-2xs">
                <MessageSquare className="w-4 h-4 text-[#171711]" />
              </div>
              <div>
                <p className="text-[11px] font-bold text-[#9e9b92] uppercase tracking-wider">Your Tickets</p>
                <p className="text-xs font-bold text-[#171711]">
                  {tickets.length} {tickets.length === 1 ? 'Report' : 'Reports'} Logged
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-[#e4e0d5] pb-3 overflow-x-auto">
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
          <span>Report a Problem &amp; Get Help</span>
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
          <span>My Support Requests Table</span>
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
          <span>Frequently Asked Questions ({FAQ_LIST.length})</span>
        </button>
      </div>

      {/* Success Banner if Ticket Just Submitted */}
      {submittedTicketId && (
        <div className="rounded-2xl border border-[#d2ebd1] bg-[#eef7ec] p-4 flex items-start justify-between gap-3 animate-in fade-in duration-200">
          <div className="flex items-start gap-3">
            <div className="w-8 h-8 rounded-xl bg-[#246328] text-white flex items-center justify-center shrink-0 mt-0.5">
              <Check className="w-4 h-4" />
            </div>
            <div>
              <p className="text-sm font-bold text-[#246328]">Report received and saved successfully!</p>
              <p className="text-xs text-[#246328]/80 mt-0.5">
                Ticket reference: <span className="font-mono font-bold">{submittedTicketId}</span>. We will follow up at your reply email.
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={() => setSubmittedTicketId(null)}
            className="text-xs text-[#246328] hover:underline font-bold"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* TAB 1: Report a Problem & Help Form */}
      {activeTab === 'report' && (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Form (2 cols) */}
          <div className="lg:col-span-2 rounded-3xl border border-[#e4e0d5] bg-white p-6 md:p-8 shadow-xs space-y-6">
            <div>
              <h2 className="text-lg font-black text-[#171711] flex items-center gap-2">
                <Bug className="w-4 h-4 text-[#171711]" />
                <span>Submit a Problem or Help Request</span>
              </h2>
              <p className="text-xs text-[#6c6b63] mt-1">
                Your request is saved straight to our secure database. Include detailed reproduction steps or screenshots links if reporting a bug.
              </p>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Category Selection Tabs */}
              <div>
                <label className="block text-xs font-bold text-[#171711] uppercase tracking-wider mb-2">
                  What kind of issue or inquiry is this?
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  {[
                    { id: 'problem', label: 'Bug / Problem', icon: <Bug className="w-3.5 h-3.5" /> },
                    { id: 'help', label: 'Need Help', icon: <QuestionIcon className="w-3.5 h-3.5" /> },
                    { id: 'feedback', label: 'Feedback / Idea', icon: <Lightbulb className="w-3.5 h-3.5" /> },
                    { id: 'other', label: 'Other Support', icon: <MessageSquare className="w-3.5 h-3.5" /> },
                  ].map(tab => (
                    <button
                      key={tab.id}
                      type="button"
                      onClick={() => setCategory(tab.id as any)}
                      className={`p-3 rounded-xl border text-xs font-bold flex items-center gap-2 justify-center transition-all cursor-pointer ${
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
                  Your Reply Email <span className="text-red-500">*</span>
                </label>
                <input
                  type="email"
                  required
                  maxLength={254}
                  value={email}
                  onChange={e => setEmail(e.target.value)}
                  placeholder="name@example.com"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-[#e4e0d5] bg-[#fbfaf7] text-sm text-[#171711] placeholder:text-[#9e9b92] focus:bg-white focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all"
                />
                <p className="text-[11px] text-[#9e9b92] mt-1">
                  We will notify you at this email address when our engineers respond.
                </p>
              </div>

              {/* Subject */}
              <div>
                <label className="block text-xs font-bold text-[#171711] uppercase tracking-wider mb-1.5">
                  Subject Summary <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  minLength={3}
                  maxLength={160}
                  value={subject}
                  onChange={e => setSubject(e.target.value)}
                  placeholder="e.g. Reader view formatting broken on Substack articles"
                  className="w-full px-3.5 py-2.5 rounded-xl border border-[#e4e0d5] bg-[#fbfaf7] text-sm text-[#171711] placeholder:text-[#9e9b92] focus:bg-white focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all"
                />
                <div className="flex justify-between items-center text-[10px] text-[#9e9b92] mt-1">
                  <span>Concise description of the problem</span>
                  <span>{subject.length}/160</span>
                </div>
              </div>

              {/* Message Description */}
              <div>
                <label className="block text-xs font-bold text-[#171711] uppercase tracking-wider mb-1.5">
                  Detailed Description &amp; Steps <span className="text-red-500">*</span>
                </label>
                <textarea
                  required
                  minLength={10}
                  maxLength={5000}
                  rows={6}
                  value={message}
                  onChange={e => setMessage(e.target.value)}
                  placeholder="What happened? What were you trying to do? What did you expect to happen instead? Please include URLs or reproduction steps if applicable."
                  className="w-full px-3.5 py-2.5 rounded-xl border border-[#e4e0d5] bg-[#fbfaf7] text-sm text-[#171711] placeholder:text-[#9e9b92] focus:bg-white focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all resize-y"
                />
                <div className="flex justify-between items-center text-[10px] text-[#9e9b92] mt-1">
                  <span>Between 10 and 5,000 characters</span>
                  <span>{message.length}/5000</span>
                </div>
              </div>

              {/* Diagnostics Toggle */}
              <div className="p-3.5 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-between">
                <div className="space-y-0.5 pr-4">
                  <p className="text-xs font-bold text-[#171711]">Attach browser and client diagnostics</p>
                  <p className="text-[11px] text-[#6c6b63]">
                    Includes web app build (v1.0.0) and operating system info to help us replicate faster. No passwords or tokens are sent.
                  </p>
                </div>
                <input
                  type="checkbox"
                  checked={includeDiagnostics}
                  onChange={e => setIncludeDiagnostics(e.target.checked)}
                  className="w-4 h-4 rounded border-[#e4e0d5] text-[#171711] focus:ring-[#171711] cursor-pointer"
                />
              </div>

              {formError && (
                <div className="p-3 rounded-xl bg-red-50 border border-red-200 text-xs font-semibold text-red-700 flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{formError}</span>
                </div>
              )}

              {/* Submit Button */}
              <div className="pt-2 flex items-center justify-between">
                <p className="text-[11px] text-[#9e9b92]">
                  Requests are saved to the public.support_requests database.
                </p>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-[#171711] text-[#e6edb0] font-bold text-xs hover:bg-[#2c2b22] transition-colors disabled:opacity-50 cursor-pointer shadow-xs"
                >
                  {isSubmitting ? (
                    <>
                      <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                      <span>Saving to Database...</span>
                    </>
                  ) : (
                    <>
                      <Send className="w-3.5 h-3.5" />
                      <span>Submit Request</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          </div>

          {/* Side Info & Tips (1 col) */}
          <div className="space-y-4">
            <div className="rounded-3xl border border-[#e4e0d5] bg-white p-5 shadow-xs space-y-3">
              <h3 className="text-xs font-black uppercase tracking-wider text-[#9e9b92] flex items-center gap-1.5">
                <Info className="w-3.5 h-3.5 text-[#171711]" />
                <span>Tips for Fast Resolution</span>
              </h3>
              <ul className="text-xs text-[#6c6b63] space-y-2.5">
                <li className="flex items-start gap-2">
                  <span className="font-bold text-[#171711]">•</span>
                  <span><strong>Specify the URL:</strong> If a specific article or webpage fails to extract, include the full link.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="font-bold text-[#171711]">•</span>
                  <span><strong>Note the browser:</strong> Tell us whether you experienced the issue in Chrome, Safari, or on mobile.</span>
                </li>
                <li className="flex items-start gap-2">
                  <span className="font-bold text-[#171711]">•</span>
                  <span><strong>Extension check:</strong> Ensure the LaterBox extension is up to date if reporting capture glitches.</span>
                </li>
              </ul>
            </div>

            <div className="rounded-3xl border border-[#e4e0d5] bg-white p-5 shadow-xs space-y-3">
              <h3 className="text-xs font-black uppercase tracking-wider text-[#9e9b92] flex items-center gap-1.5">
                <BookOpen className="w-3.5 h-3.5 text-[#171711]" />
                <span>Quick Documentation</span>
              </h3>
              <div className="space-y-2">
                <button
                  type="button"
                  onClick={() => {
                    setActiveTab('faq');
                    setFaqCategory('getting-started');
                  }}
                  className="w-full text-left p-2.5 rounded-xl bg-[#f7f5ee] hover:bg-[#ebe7dc] transition-colors text-xs font-bold text-[#171711] flex items-center justify-between"
                >
                  <span>How to save links &amp; articles</span>
                  <ArrowRight className="w-3.5 h-3.5 text-[#9e9b92]" />
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setActiveTab('faq');
                    setFaqCategory('triage');
                  }}
                  className="w-full text-left p-2.5 rounded-xl bg-[#f7f5ee] hover:bg-[#ebe7dc] transition-colors text-xs font-bold text-[#171711] flex items-center justify-between"
                >
                  <span>Keyboard shortcuts guide</span>
                  <ArrowRight className="w-3.5 h-3.5 text-[#9e9b92]" />
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setActiveTab('faq');
                    setFaqCategory('pro-billing');
                  }}
                  className="w-full text-left p-2.5 rounded-xl bg-[#f7f5ee] hover:bg-[#ebe7dc] transition-colors text-xs font-bold text-[#171711] flex items-center justify-between"
                >
                  <span>Pro Plan cloud sync &amp; billing</span>
                  <ArrowRight className="w-3.5 h-3.5 text-[#9e9b92]" />
                </button>
              </div>
            </div>

            <div className="rounded-3xl border border-[#e4e0d5] bg-white p-5 shadow-xs space-y-2">
              <h3 className="text-xs font-black uppercase tracking-wider text-[#9e9b92] flex items-center gap-1.5">
                <Shield className="w-3.5 h-3.5 text-[#171711]" />
                <span>Security &amp; Privacy SLA</span>
              </h3>
              <p className="text-xs text-[#6c6b63] leading-relaxed">
                All reports are encrypted in transit and stored in a private Supabase partition with Row Level Security.
                Never share credit card numbers or passwords in your reports.
              </p>
            </div>
          </div>
        </div>
      )}

      {/* TAB 2: Support Requests Table (Saved info in DB) */}
      {activeTab === 'tickets' && (
        <div className="space-y-4">
          <div className="rounded-3xl border border-[#e4e0d5] bg-white p-6 shadow-xs space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-2 border-b border-[#e4e0d5]/60">
              <div>
                <h2 className="text-lg font-black text-[#171711] flex items-center gap-2">
                  <Inbox className="w-4 h-4 text-[#171711]" />
                  <span>My Support Requests &amp; Problem Reports</span>
                </h2>
                <p className="text-xs text-[#6c6b63] mt-0.5">
                  Track all problem tickets saved to the database. Status updates are reflected live.
                </p>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={fetchTickets}
                  disabled={isLoadingTickets}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl border border-[#e4e0d5] bg-[#f7f5ee] hover:bg-[#ebe7dc] text-xs font-bold text-[#171711] transition-colors disabled:opacity-50 cursor-pointer"
                  title="Refresh status from database"
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

            {/* Error banner if any */}
            {ticketsError && (
              <div className="p-3 rounded-xl bg-red-50 border border-red-200 text-xs text-red-700 flex items-center gap-2">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{ticketsError}</span>
              </div>
            )}

            {/* Table or Empty State */}
            {isLoadingTickets && tickets.length === 0 ? (
              <div className="py-12 flex flex-col items-center justify-center space-y-3 text-center">
                <RefreshCw className="w-6 h-6 animate-spin text-[#9e9b92]" />
                <p className="text-xs font-bold text-[#6c6b63]">Fetching your reports from database...</p>
              </div>
            ) : tickets.length === 0 ? (
              <div className="py-12 flex flex-col items-center justify-center space-y-3 text-center max-w-md mx-auto">
                <div className="w-12 h-12 rounded-2xl bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center text-[#9e9b92]">
                  <Inbox className="w-6 h-6" />
                </div>
                <h3 className="text-sm font-bold text-[#171711]">No Support Requests Logged Yet</h3>
                <p className="text-xs text-[#6c6b63] leading-relaxed">
                  Have an issue, bug, or question? Submit a report using the button below and it will be saved directly into our support queue.
                </p>
                <button
                  type="button"
                  onClick={() => setActiveTab('report')}
                  className="mt-2 inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-[#171711] text-[#e6edb0] text-xs font-bold hover:bg-[#2c2b22] transition-colors cursor-pointer"
                >
                  <Bug className="w-3.5 h-3.5" />
                  <span>Report a Problem</span>
                </button>
              </div>
            ) : (
              <div className="overflow-x-auto rounded-2xl border border-[#e4e0d5]">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="bg-[#f7f5ee] border-b border-[#e4e0d5] text-[#9e9b92] uppercase font-black text-[10px] tracking-wider">
                      <th className="py-3 px-4">Ticket Ref</th>
                      <th className="py-3 px-4">Category</th>
                      <th className="py-3 px-4">Subject &amp; Description</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4">Submitted</th>
                      <th className="py-3 px-4 text-right">Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#e4e0d5]">
                    {tickets.map(ticket => {
                      const dateStr = new Date(ticket.created_at).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      });

                      const isSelected = selectedTicket?.id === ticket.id;

                      return (
                        <tr
                          key={ticket.id}
                          className={`hover:bg-[#fbfaf7] transition-colors ${
                            isSelected ? 'bg-[#e6edb0]/20' : ''
                          }`}
                        >
                          <td className="py-3 px-4 font-mono font-bold text-[#171711] whitespace-nowrap">
                            <div className="flex items-center gap-1.5">
                              <span>#{ticket.id.slice(0, 8)}</span>
                              <button
                                type="button"
                                onClick={() => copyTicketId(ticket.id)}
                                title="Copy full ticket ID"
                                className="text-[#9e9b92] hover:text-[#171711] transition-colors"
                              >
                                {copiedTicketId === ticket.id ? (
                                  <Check className="w-3 h-3 text-[#246328]" />
                                ) : (
                                  <Copy className="w-3 h-3" />
                                )}
                              </button>
                            </div>
                          </td>
                          <td className="py-3 px-4 whitespace-nowrap">
                            {getCategoryBadge(ticket.category)}
                          </td>
                          <td className="py-3 px-4 max-w-xs md:max-w-md">
                            <p className="font-bold text-[#171711] truncate">{ticket.subject}</p>
                            <p className="text-[#6c6b63] truncate text-[11px] mt-0.5">
                              {ticket.message}
                            </p>
                          </td>
                          <td className="py-3 px-4 whitespace-nowrap">
                            {getStatusBadge(ticket.status)}
                          </td>
                          <td className="py-3 px-4 text-[#6c6b63] whitespace-nowrap text-[11px]">
                            {dateStr}
                          </td>
                          <td className="py-3 px-4 text-right whitespace-nowrap">
                            <button
                              type="button"
                              onClick={() => setSelectedTicket(isSelected ? null : ticket)}
                              className="px-2.5 py-1 rounded-lg border border-[#e4e0d5] bg-white hover:bg-[#f7f5ee] text-[11px] font-bold text-[#171711] transition-colors cursor-pointer"
                            >
                              {isSelected ? 'Hide' : 'Details'}
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

          {/* Ticket Details Drawer / Card when a ticket is selected */}
          {selectedTicket && (
            <div className="rounded-3xl border border-[#e4e0d5] bg-white p-6 shadow-xs space-y-4 animate-in fade-in slide-in-from-top-2 duration-150">
              <div className="flex items-center justify-between pb-3 border-b border-[#e4e0d5]">
                <div className="flex items-center gap-3">
                  <span className="font-mono font-bold text-sm text-[#171711]">
                    Ticket #{selectedTicket.id}
                  </span>
                  {getStatusBadge(selectedTicket.status)}
                  {getCategoryBadge(selectedTicket.category)}
                </div>
                <button
                  type="button"
                  onClick={() => setSelectedTicket(null)}
                  className="text-xs font-bold text-[#6c6b63] hover:text-[#171711]"
                >
                  Close
                </button>
              </div>

              <div className="space-y-3 text-xs">
                <div>
                  <span className="font-bold text-[#9e9b92] uppercase tracking-wider text-[10px] block">
                    Subject
                  </span>
                  <p className="text-sm font-bold text-[#171711] mt-0.5">{selectedTicket.subject}</p>
                </div>

                <div>
                  <span className="font-bold text-[#9e9b92] uppercase tracking-wider text-[10px] block">
                    Full Description / Steps
                  </span>
                  <div className="p-4 rounded-xl bg-[#f7f5ee] border border-[#e4e0d5] text-[#171711] whitespace-pre-wrap leading-relaxed mt-1 font-mono text-[11px]">
                    {selectedTicket.message}
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2">
                  <div className="p-3 rounded-xl bg-[#fbfaf7] border border-[#e4e0d5]">
                    <span className="font-bold text-[#9e9b92] uppercase tracking-wider text-[10px] block">
                      Reply Email
                    </span>
                    <p className="font-bold text-[#171711] mt-0.5 truncate">{selectedTicket.email}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-[#fbfaf7] border border-[#e4e0d5]">
                    <span className="font-bold text-[#9e9b92] uppercase tracking-wider text-[10px] block">
                      Platform &amp; Client
                    </span>
                    <p className="font-bold text-[#171711] mt-0.5 uppercase">{selectedTicket.platform}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-[#fbfaf7] border border-[#e4e0d5]">
                    <span className="font-bold text-[#9e9b92] uppercase tracking-wider text-[10px] block">
                      Submitted At
                    </span>
                    <p className="font-bold text-[#171711] mt-0.5">
                      {new Date(selectedTicket.created_at).toLocaleString()}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* TAB 3: FAQ & Knowledge Base */}
      {activeTab === 'faq' && (
        <div className="space-y-6">
          {/* FAQ Search Bar & Category Filters */}
          <div className="rounded-3xl border border-[#e4e0d5] bg-white p-6 shadow-xs space-y-4">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
              <div>
                <h2 className="text-lg font-black text-[#171711] flex items-center gap-2">
                  <HelpCircle className="w-4 h-4 text-[#171711]" />
                  <span>Frequently Asked Questions</span>
                </h2>
                <p className="text-xs text-[#6c6b63] mt-0.5">
                  Browse {FAQ_LIST.length} detailed questions and answers covering all LaterBox capabilities.
                </p>
              </div>

              {/* Search input */}
              <div className="relative min-w-[280px]">
                <Search className="w-4 h-4 text-[#9e9b92] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
                <input
                  type="text"
                  value={faqSearch}
                  onChange={e => setFaqSearch(e.target.value)}
                  placeholder="Search questions or keywords..."
                  className="w-full pl-10 pr-4 py-2 rounded-xl border border-[#e4e0d5] bg-[#fbfaf7] text-xs text-[#171711] placeholder:text-[#9e9b92] focus:bg-white focus:outline-none focus:ring-2 focus:ring-[#171711]/20 transition-all"
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
            </div>

            {/* Category Pills */}
            <div className="flex items-center gap-2 overflow-x-auto pb-1 pt-1">
              {FAQ_CATEGORIES.map(cat => {
                const count =
                  cat.id === 'all'
                    ? FAQ_LIST.length
                    : FAQ_LIST.filter(i => i.category === cat.id).length;

                return (
                  <button
                    key={cat.id}
                    type="button"
                    onClick={() => setFaqCategory(cat.id)}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all cursor-pointer ${
                      faqCategory === cat.id
                        ? 'bg-[#171711] text-[#e6edb0]'
                        : 'bg-[#f7f5ee] border border-[#e4e0d5] text-[#6c6b63] hover:text-[#171711]'
                    }`}
                  >
                    <span>{cat.label}</span>
                    <span className="ml-1.5 opacity-70 text-[10px]">({count})</span>
                  </button>
                );
              })}
            </div>
          </div>

          {/* FAQs Accordion List */}
          <div className="space-y-3">
            {filteredFaqs.length === 0 ? (
              <div className="rounded-3xl border border-[#e4e0d5] bg-white p-12 text-center space-y-2">
                <Search className="w-6 h-6 text-[#9e9b92] mx-auto" />
                <h3 className="text-sm font-bold text-[#171711]">No matching questions found</h3>
                <p className="text-xs text-[#6c6b63]">
                  Try different keywords or check all categories.
                </p>
                <button
                  type="button"
                  onClick={() => {
                    setFaqSearch('');
                    setFaqCategory('all');
                  }}
                  className="mt-2 text-xs font-bold text-[#171711] underline"
                >
                  Reset search filters
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
                      className="w-full text-left p-4 md:p-5 flex items-start justify-between gap-4 hover:bg-[#fbfaf7] transition-colors cursor-pointer"
                    >
                      <div className="flex items-start gap-3">
                        <span className="w-6 h-6 rounded-lg bg-[#f7f5ee] border border-[#e4e0d5] flex items-center justify-center shrink-0 font-bold text-xs text-[#171711] mt-0.5">
                          {index + 1}
                        </span>
                        <div>
                          <h3 className="text-sm font-bold text-[#171711] leading-snug">
                            {faq.question}
                          </h3>
                          <div className="flex items-center gap-1.5 mt-1.5 flex-wrap">
                            {faq.tags.map(tag => (
                              <span
                                key={tag}
                                className="px-2 py-0.5 rounded-md bg-[#f7f5ee] text-[10px] font-bold text-[#9e9b92]"
                              >
                                #{tag}
                              </span>
                            ))}
                          </div>
                        </div>
                      </div>
                      <div className="shrink-0 p-1 rounded-lg text-[#9e9b92]">
                        {isExpanded ? (
                          <ChevronUp className="w-4 h-4 text-[#171711]" />
                        ) : (
                          <ChevronDown className="w-4 h-4" />
                        )}
                      </div>
                    </button>

                    {isExpanded && (
                      <div className="px-5 pb-5 pt-2 text-xs text-[#6c6b63] leading-relaxed border-t border-[#e4e0d5]/60 bg-[#fdfdfc] whitespace-pre-line pl-13">
                        {faq.answer}
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>

          {/* Bottom Help Prompt */}
          <div className="rounded-3xl border border-[#e4e0d5] bg-white p-6 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="text-sm font-bold text-[#171711]">Still have a question or need personalized help?</h3>
              <p className="text-xs text-[#6c6b63] mt-0.5">
                Our support team is ready to investigate. Submit a problem report and we will get back to you promptly.
              </p>
            </div>
            <button
              type="button"
              onClick={() => setActiveTab('report')}
              className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-[#171711] text-[#e6edb0] font-bold text-xs hover:bg-[#2c2b22] transition-colors cursor-pointer shrink-0"
            >
              <Bug className="w-3.5 h-3.5" />
              <span>Report a Problem</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
