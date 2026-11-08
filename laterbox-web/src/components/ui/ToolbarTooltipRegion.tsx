// laterbox-web/src/components/ui/ToolbarTooltipRegion.tsx
'use client';

import {
  useEffect,
  useRef,
  useState,
  type FocusEvent,
  type MouseEvent,
  type ReactNode,
} from 'react';
import { createPortal } from 'react-dom';

type Tooltip = { label: string; left: number; top: number; below: boolean };

/**
 * Adds a single, accessible-on-focus hover label to controls marked with
 * data-tooltip. Portaling prevents overflow-x-auto toolbars from clipping it.
 * The control itself remains responsible for its accessible name (aria-label
 * or visible button text).
 */
export function ToolbarTooltipRegion({
  children,
  className,
}: {
  children: ReactNode;
  className?: string;
}) {
  const regionRef = useRef<HTMLDivElement>(null);
  const [tooltip, setTooltip] = useState<Tooltip | null>(null);

  const getTrigger = (target: EventTarget | null): HTMLElement | null => {
    if (!(target instanceof Element)) return null;
    const element = target.closest<HTMLElement>('[data-tooltip]');
    return element && regionRef.current?.contains(element) ? element : null;
  };

  const show = (trigger: HTMLElement) => {
    const label = trigger.dataset.tooltip;
    if (!label) return;
    const rect = trigger.getBoundingClientRect();
    const estimatedWidth = Math.min(248, Math.max(92, label.length * 7.5 + 24));
    const left = Math.min(
      window.innerWidth - estimatedWidth / 2 - 8,
      Math.max(estimatedWidth / 2 + 8, rect.left + rect.width / 2),
    );
    const below = rect.bottom + 54 < window.innerHeight;
    setTooltip({
      label,
      left,
      top: below ? rect.bottom + 11 : rect.top - 11,
      below,
    });
  };

  const handleMouseOver = (event: MouseEvent<HTMLDivElement>) => {
    const trigger = getTrigger(event.target);
    if (!trigger) return;
    if (event.relatedTarget instanceof Node && trigger.contains(event.relatedTarget)) return;
    show(trigger);
  };

  const handleMouseOut = (event: MouseEvent<HTMLDivElement>) => {
    const trigger = getTrigger(event.target);
    if (!trigger) return;
    if (event.relatedTarget instanceof Node && trigger.contains(event.relatedTarget)) return;
    setTooltip(null);
  };

  const handleFocus = (event: FocusEvent<HTMLDivElement>) => {
    const trigger = getTrigger(event.target);
    if (trigger) show(trigger);
  };

  useEffect(() => {
    const hide = () => setTooltip(null);
    document.addEventListener('scroll', hide, true);
    window.addEventListener('resize', hide);
    return () => {
      document.removeEventListener('scroll', hide, true);
      window.removeEventListener('resize', hide);
    };
  }, []);

  return (
    <div
      ref={regionRef}
      className={className}
      onMouseOver={handleMouseOver}
      onMouseOut={handleMouseOut}
      onFocusCapture={handleFocus}
      onBlurCapture={() => setTooltip(null)}
      onClickCapture={() => setTooltip(null)}
    >
      {children}
      {tooltip && createPortal(
        <div
          role="tooltip"
          aria-hidden="true"
          style={{
            left: tooltip.left,
            top: tooltip.top,
            transform: tooltip.below ? 'translateX(-50%)' : 'translate(-50%, -100%)',
          }}
          className="pointer-events-none fixed z-[10000] max-w-[248px] whitespace-nowrap rounded-xl bg-[#20271c] px-3 py-2 text-center text-xs font-bold text-white shadow-[0_10px_28px_rgba(19,24,14,0.24)]"
        >
          <span
            className={`absolute left-1/2 h-2 w-2 -translate-x-1/2 rotate-45 bg-[#20271c] ${
              tooltip.below ? '-top-1' : '-bottom-1'
            }`}
            aria-hidden="true"
          />
          {tooltip.label}
        </div>,
        document.body,
      )}
    </div>
  );
}
