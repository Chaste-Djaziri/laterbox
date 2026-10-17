'use client';

import React, { useEffect, useRef, useState, useCallback } from 'react';
import { createPortal } from 'react-dom';

interface MenuPosition {
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
}

interface PortalMenuProps {
  open: boolean;
  onClose: () => void;
  triggerRef: React.RefObject<HTMLButtonElement | null>;
  children: React.ReactNode;
  width?: number;
}

/**
 * Renders children in a portal fixed to the viewport so the menu is never
 * clipped by a parent with overflow:hidden. Automatically positions itself
 * above or below the trigger button based on available space.
 */
export function PortalMenu({ open, onClose, triggerRef, children, width = 192 }: PortalMenuProps) {
  const [pos, setPos] = useState<MenuPosition>({});
  const menuRef = useRef<HTMLDivElement>(null);

  const reposition = useCallback(() => {
    if (!triggerRef.current) return;
    const btn = triggerRef.current.getBoundingClientRect();
    const vw = window.innerWidth;
    const vh = window.innerHeight;
    const MENU_W = Math.min(width, vw - 16);
    const MENU_H = menuRef.current?.offsetHeight || 260;

    // Horizontal: prefer align-right with trigger, flip left if out of viewport
    const leftAligned = btn.right - MENU_W;
    const rightAligned = btn.left;
    const left = leftAligned >= 0 ? leftAligned : rightAligned;
    const clampedLeft = Math.max(8, Math.min(left, vw - MENU_W - 8));

    // Vertical: prefer opening upward, fall back to downward
    const spaceAbove = btn.top;
    const spaceBelow = vh - btn.bottom;

    if (spaceAbove >= MENU_H || spaceAbove >= spaceBelow) {
      setPos({ bottom: vh - btn.top + 4, left: clampedLeft });
    } else {
      setPos({ top: btn.bottom + 4, left: clampedLeft });
    }
  }, [triggerRef, width]);

  useEffect(() => {
    if (!open) return;
    reposition();
    const frame = requestAnimationFrame(reposition);
    window.addEventListener('scroll', reposition, true);
    window.addEventListener('resize', reposition);
    return () => {
      cancelAnimationFrame(frame);
      window.removeEventListener('scroll', reposition, true);
      window.removeEventListener('resize', reposition);
    };
  }, [open, reposition]);

  // Close on outside click
  useEffect(() => {
    if (!open) return;
    const handler = (e: MouseEvent) => {
      if (
        menuRef.current &&
        !menuRef.current.contains(e.target as Node) &&
        triggerRef.current &&
        !triggerRef.current.contains(e.target as Node)
      ) {
        onClose();
      }
    };
    const escape = (e: KeyboardEvent) => { if (e.key === 'Escape') onClose(); };
    document.addEventListener('mousedown', handler);
    document.addEventListener('keydown', escape);
    return () => {
      document.removeEventListener('mousedown', handler);
      document.removeEventListener('keydown', escape);
    };
  }, [open, onClose, triggerRef]);

  if (!open || typeof document === 'undefined') return null;

  return createPortal(
    <div
      ref={menuRef}
      style={{
        position: 'fixed',
        zIndex: 9999,
        width: `min(${width}px, calc(100vw - 16px))`,
        maxHeight: 'calc(100dvh - 16px)',
        overflowY: 'auto',
        ...pos,
      }}
      className="rounded-2xl bg-white border border-[#e4e0d5] shadow-2xl py-1.5 text-xs font-semibold animate-in fade-in duration-100"
      onClick={(e) => e.stopPropagation()}
    >
      {children}
    </div>,
    document.body
  );
}
