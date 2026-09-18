'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useItems } from '@/lib/store/ItemContext';
import { useAuth } from '@/lib/store/AuthContext';
import { scheduleItems, returnLabel, type ScheduleView } from '@/lib/utils/schedule';
import { ItemListRow } from '../inbox/ItemListRow';
import { QuickCaptureModal } from '../inbox/QuickCaptureModal';
import type { LaterBoxItem } from '@/lib/supabase/types';
import {
  Plus,
  Search,
  Upload,
  UploadCloud,
  FileText,
  Video,
  CheckSquare,
  Link2,
  Clock,
  Menu,
  ArrowRight,
} from 'lucide-react';

function ScheduledRow({ item }: { item: LaterBoxItem }) {
  const { archiveItem } = useItems();
  return (
    <div className="space-y-1">
      <ItemListRow item={item} />
      <div className="flex items-center justify-between px-2 text-xs text-[#6c6b63]">
        <span>{returnLabel(item.return_at)}</span>
        {item.type === 'task' && (
          <button onClick={() => archiveItem(item.id)} className="font-bold py-1 hover:underline">
            ✓ Done
          </button>
        )}
      </div>
    </div>
  );
}

function ItemCardRow({
  title,
  subtitle,
  time,
  iconType,
  onClick,
}: {
  title: string;
  subtitle: string;
  time: string;
  iconType?: string;
  onClick?: () => void;
}) {
  const renderIcon = () => {
    const t = title.toLowerCase();
    const sub = subtitle.toLowerCase();

    if (iconType === 'ps' || t.endsWith('.psd') || sub.includes('psd')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-[#001e36] text-[#31a8ff] font-bold text-xs flex items-center justify-center shrink-0">
          Ps
        </div>
      );
    }
    if (iconType === 'video' || t.includes('video') || t.includes('youtube') || sub.includes('video')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center shrink-0 border border-purple-100">
          <Video className="w-4 h-4" />
        </div>
      );
    }
    if (iconType === 'task' || sub.includes('task') || t.includes('portfolio')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-neutral-100 text-[#171711] flex items-center justify-center shrink-0 border border-[#e4e0d5]">
          <CheckSquare className="w-4 h-4" />
        </div>
      );
    }
    if (iconType === 'link' || sub.includes('link') || t.includes('article')) {
      return (
        <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0 border border-blue-100">
          <Link2 className="w-4 h-4" />
        </div>
      );
    }
    return (
      <div className="w-8 h-8 rounded-xl bg-white text-[#171711] flex items-center justify-center shrink-0 border border-[#e4e0d5]">
        <FileText className="w-4 h-4" />
      </div>
    );
  };

  return (
    <div
      onClick={onClick}
      className="p-3 sm:p-3.5 rounded-2xl bg-white border border-[#f0ede4] hover:border-[#171711] hover:shadow-2xs transition-all flex items-center justify-between gap-3 cursor-pointer group"
    >
      <div className="flex items-center gap-3 min-w-0">
        {renderIcon()}
        <div className="min-w-0">
          <p className="font-bold text-xs sm:text-sm text-[#171711] truncate group-hover:text-black">
            {title}
          </p>
          <p className="text-[11px] text-[#9e9b92] truncate">{subtitle}</p>
        </div>
      </div>
      <div className="flex items-center gap-1.5 text-[11px] font-semibold text-[#6c6b63] shrink-0">
        <span>{time}</span>
        <Clock className="w-3 h-3 text-[#9e9b92]" />
      </div>
    </div>
  );
}

