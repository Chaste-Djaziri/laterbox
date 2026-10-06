import React from 'react';

export const APP_STORE_URL = 'https://apps.apple.com/us/app/laterbox-save-for-later/id6804139119';

interface AppStoreButtonProps {
  className?: string;
  size?: 'default' | 'large';
  theme?: 'dark' | 'light';
}

export function AppStoreButton({
  className = '',
  size = 'large',
  theme = 'dark',
}: AppStoreButtonProps) {
  const isLarge = size === 'large';
  const isDark = theme === 'dark';

  return (
    <a
      href={APP_STORE_URL}
      target="_blank"
      rel="noopener noreferrer"
      aria-label="Download LaterBox on the Apple App Store"
      className={`inline-flex items-center gap-3.5 transition-all duration-200 select-none group cursor-pointer ${
        isLarge ? 'px-6 py-3.5 rounded-2xl' : 'px-5 py-2.5 rounded-xl'
      } ${
        isDark
          ? 'bg-black hover:bg-[#1a1a17] text-white border border-[#2e2d27] shadow-md hover:shadow-lg hover:border-[#45443c] active:scale-[0.98]'
          : 'bg-white hover:bg-[#f7f5ee] text-[#171711] border border-[#e4e0d5] shadow-xs hover:border-[#171711] active:scale-[0.98]'
      } ${className}`}
    >
      <svg
        className={`${isLarge ? 'w-8 h-8' : 'w-6 h-6'} fill-current shrink-0 transition-transform group-hover:scale-105`}
        viewBox="0 0 24 24"
        aria-hidden="true"
      >
        <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.56-.73 1.01-1.73.89-2.77-.92.05-2.01.63-2.65 1.38-.57.65-1.06 1.7-.93 2.7.99.08 2.06-.52 2.69-1.31z" />
      </svg>
      <div className="flex flex-col text-left leading-none">
        <span
          className={`font-semibold tracking-wider uppercase leading-none ${
            isLarge ? 'text-[10px] sm:text-[11px]' : 'text-[9px]'
          } ${isDark ? 'text-neutral-300' : 'text-[#6c6b63]'}`}
        >
          Download on the
        </span>
        <span
          className={`font-bold tracking-tight leading-tight font-sans mt-0.5 ${
            isLarge ? 'text-xl sm:text-2xl' : 'text-base sm:text-lg'
          } ${isDark ? 'text-white' : 'text-[#171711]'}`}
        >
          App Store
        </span>
      </div>
    </a>
  );
}
