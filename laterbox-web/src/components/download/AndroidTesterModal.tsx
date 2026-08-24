'use client';

import React, { useState } from 'react';
import {
  X,
  Smartphone,
  Users,
  CheckCircle2,
  ExternalLink,
  AlertTriangle,
  ArrowRight,
  Download,
  ShieldCheck,
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

  if (!isOpen) return null;

  const handleOpenGoogleGroup = () => {
    window.open('https://groups.google.com/g/laterbox-testers', '_blank');
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        className="relative w-full max-w-lg rounded-3xl bg-[#f7f5ee] border border-[#e4e0d5] shadow-2xl p-6 sm:p-8 text-[#171711] overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* Close Button */}
        <button
          onClick={onClose}
          className="absolute top-5 right-5 p-2 rounded-full text-[#6c6b63] hover:text-[#171711] hover:bg-[#ebe7dc] transition-colors cursor-pointer"
          aria-label="Close modal"
        >
          <X className="w-5 h-5" />
        </button>

        {/* Modal Header */}
        <div className="flex items-center gap-3.5 mb-6">
          <div className="w-12 h-12 rounded-2xl bg-[#e6edb0] border border-[#d0db84] flex items-center justify-center shrink-0">
            <Smartphone className="w-6 h-6 text-[#171711]" />
          </div>
          <div>
            <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-[#ebe7dc] text-[#171711] text-[11px] font-bold">
              <ShieldCheck className="w-3 h-3 text-[#171711]" />
              <span>Google Play Closed Beta</span>
            </div>
            <h2 className="text-xl sm:text-2xl font-black tracking-tight text-[#171711]">
              Get LaterBox for Android
            </h2>
          </div>
        </div>

        {/* Step Indicator */}
        <div className="flex items-center gap-2 mb-6 text-xs font-bold">
          <button
            type="button"
            onClick={() => setStep(1)}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full transition-all cursor-pointer ${
              step === 1
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-[#e6edb0] text-[#171711] hover:bg-[#dce3a5]'
            }`}
          >
            <span>1</span>
            <span>Join Google Group</span>
          </button>
          <div className="w-4 h-0.5 bg-[#e4e0d5]" />
          <button
            type="button"
            onClick={() => setStep(2)}
            className={`flex items-center gap-1.5 px-3.5 py-1.5 rounded-full transition-all cursor-pointer ${
              step === 2
                ? 'bg-[#171711] text-white shadow-xs'
                : 'bg-[#ebe7dc] text-[#6c6b63] hover:text-[#171711]'
            }`}
          >
            <span>2</span>
            <span>Google Play Store</span>
          </button>
        </div>

        {step === 1 ? (
          /* STEP 1: Join Testers Google Group */
          <div className="space-y-5">
            <div className="space-y-2">
              <h3 className="text-base font-extrabold text-[#171711]">
                Step 1: Join the Google Group
              </h3>
              <p className="text-xs sm:text-sm text-[#6c6b63] leading-relaxed">
                Google Play requires testers to join our Google Group before the app listing becomes visible to your Google account.
              </p>
            </div>

            {/* CRITICAL WARNING ALERT */}
            <div className="p-4 rounded-2xl bg-[#fff8e6] border border-[#f2d888] space-y-2">
              <div className="flex items-center gap-2 text-[#925f00] text-xs font-black">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                <span>IMPORTANT GOOGLE PLAY REQUIREMENT</span>
              </div>
              <p className="text-xs text-[#734b00] leading-relaxed">
                The account you use to join <strong>must be the exact same Google account</strong> you use on your Android device for Google Play.
              </p>
            </div>

            {/* External Google Group Link */}
            <div className="space-y-3 pt-1">
              <button
                type="button"
                onClick={handleOpenGoogleGroup}
                className="w-full inline-flex items-center justify-center gap-2 px-5 py-3.5 rounded-2xl bg-[#171711] hover:bg-[#282723] text-white text-sm font-extrabold shadow-sm hover:shadow-md transition-all group cursor-pointer"
              >
                <Users className="w-4 h-4 text-[#E7FF57]" />
                <span>1. Open Google Group to Join</span>
                <ExternalLink className="w-4 h-4 text-white/70 group-hover:translate-x-0.5 transition-transform" />
              </button>

              <div className="p-3.5 rounded-xl bg-white border border-[#e4e0d5] text-xs text-[#6c6b63] leading-relaxed flex items-center gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-[#171711] shrink-0" />
                <span>Once you click <strong>Join group</strong> on the Google page, return here and click <strong>Continue to Google Play</strong>.</span>
              </div>

              <button
                type="button"
                onClick={() => setStep(2)}
                className="w-full inline-flex items-center justify-center gap-1.5 px-4 py-2.5 rounded-xl bg-[#e6edb0] hover:bg-[#d9e29a] text-xs font-extrabold text-[#171711] transition-colors cursor-pointer"
              >
                <span>Joined the Group → Continue to Google Play</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            {onDownloadApk && (
              <div className="pt-2 border-t border-[#e4e0d5] flex items-center justify-end">
                <button
                  type="button"
                  onClick={onDownloadApk}
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Or download direct .apk installer</span>
                </button>
              </div>
            )}
          </div>
        ) : (
          /* STEP 2: Google Play Link & Direct APK Option */
          <div className="space-y-5 animate-in fade-in duration-200">
            <div className="p-4 rounded-2xl bg-[#e6edb0]/60 border border-[#d0db84] flex items-start gap-3">
              <CheckCircle2 className="w-5 h-5 text-[#171711] shrink-0 mt-0.5" />
              <div className="space-y-1">
                <h4 className="text-xs sm:text-sm font-extrabold text-[#171711]">
                  Ready to install LaterBox!
                </h4>
                <p className="text-xs text-[#6c6b63] leading-relaxed">
                  Open the Google Play Store link below on your Android device to install and receive automatic updates.
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
                <Smartphone className="w-4 h-4 text-[#E7FF57]" />
                <span>2. Open in Google Play Store</span>
                <ExternalLink className="w-4 h-4 text-white/70 group-hover:translate-x-0.5 transition-transform" />
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
                className="text-xs font-bold text-[#6c6b63] hover:text-[#171711] transition-colors cursor-pointer"
              >
                ← Back to Step 1
              </button>

              {onDownloadApk && (
                <button
                  type="button"
                  onClick={onDownloadApk}
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-[#171711] hover:underline cursor-pointer"
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download .apk directly</span>
                </button>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
