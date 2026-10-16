'use client';

import { useEffect, useState } from 'react';
import {
  Activity,
  ArrowRight,
  ExternalLink,
  MapPin,
  Radio,
  RefreshCw,
  Send,
  Waves,
} from 'lucide-react';
import { Alert, Button, Card, ConfirmDialog, SeverityBadge } from '@/components/admin/ui';
import { adminFetch, errorMessage } from '@/lib/admin/client';
import type { Severity } from '@/lib/admin/types';

export interface BmkgQuake {
  Tanggal?: string;
  Jam?: string;
  DateTime?: string;
  Coordinates?: string;
  Lintang?: string;
  Bujur?: string;
  Magnitude?: string;
  Kedalaman?: string;
  Wilayah?: string;
  Potensi?: string;
  Dirasakan?: string;
  Shakemap?: string;
}

const SEVERITY_HINT: Record<Severity, string> = {
  AWAS: 'Ancaman sedang terjadi, segera bertindak',
  SIAGA: 'Ancaman dekat, bersiap evakuasi',
  WASPADA: 'Potensi ancaman, pantau perkembangan',
  INFO: 'Informasi umum tanpa tindakan segera',
  AMAN: 'Kondisi kondusif, tidak ada bahaya',
};

interface BmkgLiveCardProps {
  onUseInDraft?: (quake: BmkgQuake, severity: Severity) => void;
  onBroadcasted?: () => void;
}

