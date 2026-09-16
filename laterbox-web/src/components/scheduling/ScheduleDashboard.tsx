'use client';
import { useState } from 'react';
import Link from 'next/link';
import { useItems } from '@/lib/store/ItemContext';
import { scheduleItems, returnLabel, type ScheduleView } from '@/lib/utils/schedule';
import { ItemListRow } from '../inbox/ItemListRow';
import { QuickCaptureModal } from '../inbox/QuickCaptureModal';
import type { LaterBoxItem } from '@/lib/supabase/types';
import { Plus, Search, UploadCloud, ArrowRight } from 'lucide-react';

function ScheduledRow({ item }: { item: LaterBoxItem }) {
  const { archiveItem } = useItems();
  return <div className="space-y-1"><ItemListRow item={item} />
    <div className="flex items-center justify-between px-2 text-xs text-[#6c6b63]">
      <span>{returnLabel(item.return_at)}</span>
      {item.type === 'task' && <button onClick={() => archiveItem(item.id)} className="font-bold py-1">✓ Done</button>}
    </div></div>;
}
function Panel({ title, children }: { title: string; children: React.ReactNode }) {
  return <section className="space-y-3"><h2 className="text-sm font-extrabold text-[#6c6b63] uppercase tracking-wide">{title}</h2>
    <div className="rounded-2xl border border-[#e4e0d5] bg-white p-5 space-y-4">{children}</div></section>;
}
export function ScheduleDashboard({ view }: { view?: ScheduleView }) {
  const { items, inboxItems, now, loading, syncStatus } = useItems();
  const [capture, setCapture] = useState(false);
  const [files, setFiles] = useState<File[] | undefined>();
  const [browse, setBrowse] = useState(false);
  const [dragging, setDragging] = useState(false);
  const upcoming = scheduleItems(items, 'upcoming', now);
  const today = scheduleItems(items, 'today', now);
  const someday = scheduleItems(items, 'someday', now);
  const open = (browseFiles = false, dropped?: File[]) => { setFiles(dropped); setBrowse(browseFiles); setCapture(true); };
  const title = view ? { today: 'Today', upcoming: 'Upcoming', someday: 'Someday' }[view] : now.getHours() < 12 ? 'Good morning.' : now.getHours() < 18 ? 'Good afternoon.' : 'Good evening.';
  const selected = view ? scheduleItems(items, view, now) : [];
  if (loading) return <p className="p-8 text-sm text-[#6c6b63]">Loading your items…</p>;
  return <div className="max-w-7xl mx-auto p-6 sm:p-8 space-y-7">
    <header className="flex items-center justify-between gap-3"><div>
      <h1 className="text-3xl font-black tracking-tight">{title}</h1>
      <p className="mt-2 text-sm text-[#6c6b63]">{view ? 'Safely stored until you’re ready.' : 'Drop it. Choose when. Forget about it. It comes back.'}</p>
    </div><Link href="/search" aria-label="Search" className="p-3 rounded-xl border border-[#e4e0d5]"><Search size={20} /></Link></header>
    {syncStatus === 'error' && <p role="status" className="text-sm text-[#6c6b63]">Cloud sync is unavailable. Your local items are still here; retry using the sync control.</p>}
    {view ? <>
      <button onClick={() => open()} className="flex items-center gap-2 rounded-xl bg-[#171711] text-white px-4 py-2.5 text-sm font-bold"><Plus size={16} /> Drop something</button>
      <div className="space-y-4">{selected.length ? selected.map(item => <ScheduledRow key={item.id} item={item} />)
        : <p className="rounded-2xl border border-[#e4e0d5] bg-white p-8 text-sm text-[#6c6b63]">{view === 'someday' ? 'Items without a return time will wait here.' : 'No returns scheduled here yet.'}</p>}</div>
    </> : <>
      <div className="grid sm:grid-cols-3 gap-4">{[
        ['Waiting in Inbox', inboxItems.length, '/inbox'], ['Returning today', today.length, '/today'], ['Upcoming', upcoming.length, '/upcoming'],
      ].map(([label, count, href]) => <Link key={href} href={String(href)} className="rounded-2xl border border-[#e4e0d5] bg-white p-5 hover:border-[#171711]">
        <p className="text-xs font-bold uppercase text-[#6c6b63]">{label}</p><p className="mt-3 text-2xl font-black">{count} items</p></Link>)}</div>
      <div className="grid lg:grid-cols-[minmax(0,2fr)_minmax(0,1fr)] gap-7">
        <div className="space-y-7"><Panel title="Ready for you">
          {inboxItems.length ? inboxItems.slice(0, 5).map(item => <ScheduledRow key={item.id} item={item} />)
            : <p className="text-sm text-[#6c6b63]">You’re all clear. Items return here when it’s time.</p>}
          <Link href="/inbox" className="flex items-center gap-2 text-sm font-bold">View Inbox ({inboxItems.length}) <ArrowRight size={16} /></Link>
        </Panel><Panel title="Coming up">
          {upcoming.length ? upcoming.slice(0, 3).map(item => <ScheduledRow key={item.id} item={item} />)
            : <p className="text-sm text-[#6c6b63]">Choose a return time to see what’s coming up.</p>}
          <Link href="/upcoming" className="flex items-center gap-2 text-sm font-bold">View upcoming ({upcoming.length}) <ArrowRight size={16} /></Link>
        </Panel></div>
        <div className="space-y-7"><div onDragOver={event => { event.preventDefault(); setDragging(true); }}
          onDragLeave={() => setDragging(false)} onDrop={event => { event.preventDefault(); setDragging(false);
            const dropped = Array.from(event.dataTransfer.files); if (dropped.length) open(false, dropped); }}
          className={dragging ? 'rounded-2xl ring-2 ring-[#171711]' : ''}>
          <Panel title="Quick Drop"><div className="flex flex-col items-center gap-4 py-4 text-center">
            <UploadCloud size={40} /><p className="text-sm text-[#6c6b63]">Drop files here, or save a link, task, or idea.</p>
            <button onClick={() => open()} className="rounded-xl bg-[#171711] text-white px-4 py-2.5 text-sm font-bold">Drop something</button>
            <button onClick={() => open(true)} className="text-sm font-bold underline">Browse Files</button>
          </div></Panel></div>
          <Panel title="Next return">{upcoming.length ? <ScheduledRow item={upcoming[0]} /> : <p className="text-sm text-[#6c6b63]">No scheduled returns yet.</p>}</Panel>
          <Panel title="Someday"><p className="text-sm text-[#6c6b63]">{someday.length} items safely out of your head.</p><Link href="/someday" className="text-sm font-bold">Open Someday →</Link></Panel>
        </div>
      </div>
    </>}
    <QuickCaptureModal isOpen={capture} onClose={() => setCapture(false)} initialFiles={files} browseFiles={browse} />
  </div>;
}
