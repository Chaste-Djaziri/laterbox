// laterbox-web/src/components/admin/AdminFeedbackDetailView.tsx
'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft,
  ArrowUpRight,
  Check,
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Clock,
  Copy,
  ExternalLink,
  Laptop,
  Mail,
  MessageSquareText,
  Shield,
  Smartphone,
  Tag,
  User,
} from 'lucide-react';
import { useAdmin, type Ticket } from './AdminContext';

interface AdminFeedbackDetailViewProps {
  ticketId: string;
}

export function AdminFeedbackDetailView({ ticketId }: AdminFeedbackDetailViewProps) {
  const router = useRouter();
  const { operations, busyOperations, updateOperations } = useAdmin();
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const tickets = operations?.tickets ?? [];

  // Locate the target ticket and calculate index for Next/Prev
  const { ticket, prevTicket, nextTicket } = useMemo(() => {
    const index = tickets.findIndex((t) => t.id === ticketId);
    if (index === -1) {
      return { ticket: null, prevTicket: null, nextTicket: null };
    }
    return {
      ticket: tickets[index],
      prevTicket: index > 0 ? tickets[index - 1] : null,
      nextTicket: index < tickets.length - 1 ? tickets[index + 1] : null,
    };
  }, [tickets, ticketId]);

  const copyToClipboard = (text: string, key: string) => {
    if (typeof navigator !== 'undefined') {
      navigator.clipboard.writeText(text);
      setCopiedKey(key);
      setTimeout(() => setCopiedKey(null), 2000);
    }
  };

  const getCategoryBadge = (category: string) => {
    switch (category) {
      case 'problem':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-lg border border-amber-200 bg-amber-50 px-2.5 py-1 text-xs font-bold text-amber-800">
            <Tag size={13} />
            Bug / Issue
          </span>
        );
      case 'feedback':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-lg border border-[#cddca8] bg-[#edf0e2] px-2.5 py-1 text-xs font-bold text-[#435b34]">
            <Tag size={13} />
            Feedback / Idea
          </span>
        );
      case 'help':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-lg border border-sky-200 bg-sky-50 px-2.5 py-1 text-xs font-bold text-sky-800">
            <Tag size={13} />
            Support Request
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 rounded-lg border border-[#e4e0d5] bg-[#f7f5ee] px-2.5 py-1 text-xs font-bold text-[#677362]">
            <Tag size={13} />
            {category || 'General'}
          </span>
        );
    }
  };

  const getStatusBadge = (status: Ticket['status']) => {
    switch (status) {
      case 'open':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-amber-300 bg-amber-50 px-3 py-1 text-xs font-bold text-amber-900">
            <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
            Open
          </span>
        );
      case 'in_progress':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-sky-300 bg-sky-50 px-3 py-1 text-xs font-bold text-sky-900">
            <Clock size={13} className="text-sky-600" />
            In Progress
          </span>
        );
      case 'resolved':
        return (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-300 bg-emerald-50 px-3 py-1 text-xs font-bold text-emerald-900">
            <CheckCircle2 size={13} className="text-emerald-600" />
            Resolved
          </span>
        );
    }
  };

  if (!operations) {
    return (
      <div className="flex h-64 items-center justify-center rounded-2xl border border-[#e4e5d9] bg-white p-8 text-center">
        <p className="text-sm font-semibold text-[#677362]">Loading ticket information…</p>
      </div>
    );
  }

  if (!ticket) {
    return (
      <div className="rounded-2xl border border-[#e4e5d9] bg-white p-10 text-center shadow-sm">
        <div className="mx-auto flex h-14 w-14 items-center justify-center rounded-2xl bg-[#edf0e2] text-[#435b34]">
          <MessageSquareText size={28} />
        </div>
        <h2 className="mt-4 text-xl font-bold text-[#171711]">Ticket Not Found</h2>
        <p className="mx-auto mt-2 max-w-md text-sm text-[#677362]">
          This ticket ID ({ticketId}) may have been resolved, archived, or does not exist in the active queue.
        </p>
        <div className="mt-6">
          <Link
            href="/admin/feedback"
            className="inline-flex items-center gap-2 rounded-xl bg-[#e6edb0] px-4 py-2.5 text-xs font-bold text-[#171711] shadow-sm hover:bg-[#d8e39d] transition-colors"
          >
            <ArrowLeft size={16} />
            <span>Return to Feedback Inbox</span>
          </Link>
        </div>
      </div>
    );
  }

  const initial = ticket.email ? ticket.email[0].toUpperCase() : '?';

  return (
    <div className="space-y-6">
      {/* Top Header & Breadcrumb Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4 border-b border-[#e4e5d9] pb-5">
        <div className="flex items-center gap-3">
          <Link
            href="/admin/feedback"
            className="inline-flex items-center gap-1.5 rounded-xl border border-[#d9dece] bg-white px-3 py-1.5 text-xs font-bold text-[#171711] shadow-sm hover:bg-[#edf0e4] transition-colors"
          >
            <ArrowLeft size={15} />
            <span>Inbox</span>
          </Link>
          <div className="hidden sm:flex items-center gap-1.5 text-xs text-[#788470]">
            <span>/</span>
            <span className="font-mono text-[#171711] font-semibold">{ticket.id.slice(0, 13)}…</span>
          </div>
        </div>

        {/* Prev / Next ticket queue navigation */}
        <div className="flex items-center gap-2">
          {prevTicket && (
            <Link
              href={`/admin/feedback/${prevTicket.id}`}
              className="inline-flex items-center gap-1 rounded-xl border border-[#d9dece] bg-white px-3 py-1.5 text-xs font-bold text-[#171711] shadow-sm hover:bg-[#edf0e4] transition-colors"
              title={`Previous: ${prevTicket.subject}`}
            >
              <ChevronLeft size={15} />
              <span className="hidden sm:inline">Previous</span>
            </Link>
          )}

          {nextTicket && (
            <Link
              href={`/admin/feedback/${nextTicket.id}`}
              className="inline-flex items-center gap-1 rounded-xl border border-[#d9dece] bg-white px-3 py-1.5 text-xs font-bold text-[#171711] shadow-sm hover:bg-[#edf0e4] transition-colors"
              title={`Next: ${nextTicket.subject}`}
            >
              <span className="hidden sm:inline">Next</span>
              <ChevronRight size={15} />
            </Link>
          )}
        </div>
      </div>

      {/* Main Title & Status Bar Card */}
      <div className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
        <div className="flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
          <div className="space-y-2 max-w-3xl">
            <div className="flex flex-wrap items-center gap-2">
              {getStatusBadge(ticket.status)}
              {getCategoryBadge(ticket.category)}
              <span className="inline-flex items-center gap-1 rounded-lg border border-[#e4e0d5] bg-[#f7f5ee] px-2.5 py-1 text-xs font-bold capitalize text-[#677362]">
                {ticket.platform === 'ios' ? <Smartphone size={13} /> : <Laptop size={13} />}
                {ticket.platform || 'Web'}
              </span>
              {ticket.app_version && (
                <span className="rounded-lg border border-[#e4e0d5] bg-[#f7f5ee] px-2.5 py-1 text-xs font-mono font-bold text-[#677362]">
                  v{ticket.app_version}
                </span>
              )}
            </div>

            <h1 className="text-xl sm:text-2xl font-bold tracking-tight text-[#171711]">
              {ticket.subject || '(No subject provided)'}
            </h1>

            <p className="text-xs text-[#788470]">
              Submitted on {new Date(ticket.created_at).toLocaleString(undefined, { dateStyle: 'full', timeStyle: 'medium' })}
            </p>
          </div>

          {/* Quick Status Control Dropdown */}
          <div className="flex flex-col gap-2 shrink-0">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#677362]">
              Triage Status
            </span>
            <select
              aria-label="Change ticket status"
              value={ticket.status}
              disabled={busyOperations}
              onChange={(e) =>
                void updateOperations({
                  action: 'ticket',
                  ticketId: ticket.id,
                  status: e.target.value,
                })
              }
              className="rounded-xl border border-[#cddca8] bg-[#edf0e2] px-3.5 py-2 text-xs font-bold text-[#23351a] shadow-sm outline-none transition-colors hover:bg-[#e4ebd3] focus:border-[#7b9652] cursor-pointer"
            >
              <option value="open">Open (Needs attention)</option>
              <option value="in_progress">In Progress (Investigating)</option>
              <option value="resolved">Resolved (Complete)</option>
            </select>
          </div>
        </div>
      </div>

      {/* 2-Column Main Content & Contact Metadata */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column (Message content & Email reply tools) - 2 Cols */}
        <div className="lg:col-span-2 space-y-6">
          {/* Main Message Card */}
          <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between border-b border-[#f0ede5] pb-4">
              <h2 className="text-sm font-bold text-[#171711]">Message Details</h2>
              <button
                type="button"
                onClick={() => copyToClipboard(ticket.message, 'message')}
                className="inline-flex items-center gap-1 rounded-lg border border-[#dde2d2] bg-[#fbfcf9] px-2.5 py-1 text-xs font-semibold text-[#677362] hover:bg-white hover:text-[#171711] transition-colors"
              >
                {copiedKey === 'message' ? (
                  <>
                    <Check size={13} className="text-emerald-600" />
                    <span>Copied!</span>
                  </>
                ) : (
                  <>
                    <Copy size={13} />
                    <span>Copy text</span>
                  </>
                )}
              </button>
            </div>

            <div className="mt-5 rounded-2xl border border-[#e4e0d5] bg-[#fbfcf9] p-5 text-sm sm:text-base leading-relaxed text-[#171711] whitespace-pre-wrap font-sans selection:bg-[#e6edb0]">
              {ticket.message}
            </div>
          </section>

          {/* Email Reply Card */}
          <section className="rounded-2xl border border-[#e4e5d9] bg-white p-6 shadow-sm">
            <div className="flex items-center justify-between border-b border-[#f0ede5] pb-4">
              <div className="flex items-center gap-2">
                <Mail size={18} className="text-[#435b34]" />
                <h2 className="text-sm font-bold text-[#171711]">Reply to Sender</h2>
              </div>
              <span className="text-xs text-[#788470]">Direct contact</span>
            </div>

            <p className="mt-4 text-xs text-[#677362] leading-relaxed">
              Launch your system email client to write back to this user directly with a pre-formatted subject header referencing this submission.
            </p>

            <div className="mt-4 flex flex-wrap items-center gap-3">
              <a
                href={`mailto:${ticket.email}?subject=Re: ${encodeURIComponent(ticket.subject || 'LaterBox Support')}`}
                className="inline-flex items-center gap-2 rounded-xl bg-[#171711] px-4 py-2.5 text-xs font-bold text-white shadow-sm hover:bg-[#30372a] transition-colors"
              >
                <Mail size={15} />
                <span>Launch Email Client ({ticket.email})</span>
                <ArrowUpRight size={14} />
              </a>

              <button
                type="button"
                onClick={() => copyToClipboard(ticket.email, 'reply-email')}
                className="inline-flex items-center gap-1.5 rounded-xl border border-[#d9dece] bg-white px-3.5 py-2.5 text-xs font-bold text-[#171711] shadow-sm hover:bg-[#edf0e4] transition-colors"
              >
                {copiedKey === 'reply-email' ? (
                  <>
                    <Check size={14} className="text-emerald-600" />
                    <span>Email Copied</span>
                  </>
                ) : (
                  <>
                    <Copy size={14} />
                    <span>Copy Address</span>
                  </>
                )}
              </button>
            </div>
          </section>
        </div>

        {/* Right Column (Sender details & Technical metadata) - 1 Col */}
        <div className="space-y-6">
          {/* Sender & Account Information */}
          <section className="rounded-2xl border border-[#e4e5d9] bg-white p-5 shadow-sm">
            <h2 className="text-xs font-bold uppercase tracking-wider text-[#677362] border-b border-[#f0ede5] pb-3">
              Contact & User Profile
            </h2>

            <div className="mt-4 flex items-center gap-3">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-[#edf0e2] text-sm font-black text-[#435b34]">
                {initial}
              </div>
              <div className="min-w-0">
                <p className="font-bold text-sm text-[#171711] truncate" title={ticket.email}>
                  {ticket.email}
                </p>
                <p className="text-xs text-[#788470]">
                  {ticket.user_id ? 'Authenticated Member' : 'Guest / Visitor'}
                </p>
              </div>
            </div>

            <div className="mt-5 space-y-3 pt-3 border-t border-[#f0ede5] text-xs">
              <div>
                <p className="text-[11px] font-bold text-[#677362]">Email Address</p>
                <div className="mt-1 flex items-center justify-between gap-2 rounded-xl bg-[#fbfcf9] border border-[#e4e0d5] p-2">
                  <span className="font-semibold text-[#171711] truncate">{ticket.email}</span>
                  <button
                    type="button"
                    onClick={() => copyToClipboard(ticket.email, 'side-email')}
                    className="text-[#788470] hover:text-[#171711] p-0.5"
                    title="Copy email"
                  >
                    {copiedKey === 'side-email' ? <Check size={13} className="text-emerald-600" /> : <Copy size={13} />}
                  </button>
                </div>
              </div>

              <div>
                <p className="text-[11px] font-bold text-[#677362]">User ID</p>
                <div className="mt-1 flex items-center justify-between gap-2 rounded-xl bg-[#fbfcf9] border border-[#e4e0d5] p-2">
                  <span className="font-mono text-[11px] text-[#171711] truncate">
                    {ticket.user_id || 'Not linked to an account'}
                  </span>
                  {ticket.user_id && (
                    <button
                      type="button"
                      onClick={() => copyToClipboard(ticket.user_id!, 'user-id')}
                      className="text-[#788470] hover:text-[#171711] p-0.5"
                      title="Copy user ID"
                    >
                      {copiedKey === 'user-id' ? <Check size={13} className="text-emerald-600" /> : <Copy size={13} />}
                    </button>
                  )}
                </div>
              </div>

              {ticket.user_id && (
                <div className="pt-2">
                  <Link
                    href={`/admin/users`}
                    className="inline-flex w-full items-center justify-center gap-1.5 rounded-xl border border-[#dde2d2] bg-[#f9faf5] py-2 text-xs font-bold text-[#171711] hover:bg-[#edf0e4] transition-colors"
                  >
                    <User size={13} />
                    <span>Search Account in Users Table</span>
                  </Link>
                </div>
              )}
            </div>
          </section>

          {/* Technical Diagnostics */}
          <section className="rounded-2xl border border-[#e4e5d9] bg-white p-5 shadow-sm">
            <h2 className="text-xs font-bold uppercase tracking-wider text-[#677362] border-b border-[#f0ede5] pb-3">
              Diagnostics & Submission Info
            </h2>

            <div className="mt-4 space-y-3 text-xs">
              <div className="flex items-center justify-between">
                <span className="text-[#677362]">Platform:</span>
                <span className="font-bold text-[#171711] capitalize">{ticket.platform || 'Web'}</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-[#677362]">App Version:</span>
                <span className="font-mono font-bold text-[#171711]">{ticket.app_version || 'None reported'}</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-[#677362]">Category:</span>
                <span className="font-bold text-[#171711] capitalize">{ticket.category}</span>
              </div>

              <div className="flex items-center justify-between">
                <span className="text-[#677362]">Status:</span>
                <span className="font-bold text-[#171711] capitalize">{ticket.status.replace('_', ' ')}</span>
              </div>

              <div className="border-t border-[#f0ede5] pt-3">
                <p className="text-[11px] font-bold text-[#677362]">Full Ticket ID</p>
                <div className="mt-1 flex items-center justify-between gap-2 rounded-xl bg-[#fbfcf9] border border-[#e4e0d5] p-2">
                  <span className="font-mono text-[10px] text-[#171711] truncate">{ticket.id}</span>
                  <button
                    type="button"
                    onClick={() => copyToClipboard(ticket.id, 'ticket-id')}
                    className="text-[#788470] hover:text-[#171711] p-0.5"
                    title="Copy ticket ID"
                  >
                    {copiedKey === 'ticket-id' ? <Check size={13} className="text-emerald-600" /> : <Copy size={13} />}
                  </button>
                </div>
              </div>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
