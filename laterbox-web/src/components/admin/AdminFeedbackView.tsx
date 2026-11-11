// laterbox-web/src/components/admin/AdminFeedbackView.tsx
'use client';

import { useMemo, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  ArrowUpRight,
  CheckCircle2,
  Clock,
  Inbox,
  Mail,
  MessageSquareText,
  RefreshCw,
  Search,
  Sparkles,
  Tag,
  X,
} from 'lucide-react';
import { useAdmin, type Ticket } from './AdminContext';

type StatusTab = 'open' | 'in_progress' | 'resolved' | 'all';

export function AdminFeedbackView() {
  const router = useRouter();
  const { operations, busyOperations, updateOperations, refreshOperations } = useAdmin();
  const [activeTab, setActiveTab] = useState<StatusTab>('open');
  const [searchQuery, setSearchQuery] = useState('');
  const [isRefreshing, setIsRefreshing] = useState(false);

  const tickets = operations?.tickets ?? [];

  // Tab counts
  const counts = useMemo(() => {
    return {
      open: tickets.filter((t) => t.status === 'open').length,
      in_progress: tickets.filter((t) => t.status === 'in_progress').length,
      resolved: tickets.filter((t) => t.status === 'resolved').length,
      all: tickets.length,
    };
  }, [tickets]);

  // Tab configurations matching LaterBox dashboard tabs
  const tabs = [
    {
      id: 'open' as const,
      label: 'Inbox',
      icon: <Inbox className="h-4 w-4 shrink-0 text-[#171711]" />,
      count: counts.open,
      badgeBg: 'bg-[#e6edb0] text-[#171711]',
    },
    {
      id: 'in_progress' as const,
      label: 'In Progress',
      icon: <Clock className="h-4 w-4 shrink-0 text-sky-600" />,
      count: counts.in_progress,
      badgeBg: 'bg-sky-100 text-sky-800',
    },
    {
      id: 'resolved' as const,
      label: 'Resolved',
      icon: <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />,
      count: counts.resolved,
      badgeBg: 'bg-emerald-100 text-emerald-800',
    },
    {
      id: 'all' as const,
      label: 'All Submissions',
      icon: <MessageSquareText className="h-4 w-4 shrink-0 text-[#677362]" />,
      count: counts.all,
      badgeBg: 'bg-[#e4e5d9] text-[#171711]',
    },
  ];

  // Filtered tickets
  const filteredTickets = useMemo(() => {
    const q = searchQuery.toLowerCase().trim();
    return tickets.filter((ticket) => {
      if (activeTab !== 'all' && ticket.status !== activeTab) {
        return false;
      }
      if (q) {
        const matchSubject = ticket.subject?.toLowerCase().includes(q);
        const matchMessage = ticket.message?.toLowerCase().includes(q);
        const matchEmail = ticket.email?.toLowerCase().includes(q);
        const matchId = ticket.id?.toLowerCase().includes(q);
        const matchPlatform = ticket.platform?.toLowerCase().includes(q);
        const matchCategory = ticket.category?.toLowerCase().includes(q);
        if (!matchSubject && !matchMessage && !matchEmail && !matchId && !matchPlatform && !matchCategory) {
          return false;
        }
      }
      return true;
    });
  }, [tickets, activeTab, searchQuery]);

  const handleRefresh = async () => {
    setIsRefreshing(true);
    try {
      await refreshOperations();
    } finally {
      setIsRefreshing(false);
    }
  };

  const formatRelativeTime = (dateString: string) => {
    try {
      const date = new Date(dateString);
      const diffMs = Date.now() - date.getTime();
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffMins < 1) return 'Just now';
      if (diffMins < 60) return `${diffMins}m`;
      if (diffHours < 24) return `${diffHours}h`;
      if (diffDays === 1) return 'Yesterday';
      if (diffDays < 7) return `${diffDays}d`;
      return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    } catch {
      return dateString;
    }
  };

  const getStatusDot = (status: Ticket['status']) => {
    switch (status) {
      case 'open':
        return <span className="h-2 w-2 shrink-0 rounded-full bg-amber-500" title="Open ticket" />;
      case 'in_progress':
        return <span className="h-2 w-2 shrink-0 rounded-full bg-sky-500" title="In progress" />;
      case 'resolved':
        return <span className="h-2 w-2 shrink-0 rounded-full bg-emerald-500" title="Resolved" />;
    }
  };

  const getCategoryChip = (category: string) => {
    switch (category) {
      case 'problem':
        return (
          <span className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
            Bug
          </span>
        );
      case 'feedback':
        return (
          <span className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold bg-[#edf0e2] text-[#435b34] border border-[#d3df9e]">
            Feedback
          </span>
        );
      case 'help':
        return (
          <span className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold bg-sky-50 text-sky-800 border border-sky-200">
            Support
          </span>
        );
      default:
        return (
          <span className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-bold bg-[#f7f5ee] text-[#677362] border border-[#e4e0d5]">
            {category || 'Note'}
          </span>
        );
    }
  };

  if (!operations) return null;

  return (
    <div className="flex flex-col rounded-2xl border border-[#e4e0d5] bg-white shadow-sm overflow-hidden">
      {/* ===================================================================== */}
      {/* TOP CONTROLS TOOLBAR: TABS & MINIMAL SEARCH                          */}
      {/* ===================================================================== */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between border-b border-[#e4e0d5] bg-white px-3 sm:px-4 py-2 gap-2 text-xs">
        {/* Minimal Search Field */}
        <div className="relative flex-1 max-w-xs sm:max-w-sm">
          <Search className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-[#9e9b92]" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search email, subject, or message…"
            className="w-full rounded-xl border border-[#e4e0d5] bg-[#faf8f5] py-1.5 pl-8 pr-7 text-xs text-[#171711] outline-none transition-colors placeholder:text-[#9e9b92] focus:border-[#171711] focus:bg-white"
          />
          {searchQuery && (
            <button
              type="button"
              onClick={() => setSearchQuery('')}
              className="absolute right-2 top-1/2 -translate-y-1/2 p-0.5 text-[#9e9b92] hover:text-[#171711]"
            >
              <X className="h-3 w-3" />
            </button>
          )}
        </div>

        {/* Counter and Refresh */}
        <div className="flex items-center justify-between sm:justify-end gap-2 text-[#6c6b63]">
          <span className="text-[11px] font-medium text-[#8e8d87]">
            {filteredTickets.length} {filteredTickets.length === 1 ? 'submission' : 'submissions'}
          </span>
          <button
            type="button"
            onClick={handleRefresh}
            title="Refresh inbox"
            disabled={isRefreshing}
            className="rounded-lg p-1.5 text-[#6c6b63] hover:bg-[#faf8f5] hover:text-[#171711] transition-colors"
          >
            <RefreshCw className={`h-3.5 w-3.5 ${isRefreshing ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* ===================================================================== */}
      {/* CATEGORY / STATUS TABS (Identical to EmailInboxTable Tabs)           */}
      {/* ===================================================================== */}
      <div className="grid grid-cols-2 sm:grid-cols-4 border-b border-[#e4e0d5] bg-white select-none">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => setActiveTab(tab.id)}
              className={`relative flex items-center gap-2 px-3 sm:px-4 py-3 text-left transition-colors hover:bg-[#faf8f5] cursor-pointer ${
                isActive ? 'bg-[#faf8f5]/60' : 'bg-white'
              }`}
            >
              {/* Active Tab Indicator Line */}
              {isActive && (
                <span className="absolute bottom-0 left-0 right-0 h-[3px] bg-[#171711] rounded-t-sm" />
              )}

              {/* Tab Icon */}
              <div className="shrink-0">{tab.icon}</div>

              {/* Tab Title & Badge */}
              <div className="min-w-0 flex-1 flex items-center gap-1.5">
                <span
                  className={`text-xs sm:text-sm tracking-tight truncate ${
                    isActive ? 'font-black text-[#171711]' : 'font-bold text-[#6c6b63]'
                  }`}
                >
                  {tab.label}
                </span>
                {tab.count > 0 && (
                  <span
                    className={`px-1.5 py-0.2 rounded-full text-[10px] font-bold shrink-0 ${tab.badgeBg}`}
                  >
                    {tab.count}
                  </span>
                )}
              </div>
            </button>
          );
        })}
      </div>

      {/* ===================================================================== */}
      {/* EMAIL-STYLE INBOX ROWS (Simple, Clean, No Excess Controls)           */}
      {/* ===================================================================== */}
      <div className="divide-y divide-[#f0ede4]">
        {filteredTickets.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-16 px-4 text-center space-y-2">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#faf8f5] border border-[#e4e0d5] text-[#9e9b92]">
              <Inbox className="h-5 w-5" />
            </div>
            <h3 className="text-sm font-bold text-[#171711]">No submissions</h3>
            <p className="text-xs text-[#8e8d87] max-w-sm">
              {searchQuery
                ? `No submissions match "${searchQuery}".`
                : 'All caught up! No items currently in this view.'}
            </p>
          </div>
        ) : (
          filteredTickets.map((ticket) => {
            const sender = ticket.email.split('@')[0] || ticket.email;
            const title = ticket.subject || '(No subject)';
            const snippet = ticket.message || 'No message content';

            return (
              <div
                key={ticket.id}
                onClick={() => router.push(`/admin/feedback/${ticket.id}`)}
                role="link"
                tabIndex={0}
                aria-label={`View feedback from ${ticket.email}`}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    router.push(`/admin/feedback/${ticket.id}`);
                  }
                }}
                className="group relative flex items-center gap-2.5 sm:gap-3 px-3 sm:px-4 py-2.5 transition-colors cursor-pointer select-none overflow-hidden hover:bg-[#faf8f5] focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-[#758a50]"
              >
                {/* 1. Status Dot */}
                <div className="shrink-0 p-1">{getStatusDot(ticket.status)}</div>

                {/* 2. Sender Column (Fixed Width, Truncated, Bold) */}
                <div className="w-28 sm:w-44 shrink-0 truncate">
                  <span
                    className="text-xs sm:text-sm font-bold text-[#171711] group-hover:text-black"
                    title={ticket.email}
                  >
                    {ticket.email}
                  </span>
                </div>

                {/* 3. Subject & Message Snippet Inline */}
                <div className="flex-1 min-w-0 flex items-center gap-1.5 text-xs sm:text-sm overflow-hidden whitespace-nowrap">
                  <span className="font-bold text-[#171711] truncate shrink-0 max-w-[48%] sm:max-w-[40%] group-hover:text-black">
                    {title}
                  </span>
                  <span className="text-[#9e9b92] shrink-0 font-bold">–</span>
                  <span className="text-[#6c6b63] truncate flex-1 min-w-0 font-normal">
                    {snippet}
                  </span>

                  {/* Category Chip */}
                  {getCategoryChip(ticket.category)}

                  {/* Platform Tag */}
                  {ticket.platform && (
                    <span className="shrink-0 rounded px-1.5 py-0.5 text-[10px] font-semibold bg-[#f4f3ec] text-[#677362] border border-[#e4e0d5] capitalize">
                      {ticket.platform}
                    </span>
                  )}
                </div>

                {/* 4. Timestamp & Hover Quick Actions */}
                <div className="shrink-0 flex items-center justify-end min-w-[70px] sm:min-w-[110px] text-right">
                  {/* Default State: Relative Timestamp */}
                  <span className="text-xs text-[#8e8d87] group-hover:hidden">
                    {formatRelativeTime(ticket.created_at)}
                  </span>

                  {/* Hover Quick Action Buttons */}
                  <div className="hidden group-hover:flex items-center gap-1 text-[#6c6b63] bg-white/95 px-1.5 py-0.5 rounded-lg border border-[#e4e0d5]/80 shadow-2xs">
                    {/* Direct email reply */}
                    <a
                      href={`mailto:${ticket.email}?subject=Re: ${encodeURIComponent(ticket.subject || 'LaterBox Feedback')}`}
                      onClick={(e) => e.stopPropagation()}
                      title="Reply via email"
                      className="p-1 rounded hover:bg-[#faf8f5] hover:text-[#171711] transition-colors"
                    >
                      <Mail className="h-3.5 w-3.5" />
                    </a>

                    {/* Quick Toggle Resolved */}
                    <button
                      type="button"
                      disabled={busyOperations}
                      title={ticket.status === 'resolved' ? 'Mark open' : 'Mark resolved'}
                      onClick={(e) => {
                        e.stopPropagation();
                        void updateOperations({
                          action: 'ticket',
                          ticketId: ticket.id,
                          status: ticket.status === 'resolved' ? 'open' : 'resolved',
                        });
                      }}
                      className="p-1 rounded hover:bg-[#faf8f5] hover:text-[#171711] transition-colors"
                    >
                      <CheckCircle2
                        className={`h-3.5 w-3.5 ${
                          ticket.status === 'resolved' ? 'text-emerald-600' : 'text-[#8e8d87]'
                        }`}
                      />
                    </button>

                    {/* Open Details Arrow */}
                    <span className="inline-flex items-center gap-0.5 pl-1 text-[11px] font-bold text-[#171711]">
                      <span>Details</span>
                      <ArrowUpRight className="h-3 w-3" />
                    </span>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
