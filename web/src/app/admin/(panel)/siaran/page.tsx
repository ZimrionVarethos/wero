'use client';

import { useEffect, useMemo, useState, type FormEvent } from 'react';
import { useAdminData } from '@/lib/admin/use-admin-data';
import { BellRing, CircleAlert, Search, Send } from 'lucide-react';
import { useAdmin } from '@/components/admin/AdminShell';
import {
  Alert,
  Button,
  Card,
  CardHeader,
  ConfirmDialog,
  PageHeader,
  SelectField,
  SeverityBadge,
  TextArea,
  TextField,
  SEVERITY_STYLE,
} from '@/components/admin/ui';
import { BmkgLiveCard, type BmkgQuake } from '@/components/admin/BmkgLiveCard';
import { BroadcastHistoryCard } from '@/components/admin/BroadcastHistoryCard';
import { adminFetch, errorMessage } from '@/lib/admin/client';
import { HAZARD_LABEL } from '@/lib/admin/format';
import type { BroadcastRow, Region, Severity } from '@/lib/admin/types';

const SEVERITIES: { value: Severity; hint: string }[] = [
  { value: 'AWAS', hint: 'Ancaman sedang terjadi, segera bertindak' },
  { value: 'SIAGA', hint: 'Ancaman dekat, bersiap evakuasi' },
  { value: 'WASPADA', hint: 'Potensi ancaman, pantau perkembangan' },
  { value: 'INFO', hint: 'Informasi umum tanpa tindakan segera' },
];