export function BmkgLiveCard({ onUseInDraft, onBroadcasted }: BmkgLiveCardProps) {
  const [quake, setQuake] = useState<BmkgQuake | null>(null);
  const [severity, setSeverity] = useState<Severity>('INFO');
  const [loading, setLoading] = useState(true);
  const [broadcasting, setBroadcasting] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [lastFetch, setLastFetch] = useState<string | null>(null);

  const fetchBmkg = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/bmkg?type=latest');
      if (!res.ok) throw new Error(`BMKG feed respons HTTP ${res.status}`);
      const json = await res.json();
      if (json.quake) {
        setQuake(json.quake);
        setSeverity(json.severity || 'INFO');
        setLastFetch(new Date().toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' }));
      }
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchBmkg();
  }, []);

  const handleBroadcast = async () => {
    if (!quake) return;
    setBroadcasting(true);
    setError(null);
    try {
      await adminFetch('/api/bmkg', {
        method: 'POST',
        body: JSON.stringify({ quake, severity }),
      });
      setSuccess(`Sinyal peringatan BMKG M ${quake.Magnitude} berhasil disiarkan ke ponsel warga.`);
      setConfirmOpen(false);
      onBroadcasted?.();
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setBroadcasting(false);
    }
  };

  const magNum = parseFloat(quake?.Magnitude || '0');
  const isTsunami = /tsunami/i.test(quake?.Potensi || '');

  return (
    <Card className="overflow-hidden border-navy/20 shadow-sm">
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-border-neutral bg-gradient-to-r from-navy/[0.04] to-navy/[0.01] px-5 py-3.5">
        <div className="flex items-center gap-2.5">
          <span className="relative flex size-3">
            <span className="absolute inline-flex size-full animate-ping rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex size-3 rounded-full bg-emerald-500" />
          </span>
          <span className="text-xs font-bold tracking-wider text-navy uppercase">
            Sinyal Resmi BMKG TEWS
          </span>
          {lastFetch ? (
            <span className="text-xs text-muted">· Diperbarui {lastFetch} WIB</span>
          ) : null}
        </div>
        <button
          type="button"
          onClick={() => void fetchBmkg()}
          disabled={loading}
          className="inline-flex items-center gap-1.5 text-xs font-semibold text-navy hover:text-navy/70 disabled:opacity-50"
        >
          <RefreshCw className={`size-3.5 ${loading ? 'animate-spin' : ''}`} aria-hidden />
          Perbarui data
        </button>
      </div>

      <div className="p-5">
        {error ? (
          <div className="mb-4">
            <Alert tone="error" onDismiss={() => setError(null)}>{error}</Alert>
          </div>
        ) : null}
        {success ? (
          <div className="mb-4">
            <Alert tone="success" onDismiss={() => setSuccess(null)}>{success}</Alert>
          </div>
        ) : null}

        {!quake && loading ? (
          <div className="flex items-center justify-center py-8 text-sm text-muted">
            <Activity className="mr-2 size-4 animate-spin text-navy" />
            Mengambil data pengumuman gempa BMKG...
          </div>
        ) : !quake ? (
          <p className="py-4 text-center text-sm text-muted">Data BMKG belum tersedia saat ini.</p>
        ) : (
          <div className="space-y-4">
            <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
              <div className="flex items-start gap-4">
                <div className="flex flex-col items-center justify-center rounded-xl bg-navy p-3 text-white min-w-20">
                  <span className="text-[10px] font-bold uppercase tracking-wider text-white/70">
                    Magnitude
                  </span>
                  <span className="text-2xl font-black">{quake.Magnitude ?? '-'}</span>
                  <span className="text-[10px] text-white/80">{quake.Kedalaman ?? '-'}</span>
                </div>

                <div className="space-y-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <SeverityBadge level={severity} />
                    <span className="text-xs font-semibold text-muted">
                      {isTsunami ? 'Potensi Tsunami' : 'Gempa Bumi'}
                    </span>
                  </div>
                  <p className="text-xs font-medium text-navy/75">
                    {SEVERITY_HINT[severity]}
                  </p>
                  <p className="flex items-center gap-1 text-sm font-bold text-navy">
                    <MapPin className="size-4 shrink-0 text-muted" aria-hidden />
                    {quake.Wilayah ?? 'Indonesia'}
                  </p>
                </div>
              </div>

              {quake.Shakemap ? (
                <a
                  href={`https://data.bmkg.go.id/DataMKG/TEWS/${quake.Shakemap}`}
                  target="_blank"
                  rel="noreferrer"
                  className="group relative flex items-center gap-2 rounded-lg border border-border-neutral bg-cream/30 p-2 text-xs font-semibold text-navy hover:bg-cream"
                >
                  <span className="truncate max-w-36">Peta Shakemap BMKG</span>
                  <ExternalLink className="size-3.5 text-muted group-hover:text-navy" aria-hidden />
                </a>
              ) : null}
            </div>

            <div className="grid gap-2 rounded-lg border border-border-neutral bg-cream/40 p-3 text-xs sm:grid-cols-2 md:grid-cols-4">
              <div>
                <span className="text-muted block">Waktu Gempa:</span>
                <span className="font-semibold text-navy">
                  {quake.Tanggal} {quake.Jam}
                </span>
              </div>
              <div>
                <span className="text-muted block">Koordinat:</span>
                <span className="font-semibold text-navy">{quake.Coordinates ?? '-'}</span>
              </div>
              <div className="sm:col-span-2">
                <span className="text-muted block">Potensi & Keterangan:</span>
                <span className={`font-semibold ${isTsunami ? 'text-awas font-bold' : 'text-navy'}`}>
                  {quake.Potensi || 'Tidak berpotensi tsunami'}
                  {quake.Dirasakan ? ` · Dirasakan: ${quake.Dirasakan}` : ''}
                </span>
              </div>
            </div>

            <div className="flex flex-wrap items-center justify-end gap-2.5 pt-1">
              {onUseInDraft ? (
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  icon={ArrowRight}
                  onClick={() => onUseInDraft(quake, severity)}
                >
                  Salin ke Form Draf
                </Button>
              ) : null}

              <Button
                type="button"
                variant="accent"
                size="sm"
                icon={Send}
                onClick={() => setConfirmOpen(true)}
              >
                Siarkan Pengumuman BMKG Ini ke Warga
              </Button>
            </div>
          </div>
        )}
      </div>

      <ConfirmDialog
        open={confirmOpen}
        title="Siarkan Sinyal BMKG ke Warga?"
        confirmLabel="Siarkan Sekarang"
        tone="accent"
        busy={broadcasting}
        onClose={() => setConfirmOpen(false)}
        onConfirm={() => void handleBroadcast()}
      >
        <div className="space-y-3 text-sm">
          <p>
            Pengumuman resmi dari BMKG TEWS akan dipublikasikan ke daftar notifikasi seluruh warga
            dan memicu pemberitahuan darurat ke aplikasi Wero:
          </p>
          <div className="rounded-lg border border-border-neutral bg-cream/60 p-3 text-[#1A1D21]">
            <div className="flex items-center gap-2">
              <SeverityBadge level={severity} />
              <span className="font-bold text-navy">Gempa M {quake?.Magnitude}</span>
            </div>
            <p className="mt-1 text-xs font-semibold text-muted">{quake?.Wilayah}</p>
            <p className="mt-1 text-xs text-navy">{quake?.Potensi}</p>
          </div>
          <p className="text-xs text-muted">
            Tingkat status: <strong>{severity}</strong> ({SEVERITY_HINT[severity]}).
          </p>
        </div>
      </ConfirmDialog>
    </Card>
  );
}
