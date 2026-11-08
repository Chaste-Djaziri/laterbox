// laterbox-web/src/components/settings/SettingsSwitch.tsx
'use client';

import type { LucideIcon } from 'lucide-react';

interface SettingsSwitchProps {
  id: string;
  title: string;
  description: string;
  checked: boolean;
  onCheckedChange: (checked: boolean) => void;
  disabled?: boolean;
  icon?: LucideIcon;
  label?: string;
}

/** Accessible, reusable settings-row toggle. */
export function SettingsSwitch({
  id,
  title,
  description,
  checked,
  onCheckedChange,
  disabled = false,
  icon: Icon,
  label,
}: SettingsSwitchProps) {
  return (
    <div className={`flex min-h-[84px] items-center gap-3 px-4 py-4 sm:gap-4 sm:px-5 ${disabled ? 'opacity-60' : ''}`}>
      {Icon && (
        <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-[#f2f5e9] text-[#536743]">
          <Icon className="h-[19px] w-[19px]" aria-hidden="true" strokeWidth={1.85} />
        </span>
      )}
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <span id={`${id}-label`} className="text-[13px] font-extrabold text-[#262e21]">{title}</span>
          {label && (
            <span className="rounded-full bg-[#f2f5e9] px-2 py-0.5 text-[10px] font-bold text-[#71845c]">{label}</span>
          )}
        </div>
        <p id={`${id}-description`} className="mt-1 max-w-[550px] text-[11px] leading-5 text-[#858c80] sm:text-xs">{description}</p>
      </div>
      <button
        id={id}
        type="button"
        role="switch"
        aria-checked={checked}
        aria-labelledby={`${id}-label`}
        aria-describedby={`${id}-description`}
        disabled={disabled}
        onClick={() => onCheckedChange(!checked)}
        className={`relative h-[28px] w-[50px] shrink-0 rounded-full border p-[3px] transition-colors duration-200 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#798c5a] disabled:cursor-not-allowed ${
          checked ? 'border-[#333d2c] bg-[#273523]' : 'border-[#dedfd6] bg-[#e6e9df]'
        }`}
      >
        <span className={`block h-5 w-5 rounded-full bg-white shadow-sm transition-transform duration-200 ${checked ? 'translate-x-[21px]' : 'translate-x-0'}`} aria-hidden="true" />
      </button>
    </div>
  );
}