export default function BroadcastPage() {
  const me = useAdmin();
  const [severity, setSeverity] = useState<Severity>('SIAGA');
  const [hazard, setHazard] = useState('FLOOD');
  const [headline, setHeadline] = useState('');
  const [message, setMessage] = useState('');
  const [targetAll, setTargetAll] = useState(false);
  const [targets, setTargets] = useState<string[]>([]);
  const [regions, setRegions] = useState<Region[]>([]);
  const [regionQuery, setRegionQuery] = useState('');
  const historyQ = useAdminData<BroadcastRow[]>('/api/broadcast');
  const history = historyQ.loading ? null : (historyQ.data ?? []);
  const [confirming, setConfirming] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<{ delivered: boolean; target: string } | null>(null);
  const [fieldError, setFieldError] = useState<string | null>(null);

  useEffect(() => {
    if (!me.isSuper) return;
    fetch('/api/regions')
      .then((r) => r.json())
      .then((j: { data?: Region[] }) => setRegions(j.data ?? []))
      .catch(() => undefined);
  }, [me.isSuper]);

  const targetLabel = useMemo(() => {
    if (!me.isSuper) return me.regionName ?? 'Wilayah tugas';
    if (targetAll) return 'Seluruh pengguna, topik nasional';
    const names = regions.filter((r) => targets.includes(r.id)).map((r) => r.name);
    return names.length ? names.join(', ') : 'Belum dipilih';
  }, [me, targetAll, targets, regions]);

  const filteredRegions = useMemo(() => {
    const q = regionQuery.trim().toLowerCase();
    return regions.filter((r) => !q || r.name.toLowerCase().includes(q)).slice(0, 60);
  }, [regions, regionQuery]);

  const review = (e: FormEvent) => {
    e.preventDefault();
    setResult(null);
    if (headline.trim().length < 5) return setFieldError('Judul minimal 5 karakter.');
    if (me.isSuper && !targetAll && targets.length === 0) {
      return setFieldError('Pilih minimal satu wilayah tujuan.');
    }
    setFieldError(null);
    setConfirming(true);
  };

  const send = async () => {
    setSending(true);
    try {
      const res = await adminFetch<{ delivered: boolean }>('/api/broadcast', {
        method: 'POST',
        body: JSON.stringify({
          severity,
          disaster_type: hazard,
          headline: headline.trim(),
          message: message.trim(),
          target_type: me.isSuper && targetAll ? 'ALL' : 'SPECIFIC',
          target_region_ids: targets,
        }),
      });
      setResult({ delivered: res.delivered, target: targetLabel });
      setHeadline('');
      setMessage('');
      setConfirming(false);
      historyQ.reload();
    } catch (e) {
      setError(errorMessage(e));
      setConfirming(false);
    } finally {
      setSending(false);
    }
  };

  const handleUseBmkgInDraft = (quake: BmkgQuake, bmkgSeverity: Severity) => {
    setSeverity(bmkgSeverity);
    const isTsunami = /tsunami/i.test(quake.Potensi || '');
    setHazard(isTsunami ? 'TSUNAMI' : 'EARTHQUAKE');
    setHeadline(`Gempa M ${quake.Magnitude || '0'} - ${quake.Wilayah || 'Indonesia'}`);
    setMessage(
      `Kedalaman ${quake.Kedalaman || '-'}. ${quake.Potensi || ''}${
        quake.Dirasakan ? ` (Dirasakan: ${quake.Dirasakan})` : ''
      }`.trim(),
    );
    if (me.isSuper) {
      setTargetAll(true);
    }
  };

  const sev = SEVERITY_STYLE[severity];

  return (
    <>
      <PageHeader
        title="Siaran peringatan"
        description="Pantau sinyal resmi BMKG TEWS dan kirim siaran darurat ke ponsel warga di wilayah terdampak."
      />

      <div className="mb-6 space-y-3">
        {error || historyQ.error ? (
          <Alert tone="error" onDismiss={() => setError(null)}>
            {error ?? historyQ.error}
          </Alert>
        ) : null}
        {result ? (
          <Alert tone={result.delivered ? 'success' : 'error'} onDismiss={() => setResult(null)}>
            {result.delivered
              ? `Siaran terkirim ke ${result.target}.`
              : `Siaran tersimpan, tetapi notifikasi push gagal dikirim ke ${result.target}. Periksa konfigurasi FCM di server.`}
          </Alert>
        ) : null}

        {/* Live BMKG Official Earthquake Banner Card */}
        <BmkgLiveCard
          onUseInDraft={handleUseBmkgInDraft}
          onBroadcasted={() => historyQ.reload()}
        />
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,7fr)_minmax(0,5fr)]">
        <Card>
          <CardHeader title="Draf siaran manual" description="Kustomisasi judul, instruksi, dan sasaran wilayah" />
          <form onSubmit={review} className="space-y-5 p-5" noValidate>
            <fieldset>
              <legend className="mb-2 text-sm font-semibold text-navy">Tingkat status</legend>
              <div className="grid gap-2 sm:grid-cols-2">
                {SEVERITIES.map((s) => (
                  <label
                    key={s.value}
                    className={`flex min-h-14 cursor-pointer items-start gap-3 rounded-lg border p-3 transition-colors ${
                      severity === s.value
                        ? 'border-navy bg-navy/[0.03] ring-1 ring-navy'
                        : 'border-border-neutral hover:border-navy/40'
                    }`}
                  >
                    <input
                      type="radio"
                      name="severity"
                      value={s.value}
                      checked={severity === s.value}
                      onChange={() => setSeverity(s.value)}
                      className="mt-1 size-4 accent-[#12263F]"
                    />
                    <span>
                      <SeverityBadge level={s.value} />
                      <span className="mt-1 block text-xs text-muted">{s.hint}</span>
                    </span>
                  </label>
                ))}
              </div>
            </fieldset>

            <SelectField label="Jenis bencana" value={hazard} onChange={(e) => setHazard(e.target.value)}>
              {Object.entries(HAZARD_LABEL).map(([v, l]) => (
                <option key={v} value={v}>
                  {l}
                </option>
              ))}
            </SelectField>

            <TextField
              label="Judul peringatan"
              value={headline}
              maxLength={120}
              onChange={(e) => setHeadline(e.target.value)}
              hint={`${headline.length} dari 120 karakter. Tampil sebagai judul notifikasi.`}
              placeholder="Contoh: Gempa bumi M 6.2 terasa kuat, waspada gempa susulan"
            />
            <TextArea
              label="Instruksi tambahan"
              rows={3}
              maxLength={500}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              hint="Satu atau dua kalimat perintah yang jelas untuk warga."
            />

            <fieldset>
              <legend className="mb-2 text-sm font-semibold text-navy">Wilayah tujuan</legend>
              {!me.isSuper ? (
                <p className="rounded-lg border border-border-neutral bg-cream/60 px-3 py-3 text-sm">
                  <span className="font-semibold text-navy">{me.regionName ?? 'Wilayah tugas'}</span>
                  <span className="block text-xs text-muted">Admin wilayah menyiarkan ke wilayah tugasnya.</span>
                </p>
              ) : (
                <div className="space-y-3">
                  <div className="flex flex-wrap gap-2">
                    <label className={`flex min-h-12 cursor-pointer items-center gap-2 rounded-lg border px-3 text-sm font-semibold ${!targetAll ? 'border-navy ring-1 ring-navy' : 'border-border-neutral'}`}>
                      <input type="radio" name="target" checked={!targetAll} onChange={() => setTargetAll(false)} className="accent-[#12263F]" />
                      Wilayah tertentu
                    </label>
                    <label className={`flex min-h-12 cursor-pointer items-center gap-2 rounded-lg border px-3 text-sm font-semibold ${targetAll ? 'border-awas ring-1 ring-awas' : 'border-border-neutral'}`}>
                      <input type="radio" name="target" checked={targetAll} onChange={() => setTargetAll(true)} className="accent-[#C62828]" />
                      Seluruh pengguna (Nasional)
                    </label>
                  </div>
                  {!targetAll ? (
                    <div className="rounded-lg border border-border-neutral">
                      <div className="relative border-b border-border-neutral">
                        <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted" aria-hidden />
                        <input
                          id="cari-wilayah"
                          type="search"
                          value={regionQuery}
                          onChange={(e) => setRegionQuery(e.target.value)}
                          placeholder="Cari kabupaten atau kota"
                          className="min-h-12 w-full rounded-t-lg bg-white pl-9 pr-3 text-sm outline-none"
                        />
                      </div>
                      <ul className="max-h-44 overflow-y-auto p-1">
                        {filteredRegions.map((r) => (
                          <li key={r.id}>
                            <label className="flex min-h-10 cursor-pointer items-center gap-3 rounded-md px-2 text-sm hover:bg-cream">
                              <input
                                type="checkbox"
                                checked={targets.includes(r.id)}
                                onChange={(e) => setTargets((cur) => (e.target.checked ? [...cur, r.id] : cur.filter((id) => id !== r.id)))}
                                className="size-4 accent-[#12263F]"
                              />
                              {r.name}
                            </label>
                          </li>
                        ))}
                      </ul>
                    </div>
                  ) : (
                    <p className="flex items-start gap-2 rounded-lg bg-awas/5 px-3 py-2 text-xs font-medium text-awas">
                      <CircleAlert className="mt-0.5 size-4 shrink-0" aria-hidden />
                      Siaran nasional diterima seluruh pengguna aplikasi Wero.
                    </p>
                  )}
                </div>
              )}
            </fieldset>

            {fieldError ? <Alert tone="error">{fieldError}</Alert> : null}

            <Button type="submit" variant="accent" icon={Send} className="w-full sm:w-auto">
              Tinjau sebelum kirim
            </Button>
          </form>
        </Card>

        <div className="space-y-6">
          <Card>
            <CardHeader title="Pratinjau notifikasi" description="Perkiraan tampilan di ponsel warga" />
            <div className="p-5">
              <div className="rounded-2xl bg-navy p-4">
                <div className="rounded-xl bg-white p-4 shadow-sm">
                  <div className="flex items-center gap-2 text-xs text-muted">
                    <BellRing className="size-3.5" aria-hidden /> Wero · Sekarang
                  </div>
                  <div className="mt-2 flex items-start gap-3">
                    <span className={`grid size-9 shrink-0 place-items-center rounded-lg ${sev.className}`}>
                      <sev.Icon className="size-5" aria-hidden />
                    </span>
                    <div className="min-w-0">
                      <p className="text-sm font-bold text-[#1A1D21]">
                        {severity} {HAZARD_LABEL[hazard]}
                      </p>
                      <p className="mt-0.5 break-words text-sm text-[#1A1D21]">{headline || 'Judul peringatan tampil di sini'}</p>
                      {message ? <p className="mt-1 break-words text-xs text-muted">{message}</p> : null}
                    </div>
                  </div>
                </div>
              </div>
              <p className="mt-3 text-xs text-muted">Tujuan: {targetLabel}</p>
            </div>
          </Card>

          {/* Broadcast history including BMKG events */}
          <BroadcastHistoryCard
            history={history}
            loading={historyQ.loading}
            isSuper={me.isSuper}
            regionName={me.regionName}
            onReload={() => historyQ.reload()}
            onError={(msg) => setError(msg)}
          />
        </div>
      </div>

      <ConfirmDialog
        open={confirming}
        title="Kirim siaran sekarang?"
        confirmLabel="Kirim siaran"
        tone="accent"
        busy={sending}
        onClose={() => setConfirming(false)}
        onConfirm={() => void send()}
      >
        <dl className="space-y-2 rounded-lg border border-border-neutral bg-cream/60 p-3 text-[#1A1D21]">
          <div className="flex items-center gap-2">
            <dt className="sr-only">Status</dt>
            <dd>
              <SeverityBadge level={severity} />
            </dd>
            <dd className="text-sm font-semibold">{HAZARD_LABEL[hazard]}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted">Judul</dt>
            <dd className="text-sm font-semibold">{headline}</dd>
          </div>
          <div>
            <dt className="text-xs text-muted">Tujuan</dt>
            <dd className="text-sm font-semibold">{targetLabel}</dd>
          </div>
        </dl>
        <p className="mt-3 text-sm">Siaran tidak dapat ditarik kembali setelah terkirim.</p>
      </ConfirmDialog>
    </>
  );
}
