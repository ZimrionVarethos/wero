"use client";

import { useState } from "react";
import { Apple, Download, ExternalLink, HelpCircle, Smartphone, X } from "lucide-react";

interface IosDownloadModalProps {
  className?: string;
}

export default function IosDownloadModal({ className = "" }: IosDownloadModalProps) {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <>
      {/* Tombol Unduh iOS di Header dengan Logo Apple */}
      <button
        type="button"
        onClick={() => setIsOpen(true)}
        className={`inline-flex min-h-11 items-center gap-2 rounded-xl bg-black hover:bg-zinc-800 text-white px-3.5 sm:px-4 text-sm font-semibold shadow-sm transition-all focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-black ${className}`}
        aria-label="Unduh Wero untuk perangkat Apple iOS"
      >
        <Apple className="size-4.5 fill-current" aria-hidden />
        <span>Unduh iOS</span>
      </button>

      {/* Modal Dialog Panduan & Unduhan iOS */}
      {isOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200"
          onClick={() => setIsOpen(false)}
        >
          <div
            className="relative w-full max-w-lg rounded-3xl bg-white p-6 sm:p-8 shadow-2xl border border-border-neutral text-left animate-in zoom-in-95 duration-200"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Tombol Tutup */}
            <button
              type="button"
              onClick={() => setIsOpen(false)}
              aria-label="Tutup jendela"
              className="absolute top-5 right-5 grid size-9 place-items-center rounded-full text-muted hover:bg-zinc-100 hover:text-navy transition-colors"
            >
              <X className="size-5" />
            </button>

            {/* Header Modal */}
            <div className="flex items-center gap-3.5">
              <div className="grid size-12 place-items-center rounded-2xl bg-black text-white shadow-md">
                <Apple className="size-6 fill-current" />
              </div>
              <div>
                <h3 className="text-xl font-black tracking-tight text-navy">
                  Unduh Wero untuk iOS
                </h3>
                <p className="text-xs font-semibold text-muted">
                  Kompatibel dengan iPhone & iPad (iOS 15+)
                </p>
              </div>
            </div>

            {/* Content Body */}
            <div className="mt-6 space-y-4">
              {/* Opsi 1: IPA File via GitHub Release / Actions */}
              <div className="rounded-2xl border border-border-neutral bg-[#FBFBFA] p-4 transition-colors hover:border-black/30">
                <div className="flex items-start gap-3">
                  <div className="mt-0.5 grid size-7 shrink-0 place-items-center rounded-lg bg-black text-white">
                    <Download className="size-4" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-sm font-bold text-navy">
                      1. Unduh Paket Aplikasi (.ipa)
                    </h4>
                    <p className="mt-1 text-xs text-muted leading-relaxed">
                      Unduh file rilis <code className="rounded bg-zinc-200 px-1 py-0.5 text-[11px] text-zinc-800">Wero-iOS-unsigned.ipa</code> dari GitHub Actions CI/CD runner.
                    </p>
                    <a
                      href="https://github.com/ZimrionVarethos/wero/actions"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="mt-2.5 inline-flex items-center gap-1.5 text-xs font-bold text-accent hover:underline"
                    >
                      Buka Rilis Build GitHub Actions <ExternalLink className="size-3" />
                    </a>
                  </div>
                </div>
              </div>

              {/* Opsi 2: Instalasi via Sideload */}
              <div className="rounded-2xl border border-border-neutral bg-[#FBFBFA] p-4 transition-colors hover:border-black/30">
                <div className="flex items-start gap-3">
                  <div className="mt-0.5 grid size-7 shrink-0 place-items-center rounded-lg bg-navy text-white">
                    <Smartphone className="size-4" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-sm font-bold text-navy">
                      2. Pasang via Sideloadly / AltStore
                    </h4>
                    <p className="mt-1 text-xs text-muted leading-relaxed">
                      Tanpa jailbreak! Cukup buka <strong>Sideloadly</strong> di PC/Mac, masukkan Apple ID gratis Anda, dan install file IPA ke iPhone Anda.
                    </p>
                  </div>
                </div>
              </div>

              {/* Opsi 3: Pasang sebagai Web App (PWA) di Safari */}
              <div className="rounded-2xl border border-border-neutral bg-[#FBFBFA] p-4 transition-colors hover:border-black/30">
                <div className="flex items-start gap-3">
                  <div className="mt-0.5 grid size-7 shrink-0 place-items-center rounded-lg bg-accent text-white">
                    <HelpCircle className="size-4" />
                  </div>
                  <div className="flex-1">
                    <h4 className="text-sm font-bold text-navy">
                      3. Jalankan Langsung via Safari (PWA)
                    </h4>
                    <p className="mt-1 text-xs text-muted leading-relaxed">
                      Di Safari iPhone: Tekan tombol <strong>Share</strong> (ikon kotak dengan panah ke atas) &gt; pilih <strong>&quot;Tambahkan ke Layar Utama&quot;</strong> untuk aplikasi instan tanpa instalasi IPA.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Tombol Aksi */}
            <div className="mt-6 flex flex-col-reverse sm:flex-row items-center justify-end gap-2.5">
              <button
                type="button"
                onClick={() => setIsOpen(false)}
                className="w-full sm:w-auto px-5 py-2.5 rounded-xl border border-border-neutral text-sm font-semibold text-muted hover:bg-zinc-100 transition-colors"
              >
                Tutup
              </button>
              <a
                href="https://github.com/ZimrionVarethos/wero/actions"
                target="_blank"
                rel="noopener noreferrer"
                className="w-full sm:w-auto inline-flex items-center justify-center gap-2 rounded-xl bg-black px-5 py-2.5 text-sm font-bold text-white hover:bg-zinc-800 transition-colors shadow-sm"
              >
                <Apple className="size-4 fill-current" />
                <span>Unduh File IPA</span>
              </a>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
