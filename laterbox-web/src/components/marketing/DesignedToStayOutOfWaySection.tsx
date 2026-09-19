'use client';

import React, { useState } from 'react';
import {
  Home,
  Inbox,
  Clock,
  Calendar,
  Archive,
  Grid,
  History,
  Search,
  Menu,
  Upload,
  FileText,
  Video,
  CheckSquare,
  Link2,
} from 'lucide-react';
import { ResponsivePreviewContainer } from '@/components/marketing/ResponsivePreviewContainer';

// Stylized LaterBox Inbox/Tray Icon adhering to Web Theme palette
function LaterBoxBrandLogo({ className = 'w-6 h-6' }: { className?: string }) {
  return (
    <div className={`relative ${className} shrink-0 flex items-center justify-center select-none`}>
      <svg
        viewBox="0 0 72 64"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="w-full h-full drop-shadow-2xs"
      >
        {/* Envelope back container */}
        <rect x="12" y="14" width="48" height="40" rx="8" fill="#2e2e28" />

        {/* Paper sheet sticking out */}
        <rect x="18" y="8" width="36" height="22" rx="4" fill="#faf8f2" />
        <line x1="24" y1="14" x2="48" y2="14" stroke="#e4e0d5" strokeWidth="2.5" strokeLinecap="round" />
        <line x1="24" y1="20" x2="38" y2="20" stroke="#e4e0d5" strokeWidth="2.5" strokeLinecap="round" />

        {/* Envelope front fold / pouch */}
        <path
          d="M12 28L36 43L60 28V46C60 50.4183 56.4183 54 52 54H20C15.5817 54 12 50.4183 12 46V28Z"
          fill="#171711"
        />

        {/* Crease line */}
        <path d="M12 48L26 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />
        <path d="M60 48L46 36" stroke="#000000" strokeWidth="1.5" strokeOpacity="0.3" />

        {/* Circular Clock Badge in bottom right with web theme accent */}
        <circle cx="52" cy="46" r="10.5" fill="#e6edb0" stroke="#171711" strokeWidth="2" />
        <circle cx="52" cy="46" r="1.5" fill="#171711" />
        <line x1="52" y1="46" x2="52" y2="40.5" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
        <line x1="52" y1="46" x2="56.5" y2="46" stroke="#171711" strokeWidth="2" strokeLinecap="round" />
      </svg>
    </div>
  );
}

