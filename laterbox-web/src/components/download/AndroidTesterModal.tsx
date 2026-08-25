'use client';

import React from 'react';
import {
  X,
  Smartphone,
  CheckCircle2,
  ExternalLink,
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
  if (!isOpen) return null;

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

        <div className="space-y-5">
          <div className="p-4 rounded-2xl bg-[#e6edb0]/60 border border-[#d0db84] flex items-start gap-3">
              <CheckCircle2 className="w-5 h-5 text-[#171711] shrink-0 mt-0.5" />
              <div className="space-y-1">
                <h4 className="text-xs sm:text-sm font-extrabold text-[#171711]">
                  Ready to install LaterBox!
                </h4>
                <p className="text-xs text-[#6c6b63] leading-relaxed">
                  Join the testing program with the same Google account you use on your Android device, then install LaterBox from Google Play.
                </p>
              </div>
          </div>

          <div className="space-y-3">
              <a
                href="https://play.google.com/apps/testing/pro.micorp.laterbox"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full inline-flex items-center justify-center gap-2.5 px-5 py-3.5 rounded-2xl bg-[#171711] hover:bg-[#282723] active:bg-[#0f0f0e] text-white text-sm font-extrabold shadow-md transition-all group cursor-pointer"
              >
                <Smartphone className="w-4 h-4 text-[#E7FF57]" />
                <span>Join Android Testers on Google Play</span>
                <ExternalLink className="w-4 h-4 text-white/70 group-hover:translate-x-0.5 transition-transform" />
              </a>
          </div>

          <div className="pt-2 border-t border-[#e4e0d5] flex items-center justify-end">
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
      </div>
    </div>
  );
}
