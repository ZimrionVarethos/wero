'use client';

import React, { useState, useEffect } from 'react';
import {
  ShieldAlert,
  Building,
  HeartHandshake,
  Radio,
  ArrowRight,
  CheckCircle2,
  AlertTriangle,
  Server,
  Database,
  MapPin,
  Flame,
} from 'lucide-react';

interface StatsData {
  shelters: {
    total_shelters: number;
    active_shelters: number;
    total_capacity: number;
  };
  activeSos: number;
  pendingReports: number;
  activeDisasters: number;
}

interface DashboardOverviewProps {
  onNavigateTab: (tab: 'OVERVIEW' | 'MAP' | 'SHELTER' | 'SOS' | 'MODERATION' | 'BROADCAST') => void;
}

export default function DashboardOverview({ onNavigateTab }: DashboardOverviewProps) {
  const [stats, setStats] = useState<StatsData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/stats')
      .then((res) => res.json())
      .then((json) => {
        if (json.success) setStats(json.stats);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-6">
      {/* Welcome Banner */}
      <div className="bg-gradient-to-r from-slate-900 via-slate-800 to-indigo-950 text-white p-6 sm:p-8 rounded-3xl shadow-sm relative overflow-hidden">
        <div className="relative z-10 max-w-2xl">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-sky-500/20 text-sky-300 text-xs font-semibold mb-3 border border-sky-400/20">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Pusat Kendali Operasi Terkoordinasi Siagaku
          </div>
          <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
            Selamat Bertugas, Tim Koordinator & Admin
          </h1>
          <p className="mt-2 text-sm text-slate-300 leading-relaxed">
            Portal ini terintegrasi penuh dengan basis data Supabase PostGIS, telemetri live BMKG TEWS, serta sistem
            aplikasi mobile warga untuk manajemen evakuasi, shelter, dan moderasi.
          </p>

          <div className="mt-6 flex flex-wrap gap-3">
            <button
              onClick={() => onNavigateTab('MAP')}
              className="px-4 py-2.5 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold transition flex items-center gap-2 shadow-sm"
            >
              <MapPin className="w-4 h-4" /> Buka Peta Taktis (Titik SOS)
            </button>
            <button
              onClick={() => onNavigateTab('SHELTER')}
              className="px-4 py-2.5 rounded-xl bg-sky-500 hover:bg-sky-400 text-white text-xs font-bold transition flex items-center gap-2 shadow-sm"
            >
              <Building className="w-4 h-4" /> Kelola Fasilitas Shelter
            </button>
            <button
              onClick={() => onNavigateTab('SOS')}
              className="px-4 py-2.5 rounded-xl bg-slate-700 hover:bg-slate-600 text-white text-xs font-bold transition flex items-center gap-2 shadow-sm"
            >
              <ShieldAlert className="w-4 h-4" /> Pantau Sinyal SOS
            </button>
          </div>
        </div>

        {/* Decorative Grid Glow */}
        <div className="absolute right-0 top-0 bottom-0 w-1/3 opacity-10 bg-[radial-gradient(#38bdf8_1px,transparent_1px)] [background-size:16px_16px] pointer-events-none"></div>
      </div>

      {/* Primary KPI Metrics Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Metric 1 */}
        <div
          onClick={() => onNavigateTab('SHELTER')}
          className="bg-white p-5 rounded-2xl border border-slate-200 hover:border-sky-300 transition cursor-pointer shadow-xs group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Kapasitas Shelter</span>
            <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Building className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-3xl font-extrabold text-slate-900">
            {loading ? '...' : (stats?.shelters.total_capacity || 0).toLocaleString('id-ID')}
          </div>
          <div className="mt-1 flex items-center justify-between text-xs text-slate-500">
            <span>{stats?.shelters.total_shelters || 0} posko terverifikasi</span>
            <ArrowRight className="w-3.5 h-3.5 text-slate-400 group-hover:translate-x-1 transition" />
          </div>
        </div>

        {/* Metric 2 */}
        <div
          onClick={() => onNavigateTab('SOS')}
          className="bg-white p-5 rounded-2xl border border-slate-200 hover:border-rose-300 transition cursor-pointer shadow-xs group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Panggilan SOS Aktif</span>
            <div className="w-8 h-8 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center">
              <Flame className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-3xl font-extrabold text-rose-600">
            {loading ? '...' : stats?.activeSos || 0}
          </div>
          <div className="mt-1 flex items-center justify-between text-xs text-slate-500">
            <span>Perlu respon segera</span>
            <ArrowRight className="w-3.5 h-3.5 text-slate-400 group-hover:translate-x-1 transition" />
          </div>
        </div>

        {/* Metric 3 */}
        <div
          onClick={() => onNavigateTab('MODERATION')}
          className="bg-white p-5 rounded-2xl border border-slate-200 hover:border-amber-300 transition cursor-pointer shadow-xs group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Antrean Moderasi</span>
            <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-3xl font-extrabold text-amber-600">
            {loading ? '...' : stats?.pendingReports || 0}
          </div>
          <div className="mt-1 flex items-center justify-between text-xs text-slate-500">
            <span>Laporan postingan hoaks/spam</span>
            <ArrowRight className="w-3.5 h-3.5 text-slate-400 group-hover:translate-x-1 transition" />
          </div>
        </div>

        {/* Metric 4 */}
        <div
          onClick={() => onNavigateTab('BROADCAST')}
          className="bg-white p-5 rounded-2xl border border-slate-200 hover:border-indigo-300 transition cursor-pointer shadow-xs group"
        >
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Peringatan Bencana</span>
            <div className="w-8 h-8 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Radio className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3 text-3xl font-extrabold text-slate-900">
            {loading ? '...' : stats?.activeDisasters || 0}
          </div>
          <div className="mt-1 flex items-center justify-between text-xs text-slate-500">
            <span>Siaran aktif 7 hari terakhir</span>
            <ArrowRight className="w-3.5 h-3.5 text-slate-400 group-hover:translate-x-1 transition" />
          </div>
        </div>
      </div>

      {/* System Infrastructure Health Card */}
      <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-xs">
        <h3 className="font-bold text-base text-slate-900 mb-3 flex items-center gap-2">
          <Server className="w-4 h-4 text-sky-600" /> Status Koneksi & Infrastruktur Sistem
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
          <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 border border-slate-100">
            <Database className="w-5 h-5 text-emerald-600" />
            <div>
              <div className="font-bold text-slate-800">Supabase PostgreSQL & PostGIS</div>
              <div className="text-emerald-600 font-semibold flex items-center gap-1 mt-0.5">
                <CheckCircle2 className="w-3.5 h-3.5" /> Terhubung (Pooler AWS Sydney)
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 border border-slate-100">
            <Radio className="w-5 h-5 text-sky-600" />
            <div>
              <div className="font-bold text-slate-800">BMKG TEWS Open Data Feed</div>
              <div className="text-sky-600 font-semibold flex items-center gap-1 mt-0.5">
                <CheckCircle2 className="w-3.5 h-3.5" /> Real-time Sinkronisasi Aktif
              </div>
            </div>
          </div>

          <div className="flex items-center gap-3 p-3 rounded-xl bg-slate-50 border border-slate-100">
            <MapPin className="w-5 h-5 text-indigo-600" />
            <div>
              <div className="font-bold text-slate-800">Mapbox Geospatial SDK</div>
              <div className="text-indigo-600 font-semibold flex items-center gap-1 mt-0.5">
                <CheckCircle2 className="w-3.5 h-3.5" /> Token Terkonfigurasi
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