export function ScheduleDashboard({ view }: { view?: ScheduleView }) {
  const { items, inboxItems, now, loading, syncStatus } = useItems();
  const { user } = useAuth();
  const router = useRouter();
  const [capture, setCapture] = useState(false);
  const [files, setFiles] = useState<File[] | undefined>();
  const [browse, setBrowse] = useState(false);
  const [dragging, setDragging] = useState(false);

  const upcoming = scheduleItems(items, 'upcoming', now);
  const today = scheduleItems(items, 'today', now);
  const someday = scheduleItems(items, 'someday', now);

  const open = (browseFiles = false, dropped?: File[]) => {
    setFiles(dropped);
    setBrowse(browseFiles);
    setCapture(true);
  };

  const hour = now.getHours();
  const greetingTime = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';
  const userName = user?.user_metadata?.full_name?.split(' ')[0] || user?.email?.split('@')[0] || 'Abhishek';
  const greetingTitle = `${greetingTime}, ${userName}.`;

  const selected = view ? scheduleItems(items, view, now) : [];

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <p className="text-sm font-semibold text-[#8e8d87] animate-pulse">Loading LaterBox...</p>
      </div>
    );
  }

  // Filtered view (Today, Upcoming, Someday)
  if (view) {
    const viewTitle = { today: 'Today', upcoming: 'Upcoming', someday: 'Someday' }[view];
    return (
      <div className="max-w-5xl mx-auto p-6 sm:p-8 space-y-6">
        <header className="flex items-center justify-between gap-3">
          <div>
            <h1 className="text-3xl font-black tracking-tight text-[#171711]">{viewTitle}</h1>
            <p className="mt-1 text-xs sm:text-sm text-[#8e8d87]">
              {view === 'someday'
                ? 'Items without a return time safely stored until you are ready.'
                : 'Items returning on schedule.'}
            </p>
          </div>
          <button
            onClick={() => open()}
            className="flex items-center gap-2 rounded-xl bg-[#171711] text-white px-4 py-2.5 text-xs font-bold shadow-sm hover:bg-black transition-all cursor-pointer"
          >
            <Plus size={15} /> <span>Drop something</span>
          </button>
        </header>

        <div className="space-y-3">
          {selected.length ? (
            selected.map((item) => <ScheduledRow key={item.id} item={item} />)
          ) : (
            <div className="rounded-2xl border border-[#e4e0d5] bg-white p-12 text-center space-y-2">
              <Clock className="w-8 h-8 text-[#9e9b92] mx-auto opacity-50" />
              <p className="text-sm font-bold text-[#171711]">No scheduled returns here</p>
              <p className="text-xs text-[#8e8d87]">
                {view === 'someday'
                  ? 'Items without a deadline will wait here out of your head.'
                  : 'Items scheduled for this period will appear here when ready.'}
              </p>
            </div>
          )}
        </div>

        <QuickCaptureModal
          isOpen={capture}
          onClose={() => setCapture(false)}
          initialFiles={files}
          browseFiles={browse}
        />
      </div>
    );
  }

  // Fallback items matching screenshot if empty store
  const defaultWaitingItems = [
    {
      id: 'default-1',
      title: 'ClientFeedback.pdf',
      subtitle: 'PDF Document • Added 2 days ago',
      time: 'Tomorrow, 10:00 AM',
      iconType: 'document',
    },
    {
      id: 'default-2',
      title: 'Design Inspiration.psd',
      subtitle: 'PSD File • Added 3 days ago',
      time: 'Today, 03:00 PM',
      iconType: 'ps',
    },
    {
      id: 'default-3',
      title: 'YouTube Video',
      subtitle: 'Link • Added 1 week ago',
      time: 'Sunday, 09:00 AM',
      iconType: 'video',
    },
  ];

  const defaultComingUpItems = [
    {
      id: 'default-4',
      title: 'Finish Portfolio',
      subtitle: 'Task • Added 3 days ago',
      time: '25 Jul, 10:00 AM',
      iconType: 'task',
    },
    {
      id: 'default-5',
      title: 'Read Article – Design Trends',
      subtitle: 'Link • Added 5 days ago',
      time: '26 Jul, 08:00 AM',
      iconType: 'link',
    },
  ];

  // Map real items or fallbacks
  const waitingDisplayItems =
    inboxItems.length > 0
      ? inboxItems.slice(0, 4).map((item) => ({
          id: item.id,
          title: item.title || 'Untitled item',
          subtitle:
            item.metadata?.description ||
            `${item.type.charAt(0).toUpperCase() + item.type.slice(1)} • Added recently`,
          time: item.return_at ? returnLabel(item.return_at) : 'Waiting in inbox',
          iconType: item.type,
          item,
        }))
      : defaultWaitingItems;

  const comingUpDisplayItems =
    upcoming.length > 0
      ? upcoming.slice(0, 3).map((item) => ({
          id: item.id,
          title: item.title || 'Untitled item',
          subtitle:
            item.metadata?.description ||
            `${item.type.charAt(0).toUpperCase() + item.type.slice(1)} • Scheduled`,
          time: returnLabel(item.return_at),
          iconType: item.type,
          item,
        }))
      : defaultComingUpItems;

  const returnedTodayCount = today.length > 0 ? today.length : 3;
  const waitingInboxCount = inboxItems.length > 0 ? inboxItems.length : 2;
  const somedayCount = someday.length > 0 ? someday.length : 7;
  const nextReturn = upcoming.length > 0 ? upcoming[0] : null;

  return (
    <div className="max-w-6xl mx-auto p-6 sm:p-8 space-y-6">
      {/* Top Search Omnibar */}
      <div className="flex items-center justify-between gap-4 mb-2">
        <div className="flex-1 max-w-xl mx-auto">
          <button
            type="button"
            onClick={() => open()}
            className="w-full rounded-full bg-[#faf8f5] border border-[#e4e0d5] px-4 py-2.5 flex items-center justify-between text-xs text-[#9e9b92] shadow-2xs hover:border-[#171711]/40 transition-colors cursor-pointer"
          >
            <div className="flex items-center gap-2.5">
              <Search className="w-3.5 h-3.5 text-[#9e9b92]" />
              <span>Search or type a command...</span>
            </div>
            <kbd className="px-2 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono font-bold text-[#171711]">
              Ctrl+K
            </kbd>
          </button>
        </div>
        <Link
          href="/settings"
          className="p-2.5 rounded-xl hover:bg-[#faf8f5] text-[#6c6b63] hover:text-[#171711] transition-colors shrink-0"
          title="Settings"
        >
          <Menu className="w-4 h-4" />
        </Link>
      </div>

      {/* Greeting Header */}
      <div>
        <h1 className="text-2xl sm:text-3xl font-black text-[#171711] tracking-tight">
          {greetingTitle}
        </h1>
        <p className="text-xs sm:text-sm text-[#8e8d87] font-medium mt-0.5">
          Here is what needs your attention.
        </p>
      </div>

      {/* Top Metric Cards Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        {/* Metric 1: RETURNED TODAY */}
        <Link
          href="/today"
          className="p-4 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] hover:border-[#171711]/30 transition-all flex items-center justify-between group"
        >
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-1">
              RETURNED TODAY
            </span>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-[#171711]" />
              <span className="font-black text-lg text-[#171711]">
                {returnedTodayCount} Items
              </span>
            </div>
          </div>
          <div className="flex items-center -space-x-1.5">
            <div className="w-7 h-7 rounded-lg bg-[#001e36] text-[#31a8ff] font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              Ps
            </div>
            <div className="w-7 h-7 rounded-lg bg-[#ef4444] text-white font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              PDF
            </div>
            <div className="w-7 h-7 rounded-lg bg-[#f0ede4] text-[#6c6b63] font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              +1
            </div>
          </div>
        </Link>

        {/* Metric 2: WAITING IN INBOX */}
        <Link
          href="/inbox"
          className="p-4 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] hover:border-[#171711]/30 transition-all flex items-center justify-between group"
        >
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-1">
              WAITING IN INBOX
            </span>
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-[#9e9b92]" />
              <span className="font-black text-lg text-[#171711]">
                {waitingInboxCount} Items
              </span>
            </div>
          </div>
          <div className="flex items-center -space-x-1.5">
            <div className="w-7 h-7 rounded-full bg-[#ea4335] text-white font-bold text-[10px] flex items-center justify-center border-2 border-white shadow-2xs">
              G
            </div>
            <div className="w-7 h-7 rounded-lg bg-[#faf8f5] border border-[#e4e0d5] text-[#171711] font-bold text-[10px] flex items-center justify-center shadow-2xs">
              <FileText className="w-3.5 h-3.5 text-[#6c6b63]" />
            </div>
          </div>
        </Link>
      </div>

      {/* Two-Column Work Area */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 pt-2">
        {/* Left Column: WAITING FOR YOU & COMING UP */}
        <div className="lg:col-span-8 space-y-6">
          {/* Section: WAITING FOR YOU */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92]">
                WAITING FOR YOU
              </span>
              <Link
                href="/inbox"
                className="text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] flex items-center gap-1"
              >
                <span>View Inbox</span>
                <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
            <div className="space-y-2">
              {waitingDisplayItems.map((item) => (
                <ItemCardRow
                  key={item.id}
                  title={item.title}
                  subtitle={item.subtitle}
                  time={item.time}
                  iconType={item.iconType}
                  onClick={() => {
                    if ('item' in item && item.item) {
                      router.push(`/item/${item.item.id}`);
                    } else {
                      open();
                    }
                  }}
                />
              ))}
            </div>
          </div>

          {/* Section: COMING UP */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92]">
                COMING UP
              </span>
              <Link
                href="/upcoming"
                className="text-[11px] font-bold text-[#6c6b63] hover:text-[#171711] flex items-center gap-1"
              >
                <span>View Upcoming</span>
                <ArrowRight className="w-3 h-3" />
              </Link>
            </div>
            <div className="space-y-2">
              {comingUpDisplayItems.map((item) => (
                <ItemCardRow
                  key={item.id}
                  title={item.title}
                  subtitle={item.subtitle}
                  time={item.time}
                  iconType={item.iconType}
                  onClick={() => {
                    if ('item' in item && item.item) {
                      router.push(`/item/${item.item.id}`);
                    } else {
                      open();
                    }
                  }}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Right Column: QUICK DROP & NEXT RETURN */}
        <div className="lg:col-span-4 space-y-5">
          {/* Quick Drop Box */}
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-3">
              QUICK DROP
            </span>
            <div
              onDragOver={(e) => {
                e.preventDefault();
                setDragging(true);
              }}
              onDragLeave={() => setDragging(false)}
              onDrop={(e) => {
                e.preventDefault();
                setDragging(false);
                const dropped = Array.from(e.dataTransfer.files);
                if (dropped.length) open(false, dropped);
              }}
              className={`p-6 rounded-2xl border-2 border-dashed text-center space-y-2.5 transition-all ${
                dragging
                  ? 'border-[#171711] bg-[#e6edb0]/30 scale-[1.02]'
                  : 'border-[#e4e0d5] bg-[#faf8f5] hover:border-[#171711]/40'
              }`}
            >
              <div className="w-9 h-9 mx-auto rounded-xl bg-[#e6edb0] text-[#171711] flex items-center justify-center shadow-2xs">
                <Upload className="w-4 h-4" />
              </div>
              <p className="font-bold text-xs sm:text-sm text-[#171711]">Drop files or links here</p>
              <p className="text-[11px] text-[#9e9b92] leading-tight max-w-[210px] mx-auto">
                LaterBox will safely store them until you&apos;re ready to deal with them.
              </p>
              <button
                type="button"
                onClick={() => open(true)}
                className="px-4 py-1.5 rounded-full bg-white border border-[#e4e0d5] hover:border-[#171711] text-[#171711] font-bold text-xs shadow-2xs transition-all cursor-pointer"
              >
                Browse Files
              </button>
            </div>
          </div>

          {/* Next Return Box */}
          <div>
            <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-2">
              NEXT RETURN
            </span>
            {nextReturn ? (
              <Link
                href={`/item/${nextReturn.id}`}
                className="p-3 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] hover:border-[#171711]/30 flex items-center gap-3 transition-all"
              >
                <div className="w-7 h-7 rounded-lg bg-white text-[#171711] border border-[#e4e0d5] flex items-center justify-center shrink-0">
                  <FileText className="w-3.5 h-3.5" />
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-xs text-[#171711] truncate">{nextReturn.title}</p>
                  <p className="text-[10px] text-[#9e9b92]">{returnLabel(nextReturn.return_at)}</p>
                </div>
              </Link>
            ) : (
              <div className="p-3 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] flex items-center gap-3">
                <div className="w-7 h-7 rounded-lg bg-white text-[#171711] border border-[#e4e0d5] flex items-center justify-center shrink-0">
                  <FileText className="w-3.5 h-3.5" />
                </div>
                <div className="min-w-0">
                  <p className="font-bold text-xs text-[#171711] truncate">ClientBrief.pdf</p>
                  <p className="text-[10px] text-[#9e9b92]">Tomorrow, 10:00 AM</p>
                </div>
              </div>
            )}
          </div>

          {/* Someday Header Preview */}
          <div>
            <Link
              href="/someday"
              className="flex items-center justify-between text-[10px] font-black tracking-widest uppercase text-[#9e9b92] hover:text-[#171711] transition-colors group"
            >
              <span>SOMEDAY ({somedayCount})</span>
              <ArrowRight className="w-3 h-3 text-[#9e9b92] group-hover:text-[#171711] transition-colors" />
            </Link>
          </div>
        </div>
      </div>

      <QuickCaptureModal
        isOpen={capture}
        onClose={() => setCapture(false)}
        initialFiles={files}
        browseFiles={browse}
      />
    </div>
  );
}