export function DesignedToStayOutOfWaySection() {
  const [activeTab, setActiveTab] = useState<string>('Home');
  const [droppedToast, setDroppedToast] = useState<string | null>(null);

  const triggerAdd = () => {
    setDroppedToast('Quick capture activated! Press ⌥ Space anytime.');
    setTimeout(() => setDroppedToast(null), 3500);
  };

  const navItems = [
    { name: 'Home', icon: Home, count: null },
    { name: 'Inbox', icon: Inbox, count: 2 },
    { name: 'Today', icon: Clock, count: 3 },
    { name: 'Upcoming', icon: Calendar, count: 5 },
    { name: 'Someday', icon: Archive, count: 7 },
  ];

  return (
    <section className="bg-[#faf8f5] text-[#171711] py-24 sm:py-36 px-4 sm:px-6 lg:px-8 border-t border-[#e4e0d5] select-none overflow-hidden">
      <div className="max-w-6xl mx-auto text-center">
        {/* Headline */}
        <h2 className="leading-none text-center">
          <span className="block text-5xl sm:text-7xl lg:text-8xl font-black text-[#171711] tracking-tight">
            Designed to stay
          </span>
          <span className="block text-5xl sm:text-7xl lg:text-8xl font-serif italic text-[#171711] font-normal lowercase tracking-normal mt-1 sm:mt-2">
            out of your way.
          </span>
        </h2>

        {/* Dashboard Mockup Container */}
        <ResponsivePreviewContainer
          baseWidth={1080}
          className="max-w-6xl mx-auto mt-14 sm:mt-18"
        >
          <div className="w-full rounded-[32px] bg-white border border-[#e4e0d5] shadow-2xl overflow-hidden text-left flex flex-row select-none">
            {/* ============================================================ */}
            {/* Left Sidebar */}
            {/* ============================================================ */}
            <aside className="w-64 border-r border-[#f0ede4] p-5 bg-[#faf8f2] flex flex-col justify-between shrink-0">
              <div>
                {/* Brand Logo Header */}
                <div className="flex items-center gap-2.5 px-2 py-1 mb-5">
                  <LaterBoxBrandLogo className="w-6 h-6" />
                  <span className="font-black text-base tracking-tight text-[#171711]">
                    LaterBox
                  </span>
                </div>

              {/* Primary Add Button styled in Web Theme Primary (#171711) */}
              <button
                type="button"
                onClick={triggerAdd}
                className="w-full bg-[#171711] hover:bg-black text-white font-black text-xs py-3 px-3.5 rounded-xl shadow-xs tracking-wider flex items-center justify-center gap-1.5 transition-all active:scale-95 cursor-pointer mb-6"
              >
                <span>+ ADD TO LATERBOX</span>
              </button>

              {/* Main Nav Items */}
              <nav className="space-y-1">
                {navItems.map((item) => {
                  const isActive = activeTab === item.name;
                  const Icon = item.icon;

                  return (
                    <button
                      key={item.name}
                      type="button"
                      onClick={() => setActiveTab(item.name)}
                      className={`w-full flex items-center justify-between px-3 py-2 rounded-xl text-xs font-bold transition-all relative cursor-pointer ${
                        isActive
                          ? 'bg-white border border-[#e4e0d5]/80 text-[#171711] shadow-2xs'
                          : 'text-[#6c6b63] hover:text-[#171711] hover:bg-[#f0ede4]/60'
                      }`}
                    >
                      {isActive && (
                        <span className="w-1.5 h-6 bg-[#171711] rounded-r-md absolute left-0 top-1/2 -translate-y-1/2" />
                      )}
                      <div className="flex items-center gap-2.5">
                        <Icon className={`w-4 h-4 ${isActive ? 'text-[#171711]' : 'text-[#9e9b92]'}`} />
                        <span>{item.name}</span>
                      </div>
                      {item.count !== null && (
                        <span className="w-5 h-5 rounded-full bg-[#e6edb0] text-[#171711] text-[10px] font-black flex items-center justify-center">
                          {item.count}
                        </span>
                      )}
                    </button>
                  );
                })}
              </nav>

              {/* Library Section */}
              <div className="pt-6">
                <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] px-3 block mb-1.5">
                  LIBRARY
                </span>
                <button
                  type="button"
                  onClick={() => setActiveTab('All Items')}
                  className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                    activeTab === 'All Items'
                      ? 'bg-white border border-[#e4e0d5] text-[#171711]'
                      : 'text-[#6c6b63] hover:text-[#171711]'
                  }`}
                >
                  <Grid className="w-4 h-4 text-[#9e9b92]" />
                  <span>All Items</span>
                </button>
              </div>

              {/* Activity Section */}
              <div className="pt-4">
                <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] px-3 block mb-1.5">
                  ACTIVITY
                </span>
                <button
                  type="button"
                  onClick={() => setActiveTab('History')}
                  className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                    activeTab === 'History'
                      ? 'bg-white border border-[#e4e0d5] text-[#171711]'
                      : 'text-[#6c6b63] hover:text-[#171711]'
                  }`}
                >
                  <History className="w-4 h-4 text-[#9e9b92]" />
                  <span>History</span>
                </button>
              </div>
            </div>
          </aside>

          {/* ============================================================ */}
          {/* Main Dashboard Panel */}
          {/* ============================================================ */}
          <main className="flex-1 p-8 bg-white min-w-0">
            {/* Top Search Omnibar */}
            <div className="flex items-center justify-between gap-4 mb-8">
              <div className="max-w-md w-full mx-auto rounded-full bg-[#faf8f5] border border-[#e4e0d5] px-4 py-2 flex items-center justify-between text-xs text-[#9e9b92] shadow-2xs">
                <div className="flex items-center gap-2">
                  <Search className="w-3.5 h-3.5 text-[#9e9b92]" />
                  <span>Search or type a command...</span>
                </div>
                <kbd className="px-2 py-0.5 rounded bg-[#ebe7dc] text-[10px] font-mono font-bold text-[#171711]">
                  Ctrl+K
                </kbd>
              </div>
              <button
                type="button"
                className="p-2 rounded-xl hover:bg-[#faf8f5] text-[#6c6b63] transition-colors"
                title="Options"
              >
                <Menu className="w-4 h-4" />
              </button>
            </div>

            {/* Greeting Header */}
            <div className="mb-6">
              <h3 className="text-3xl font-black text-[#171711] tracking-tight">
                Good morning, Abhishek.
              </h3>
              <p className="text-sm text-[#8e8d87] font-medium mt-0.5">
                Here is what needs your attention.
              </p>
            </div>

            {/* Top Metric Cards Row */}
            <div className="grid grid-cols-2 gap-4 mb-8">
              {/* Metric 1: Returned Today */}
              <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-1">
                    RETURNED TODAY
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-[#171711]" />
                    <span className="font-black text-lg text-[#171711]">3 Items</span>
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
              </div>

              {/* Metric 2: Waiting in Inbox */}
              <div className="p-4 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] flex items-center justify-between">
                <div>
                  <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-1">
                    WAITING IN INBOX
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="w-2 h-2 rounded-full bg-[#9e9b92]" />
                    <span className="font-black text-lg text-[#171711]">2 Items</span>
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
              </div>
            </div>

            {/* Two-Column Work Area */}
            <div className="grid grid-cols-12 gap-6">
              {/* Left Column: WAITING FOR YOU & COMING UP */}
              <div className="col-span-8 space-y-6">
                {/* Section: WAITING FOR YOU */}
                <div>
                  <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-3">
                    WAITING FOR YOU
                  </span>
                  <div className="space-y-2">
                    {/* Item 1 */}
                    <div className="p-3.5 rounded-2xl bg-white border border-[#f0ede4] hover:border-[#171711] hover:shadow-2xs transition-all flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-8 h-8 rounded-xl bg-[#faf8f2] text-[#171711] flex items-center justify-center shrink-0 border border-[#e4e0d5]">
                          <FileText className="w-4 h-4" />
                        </div>
                        <div className="min-w-0">
                          <p className="font-bold text-sm text-[#171711] truncate">
                            ClientFeedback.pdf
                          </p>
                          <p className="text-[11px] text-[#9e9b92]">PDF Document • Added 2 days ago</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 text-[11px] font-semibold text-[#6c6b63] shrink-0">
                        <span>Tomorrow, 10:00 AM</span>
                        <Clock className="w-3 h-3 text-[#9e9b92]" />
                      </div>
                    </div>

                    {/* Item 2 */}
                    <div className="p-3.5 rounded-2xl bg-white border border-[#f0ede4] hover:border-[#171711] hover:shadow-2xs transition-all flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-8 h-8 rounded-xl bg-[#001e36] text-[#31a8ff] font-bold text-xs flex items-center justify-center shrink-0">
                          Ps
                        </div>
                        <div className="min-w-0">
                          <p className="font-bold text-sm text-[#171711] truncate">
                            Design Inspiration.psd
                          </p>
                          <p className="text-[11px] text-[#9e9b92]">PSD File • Added 3 days ago</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 text-[11px] font-semibold text-[#6c6b63] shrink-0">
                        <span>Today, 03:00 PM</span>
                        <Clock className="w-3 h-3 text-[#9e9b92]" />
                      </div>
                    </div>

                    {/* Item 3 */}
                    <div className="p-3.5 rounded-2xl bg-white border border-[#f0ede4] hover:border-[#171711] hover:shadow-2xs transition-all flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-8 h-8 rounded-xl bg-purple-50 text-purple-600 flex items-center justify-center shrink-0">
                          <Video className="w-4 h-4" />
                        </div>
                        <div className="min-w-0">
                          <p className="font-bold text-sm text-[#171711] truncate">
                            YouTube Video
                          </p>
                          <p className="text-[11px] text-[#9e9b92]">Link • Added 1 week ago</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 text-[11px] font-semibold text-[#6c6b63] shrink-0">
                        <span>Sunday, 09:00 AM</span>
                        <Clock className="w-3 h-3 text-[#9e9b92]" />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Section: COMING UP */}
                <div>
                  <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-3">
                    COMING UP
                  </span>
                  <div className="space-y-2">
                    {/* Item 1 */}
                    <div className="p-3.5 rounded-2xl bg-white border border-[#f0ede4] hover:border-[#171711] hover:shadow-2xs transition-all flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-8 h-8 rounded-xl bg-neutral-100 text-[#171711] flex items-center justify-center shrink-0">
                          <CheckSquare className="w-4 h-4" />
                        </div>
                        <div className="min-w-0">
                          <p className="font-bold text-sm text-[#171711] truncate">
                            Finish Portfolio
                          </p>
                          <p className="text-[11px] text-[#9e9b92]">Task • Added 3 days ago</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 text-[11px] font-semibold text-[#6c6b63] shrink-0">
                        <span>25 Jul, 10:00 AM</span>
                        <Clock className="w-3 h-3 text-[#9e9b92]" />
                      </div>
                    </div>

                    {/* Item 2 */}
                    <div className="p-3.5 rounded-2xl bg-white border border-[#f0ede4] hover:border-[#171711] hover:shadow-2xs transition-all flex items-center justify-between gap-3">
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center shrink-0">
                          <Link2 className="w-4 h-4" />
                        </div>
                        <div className="min-w-0">
                          <p className="font-bold text-sm text-[#171711] truncate">
                            Read Article – Design Trends
                          </p>
                          <p className="text-[11px] text-[#9e9b92]">Link • Added 5 days ago</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 text-[11px] font-semibold text-[#6c6b63] shrink-0">
                        <span>26 Jul, 08:00 AM</span>
                        <Clock className="w-3 h-3 text-[#9e9b92]" />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Right Column: QUICK DROP & NEXT RETURN */}
              <div className="col-span-4 space-y-4">
                {/* Quick Drop Box */}
                <div>
                  <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block mb-3">
                    QUICK DROP
                  </span>
                  <div className="p-5 rounded-2xl bg-[#faf8f5] border border-dashed border-[#e4e0d5] text-center space-y-2.5">
                    <div className="w-9 h-9 mx-auto rounded-xl bg-[#e6edb0] text-[#171711] flex items-center justify-center shadow-2xs">
                      <Upload className="w-4 h-4" />
                    </div>
                    <p className="font-bold text-xs text-[#171711]">Drop files or links here</p>
                    <p className="text-[11px] text-[#9e9b92] leading-tight">
                      LaterBox will safely store them until you&apos;re ready to deal with them.
                    </p>
                    <button
                      type="button"
                      onClick={triggerAdd}
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
                  <div className="p-3 rounded-2xl bg-[#faf8f5] border border-[#f0ede4] flex items-center gap-3">
                    <div className="w-7 h-7 rounded-lg bg-[#faf8f2] text-[#171711] border border-[#e4e0d5] flex items-center justify-center shrink-0">
                      <FileText className="w-3.5 h-3.5" />
                    </div>
                    <div className="min-w-0">
                      <p className="font-bold text-xs text-[#171711] truncate">ClientBrief.pdf</p>
                      <p className="text-[10px] text-[#9e9b92]">Tomorrow, 10:00 AM</p>
                    </div>
                  </div>
                </div>

                {/* Someday Header Preview */}
                <div className="pt-1">
                  <span className="text-[10px] font-black tracking-widest uppercase text-[#9e9b92] block">
                    SOMEDAY (7)
                  </span>
                </div>
              </div>
            </div>
          </main>
        </div>
      </ResponsivePreviewContainer>

      {/* Interactive Toast */}
      {droppedToast && (
        <div className="fixed bottom-6 right-6 z-50 bg-[#171711] text-white text-xs font-bold px-4 py-3 rounded-2xl shadow-2xl border border-white/10 animate-fade-in">
          {droppedToast}
        </div>
      )}
    </div>
  </section>
  );
}
