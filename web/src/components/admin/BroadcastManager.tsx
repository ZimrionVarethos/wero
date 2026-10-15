'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Radio,
  Send,
  AlertTriangle,
  RefreshCw,
  Clock,
  ExternalLink,
  MapPin,
  Waves,
  CheckCircle,
} from 'lucide-react';

interface DisasterEventRow {
  id: string;
  headline: string;
  disaster_type: string;
  severity: string;
  source: string;
  magnitude: number | null;
  depth_km: number | null;
  source_url: string | null;
  occurred_at: string;
  created_at?: string;
  is_published: boolean;
}

interface BmkgLatestQuake {
  Tanggal: string;
  Jam: string;
  DateTime: string;
  Coordinates: string;
  Magnitude: string;
  Kedalaman: string;
  Wilayah: string;
  Potensi: string;
  Shakemap?: string;
}

export default function BroadcastManager() {
  const [events, setEvents] = useState<DisasterEventRow[]>([]);
  const [bmkgQuake, setBmkgQuake] = useState<BmkgLatestQuake | null>(null);
  const [loading, setLoading] = useState(true);
  const [broadcasting, setBroadcasting] = useState(false);
  const [toast, setToast] = useState<string | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    headline: '',
    disaster_type: 'EARTHQUAKE',
    severity: 'WARNING',
    magnitude: '',
    depth_km: '',
    source: 'PUSKODALOPS BPBD DIY',
    source_url: '',
  });

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      // 1. Fetch DB broadcasts
      const res = await fetch('/api/broadcast');
      const json = await res.json();
      if (json.success) {
        setEvents(json.data || []);
      }

      // 2. Fetch live BMKG feed
      const bmkgRes = await fetch('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json');
      if (bmkgRes.ok) {
        const bmkgData = await bmkgRes.json();
        if (bmkgData.Infogempa?.gempa) {
          setBmkgQuake(bmkgData.Infogempa.gempa);
        }
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleBroadcast = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.headline.trim()) return;

    setBroadcasting(true);
    try {
      const res = await fetch('/api/broadcast', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      });
      const json = await res.json();
      if (json.success) {
        setToast('Peringatan darurat berhasil disiarkan ke seluruh aplikasi warga');
        setTimeout(() => setToast(null), 4000);
        setFormData({
          headline: '',
          disaster_type: 'EARTHQUAKE',
          severity: 'WARNING',
          magnitude: '',
          depth_km: '',
          source: 'PUSKODALOPS BPBD DIY',
          source_url: '',
        });
        fetchData();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setBroadcasting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {toast && (
        <div className="fixed bottom-6 right-6 z-50 px-4 py-3 rounded-xl shadow-lg border text-sm font-medium flex items-center gap-2 bg-emerald-900 text-white border-emerald-700 animate-fade-in">
          <CheckCircle className="w-4 h-4 text-emerald-400" />
          {toast}
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <div>
          <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2">
            <Radio className="w-5 h-5 text-rose-500 animate-pulse" /> Peringatan Dini & Broadcast Evakuasi Darurat
          </h2>
          <p className="text-xs text-slate-500 mt-1">
            Pantau feed BMKG resmi secara live dan siarkan pengumuman darurat resmi ke seluruh ponsel warga.
          </p>
        </div>
        <button
          onClick={fetchData}
          disabled={loading}
          className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Muat Ulang Feed
        </button>
      </div>

      {/* BMKG Live Feed Banner */}
      {bmkgQuake && (
        <div className="bg-gradient-to-r from-amber-500 to-rose-600 text-white p-5 rounded-2xl shadow-md">
          <div className="flex items-center justify-between gap-2 pb-2 border-b border-white/20">
            <div className="flex items-center gap-2">
              <span className="px-2 py-0.5 rounded-full bg-white/20 text-xs font-bold uppercase tracking-wider backdrop-blur-xs">
                BMKG Live Auto-Gempa
              </span>
              <span className="text-xs text-white/80">
                {bmkgQuake.Tanggal} • {bmkgQuake.Jam}
              </span>
            </div>
            <a
              href="https://data.bmkg.go.id/"
              target="_blank"
              rel="noreferrer"
              className="text-xs font-semibold hover:underline flex items-center gap-1 text-white/90"
            >
              Open Data BMKG <ExternalLink className="w-3 h-3" />
            </a>
          </div>

          <div className="mt-3 flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-3">
                <span className="text-3xl font-extrabold tracking-tight">M {bmkgQuake.Magnitude}</span>
                <div>
                  <div className="text-sm font-bold text-white leading-snug">{bmkgQuake.Wilayah}</div>
                  <div className="text-xs text-white/80 flex items-center gap-3">
                    <span>Kedalaman: {bmkgQuake.Kedalaman}</span>
                    <span>Koordinat: {bmkgQuake.Coordinates}</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <div className="bg-black/25 px-3 py-2 rounded-xl backdrop-blur-xs text-xs font-semibold flex items-center gap-1.5">
                <Waves className="w-4 h-4 text-amber-200" />
                {bmkgQuake.Potensi}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Broadcast Form and Broadcast History */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Broadcast Form */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-xs">
          <h3 className="font-bold text-base text-slate-900 mb-1 flex items-center gap-2">
            <Send className="w-4 h-4 text-sky-600" /> Siarkan Peringatan Darurat Baru
          </h3>
          <p className="text-xs text-slate-500 mb-4">
            Pengumuman ini akan langsung muncul di banner atas aplikasi mobile Siagaku.
          </p>

          <form onSubmit={handleBroadcast} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Judul Siaran Darurat (Headline) *
              </label>
              <textarea
                required
                rows={2}
                placeholder="Contoh: PERINGATAN EVAKUASI: Sesar Opak Meningkat, Warga Radius 5km Diimbau Menuju Barak Glagaharjo"
                value={formData.headline}
                onChange={(e) => setFormData({ ...formData, headline: e.target.value })}
                className="w-full px-3.5 py-2.5 text-sm rounded-xl border border-slate-200 focus:outline-none focus:border-rose-500"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Tingkat Bahaya
                </label>
                <select
                  value={formData.severity}
                  onChange={(e) => setFormData({ ...formData, severity: e.target.value })}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-slate-200 bg-white"
                >
                  <option value="WARNING">SIAGA (Warning)</option>
                  <option value="DANGER">AWAS (Critical / Danger)</option>
                  <option value="INFO">WASPADA / INFO</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Tipe Kejadian
                </label>
                <select
                  value={formData.disaster_type}
                  onChange={(e) => setFormData({ ...formData, disaster_type: e.target.value })}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-slate-200 bg-white"
                >
                  <option value="EARTHQUAKE">Gempa Bumi</option>
                  <option value="VOLCANO">Erupsi Gunung Berapi</option>
                  <option value="TSUNAMI">Tsunami</option>
                  <option value="FLOOD">Banjir Bandang</option>
                  <option value="LANDSLIDE">Tanah Longsor</option>
                </select>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Magnitudo / Skala (Opsional)
                </label>
                <input
                  type="number"
                  step="0.1"
                  placeholder="Misal: 6.2"
                  value={formData.magnitude}
                  onChange={(e) => setFormData({ ...formData, magnitude: e.target.value })}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Kedalaman (km)
                </label>
                <input
                  type="number"
                  placeholder="Misal: 10"
                  value={formData.depth_km}
                  onChange={(e) => setFormData({ ...formData, depth_km: e.target.value })}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                Instansi Pengirim
              </label>
              <input
                type="text"
                value={formData.source}
                onChange={(e) => setFormData({ ...formData, source: e.target.value })}
                className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200"
              />
            </div>

            <button
              type="submit"
              disabled={broadcasting}
              className="w-full py-3 rounded-xl bg-rose-600 hover:bg-rose-700 text-white font-bold text-sm transition flex items-center justify-center gap-2 shadow-sm"
            >
              {broadcasting ? <RefreshCw className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4" />}
              Siarkan Peringatan Sekarang
            </button>
          </form>
        </div>

        {/* Broadcast History */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-xs flex flex-col">
          <h3 className="font-bold text-base text-slate-900 mb-1 flex items-center gap-2">
            <Clock className="w-4 h-4 text-slate-600" /> Riwayat Siaran Peringatan Terakhir
          </h3>
          <p className="text-xs text-slate-500 mb-4">Daftar peristiwa bencana yang telah dipublikasikan.</p>

          <div className="divide-y divide-slate-100 flex-1 overflow-y-auto max-h-[480px]">
            {events.length === 0 ? (
              <div className="p-8 text-center text-slate-400 text-sm">Belum ada siaran darurat.</div>
            ) : (
              events.map((ev) => (
                <div key={ev.id} className="py-3.5 space-y-1">
                  <div className="flex items-center gap-2">
                    <span
                      className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                        ev.severity === 'DANGER'
                          ? 'bg-rose-100 text-rose-800'
                          : ev.severity === 'WARNING'
                          ? 'bg-amber-100 text-amber-800'
                          : 'bg-sky-100 text-sky-800'
                      }`}
                    >
                      {ev.severity}
                    </span>
                    <span className="text-xs font-semibold text-slate-500">{ev.disaster_type}</span>
                    <span className="text-[11px] text-slate-400">
                      {new Date(ev.occurred_at || ev.created_at || Date.now()).toLocaleString('id-ID', {
                        dateStyle: 'medium',
                        timeStyle: 'short',
                      })}
                    </span>
                  </div>
                  <h4 className="font-bold text-sm text-slate-900 leading-snug">{ev.headline}</h4>
                  <div className="text-xs text-slate-500">
                    Sumber: <span className="font-medium text-slate-700">{ev.source}</span>
                    {ev.magnitude && <span className="ml-2 font-mono font-bold text-rose-600">• M {ev.magnitude}</span>}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
