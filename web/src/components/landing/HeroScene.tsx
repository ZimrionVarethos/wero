"use client";

import dynamic from "next/dynamic";
import { useState } from "react";
import { Activity, CloudRain, LifeBuoy, MapPin, Waves } from "lucide-react";
import type { DisasterScenario } from "./DisasterScene";

const DisasterScene = dynamic(() => import("./DisasterScene"), {
  ssr: false,
  loading: () => (
    <div className="absolute inset-0 grid place-items-center text-sm text-white/60" role="status">
      Memuat ilustrasi 3D
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

export default function HeroScene() {
  const [scenario, setScenario] = useState<DisasterScenario>("tsunami");
  const active = SCENARIOS.find((s) => s.id === scenario)!;

  return (
    <figure className="relative h-[420px] sm:h-[520px] lg:h-[600px] overflow-hidden rounded-2xl border border-white/10 bg-[radial-gradient(120%_90%_at_70%_20%,#1d3a5f_0%,#12263F_55%,#0b1a2c_100%)]">
      <DisasterScene scenario={scenario} className="absolute inset-0 cursor-grab active:cursor-grabbing" />

      {/* Pemilih skenario */}
      <div
        role="radiogroup"
        aria-label="Pilih skenario ilustrasi bencana"
        className="absolute left-3 top-3 sm:left-4 sm:top-4 flex gap-1 rounded-xl bg-[#0b1a2c]/80 p-1 backdrop-blur border border-white/10"
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
              className={`flex min-h-12 items-center gap-2 rounded-lg px-3 sm:px-4 text-sm font-semibold transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#E8590C] ${
                selected ? "bg-white text-[#12263F]" : "text-white/75 hover:text-white hover:bg-white/10"
              }`}
            >
              <Icon className="size-4" aria-hidden />
              {label}
            </button>
          );
        })}
      </div>

      {/* Legenda, selalu ikon dan teks, tidak hanya warna */}
      <div className="absolute right-3 top-3 sm:right-4 sm:top-4 hidden sm:flex flex-col gap-2 rounded-xl bg-[#0b1a2c]/80 p-3 text-xs text-white/85 backdrop-blur border border-white/10">
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
        className="absolute inset-x-3 bottom-3 sm:inset-x-4 sm:bottom-4 rounded-xl bg-[#0b1a2c]/85 p-4 text-white backdrop-blur border border-white/10"
      >
        <p className="text-sm font-semibold">Skenario {active.label}</p>
        <p className="mt-1 text-sm text-white/75 leading-relaxed">{active.caption}</p>
        <p className="mt-2 text-[11px] uppercase tracking-wider text-white/50">
          Ilustrasi 3D, bukan data atau peta langsung
        </p>
      </figcaption>
    </figure>
  );
}
