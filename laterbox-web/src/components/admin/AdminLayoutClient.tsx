// laterbox-web/src/components/admin/AdminLayoutClient.tsx
'use client';

import { useState, type ReactNode } from 'react';
import { Menu } from 'lucide-react';
import { AdminProvider } from './AdminContext';
import { AdminSidebar } from './AdminSidebar';

export function AdminLayoutClient({ children }: { children: ReactNode }) {
  const [mobileOpen, setMobileOpen] = useState(false);

  return (
    <AdminProvider>
      <div className="flex h-screen w-full overflow-hidden bg-[#f7f5ee] text-[#171711]">
        {/* Desktop Sidebar: ALWAYS flush attached to left screen edge */}
        <AdminSidebar mobileOpen={mobileOpen} onCloseMobile={() => setMobileOpen(false)} />

        {/* Main Content Area */}
        <div className="flex-1 flex flex-col min-w-0 h-full overflow-hidden bg-[#f7f5ee]">
          {/* Mobile Top Navigation Header */}
          <div className="flex lg:hidden items-center justify-between border-b border-[#e4e5d9] bg-[#f7f5ee] px-4 py-3 shrink-0">
            <button
              type="button"
              onClick={() => setMobileOpen(true)}
              className="flex items-center gap-2 rounded-xl border border-[#d9dece] bg-white px-3 py-1.5 text-xs font-bold text-[#171711] shadow-sm hover:bg-[#edf0e4] transition-colors"
              aria-label="Open administration menu"
            >
              <Menu size={16} />
              <span>Menu</span>
            </button>
            <div className="flex items-center gap-2">
              <span className="flex h-7 w-7 items-center justify-center rounded-lg bg-[#e6edb0] text-xs font-black text-[#171711]">
                LB
              </span>
              <span className="text-xs font-bold text-[#171711]">Control center</span>
            </div>
          </div>

          {/* Page View Container */}
          <main className="flex-1 min-h-0 overflow-y-auto px-5 py-7 sm:px-8 lg:px-11">
            <div className="max-w-7xl mx-auto space-y-7 pb-12">
              {children}
            </div>
          </main>
        </div>
      </div>
    </AdminProvider>
  );
}

