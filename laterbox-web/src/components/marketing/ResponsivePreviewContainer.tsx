'use client';

import React, { useRef, useState, useEffect, useCallback } from 'react';

interface ResponsivePreviewContainerProps {
  children: React.ReactNode;
  baseWidth?: number;
  className?: string;
  id?: string;
}

export function ResponsivePreviewContainer({
  children,
  baseWidth = 1080,
  className = '',
  id,
}: ResponsivePreviewContainerProps) {
  const outerRef = useRef<HTMLDivElement>(null);
  const innerRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(1);
  const [wrapperHeight, setWrapperHeight] = useState<number | undefined>(undefined);

  const updateSize = useCallback(() => {
    if (!outerRef.current || !innerRef.current) return;
    const availableWidth = outerRef.current.offsetWidth;
    if (availableWidth > 0 && availableWidth < baseWidth) {
      const newScale = availableWidth / baseWidth;
      setScale((prev) => (Math.abs(prev - newScale) > 0.0005 ? newScale : prev));
      const innerHeight = innerRef.current.offsetHeight || innerRef.current.scrollHeight;
      if (innerHeight > 0) {
        const nextH = Math.ceil(innerHeight * newScale);
        setWrapperHeight((prev) => (prev !== nextH ? nextH : prev));
      }
    } else {
      setScale((prev) => (prev !== 1 ? 1 : prev));
      setWrapperHeight((prev) => (prev !== undefined ? undefined : prev));
    }
  }, [baseWidth]);

  useEffect(() => {
    updateSize();

    let ro: ResizeObserver | null = null;
    if (typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(() => {
        updateSize();
      });
      if (outerRef.current) ro.observe(outerRef.current);
      if (innerRef.current) ro.observe(innerRef.current);
    }

    window.addEventListener('resize', updateSize);
    window.addEventListener('orientationchange', updateSize);

    return () => {
      window.removeEventListener('resize', updateSize);
      window.removeEventListener('orientationchange', updateSize);
      ro?.disconnect();
    };
  }, [updateSize]);

  return (
    <div
      ref={outerRef}
      id={id}
      className={`w-full overflow-hidden ${className}`}
      style={{
        height: wrapperHeight !== undefined ? `${wrapperHeight}px` : 'auto',
      }}
    >
      <div
        ref={innerRef}
        style={{
          width: scale < 1 ? `${baseWidth}px` : '100%',
          minWidth: `${baseWidth}px`,
          transform: scale < 1 ? `scale(${scale})` : 'none',
          transformOrigin: 'top left',
        }}
      >
        {children}
      </div>
    </div>
  );
}
