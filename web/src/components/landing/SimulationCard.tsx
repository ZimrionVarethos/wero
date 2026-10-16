"use client";

import dynamic from "next/dynamic";
import { useState } from "react";
import { Activity, CloudRain, LifeBuoy, MapPin, Waves } from "lucide-react";
import type { DisasterScenario } from "./DisasterScene";

const DisasterScene = dynamic(() => import("./DisasterScene"), {
  ssr: false,
  loading: () => (
    <div className="absolute inset-0 grid place-items-center text-sm text-white/60" role="status">
      Memuat simulasi 3D...
    </div>
  ),
});

const SCENARIOS: {
  id: DisasterScenario;
  label: string;
  icon: typeof Activity;
  caption: string;
}[] = [
  {
    id: "gempa",
    label: "Gempa",
    icon: Activity,
    caption: "Guncangan dari episentrum di laut. Warga diarahkan menjauhi bangunan menuju titik kumpul.",
  },
  {
    id: "tsunami",
    label: "Tsunami",
    icon: Waves,
    caption: "Gelombang menuju pesisir. Jalur evakuasi mengarah ke dataran tinggi terdekat.",
  },
  {
    id: "banjir",
    label: "Banjir",
    icon: CloudRain,
    caption: "Hujan lebat menaikkan muka air di kawasan rendah. Titik evakuasi berada di bukit.",
  },
];

export default function SimulationCard({ className = "" }: { className?: string }) {
  const [scenario, setScenario] = useState<DisasterScenario>("tsunami");
  const active = SCENARIOS.find((s) => s.id === scenario)!;

  return (
    <figure
      className={`relative h-[520px] sm:h-[570px] lg:h-[610px] w-full overflow-hidden rounded-[28px] border border-white/10 bg-[radial-gradient(120%_90%_at_70%_20%,#1d3a5f_0%,#12263F_55%,#0b1a2c_100%)] shadow-2xl ${className}`}
    >
      <DisasterScene scenario={scenario} className="absolute inset-0 cursor-grab active:cursor-grabbing" />

      {/* Skenario Selector */}
      <div
        role="radiogroup"
        aria-label="Pilih skenario bencana"
        className="absolute left-3 top-3 sm:left-4 sm:top-4 z-10 flex gap-1 rounded-xl bg-[#0b1a2c]/85 p-1 backdrop-blur border border-white/15 shadow-lg"
      >
        {SCENARIOS.map(({ id, label, icon: Icon }) => {
          const selected = id === scenario;
          return (
            <button
              key={id}
              type="button"
              role="radio"
              aria-checked={selected}
              onClick={() => setScenario(id)}
              className={`flex min-h-10 items-center gap-2 rounded-lg px-3 text-xs font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#E8590C] ${
                selected
                  ? "bg-white text-[#12263F] shadow-sm font-bold"
                  : "text-white/75 hover:text-white hover:bg-white/10"
              }`}
            >
              <Icon className="size-3.5" aria-hidden />
              {label}
            </button>
          );
        })}
      </div>

      {/* Legenda Peta 3D */}
      <div className="absolute right-3 top-3 sm:right-4 sm:top-4 z-10 hidden sm:flex flex-col gap-2 rounded-xl bg-[#0b1a2c]/85 p-3 text-xs text-white/85 backdrop-blur border border-white/15 shadow-lg">
        <span className="flex items-center gap-2">
          <span className="grid size-5 place-items-center rounded-full bg-[#2E7D32]">
            <MapPin className="size-3 text-white" aria-hidden />
          </span>
          Titik evakuasi
        </span>
        <span className="flex items-center gap-2">
          <span className="grid size-5 place-items-center rounded-full bg-[#C62828]">
            <LifeBuoy className="size-3 text-white" aria-hidden />
          </span>
          Sinyal SOS
        </span>
        <span className="flex items-center gap-2">
          <span className="w-5 border-t-2 border-dashed border-white" aria-hidden />
          Jalur evakuasi
        </span>
      </div>

      <figcaption
        aria-live="polite"
        className="absolute inset-x-3 bottom-3 sm:inset-x-4 sm:bottom-4 z-10 rounded-2xl bg-[#0b1a2c]/90 p-4 text-white backdrop-blur border border-white/15 shadow-xl"
      >
        <p className="text-sm font-bold text-white flex items-center gap-2">
          <span className="inline-block size-2 rounded-full bg-accent" />
          Skenario: {active.label}
        </p>
        <p className="mt-1 text-xs text-white/80 leading-relaxed sm:text-sm">{active.caption}</p>
        <p className="mt-2 text-[10px] uppercase tracking-wider text-white/50">
          Simulasi visual 3D interaktif — Geser mouse untuk memutar sudut pandang
        </p>
      </figcaption>
    </figure>
  );
}
