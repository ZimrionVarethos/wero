"use client";

import { useState } from "react";
import { RotateCcw, Smartphone, ExternalLink, Sparkles, Settings2 } from "lucide-react";

interface PhoneMockupProps {
  demoUrl?: string;
  className?: string;
}

export default function PhoneMockup({
  demoUrl = "/app/index.html",
  className = "",
}: PhoneMockupProps) {
  const [activeUrl, setActiveUrl] = useState(demoUrl);
  const [customInput, setCustomInput] = useState("");
  const [showConfig, setShowConfig] = useState(false);
  const [iframeKey, setIframeKey] = useState(0);
  const [isLoading, setIsLoading] = useState(true);

  const handleReload = () => {
    setIsLoading(true);
    setIframeKey((prev) => prev + 1);
  };

  const applyCustomUrl = (e: React.FormEvent) => {
    e.preventDefault();
    if (customInput.trim()) {
      setActiveUrl(customInput.trim());
      setIsLoading(true);
      setIframeKey((prev) => prev + 1);
      setShowConfig(false);
    }
  };

  return (
    <div className={`flex flex-col items-center ${className}`}>
      {/* Header bar controls */}
      <div className="mb-3 flex flex-wrap items-center justify-center gap-2">
        <span className="inline-flex items-center gap-1.5 rounded-full bg-accent/20 px-3 py-1 text-xs font-semibold text-accent border border-accent/30">
          <Sparkles className="size-3.5" aria-hidden />
          Live Interactive Demo
        </span>
        <button
          type="button"
          onClick={handleReload}
          title="Muat ulang tampilan demo"
          className="inline-flex items-center gap-1.5 rounded-lg border border-white/20 bg-white/10 px-2.5 py-1 text-xs font-medium text-white transition hover:bg-white/20"
        >
          <RotateCcw className="size-3" aria-hidden />
          Reset
        </button>
        <button
          type="button"
          onClick={() => setShowConfig(!showConfig)}
          title="Ubah sumber demo (Localhost / Bundled)"
          className="inline-flex items-center gap-1.5 rounded-lg border border-white/20 bg-white/10 px-2.5 py-1 text-xs font-medium text-white transition hover:bg-white/20"
        >
          <Settings2 className="size-3" aria-hidden />
          Sumber URL
        </button>
        <a
          href={activeUrl}
          target="_blank"
          rel="noopener noreferrer"
          title="Buka demo di tab baru"
          className="inline-flex items-center gap-1.5 rounded-lg border border-white/20 bg-white/10 px-2.5 py-1 text-xs font-medium text-white transition hover:bg-white/20"
        >
          <ExternalLink className="size-3" aria-hidden />
          Tab Penuh
        </a>
      </div>

      {/* URL Config Popup */}
      {showConfig && (
        <form
          onSubmit={applyCustomUrl}
          className="mb-3 flex items-center gap-2 rounded-xl bg-[#0b1a2c] p-2 text-xs border border-white/20 shadow-xl"
        >
          <input
            type="text"
            placeholder="http://localhost:XXXXX atau /app/index.html"
            value={customInput}
            onChange={(e) => setCustomInput(e.target.value)}
            className="w-56 rounded-lg bg-white/10 px-2.5 py-1 text-white placeholder-white/40 focus:outline-none focus:ring-1 focus:ring-accent"
          />
          <button
            type="submit"
            className="rounded-lg bg-accent px-3 py-1 font-semibold text-white hover:bg-accent/80"
          >
            Terapkan
          </button>
          <button
            type="button"
            onClick={() => {
              setActiveUrl("/app/index.html");
              setIsLoading(true);
              setIframeKey((k) => k + 1);
              setShowConfig(false);
            }}
            className="rounded-lg border border-white/20 px-2 py-1 text-white/70 hover:text-white"
          >
            Default
          </button>
        </form>
      )}

      {/* Realistic Smartphone Chassis Frame (Compact & Sleek) */}
      <div className="relative mx-auto w-[240px] sm:w-[260px] md:w-[280px] aspect-[9/18.5] rounded-[44px] bg-[#12141a] p-[8px] shadow-[0_20px_50px_-12px_rgba(0,0,0,0.8),0_0_0_1px_rgba(255,255,255,0.18)] ring-1 ring-white/10">
        {/* Exterior button accents (Volume & Power notches) */}
        <div className="absolute -left-[10px] top-20 h-7 w-[2.5px] rounded-l-md bg-[#2d3139]" />
        <div className="absolute -left-[10px] top-30 h-7 w-[2.5px] rounded-l-md bg-[#2d3139]" />
        <div className="absolute -right-[10px] top-24 h-10 w-[2.5px] rounded-r-md bg-[#2d3139]" />

        {/* Inner Phone Screen */}
        <div className="relative h-full w-full overflow-hidden rounded-[36px] bg-white shadow-inner">
          {/* Dynamic Island / Top Speaker & Camera Notch */}
          <div className="pointer-events-none absolute left-1/2 top-2 z-30 flex h-4.5 -translate-x-1/2 items-center justify-between gap-2 rounded-full bg-black px-2.5 shadow-md">
            <div className="size-1.5 rounded-full bg-[#182335] ring-1 ring-white/10" />
            <div className="h-0.5 w-4 rounded-full bg-[#1e2029]" />
            <div className="size-1 rounded-full bg-[#0d47a1]/80" />
          </div>

          {/* Loading indicator */}
          {isLoading && (
            <div className="absolute inset-0 z-20 flex flex-col items-center justify-center bg-[#f4f2ee] text-navy">
              <div className="size-8 animate-spin rounded-full border-3 border-accent border-t-transparent" />
              <p className="mt-3 text-xs font-semibold text-muted">Memuat Wero Mobile Demo...</p>
            </div>
          )}

          {/* Live Flutter App Iframe */}
          <iframe
            key={iframeKey}
            src={activeUrl}
            onLoad={() => setIsLoading(false)}
            className="h-full w-full border-0"
            title="Wero Mobile Interactive Demo"
            allow="geolocation; camera; microphone"
          />

          {/* Bottom Home Indicator Bar */}
          <div className="pointer-events-none absolute bottom-1.5 left-1/2 z-30 h-1 w-24 -translate-x-1/2 rounded-full bg-black/40 backdrop-blur-sm" />
        </div>
      </div>

      <p className="mt-3 text-center text-xs text-white/60">
        Layar HP di atas dapat disentuh/diklik langsung untuk mencoba seluruh fitur aplikasi Wero.
      </p>
    </div>
  );
}
