'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Radio,
  Send,
  RefreshCw,
  Clock,
  ExternalLink,
  MapPin,
  Waves,
  CheckCircle,
  AlertCircle,
  Globe,
  Search,
  Check,
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
  region_id?: string | null;
  source_payload?: {
    target_type?: 'ALL' | 'SPECIFIC';
    target_region_ids?: string[];
    target_regions?: string[];
    broadcasted_by?: string;
  } | null;
}

interface RegionOption {
  id: string;
  name: string;
  code: string;
  level: string;
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
  const [availableRegions, setAvailableRegions] = useState<RegionOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [broadcasting, setBroadcasting] = useState(false);
  const [toast, setToast] = useState<{ message: string; isError?: boolean } | null>(null);

  // Target Region State
  const [targetType, setTargetType] = useState<'ALL' | 'SPECIFIC'>('ALL');
  const [selectedRegionIds, setSelectedRegionIds] = useState<string[]>([]);
  const [regionSearch, setRegionSearch] = useState('');

  // Form State
  const [formData, setFormData] = useState({
    headline: '',
    disaster_type: 'EARTHQUAKE',
    severity: 'SIAGA',
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

      // 2. Fetch available regions
      const regRes = await fetch('/api/regions');
      const regJson = await regRes.json();
      if (regJson.success) {
        setAvailableRegions(regJson.data || []);
      }

      // 3. Fetch live BMKG feed
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

  const filteredRegions = useMemo(() => {
    if (!regionSearch.trim()) return availableRegions;
    const q = regionSearch.toLowerCase();
    return availableRegions.filter(
      (r) => r.name.toLowerCase().includes(q) || r.code.includes(q)
    );
  }, [availableRegions, regionSearch]);

  const toggleRegion = (id: string) => {
    setSelectedRegionIds((prev) =>
      prev.includes(id) ? prev.filter((rId) => rId !== id) : [...prev, id]
    );
  };

  const handleBroadcast = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.headline.trim()) {
      setToast({ message: 'Judul peringatan (headline) wajib diisi', isError: true });
      setTimeout(() => setToast(null), 4000);
      return;
    }

    if (targetType === 'SPECIFIC' && selectedRegionIds.length === 0) {
      setToast({
        message: 'Silakan pilih minimal 1 daerah sasaran siaran darurat',
        isError: true,
      });
      setTimeout(() => setToast(null), 4000);
      return;
    }

    setBroadcasting(true);
    try {
      const selectedRegionNames = availableRegions
        .filter((r) => selectedRegionIds.includes(r.id))
        .map((r) => r.name);

      const payload = {
        ...formData,
        target_type: targetType,
        target_region_ids: targetType === 'SPECIFIC' ? selectedRegionIds : [],
        target_regions: targetType === 'SPECIFIC' ? selectedRegionNames : [],
      };

      const res = await fetch('/api/broadcast', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });
      const json = await res.json();
      if (json.success) {
        const targetDesc =
          targetType === 'ALL'
            ? 'seluruh daerah (Nasional)'
            : `${selectedRegionNames.length} daerah terpilih`;

        let fcmNote = '';
        if (json.fcm) {
          if (json.fcm.success && json.fcm.dispatched > 0) {
            fcmNote = ` • 📲 Push FCM (${json.fcm.method}) terkirim!`;
          } else if (json.fcm.reason) {
            fcmNote = ` • ⚠️ Push FCM dilewati (${json.fcm.reason})`;
          }
        }

        setToast({
          message: `Peringatan darurat berhasil disiarkan ke ${targetDesc}${fcmNote}`,
          isError: false,
        });
        setTimeout(() => setToast(null), 6000);
        setFormData({
          headline: '',
          disaster_type: 'EARTHQUAKE',
          severity: 'SIAGA',
          magnitude: '',
          depth_km: '',
          source: 'PUSKODALOPS BPBD DIY',
          source_url: '',
        });
        setSelectedRegionIds([]);
        setTargetType('ALL');
        fetchData();
      } else {
        setToast({
          message: `Gagal menyiarkan: ${json.error || 'Terjadi kesalahan sistem'}`,
          isError: true,
        });
        setTimeout(() => setToast(null), 5000);
      }
    } catch (err: any) {
      console.error(err);
      setToast({
        message: `Terjadi kendala jaringan: ${err.message || 'Gagal menghubungi server'}`,
        isError: true,
      });
      setTimeout(() => setToast(null), 5000);
    } finally {
      setBroadcasting(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {toast && (
        <div
          className={`fixed bottom-6 right-6 z-50 px-4 py-3 rounded-xl shadow-lg border text-sm font-medium flex items-center gap-2 animate-fade-in ${
            toast.isError
              ? 'bg-rose-900 text-white border-rose-700'
              : 'bg-emerald-900 text-white border-emerald-700'
          }`}
        >
          {toast.isError ? (
            <AlertCircle className="w-4 h-4 text-rose-300" />
          ) : (
            <CheckCircle className="w-4 h-4 text-emerald-400" />
          )}
          {toast.message}
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <div>
          <h2 className="text-xl font-bold text-slate-900 flex items-center gap-2">
            <Radio className="w-5 h-5 text-rose-500 animate-pulse" /> Peringatan Dini & Broadcast Evakuasi Darurat
          </h2>
          <p className="text-xs text-slate-500 mt-1">
            Pantau feed BMKG resmi secara live dan siarkan pengumuman darurat resmi ke ponsel warga.
          </p>
        </div>
        <button
          onClick={fetchData}
          disabled={loading}
          className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          Segarkan Data
        </button>
      </div>

      {/* BMKG Live Autogempa Feed Banner */}
      {bmkgQuake && (
        <div className="bg-gradient-to-r from-amber-600 via-rose-600 to-rose-700 text-white p-5 rounded-2xl shadow-sm">
          <div className="flex items-center justify-between gap-3">
            <span className="text-[11px] font-extrabold uppercase tracking-wider bg-black/25 px-2.5 py-1 rounded-full">
              Pusat Gempa Terkini (BMKG Real-time)
            </span>
            <a
              href="https://data.bmkg.go.id"
              target="_blank"
              rel="noopener noreferrer"
              className="text-[11px] underline flex items-center gap-1 opacity-90 hover:opacity-100"
            >
              Sumber: BMKG Indonesia <ExternalLink className="w-3 h-3" />
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
            Pengumuman ini akan memicu pop-up overlay darurat, suara sirine, dan getaran di ponsel warga.
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

            {/* Target Daerah / Wilayah Selector */}
            <div className="space-y-2">
              <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider">
                Sasaran Wilayah Penerima Siaran
              </label>
              <div className="grid grid-cols-2 gap-2">
                <button
                  type="button"
                  onClick={() => setTargetType('ALL')}
                  className={`px-3 py-2.5 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition ${
                    targetType === 'ALL'
                      ? 'border-rose-500 bg-rose-50 text-rose-700 shadow-xs'
                      : 'border-slate-200 bg-slate-50 text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <Globe className="w-3.5 h-3.5" />
                  Semua Daerah (Nasional)
                </button>
                <button
                  type="button"
                  onClick={() => setTargetType('SPECIFIC')}
                  className={`px-3 py-2.5 rounded-xl border text-xs font-bold flex items-center justify-center gap-1.5 transition ${
                    targetType === 'SPECIFIC'
                      ? 'border-rose-500 bg-rose-50 text-rose-700 shadow-xs'
                      : 'border-slate-200 bg-slate-50 text-slate-600 hover:bg-slate-100'
                  }`}
                >
                  <MapPin className="w-3.5 h-3.5" />
                  Pilih Daerah Tertentu ({selectedRegionIds.length})
                </button>
              </div>

              {targetType === 'SPECIFIC' && (
                <div className="mt-2.5 p-3 rounded-xl border border-slate-200 bg-slate-50/70 space-y-2.5 animate-fade-in">
                  <div className="flex items-center justify-between gap-2">
                    <div className="relative flex-1">
                      <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                      <input
                        type="text"
                        placeholder="Cari kota / kabupaten..."
                        value={regionSearch}
                        onChange={(e) => setRegionSearch(e.target.value)}
                        className="w-full pl-8 pr-3 py-1.5 text-xs rounded-lg border border-slate-200 bg-white focus:outline-none focus:border-rose-500"
                      />
                    </div>
                    <div className="flex items-center gap-1">
                      <button
                        type="button"
                        onClick={() => setSelectedRegionIds(availableRegions.map((r) => r.id))}
                        className="px-2 py-1 text-[11px] font-semibold text-rose-600 hover:bg-rose-50 rounded"
                      >
                        Pilih Semua
                      </button>
                      <span className="text-slate-300">|</span>
                      <button
                        type="button"
                        onClick={() => setSelectedRegionIds([])}
                        className="px-2 py-1 text-[11px] font-semibold text-slate-500 hover:bg-slate-200/60 rounded"
                      >
                        Reset
                      </button>
                    </div>
                  </div>

                  {/* Multi-Select Badges */}
                  <div className="flex flex-wrap gap-1.5 max-h-36 overflow-y-auto p-1">
                    {filteredRegions.length === 0 ? (
                      <div className="text-[11px] text-slate-400 py-1">Tidak ada daerah yang cocok.</div>
                    ) : (
                      filteredRegions.map((reg) => {
                        const isSelected = selectedRegionIds.includes(reg.id);
                        return (
                          <button
                            key={reg.id}
                            type="button"
                            onClick={() => toggleRegion(reg.id)}
                            className={`px-2.5 py-1 rounded-lg text-xs font-medium border flex items-center gap-1.5 transition ${
                              isSelected
                                ? 'bg-rose-600 text-white border-rose-600 shadow-xs'
                                : 'bg-white text-slate-700 border-slate-200 hover:border-slate-300'
                            }`}
                          >
                            {isSelected ? <Check className="w-3 h-3 stroke-[3]" /> : null}
                            {reg.name}
                          </button>
                        );
                      })
                    )}
                  </div>
                  {selectedRegionIds.length > 0 && (
                    <div className="text-[11px] text-rose-600 font-semibold flex items-center gap-1 pt-1">
                      <CheckCircle className="w-3.5 h-3.5" />
                      {selectedRegionIds.length} daerah terpilih akan menerima sirine & getaran.
                    </div>
                  )}
                </div>
              )}
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
                  <option value="SIAGA">SIAGA (Warning / Siaga)</option>
                  <option value="AWAS">AWAS (Critical / Bahaya Tinggi)</option>
                  <option value="WASPADA">WASPADA (Advisory / Waspada)</option>
                  <option value="INFO">INFO (Informasi / Edukasi)</option>
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
                        ev.severity === 'AWAS' || ev.severity === 'DANGER'
                          ? 'bg-rose-100 text-rose-800'
                          : ev.severity === 'SIAGA' || ev.severity === 'WARNING'
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

                  {/* Target Region Badge in History */}
                  <div className="flex items-center gap-1 text-[11px] text-slate-600 pt-0.5">
                    {ev.source_payload?.target_type === 'SPECIFIC' &&
                    ev.source_payload?.target_regions &&
                    ev.source_payload.target_regions.length > 0 ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-rose-50 text-rose-700 font-semibold border border-rose-100">
                        <MapPin className="w-3 h-3" />
                        {ev.source_payload.target_regions.join(', ')}
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-700 font-semibold border border-emerald-100">
                        <Globe className="w-3 h-3" />
                        Semua Daerah (Nasional)
                      </span>
                    )}
                  </div>

                  <div className="text-xs text-slate-500 pt-0.5">
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
