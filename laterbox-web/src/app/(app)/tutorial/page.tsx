'use client';

import { useEffect, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { ArrowRight, Check, CheckCircle2, ChevronRight, CircleHelp, Command, Copy, Download, ExternalLink, Globe2, Inbox, Laptop, Monitor, MousePointerClick, Puzzle, Search, Share2, ShieldCheck, Smartphone, Sparkles, Zap } from 'lucide-react';
import { APP_VERSION } from '@/lib/version';

type DeviceId = 'macos' | 'windows' | 'linux' | 'ios' | 'android' | 'web';
type TutorialStep = { title: string; description: string; detail: string; icon: ReactNode };
type DeviceGuide = {
  label: string; shortLabel: string; eyebrow: string; intro: string; requirement: string;
  primaryAction: string; primaryHref: string; captureLabel: string; captureKeys: string;
  steps: TutorialStep[]; tips: string[];
};

const devices: { id: DeviceId; label: string; icon: ReactNode }[] = [
  { id: 'macos', label: 'Mac', icon: <Laptop aria-hidden="true" /> },
  { id: 'windows', label: 'Windows', icon: <Monitor aria-hidden="true" /> },
  { id: 'linux', label: 'Linux', icon: <Monitor aria-hidden="true" /> },
  { id: 'ios', label: 'iPhone & iPad', icon: <Smartphone aria-hidden="true" /> },
  { id: 'android', label: 'Android', icon: <Smartphone aria-hidden="true" /> },
  { id: 'web', label: 'Web', icon: <Globe2 aria-hidden="true" /> },
];

const sharedFinishSteps: TutorialStep[] = [
  {
    title: 'Find it in your inbox',
    description: 'Open LaterBox and look at the top of Inbox. Your newest save appears first.',
    detail: 'LaterBox adds the title, preview image, reading time, and content type automatically when available.',
    icon: <Inbox aria-hidden="true" />,
  },
  {
    title: 'Read, organize, or archive',
    description: 'Open the item to read it, add a note, star it, or place it in a collection.',
    detail: 'Archive finished items to keep Inbox focused. They remain searchable in Library.',
    icon: <Sparkles aria-hidden="true" />,
  },
];

const guides: Record<DeviceId, DeviceGuide> = {
  macos: {
    label: 'LaterBox for Mac', shortLabel: 'Mac', eyebrow: 'macOS desktop guide',
    intro: 'Capture from any Mac app, use the Safari or browser extension, and keep a local copy ready offline.',
    requirement: 'macOS 12 Monterey or newer', primaryAction: 'Download for Mac', primaryHref: '/downloads',
    captureLabel: 'Open Quick Capture', captureKeys: '⌥ Space',
    steps: [
      { title: 'Install and open LaterBox', description: 'Download the Apple Silicon or Intel build, open the DMG, then drag LaterBox into Applications.', detail: 'If macOS asks for permission, allow LaterBox to run in System Settings, Privacy & Security.', icon: <Download aria-hidden="true" /> },
      { title: 'Save from anywhere', description: 'Press Option and Space together, paste a link or note, then press Return.', detail: 'The capture window works above your current app. Change the shortcut later in Settings if it conflicts with another app.', icon: <Command aria-hidden="true" /> },
      ...sharedFinishSteps,
    ],
    tips: ['Use the Safari extension for one click saves', 'The menu bar icon keeps capture close', 'Press ⌘ K in the web app to search'],
  },
  windows: {
    label: 'LaterBox for Windows', shortLabel: 'Windows', eyebrow: 'Windows 10 and 11 guide',
    intro: 'Install the native desktop app, capture without leaving your current window, and work from the system tray.',
    requirement: '64 bit Windows 10 or Windows 11', primaryAction: 'Download for Windows', primaryHref: '/downloads',
    captureLabel: 'Open Quick Capture', captureKeys: 'Ctrl Alt Space',
    steps: [
      { title: 'Run the Windows installer', description: 'Download LaterBox Setup, open the file, and follow the short installation wizard.', detail: 'Keep “Launch LaterBox” selected on the final screen. LaterBox will also appear in the Start menu.', icon: <Download aria-hidden="true" /> },
      { title: 'Save from any program', description: 'Press Ctrl, Alt, and Space together. Paste a URL or type a note, then press Enter.', detail: 'LaterBox can remain in the system tray, so Quick Capture stays available when the main window is closed.', icon: <Command aria-hidden="true" /> },
      ...sharedFinishSteps,
    ],
    tips: ['Pin LaterBox to the Start menu', 'Use the Edge or Chrome extension for web pages', 'Right click the tray icon for quick actions'],
  },
  linux: {
    label: 'LaterBox for Linux', shortLabel: 'Linux', eyebrow: 'Linux desktop guide',
    intro: 'Use the desktop build or web app, save through your browser, and keep your reading queue available across devices.',
    requirement: 'A modern 64 bit Linux distribution', primaryAction: 'See Linux downloads', primaryHref: '/downloads',
    captureLabel: 'Open Quick Capture', captureKeys: 'Alt Space',
    steps: [
      { title: 'Choose your package', description: 'Open Downloads and choose the package offered for your distribution, or continue with the web app.', detail: 'Your desktop environment may ask you to mark the downloaded file as executable before the first launch.', icon: <Download aria-hidden="true" /> },
      { title: 'Capture a link or thought', description: 'Press Alt and Space together, enter your content, then press Enter to save.', detail: 'If your desktop already uses Alt Space, set a different global shortcut in LaterBox Settings.', icon: <Command aria-hidden="true" /> },
      ...sharedFinishSteps,
    ],
    tips: ['Install the Firefox or Chromium extension', 'Pin the web app when a native package is unavailable', 'Use Ctrl K in the web app to search'],
  },
  ios: {
    label: 'LaterBox for iPhone and iPad', shortLabel: 'iPhone & iPad', eyebrow: 'iOS and iPadOS guide',
    intro: 'Save links directly from Safari, YouTube, social apps, and any app that includes the Apple share button.',
    requirement: 'Safari on a recent iPhone or iPad', primaryAction: 'Set up on iPhone or iPad', primaryHref: '/downloads',
    captureLabel: 'Main action', captureKeys: 'Share → LaterBox',
    steps: [
      { title: 'Add LaterBox to your Home Screen', description: 'Open LaterBox in Safari, tap Share, then choose Add to Home Screen and confirm.', detail: 'Always use Safari for this setup. The new LaterBox icon opens like a normal app.', icon: <Download aria-hidden="true" /> },
      { title: 'Open the item you want to save', description: 'In Safari, YouTube, or another app, tap the square Share button with the upward arrow.', detail: 'Scroll through the app row and choose LaterBox. If it is hidden, tap More and add it to Favorites.', icon: <Share2 aria-hidden="true" /> },
      ...sharedFinishSteps,
    ],
    tips: ['Move LaterBox near the front of the Share row', 'Sign in once before your first share', 'Pull down in Inbox if a save is still syncing'],
  },
  android: {
    label: 'LaterBox for Android', shortLabel: 'Android', eyebrow: 'Android phone and tablet guide',
    intro: 'Send links to LaterBox from Chrome, YouTube, Reddit, and any Android app with a Share action.',
    requirement: 'Android 8 Oreo or newer', primaryAction: 'Get LaterBox for Android', primaryHref: '/downloads',
    captureLabel: 'Main action', captureKeys: 'Share → LaterBox',
    steps: [
      { title: 'Install LaterBox', description: 'Join the Google Play test from Downloads, then install LaterBox using the same Google account.', detail: 'Open LaterBox once and sign in before trying to share content from another app.', icon: <Download aria-hidden="true" /> },
      { title: 'Share an item to LaterBox', description: 'Open a page or video, tap Share, then select LaterBox from the Android share sheet.', detail: 'You can pin LaterBox in the share sheet on supported phones so it stays near the top.', icon: <Share2 aria-hidden="true" /> },
      ...sharedFinishSteps,
    ],
    tips: ['Allow background data for reliable sync', 'Long press LaterBox in the share sheet to pin it', 'Share several files together as one saved item'],
  },
  web: {
    label: 'LaterBox on the web', shortLabel: 'Web', eyebrow: 'Browser guide',
    intro: 'Capture and organize from any modern browser without installing the desktop or mobile app.',
    requirement: 'A current version of Chrome, Edge, Firefox, or Safari', primaryAction: 'Go to your inbox', primaryHref: '/inbox',
    captureLabel: 'New capture', captureKeys: '⌘ N or Ctrl N',
    steps: [
      { title: 'Open Quick Capture', description: 'Select New capture in the sidebar. On Mac press Command N, or on Windows and Linux press Ctrl N.', detail: 'Paste a URL, write a plain note, or add supported files, then choose Save to inbox.', icon: <MousePointerClick aria-hidden="true" /> },
      { title: 'Connect the browser extension', description: 'Install the LaterBox extension, open it on any page, and follow Connect to LaterBox.', detail: 'Once connected, use the toolbar button to save the current tab without opening the LaterBox app.', icon: <Puzzle aria-hidden="true" /> },
      ...sharedFinishSteps,
    ],
    tips: ['Press / or ⌘ K to search', 'Use the extension to save the active page', 'The web app works well when installed as a PWA'],
  },
};

function detectDevice(): DeviceId {
  const userAgent = navigator.userAgent;
  const platform = navigator.platform;
  if (/iPad|iPhone|iPod/.test(userAgent) || (platform === 'MacIntel' && navigator.maxTouchPoints > 1)) return 'ios';
  if (/Android/i.test(userAgent)) return 'android';
  if (/Win/i.test(userAgent) || /Win/i.test(platform)) return 'windows';
  if (/Linux/i.test(userAgent)) return 'linux';
  if (/Mac/i.test(userAgent) || /Mac/i.test(platform)) return 'macos';
  return 'web';
}

export default function InAppGuidePage() {
  const [activeDevice, setActiveDevice] = useState<DeviceId>('web');
  const [detectedDevice, setDetectedDevice] = useState<DeviceId | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    const device = detectDevice();
    setDetectedDevice(device);
    setActiveDevice(device);
  }, []);

  const guide = guides[activeDevice];
  const copyCaptureShortcut = async () => {
    await navigator.clipboard.writeText(guide.captureKeys);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1800);
  };

  return (
    <main className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <header className="overflow-hidden rounded-3xl border border-[#e4e0d5] bg-[#171711] text-white shadow-sm">
        <div className="grid gap-8 px-5 py-7 sm:px-8 sm:py-9 lg:grid-cols-[1fr_auto] lg:items-end">
          <div className="max-w-2xl">
            <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-xs font-semibold text-[#e6edb0]">
              <Zap className="size-3.5" aria-hidden="true" /><span>Quick start for your device</span>
            </div>
            <h1 className="text-3xl font-extrabold tracking-tight sm:text-4xl">Start saving with LaterBox</h1>
            <p className="mt-3 max-w-xl text-sm leading-6 text-white/70 sm:text-base">Choose your device for exact setup, capture, and organization instructions. Most people save their first item in under two minutes.</p>
          </div>
          <div className="flex items-center gap-3 text-xs text-white/60"><ShieldCheck className="size-4 text-[#e6edb0]" aria-hidden="true" /><span>Version {APP_VERSION} · Local first and private</span></div>
        </div>
      </header>

      <nav className="mt-5" aria-label="Choose a device">
        <div className="scrollbar-none flex gap-2 overflow-x-auto pb-1" role="tablist" aria-label="Device tutorials">
          {devices.map((device) => {
            const isActive = device.id === activeDevice;
            const isDetected = device.id === detectedDevice;
            return (
              <button key={device.id} type="button" role="tab" aria-selected={isActive} aria-controls="device-guide" onClick={() => setActiveDevice(device.id)}
                className={`relative inline-flex min-h-11 shrink-0 items-center gap-2 rounded-xl border px-3.5 py-2 text-sm font-semibold transition focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#171711] focus-visible:ring-offset-2 ${isActive ? 'border-[#171711] bg-[#171711] text-white shadow-sm' : 'border-[#e4e0d5] bg-white text-[#59584f] hover:border-[#b9b4a6] hover:text-[#171711]'}`}>
                <span className="[&>svg]:size-4">{device.icon}</span><span>{device.label}</span>
                {isDetected && <span className={`rounded px-1.5 py-0.5 text-[9px] font-extrabold uppercase tracking-wider ${isActive ? 'bg-white/15 text-[#e6edb0]' : 'bg-[#eef2c8] text-[#494b1f]'}`}>This device</span>}
              </button>
            );
          })}
        </div>
      </nav>

      <section id="device-guide" role="tabpanel" className="mt-5 grid gap-5 lg:grid-cols-[minmax(0,1fr)_18rem]">
        <div className="overflow-hidden rounded-3xl border border-[#e4e0d5] bg-white shadow-sm">
          <div className="border-b border-[#e4e0d5] bg-[#fbfaf6] px-5 py-6 sm:px-7">
            <p className="text-xs font-extrabold uppercase tracking-[0.16em] text-[#77756c]">{guide.eyebrow}</p>
            <div className="mt-2 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
              <div><h2 className="text-2xl font-extrabold tracking-tight text-[#171711]">{guide.label}</h2><p className="mt-2 max-w-2xl text-sm leading-6 text-[#66645c]">{guide.intro}</p></div>
              <Link href={guide.primaryHref} className="inline-flex min-h-11 shrink-0 items-center justify-center gap-2 rounded-xl bg-[#dce884] px-4 py-2.5 text-sm font-extrabold text-[#171711] transition hover:bg-[#d1df70] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#171711] focus-visible:ring-offset-2"><Download className="size-4" aria-hidden="true" />{guide.primaryAction}</Link>
            </div>
          </div>
          <ol className="divide-y divide-[#ece8de] px-5 sm:px-7">
            {guide.steps.map((step, index) => (
              <li key={step.title} className="grid gap-4 py-6 sm:grid-cols-[3rem_1fr]">
                <div className="flex size-11 items-center justify-center rounded-xl bg-[#f0eee6] text-[#393832] [&>svg]:size-5" aria-hidden="true">{step.icon}</div>
                <div className="flex items-start gap-3">
                  <span className="mt-0.5 flex size-5 shrink-0 items-center justify-center rounded-full bg-[#171711] text-[10px] font-extrabold text-white">{index + 1}</span>
                  <div><h3 className="font-bold text-[#171711]">{step.title}</h3><p className="mt-1 text-sm leading-6 text-[#55544d]">{step.description}</p><p className="mt-2 rounded-lg bg-[#f7f5ee] px-3 py-2 text-xs leading-5 text-[#706e65]">{step.detail}</p></div>
                </div>
              </li>
            ))}
          </ol>
        </div>

        <aside className="space-y-5 lg:sticky lg:top-6 lg:self-start" aria-label={`${guide.shortLabel} quick reference`}>
          <div className="rounded-2xl border border-[#e4e0d5] bg-white p-5 shadow-sm">
            <p className="text-xs font-bold uppercase tracking-wider text-[#77756c]">Quick reference</p>
            <div className="mt-4 space-y-4">
              <div><p className="text-xs text-[#77756c]">Works with</p><p className="mt-1 text-sm font-semibold leading-5 text-[#24231f]">{guide.requirement}</p></div>
              <div className="border-t border-[#ece8de] pt-4">
                <p className="text-xs text-[#77756c]">{guide.captureLabel}</p>
                <button type="button" onClick={copyCaptureShortcut} className="mt-2 flex min-h-11 w-full items-center justify-between rounded-xl border border-[#d9d5ca] bg-[#f7f5ee] px-3 py-2 text-left text-sm font-bold text-[#171711] transition hover:border-[#aaa597] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#171711]" aria-label={`Copy ${guide.captureKeys}`}>
                  <span>{guide.captureKeys}</span>{copied ? <Check className="size-4 text-emerald-700" aria-hidden="true" /> : <Copy className="size-4 text-[#77756c]" aria-hidden="true" />}
                </button>
                <p className="mt-1.5 text-[11px] text-[#858279]" aria-live="polite">{copied ? 'Copied to clipboard' : 'Select to copy'}</p>
              </div>
            </div>
          </div>
          <div className="rounded-2xl border border-[#dbe28f] bg-[#f2f5d5] p-5">
            <div className="flex items-center gap-2 font-bold text-[#2d3014]"><CheckCircle2 className="size-4" aria-hidden="true" /><h2>Good to know</h2></div>
            <ul className="mt-3 space-y-3">{guide.tips.map((tip) => <li key={tip} className="flex gap-2 text-xs leading-5 text-[#55582c]"><ChevronRight className="mt-0.5 size-3.5 shrink-0" aria-hidden="true" /><span>{tip}</span></li>)}</ul>
          </div>
          <div className="rounded-2xl border border-[#e4e0d5] bg-[#171711] p-5 text-white">
            <div className="flex items-center gap-2 font-bold"><CircleHelp className="size-4 text-[#e6edb0]" aria-hidden="true" /><h2>Need more help?</h2></div>
            <p className="mt-2 text-xs leading-5 text-white/65">Connect your extension, browse downloads, or read the complete documentation.</p>
            <div className="mt-4 space-y-1">
              <Link href="/extension/connect" className="flex min-h-11 items-center justify-between rounded-lg px-2 text-sm font-semibold hover:bg-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#e6edb0]">Connect extension <ArrowRight className="size-4" aria-hidden="true" /></Link>
              <a href="https://docs.laterbox.dev" target="_blank" rel="noopener noreferrer" className="flex min-h-11 items-center justify-between rounded-lg px-2 text-sm font-semibold hover:bg-white/10 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#e6edb0]">Full documentation <ExternalLink className="size-4" aria-hidden="true" /></a>
            </div>
          </div>
        </aside>
      </section>

      <section className="mt-5 grid gap-4 rounded-2xl border border-[#e4e0d5] bg-white p-5 sm:grid-cols-3 sm:p-6" aria-labelledby="every-device-title">
        <div><Search className="size-5 text-[#777e2d]" aria-hidden="true" /><h2 id="every-device-title" className="mt-2 font-bold text-[#171711]">Search everything</h2><p className="mt-1 text-xs leading-5 text-[#6c6b63]">Find titles, notes, URLs, and summaries from one search.</p></div>
        <div><ShieldCheck className="size-5 text-[#777e2d]" aria-hidden="true" /><h2 className="mt-2 font-bold text-[#171711]">Available offline</h2><p className="mt-1 text-xs leading-5 text-[#6c6b63]">The native apps keep a local library ready without a connection.</p></div>
        <div><Globe2 className="size-5 text-[#777e2d]" aria-hidden="true" /><h2 className="mt-2 font-bold text-[#171711]">One account</h2><p className="mt-1 text-xs leading-5 text-[#6c6b63]">Sign in on your devices to keep saves and organization in sync.</p></div>
      </section>
    </main>
  );
}
