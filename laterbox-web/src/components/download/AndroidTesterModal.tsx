'use client';

import React, { useState } from 'react';
import {
  X,
  Smartphone,
  Users,
  CheckCircle2,
  ExternalLink,
  Mail,
  AlertTriangle,
  ArrowRight,
  Download,
} from 'lucide-react';

interface AndroidTesterModalProps {
  isOpen: boolean;
  onClose: () => void;
  onDownloadApk?: () => void;
}

export function AndroidTesterModal({
  isOpen,
  onClose,
  onDownloadApk,
}: AndroidTesterModalProps) {
  const [step, setStep] = useState<1 | 2>(1);
  const [email, setEmail] = useState('');
  const [hasSubscribed, setHasSubscribed] = useState(false);

  if (!isOpen) return null;

  const handleEmailSubscribe = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;

    // Trigger mailto subscription to Google Group
    const mailtoUrl = `mailto:laterbox-testers+subscribe@googlegroups.com?subject=Join%20LaterBox%20Testers&body=Please%20add%20${encodeURIComponent(
      email.trim()
    )}%20to%20the%20LaterBox%20Google%20Play%20testers%20group.`;

    window.open(mailtoUrl, '_blank');
    setHasSubscribed(true);
    setStep(2);
  };

  const handleDirectWebJoin = () => {
    window.open('https://groups.google.com/g/laterbox-testers', '_blank');
    setHasSubscribed(true);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200">
      <div
        className="relative w-full max-w-lg rounded-3xl bg-[#f7f5ee] border border-[#e4e0d5] shadow-2xl p-6 sm:p-8 text-[#171711] overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 rounded-full text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc] transition-colors"
          aria-label="Close modal"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Header */}
        <div className="flex items-center gap-3 mb-6">
          <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center shrink-0">
            <Smartphone className="w-6 h-6 text-[#171711]" />
          </div>
          <div>
            <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[#ebe7dc] text-[#171711] text-[11px] font-bold">
              <span>Google Play Closed Beta</span>
            </div>
            <h2 className="text-xl sm:text-2xl font-black tracking-tight text-[#171711]">
              Get laterbox for Android
            </h2>
          </div>
        </div>

        {/* Step Indicator */}
        <div className="flex items-center gap-2 mb-6 text-xs font-bold">
          <div
            className={`flex items-center gap-1.5 px-3 py-1 rounded-full ${
              step === 1
                ? 'bg-[#171711] text-white'
                : 'bg-[#e6edb0] text-[#171711]'
            }`}
          >
            {step === 2 ? <CheckCircle2 className="w-3.5 h-3.5" /> : <span>1</span>}
            <span>Join Group</span>
          </div>
          <div className="w-4 h-0.5 bg-[#e4e0d5]" />
          <div
            className={`flex items-center gap-1.5 px-3 py-1 rounded-full ${
              step === 2
                ? 'bg-[#171711] text-white'
                : 'bg-[#ebe7dc] text-[#6c6b63]'
            }`}
          >
            <span>2</span>
            <span>Google Play</span>
          </div>
        </div>

        {step === 1 ? (
          /* STEP 1: Join Testers Google Group */
          <div className="space-y-5">
            <div className="space-y-2">
              <h3 className="text-base font-extrabold text-[#171711]">
                Step 1: Join the Testers Google Group
              </h3>
              <p className="text-xs sm:text-sm text-[#6c6b63] leading-relaxed">
                Google Play requires testers to be part of our Google Group before the store listing becomes visible to your account.
              </p>
            </div>

            {/* CRITICAL WARNING ALERT */}
            <div className="p-4 rounded-2xl bg-[#fff8e6] border border-[#f2d888] space-y-2">
              <div className="flex items-center gap-2 text-[#925f00] text-xs font-black">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                <span>IMPORTANT GOOGLE PLAY REQUIREMENT</span>
              </div>
              <p className="text-xs text-[#734b00] leading-relaxed">
                The email you use to join <strong>must be the exact same Google email address</strong> you use on your Android device for Google Play. If you use a different email, Google Play will display <em>&ldquo;App not available / Item not found&rdquo;</em>.
              </p>
            </div>

            {/* Quick 1-Click Join Form */}
            <form onSubmit={handleEmailSubscribe} className="space-y-3">
              <label className="block text-xs font-bold text-[#171711]">
                Enter your Google Play email address:
              </label>
              <div className="flex gap-2">
                <div className="relative flex-1">
                  <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9e9b92]" />
                  <input
                    type="email"
                    required
                    placeholder="yourname@gmail.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    className="w-full pl-10 pr-3 py-2.5 rounded-xl bg-white border border-[#e4e0d5] text-xs sm:text-sm font-medium text-[#171711] placeholder:text-[#9e9b92] focus:outline-hidden focus:border-[#171711]"
                  />
                </div>
                <button
                  type="submit"
                  className="px-4 py-2.5 rounded-xl bg-[#171711] hover:bg-[#282723] text-white text-xs font-extrabold shadow-xs transition-colors shrink-0 flex items-center gap-1.5 cursor-pointer"
                >
                  <span>1-Click Join</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            </form>

            <div className="relative flex py-1 items-center">
              <div className="grow border-t border-[#e4e0d5]"></div>
              <span className="shrink mx-3 text-[11px] font-bold text-[#9e9b92] uppercase">
                Or join via Google Groups
              </span>
              <div className="grow border-t border-[#e4e0d5]"></div>
            </div>

            <div className="flex flex-col sm:flex-row gap-2.5">
              <button
                type="button"
                onClick={handleDirectWebJoin}
                className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-[#e4e0d5] hover:bg-[#ebe7dc] text-xs font-bold text-[#171711] transition-colors cursor-pointer"
              >
                <Users className="w-4 h-4" />
                <span>Open Google Group Page</span>
                <ExternalLink className="w-3 h-3 text-[#6c6b63]" />
              </button>

              <button
                type="button"
                onClick={() => setStep(2)}
                className="flex-1 inline-flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-[#e6edb0] hover:bg-[#d9e29a] text-xs font-extrabold text-[#171711] transition-colors cursor-pointer"
              >
                <span>Already Joined → Continue</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        ) : (
          /* STEP 2: Google Play Link & Direct APK Option */
          <div className="space-y-5 animate-in fade-in duration-200">
            <div className="p-4 rounded-2xl bg-[#e6edb0]/60 border border-[#d0db84] flex items-start gap-3">
              <CheckCircle2 className="w-5 h-5 text-[#171711] shrink-0 mt-0.5" />
              <div className="space-y-1">
                <h4 className="text-xs sm:text-sm font-extrabold text-[#171711]">
                  Google Group Membership Requested!
                </h4>
                <p className="text-xs text-[#6c6b63] leading-relaxed">
                  You can now access the Google Play Store link. Remember to use the <strong>same Google account</strong> when downloading from the Play Store.
                </p>
              </div>
            </div>

            <div className="space-y-3">
              <a
                href="https://play.google.com/store/apps/details?id=pro.micorp.laterbox"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full inline-flex items-center justify-center gap-2.5 px-5 py-3.5 rounded-2xl bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white text-sm font-extrabold shadow-md transition-all group cursor-pointer"
              >
                <Smartphone className="w-4 h-4" />
                <span>Open in Google Play Store</span>
                <ExternalLink className="w-3.5 h-3.5 text-white/70 group-hover:translate-x-0.5 transition-transform" />
              </a>

              <a
                href="https://play.google.com/apps/testing/pro.micorp.laterbox"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-white border border-[#e4e0d5] hover:bg-[#ebe7dc] text-xs font-bold text-[#171711] transition-colors"
              >
                <span>Web Testing Opt-In Link (Alternative)</span>
                <ExternalLink className="w-3 h-3 text-[#6c6b63]" />
              </a>
            </div>

            <div className="pt-2 border-t border-[#e4e0d5] flex items-center justify-between">
              <button
                type="button"
                onClick={() => setStep(1)}
                className="text-xs font-bold text-[#6c6b63] hover:text-[#171711] transition-colors"
              >
                ← Back to Step 1
              </button>

              {onDownloadApk && (
                <button
                  type="button"
                  onClick={onDownloadApk}
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-[#171711] hover:underline"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Or download .apk directly</span>
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
