// laterbox-web/src/components/admin/AdminFeedbackView.tsx
'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import {
  ArrowUpRight,
  Check,
  CheckCircle2,
  Clock,
  Copy,
  ExternalLink,
  Filter,
  Inbox,
  Mail,
  MessageSquareText,
  Search,
  Sparkles,
  User,
  XCircle,
} from 'lucide-react';
import { useAdmin, type Ticket } from './AdminContext';

type StatusFilter = 'all' | 'open' | 'in_progress' | 'resolved';

export function AdminFeedbackView() {
  const { operations, busyOperations, updateOperations } = useAdmin();
  const [statusTab, setStatusTab] = useState<StatusFilter>('open');
  const [categoryFilter, setCategoryFilter] = useState('all');
  const [platformFilter, setPlatformFilter] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const tickets = operations?.tickets ?? [];

  // Status counts for tab pills
  const counts = useMemo(() => {
    return {
      all: tickets.length,
      open: tickets.filter((t) => t.status === 'open').length,
      in_progress: tickets.filter((t) => t.status === 'in_progress').length,
      resolved: tickets.filter((t) => t.status === 'resolved').length,
    };
  }, [tickets]);

  // Filtered tickets based on tab, category, platform, and search
  const filteredTickets = useMemo(() => {
    const q = searchQuery.toLowerCase().trim();
    return tickets.filter((ticket) => {
      // Tab filter
      if (statusTab !== 'all' && ticket.status !== statusTab) {
        return false;
      }
      // Category filter
      if (categoryFilter !== 'all' && ticket.category !== categoryFilter) {
        return false;
      }
      // Platform filter
      if (platformFilter !== 'all' && ticket.platform !== platformFilter) {
        return false;
      }
      // Search query
      if (q) {
        const matchSubject = ticket.subject?.toLowerCase().includes(q);
        const matchMessage = ticket.message?.toLowerCase().includes(q);
        const matchEmail = ticket.email?.toLowerCase().includes(q);
        const matchUserId = ticket.user_id?.toLowerCase().includes(q);
        const matchId = ticket.id?.toLowerCase().includes(q);
        const matchPlatform = ticket.platform?.toLowerCase().includes(q);
        if (!matchSubject && !matchMessage && !matchEmail && !matchUserId && !matchId && !matchPlatform) {
          return false;
        }
      }
      return true;
    });
  }, [tickets, statusTab, categoryFilter, platformFilter, searchQuery]);

  const copyToClipboard = (text: string, id: string) => {
    if (typeof navigator !== 'undefined') {
      navigator.clipboard.writeText(text);
      setCopiedId(id);
      setTimeout(() => setCopiedId(null), 2000);
    }
  };

  const getCategoryBadge = (category: string) => {
    switch (category) {
      case 'problem':
        return (
          <span className="inline-flex items-center gap-1 rounded-md border border-amber-200 bg-amber-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-amber-800">
            Bug / Issue
          </span>
        );
      case 'feedback':
        return (
          <span className="inline-flex items-center gap-1 rounded-md border border-[#cddca8] bg-[#edf0e2] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-[#435b34]">
            Feedback
          </span>
        );
      case 'help':
        return (
          <span className="inline-flex items-center gap-1 rounded-md border border-sky-200 bg-sky-50 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-sky-800">
            Support
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 rounded-md border border-[#e4e0d5] bg-[#f7f5ee] px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-[#677362]">
            {category || 'General'}
          </span>
        );
    }
  };

  const getStatusBadge = (status: Ticket['status']) => {
    switch (status) {
      case 'open':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-amber-300 bg-amber-50 px-2.5 py-0.5 text-xs font-bold text-amber-900">
            <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
            Open
          </span>
        );
      case 'in_progress':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-sky-300 bg-sky-50 px-2.5 py-0.5 text-xs font-bold text-sky-900">
            <Clock size={12} className="text-sky-600" />
            In Progress
          </span>
        );
      case 'resolved':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-300 bg-emerald-50 px-2.5 py-0.5 text-xs font-bold text-emerald-900">
            <CheckCircle2 size={12} className="text-emerald-600" />
            Resolved
          </span>
        );
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
      if (diffMins < 60) return `${diffMins}m ago`;
      if (diffHours < 24) return `${diffHours}h ago`;
      if (diffDays === 1) return 'Yesterday';
      if (diffDays < 7) return `${diffDays}d ago`;
      return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
    } catch {
      return dateString;
    }
  };

  if (!operations) return null;

  return (
    <div className="space-y-6">
      {/* Top Filter and Status Navigation Rail */}
      <section className="rounded-2xl border border-[#e4e5d9] bg-white p-5 shadow-sm">
        {/* Header Title & Status Tabs */}
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between border-b border-[#f0ede5] pb-5">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#e6edb0] text-[#171711]">
              <Inbox size={22} strokeWidth={2.2} />
            </div>
            <div>
              <h2 className="text-base font-bold text-[#171711]">Feedback & Support Inbox</h2>
              <p className="text-xs text-[#677362]">
                Triage user reports, product feedback, and direct contact inquiries
              </p>
            </div>
          </div>

          {/* Status Tabs with Live Count Badges */}
          <div className="flex flex-wrap items-center gap-1.5 rounded-xl border border-[#e4e5d9] bg-[#fbfcf9] p-1">
            <button
              type="button"
              onClick={() => setStatusTab('open')}
              className={`flex items-center gap-2 rounded-lg px-3 py-1.5 text-xs font-bold transition-all ${
                statusTab === 'open'
                  ? 'bg-[#171711] text-white shadow-sm'
                  : 'text-[#677362] hover:text-[#171711] hover:bg-[#edf0e4]'
              }`}
            >
              <span>Inbox (Open)</span>
              <span
                className={`rounded-full px-1.5 py-0.2 text-[10px] font-black ${
                  statusTab === 'open' ? 'bg-[#e6edb0] text-[#171711]' : 'bg-[#e4e5d9] text-[#171711]'
                }`}
              >
                {counts.open}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setStatusTab('in_progress')}
              className={`flex items-center gap-2 rounded-lg px-3 py-1.5 text-xs font-bold transition-all ${
                statusTab === 'in_progress'
                  ? 'bg-[#171711] text-white shadow-sm'
                  : 'text-[#677362] hover:text-[#171711] hover:bg-[#edf0e4]'
              }`}
            >
              <span>In Progress</span>
              <span
                className={`rounded-full px-1.5 py-0.2 text-[10px] font-black ${
                  statusTab === 'in_progress' ? 'bg-[#e6edb0] text-[#171711]' : 'bg-[#e4e5d9] text-[#171711]'
                }`}
              >
                {counts.in_progress}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setStatusTab('resolved')}
              className={`flex items-center gap-2 rounded-lg px-3 py-1.5 text-xs font-bold transition-all ${
                statusTab === 'resolved'
                  ? 'bg-[#171711] text-white shadow-sm'
                  : 'text-[#677362] hover:text-[#171711] hover:bg-[#edf0e4]'
              }`}
            >
              <span>Resolved</span>
              <span
                className={`rounded-full px-1.5 py-0.2 text-[10px] font-black ${
                  statusTab === 'resolved' ? 'bg-[#e6edb0] text-[#171711]' : 'bg-[#e4e5d9] text-[#171711]'
                }`}
              >
                {counts.resolved}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setStatusTab('all')}
              className={`flex items-center gap-2 rounded-lg px-3 py-1.5 text-xs font-bold transition-all ${
                statusTab === 'all'
                  ? 'bg-[#171711] text-white shadow-sm'
                  : 'text-[#677362] hover:text-[#171711] hover:bg-[#edf0e4]'
              }`}
            >
              <span>All Submissions</span>
              <span
                className={`rounded-full px-1.5 py-0.2 text-[10px] font-black ${
                  statusTab === 'all' ? 'bg-[#e6edb0] text-[#171711]' : 'bg-[#e4e5d9] text-[#171711]'
                }`}
              >
                {counts.all}
              </span>
            </button>
          </div>
        </div>

        {/* Filter Controls & Search Bar */}
        <div className="mt-4 flex flex-wrap items-center justify-between gap-3">
          {/* Search Input */}
          <div className="relative flex-1 min-w-[240px] sm:max-w-md">
            <Search
              size={16}
              className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-[#788470]"
            />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search contact, subject, message content or ID…"
              className="w-full rounded-xl border border-[#dde2d2] bg-[#fbfcf9] py-2 pl-10 pr-4 text-xs sm:text-sm text-[#171711] outline-none transition-colors placeholder:text-[#91998b] focus:border-[#9bad79] focus:bg-white"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-[#86927f] hover:text-[#171711]"
              >
                Clear
              </button>
            )}
          </div>

          {/* Category & Platform Selectors */}
          <div className="flex flex-wrap items-center gap-2.5">
            <div className="flex items-center gap-1.5">
              <span className="text-xs font-bold text-[#677362]">Category:</span>
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="rounded-xl border border-[#dde2d2] bg-[#fbfcf9] px-3 py-1.5 text-xs font-semibold text-[#171711] outline-none focus:border-[#9bad79]"
              >
                <option value="all">All Categories</option>
                <option value="problem">Problem / Bug</option>
                <option value="feedback">Feedback / Idea</option>
                <option value="help">Help / Support</option>
                <option value="other">Other / Contact</option>
              </select>
            </div>

            <div className="flex items-center gap-1.5">
              <span className="text-xs font-bold text-[#677362]">Platform:</span>
              <select
                value={platformFilter}
                onChange={(e) => setPlatformFilter(e.target.value)}
                className="rounded-xl border border-[#dde2d2] bg-[#fbfcf9] px-3 py-1.5 text-xs font-semibold text-[#171711] outline-none focus:border-[#9bad79]"
              >
                <option value="all">All Platforms</option>
                <option value="web">Web App</option>
                <option value="ios">iOS App</option>
                <option value="extension">Extension</option>
              </select>
            </div>
          </div>
        </div>
      </section>

      {/* Main Feedback & Contacts Data Table */}
      <section className="overflow-hidden rounded-2xl border border-[#e4e5d9] bg-white shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-[#171711]">
            <thead className="border-b border-[#e4e5d9] bg-[#f9faf5] text-[11px] font-bold uppercase tracking-wider text-[#677362]">
              <tr>
                <th className="px-5 py-3.5">Contact / Sender</th>
                <th className="px-5 py-3.5">Subject & Content</th>
                <th className="px-5 py-3.5">Category</th>
                <th className="px-5 py-3.5">Platform</th>
                <th className="px-5 py-3.5">Status</th>
                <th className="px-5 py-3.5">Date</th>
                <th className="px-5 py-3.5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#edf0e7]">
              {filteredTickets.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-16 text-center text-sm text-[#788272]">
                    <div className="flex flex-col items-center justify-center gap-2">
                      <Inbox size={32} className="text-[#a4ad9f]" />
                      <p className="font-bold text-[#171711]">No submissions found</p>
                      <p className="text-xs text-[#788470]">
                        {searchQuery || categoryFilter !== 'all' || platformFilter !== 'all'
                          ? 'Try clearing your search query or filters.'
                          : 'Your inbox is clear! No tickets currently in this status.'}
                      </p>
                    </div>
                  </td>
                </tr>
              ) : (
                filteredTickets.map((ticket) => {
                  const initial = ticket.email ? ticket.email[0].toUpperCase() : '?';
                  return (
                    <tr
                      key={ticket.id}
                      className="group transition-colors hover:bg-[#fafbf7]"
                    >
                      {/* Contact / Sender Column */}
                      <td className="px-5 py-4 align-top">
                        <div className="flex items-start gap-2.5">
                          <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-[#edf0e2] text-xs font-black text-[#435b34]">
                            {initial}
                          </div>
                          <div className="min-w-0">
                            <div className="flex items-center gap-1.5">
                              <span className="font-semibold text-xs text-[#171711] truncate max-w-[170px]" title={ticket.email}>
                                {ticket.email}
                              </span>
                              <button
                                type="button"
                                onClick={() => copyToClipboard(ticket.email, `email-${ticket.id}`)}
                                title="Copy email address"
                                className="rounded p-0.5 text-[#85917e] hover:bg-[#e9ebe0] hover:text-[#171711] transition-colors"
                              >
                                {copiedId === `email-${ticket.id}` ? (
                                  <Check size={12} className="text-emerald-600" />
                                ) : (
                                  <Copy size={12} />
                                )}
                              </button>
                            </div>
                            <div className="mt-0.5 flex items-center gap-1">
                              {ticket.user_id ? (
                                <span className="text-[10px] text-[#74806e] font-mono">
                                  User: {ticket.user_id.slice(0, 8)}…
                                </span>
                              ) : (
                                <span className="text-[10px] text-[#91998b] italic">
                                  Visitor / Guest
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                      </td>

                      {/* Subject & Preview Column */}
                      <td className="px-5 py-4 align-top max-w-xs md:max-w-md">
                        <Link
                          href={`/admin/feedback/${ticket.id}`}
                          className="group-hover:text-[#435b34] transition-colors"
                        >
                          <p className="font-bold text-xs sm:text-sm text-[#171711] leading-snug line-clamp-1">
                            {ticket.subject || '(No subject provided)'}
                          </p>
                          <p className="mt-1 text-xs text-[#677362] line-clamp-2 leading-relaxed">
                            {ticket.message}
                          </p>
                        </Link>
                      </td>

                      {/* Category Badge */}
                      <td className="px-5 py-4 align-top whitespace-nowrap">
                        {getCategoryBadge(ticket.category)}
                      </td>

                      {/* Platform & Version */}
                      <td className="px-5 py-4 align-top whitespace-nowrap">
                        <div className="flex flex-col">
                          <span className="font-semibold text-xs text-[#171711] capitalize">
                            {ticket.platform || 'Web'}
                          </span>
                          {ticket.app_version && (
                            <span className="text-[10px] text-[#788470] font-mono">
                              v{ticket.app_version}
                            </span>
                          )}
                        </div>
                      </td>

                      {/* Status Selector */}
                      <td className="px-5 py-4 align-top whitespace-nowrap">
                        <div className="flex flex-col gap-1.5">
                          {getStatusBadge(ticket.status)}
                          <select
                            aria-label={`Update status for ${ticket.subject}`}
                            value={ticket.status}
                            disabled={busyOperations}
                            onChange={(e) =>
                              void updateOperations({
                                action: 'ticket',
                                ticketId: ticket.id,
                                status: e.target.value,
                              })
                            }
                            className="w-28 rounded-lg border border-[#d9dfcb] bg-[#f8faf3] px-2 py-1 text-[11px] font-semibold text-[#171711] outline-none transition-colors hover:bg-white focus:border-[#9bad79] cursor-pointer"
                          >
                            <option value="open">Open</option>
                            <option value="in_progress">In Progress</option>
                            <option value="resolved">Resolved</option>
                          </select>
                        </div>
                      </td>

                      {/* Date Submitted */}
                      <td className="px-5 py-4 align-top whitespace-nowrap">
                        <span
                          className="text-xs text-[#677362]"
                          title={new Date(ticket.created_at).toLocaleString()}
                        >
                          {formatRelativeTime(ticket.created_at)}
                        </span>
                      </td>

                      {/* Actions */}
                      <td className="px-5 py-4 align-top whitespace-nowrap text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <a
                            href={`mailto:${ticket.email}?subject=Re: ${encodeURIComponent(
                              ticket.subject || 'LaterBox Feedback'
                            )}`}
                            title="Reply via Email"
                            className="inline-flex items-center justify-center rounded-lg border border-[#dde2d2] bg-white p-1.5 text-[#677362] hover:bg-[#edf0e4] hover:text-[#171711] transition-colors"
                          >
                            <Mail size={14} />
                          </a>

                          <Link
                            href={`/admin/feedback/${ticket.id}`}
                            className="inline-flex items-center gap-1 rounded-lg bg-[#e6edb0] px-2.5 py-1.5 text-xs font-bold text-[#171711] shadow-sm hover:bg-[#d8e39d] transition-colors"
                          >
                            <span>Details</span>
                            <ArrowUpRight size={13} />
                          </Link>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
