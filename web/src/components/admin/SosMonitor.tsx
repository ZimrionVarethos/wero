'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  AlertCircle,
  Phone,
  Clock,
  CheckCircle,
  ExternalLink,
  MapPin,
  RefreshCw,
  Activity,
  Heart,
  ShieldAlert,
} from 'lucide-react';

interface SosEventItem {
  id: string;
  victim_id: string;
  mode: string;
  escalation: string;
  stage: number;
  status: string;
  note: string | null;
  accuracy_m: number | null;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
  resolved_at: string | null;
  victim_name: string | null;
  victim_phone: string | null;
}

interface UrgentCheckinItem {
  id: string;
  user_id: string;
  status: string;
  note: string | null;
  latitude: number | null;
  longitude: number | null;
  accuracy_meters: number | null;
  created_at: string;
  user_name: string | null;
  user_phone: string | null;
}

export default function SosMonitor({
  onNavigateToMap,
}: {
  onNavigateToMap?: () => void;
}) {
  const [sosList, setSosList] = useState<SosEventItem[]>([]);
  const [checkins, setCheckins] = useState<UrgentCheckinItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  const fetchSosData = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/sos');
      const json = await res.json();
      if (json.success) {
        setSosList(json.sosEvents || []);
        setCheckins(json.urgentCheckins || []);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSosData();
    const interval = setInterval(fetchSosData, 15000); // 15s polling for operations
    return () => clearInterval(interval);
  }, [fetchSosData]);

  const updateStatus = async (id: string, newStatus: string) => {
    setUpdatingId(id);
    try {
      const res = await fetch('/api/sos', {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id, status: newStatus }),
      });
      const json = await res.json();
      if (json.success) {
        fetchSosData();
      }
    } catch (err) {
      console.error(err);
    } finally {
      setUpdatingId(null);
    }
  };

  const activeSosList = sosList.filter((s) => s.status !== 'RESOLVED' && s.status !== 'CANCELLED');

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <div>
          <div className="flex items-center gap-2">
            <span className="flex h-3 w-3 relative">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-rose-500"></span>
            </span>
            <h2 className="text-xl font-bold text-slate-900">Monitoring Sinyal Darurat SOS & Evakuasi Warga</h2>
          </div>
          <p className="text-xs text-slate-500 mt-1">
            Feed telemetri darurat real-time dari warga yang menekan tombol SOS atau broadcast butuh bantuan.
          </p>
        </div>
        <div className="flex items-center gap-2">
          {onNavigateToMap && (
            <button
              onClick={onNavigateToMap}
              className="inline-flex items-center gap-1.5 px-3 py-2 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold transition shadow-xs"
            >
              <MapPin className="w-3.5 h-3.5" /> Buka Peta Taktis
            </button>
          )}
          <button
            onClick={fetchSosData}
            disabled={loading}
            className="inline-flex items-center gap-2 px-3 py-2 rounded-xl border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 transition"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} /> Sinkronisasi
          </button>
        </div>
      </div>

      {/* Overview Stat Counters */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-rose-50 border border-rose-200 p-4 rounded-2xl">
          <div className="flex items-center justify-between text-rose-700 text-xs font-bold uppercase tracking-wider">
            <span>Sinyal SOS Aktif</span>
            <ShieldAlert className="w-4 h-4 text-rose-600" />
          </div>
          <div className="mt-2 text-3xl font-extrabold text-rose-900">{activeSosList.length}</div>
          <span className="text-[11px] text-rose-600 mt-0.5 block">Membutuhkan evakuasi/respon cepat</span>
        </div>

        <div className="bg-amber-50 border border-amber-200 p-4 rounded-2xl">
          <div className="flex items-center justify-between text-amber-700 text-xs font-bold uppercase tracking-wider">
            <span>Warga Butuh Bantuan (Check-in)</span>
            <Heart className="w-4 h-4 text-amber-600" />
          </div>
          <div className="mt-2 text-3xl font-extrabold text-amber-900">
            {checkins.filter((c) => c.status === 'NEED_HELP').length}
          </div>
          <span className="text-[11px] text-amber-600 mt-0.5 block">Status `NEED_HELP` dari keluarga</span>
        </div>

        <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-2xl">
          <div className="flex items-center justify-between text-emerald-700 text-xs font-bold uppercase tracking-wider">
            <span>Kasus Terselesaikan</span>
            <CheckCircle className="w-4 h-4 text-emerald-600" />
          </div>
          <div className="mt-2 text-3xl font-extrabold text-emerald-900">
            {sosList.filter((s) => s.status === 'RESOLVED').length}
          </div>
          <span className="text-[11px] text-emerald-600 mt-0.5 block">Telah dievakuasi atau aman</span>
        </div>
      </div>

      {/* SOS Events Section */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="p-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <h3 className="font-bold text-sm text-slate-800 flex items-center gap-2">
            <Activity className="w-4 h-4 text-rose-500" /> Antrean Panggilan Darurat SOS
          </h3>
          <span className="text-xs text-slate-500">{activeSosList.length} kasus aktif</span>
        </div>

        <div className="divide-y divide-slate-100">
          {sosList.length === 0 ? (
            <div className="p-8 text-center text-slate-400 text-sm">
              Tidak ada panggilan SOS aktif saat ini.
            </div>
          ) : (
            sosList.map((sos) => {
              const isActive = sos.status !== 'RESOLVED' && sos.status !== 'CANCELLED';
              return (
                <div key={sos.id} className={`p-4 transition ${isActive ? 'bg-rose-50/30' : 'bg-white'}`}>
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[11px] font-bold ${
                            isActive ? 'bg-rose-600 text-white animate-pulse' : 'bg-slate-200 text-slate-700'
                          }`}
                        >
                          {sos.status}
                        </span>
                        <span className="text-xs font-mono text-slate-400">ID: {sos.id.slice(0, 8)}...</span>
                        <span className="text-xs text-slate-500 flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {new Date(sos.created_at).toLocaleString('id-ID', {
                            dateStyle: 'medium',
                            timeStyle: 'short',
                          })}
                        </span>
                      </div>

                      <div className="text-base font-bold text-slate-900 flex items-center gap-2">
                        {sos.victim_name || 'Korban / Warga Terdaftar'}
                        {sos.victim_phone && (
                          <a
                            href={`tel:${sos.victim_phone}`}
                            className="text-xs font-semibold text-sky-600 hover:underline inline-flex items-center gap-1 ml-2 bg-sky-50 px-2 py-0.5 rounded-md"
                          >
                            <Phone className="w-3 h-3" /> {sos.victim_phone}
                          </a>
                        )}
                      </div>

                      <p className="text-xs text-slate-600">
                        {sos.note || 'Panggilan darurat aktif dipicu dari tombol SOS aplikasi Siagaku.'}
                      </p>
                      <div className="text-[11px] text-slate-400">
                        Eskalasi: <span className="font-semibold text-slate-600">{sos.escalation}</span> • Mode:{' '}
                        <span className="font-semibold text-slate-600">{sos.mode}</span>
                      </div>

                      {sos.latitude && sos.longitude && (
                        <div className="flex flex-wrap items-center gap-2 pt-1.5">
                          <span className="text-[11px] font-mono text-slate-600 bg-slate-100 px-2 py-0.5 rounded border border-slate-200/60 flex items-center gap-1">
                            <MapPin className="w-3 h-3 text-rose-500" />
                            GPS: {sos.latitude.toFixed(5)}, {sos.longitude.toFixed(5)}
                          </span>
                          {onNavigateToMap && (
                            <button
                              onClick={onNavigateToMap}
                              className="text-xs text-sky-600 font-semibold hover:underline inline-flex items-center gap-1"
                            >
                              Lihat di Peta Ops ↗
                            </button>
                          )}
                          <a
                            href={`https://www.google.com/maps/search/?api=1&query=${sos.latitude},${sos.longitude}`}
                            target="_blank"
                            rel="noreferrer"
                            className="text-xs text-slate-400 hover:text-slate-700 inline-flex items-center gap-1"
                          >
                            Google Maps <ExternalLink className="w-3 h-3" />
                          </a>
                        </div>
                      )}
                    </div>

                    <div className="flex items-center gap-2">
                      {isActive && (
                        <button
                          onClick={() => updateStatus(sos.id, 'RESOLVED')}
                          disabled={updatingId === sos.id}
                          className="px-3.5 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition flex items-center gap-1.5 shadow-xs"
                        >
                          <CheckCircle className="w-3.5 h-3.5" /> Selesaikan Kasus
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>

      {/* Urgent Check-in Feed */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="p-4 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
          <h3 className="font-bold text-sm text-slate-800 flex items-center gap-2">
            <Heart className="w-4 h-4 text-amber-500" /> Laporan Butuh Bantuan Keluarga (Family Check-in)
          </h3>
          <span className="text-xs text-slate-500">{checkins.length} laporan siaga</span>
        </div>

        <div className="divide-y divide-slate-100">
          {checkins.length === 0 ? (
            <div className="p-8 text-center text-slate-400 text-sm">
              Belum ada keluarga yang melaporkan kondisi bahaya.
            </div>
          ) : (
            checkins.map((item) => (
              <div key={item.id} className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span
                      className={`px-2 py-0.5 rounded-full text-[11px] font-bold ${
                        item.status === 'NEED_HELP'
                          ? 'bg-rose-100 text-rose-700 border border-rose-300'
                          : 'bg-amber-100 text-amber-700 border border-amber-300'
                      }`}
                    >
                      {item.status === 'NEED_HELP' ? '🚨 BUTUH BANTUAN SEGERA' : '🏃 SEDANG MENGUNGSI'}
                    </span>
                    <span className="text-xs text-slate-400">
                      {new Date(item.created_at).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })} WIB
                    </span>
                  </div>

                  <div className="font-bold text-sm text-slate-900">{item.user_name || 'Anggota Keluarga'}</div>
                  {item.note && <div className="text-xs text-slate-600 italic">"{item.note}"</div>}
                </div>

                {item.latitude && item.longitude && (
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}`}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-sky-50 text-sky-700 text-xs font-semibold hover:bg-sky-100 transition self-start sm:self-auto"
                  >
                    <MapPin className="w-3.5 h-3.5" /> Buka Lokasi GPS ({item.latitude.toFixed(4)},{' '}
                    {item.longitude.toFixed(4)})
                    <ExternalLink className="w-3 h-3" />
                  </a>
                )}
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
