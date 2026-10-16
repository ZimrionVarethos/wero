'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useAdminData } from '@/lib/admin/use-admin-data';
import { ArrowLeft, CheckCircle2, ClipboardCopy, Eye, LockKeyhole, RefreshCw, Siren, UserRound, XCircle } from 'lucide-react';
import { AdminMap, INDONESIA_CENTER, type MapPoint } from '@/components/admin/Map';
import { Alert, Button, Card, ConfirmDialog, EmptyState, PageHeader, Segmented, SkeletonRows, SosStatusPill } from '@/components/admin/ui';
import { adminFetch, errorMessage } from '@/lib/admin/client';
import { formatAgo, formatDateTime, formatTime, MODE_LABEL } from '@/lib/admin/format';
import type { SosDetail, SosRow, SosStatus } from '@/lib/admin/types';

type Filter = 'OPEN' | 'ALL' | 'RESOLVED' | 'CANCELLED';

const FILTERS: { value: Filter; label: string }[] = [
  { value: 'OPEN', label: 'Aktif' },
  { value: 'RESOLVED', label: 'Selesai' },
  { value: 'CANCELLED', label: 'Dibatalkan' },
  { value: 'ALL', label: 'Semua' },
];

const ESCALATION_LABEL: Record<string, string> = {
  NONE: 'Belum diperluas',
  TO_PUBLIC: 'Diperluas ke publik',
  TO_POSKO: 'Diteruskan ke posko',
};

const PIN: Record<SosStatus, string> = {
  ACTIVE: '#C62828',
  CLAIMED: '#1565C0',
  RESOLVED: '#2E7D32',
  CANCELLED: '#5F6B76',
  EXPIRED: '#5F6B76',
};

const REFRESH_MS = 15_000;

function DetailRow({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <dt className="text-xs font-semibold text-muted">{label}</dt>
      <dd className="mt-0.5 text-sm font-medium text-[#1A1D21]">{children}</dd>
    </div>
  );
}

function SosDetailPanel({ id, onClose, onChanged }: { id: string; onClose: () => void; onChanged: (d: SosDetail) => void }) {
  const [detail, setDetail] = useState<SosDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [dialog, setDialog] = useState<'RESOLVED' | 'CANCELLED' | null>(null);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState<string | null>(null);

  // The parent keys this panel by case id, so state starts fresh for every case.
  useEffect(() => {
    adminFetch<SosDetail>(`/api/sos/${id}`)
      .then((d) => {
        setDetail(d);
        onChanged(d);
      })
      .catch((e) => setError(errorMessage(e)));
  }, [id, onChanged]);

  const changeStatus = async (status: 'RESOLVED' | 'CANCELLED', reason: string) => {
    setBusy(true);
    try {
      const d = await adminFetch<SosDetail>(`/api/sos/${id}`, { method: 'PATCH', body: JSON.stringify({ status, reason }) });
      setDetail(d);
      onChanged(d);
      setNotice(status === 'RESOLVED' ? 'Kasus ditandai selesai.' : 'Kasus dibatalkan.');
      setDialog(null);
    } catch (e) {
      setError(errorMessage(e));
      setDialog(null);
    } finally {
      setBusy(false);
    }
  };

  const copyCoords = async () => {
    if (!detail) return;
    await navigator.clipboard.writeText(`${detail.lat.toFixed(6)}, ${detail.lng.toFixed(6)}`).catch(() => undefined);
    setNotice('Koordinat disalin.');
  };

  const open = detail && (detail.status === 'ACTIVE' || detail.status === 'CLAIMED');

  return (
    <Card as="aside" className="flex min-h-0 flex-col">
      <div className="flex items-center gap-2 border-b border-border-neutral px-3 py-2">
        <Button variant="ghost" size="sm" icon={ArrowLeft} onClick={onClose}>
          Daftar kasus
        </Button>
      </div>

      <div className="min-h-0 flex-1 space-y-5 overflow-y-auto p-5">
        {error ? <Alert tone="error">{error}</Alert> : null}
        {notice ? (
          <Alert tone="success" onDismiss={() => setNotice(null)}>
            {notice}
          </Alert>
        ) : null}

        {!detail && !error ? <SkeletonRows rows={4} /> : null}

        {detail ? (
          <>
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <SosStatusPill status={detail.status} />
                {!detail.inside_region ? <span className="rounded-full bg-cream px-2 py-0.5 text-xs font-semibold text-muted">Zona penyangga</span> : null}
              </div>
              <h2 className="mt-2 text-xl font-bold text-navy">{detail.victim_name}</h2>
              <p className="text-sm text-muted">Dibuat {formatDateTime(detail.created_at)}, {formatAgo(detail.created_at)}</p>
            </div>

            <dl className="grid grid-cols-2 gap-4">
              <DetailRow label="Mode">{MODE_LABEL[detail.mode]}</DetailRow>
              <DetailRow label="Tahap radius">Tahap {detail.stage}</DetailRow>
              <DetailRow label="Eskalasi">{ESCALATION_LABEL[detail.escalation] ?? detail.escalation}</DetailRow>
              <DetailRow label="Akurasi GPS">{detail.accuracy_m != null ? `${Math.round(detail.accuracy_m)} m` : 'Tidak tersedia'}</DetailRow>
            </dl>

            <div className="rounded-lg border border-navy/15 bg-navy/[0.03] p-4">
              <p className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-navy">
                <LockKeyhole className="size-3.5" aria-hidden /> Lokasi tepat
              </p>
              <p className="mt-1.5 font-mono text-sm text-[#1A1D21]">
                {detail.lat.toFixed(6)}, {detail.lng.toFixed(6)}
              </p>
              <div className="mt-3 flex flex-wrap gap-2">
                <Button size="sm" variant="secondary" icon={ClipboardCopy} onClick={copyCoords}>
                  Salin koordinat
                </Button>
              </div>
              <p className="mt-3 flex items-start gap-1.5 text-xs text-muted">
                <Eye className="mt-0.5 size-3.5 shrink-0" aria-hidden />
                Pembukaan lokasi ini tercatat di log audit atas nama Anda. Bagikan hanya kepada tim penolong resmi.
              </p>
            </div>

            {detail.note ? (
              <div>
                <h3 className="text-sm font-bold text-navy">Catatan korban</h3>
                <p className="mt-1 whitespace-pre-line text-sm text-[#1A1D21]">{detail.note}</p>
              </div>
            ) : null}

            <div>
              <h3 className="text-sm font-bold text-navy">Penolong</h3>
              {detail.responders.length === 0 ? (
                <p className="mt-1 text-sm text-muted">Belum ada relawan yang mengklaim kasus ini.</p>
              ) : (
                <ul className="mt-2 space-y-2">
                  {detail.responders.map((r, i) => (
                    <li key={`${r.name}-${i}`} className="flex items-center gap-3 rounded-lg border border-border-neutral px-3 py-2">
                      <UserRound className="size-4 text-muted" aria-hidden />
                      <span className="text-sm font-semibold text-navy">{r.name}</span>
                      <span className="ml-auto text-xs text-muted">
                        {r.status === 'ARRIVED' ? 'Sudah tiba' : 'Menuju lokasi'}, sejak {formatTime(r.claimed_at)}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </div>

            {open ? (
              <div className="grid gap-2 border-t border-border-neutral pt-5 sm:grid-cols-2">
                <Button variant="primary" icon={CheckCircle2} onClick={() => setDialog('RESOLVED')}>
                  Tandai selesai
                </Button>
                <Button variant="danger" icon={XCircle} onClick={() => setDialog('CANCELLED')}>
                  Batalkan kasus
                </Button>
              </div>
            ) : null}
          </>
        ) : null}
      </div>

      <ConfirmDialog
        open={dialog !== null}
        title={dialog === 'RESOLVED' ? 'Tandai SOS selesai?' : 'Batalkan SOS ini?'}
        confirmLabel={dialog === 'RESOLVED' ? 'Tandai selesai' : 'Batalkan kasus'}
        tone={dialog === 'RESOLVED' ? 'primary' : 'danger'}
        requireReason
        reasonLabel={dialog === 'RESOLVED' ? 'Ringkasan penanganan' : 'Alasan pembatalan, misalnya laporan palsu atau ganda'}
        busy={busy}
        onClose={() => setDialog(null)}
        onConfirm={(reason) => dialog && void changeStatus(dialog, reason)}
      >
        {dialog === 'RESOLVED'
          ? 'Kasus akan ditutup dan relawan tidak lagi diarahkan ke lokasi ini.'
          : 'Kasus dihentikan dan tidak lagi tampil sebagai aktif bagi relawan maupun warga sekitar.'}
      </ConfirmDialog>
    </Card>
  );
}

export default function SosPage() {
  const [filter, setFilter] = useState<Filter>('OPEN');
  // Deep link from the overview page, for example /admin/sos?kasus=<id>. The shell only renders
  // this page in the browser, so reading the URL during the first render is safe.
  const [selected, setSelected] = useState<string | null>(() =>
    typeof window === 'undefined' ? null : new URLSearchParams(window.location.search).get('kasus'),
  );
  const [exact, setExact] = useState<SosDetail | null>(null);
  const sos = useAdminData<SosRow[]>(`/api/sos?status=${filter}`, REFRESH_MS);
  const rows = useMemo(() => (sos.loading ? null : (sos.data ?? [])), [sos.loading, sos.data]);
  const { error, updatedAt, refreshing, reload, mutate } = sos;

  const select = (pointId: string) => {
    const id = pointId.split('#')[0];
    if (id === selected) return;
    setExact(null);
    setSelected(id);
    window.history.replaceState(null, '', `/admin/sos?kasus=${id}`);
  };

  const close = () => {
    setSelected(null);
    setExact(null);
    window.history.replaceState(null, '', '/admin/sos');
  };

  const onChanged = useCallback(
    (d: SosDetail) => {
      setExact(d);
      mutate((cur) => cur.map((r) => (r.id === d.id ? { ...r, status: d.status, responders: d.responders.length } : r)));
    },
    [mutate],
  );

  const points: MapPoint[] = useMemo(() => {
    const list: MapPoint[] = (rows ?? []).map((r) => ({
      id: r.id,
      lng: Number(r.approx_lng),
      lat: Number(r.approx_lat),
      color: PIN[r.status],
      approximate: true,
      muted: r.status !== 'ACTIVE' && r.status !== 'CLAIMED',
    }));
    // The opened case also gets a pin at its exact location.
    if (exact) list.push({ id: `${exact.id}#tepat`, lng: Number(exact.lng), lat: Number(exact.lat), color: '#12263F' });
    return list;
  }, [rows, exact]);

  const counts = useMemo(() => {
    const active = rows?.filter((r) => r.status === 'ACTIVE').length ?? 0;
    const claimed = rows?.filter((r) => r.status === 'CLAIMED').length ?? 0;
    return { active, claimed };
  }, [rows]);

  return (
    <>
      <PageHeader
        title="Pemantauan SOS"
        description={`Peta menampilkan lokasi perkiraan. Buka kasus untuk melihat lokasi tepat. Diperbarui setiap 15 detik${updatedAt ? `, terakhir pukul ${formatTime(updatedAt)}` : ''}.`}
        actions={
          <Button variant="secondary" icon={RefreshCw} onClick={reload} loading={refreshing}>
            Muat ulang
          </Button>
        }
      />

      {error ? (
        <div className="mb-4">
          <Alert tone="error">{error}</Alert>
        </div>
      ) : null}

      <div className="grid gap-4 lg:h-[calc(100vh-12.5rem)] lg:min-h-[560px] lg:grid-cols-[minmax(0,1fr)_400px]">
        <Card className="relative h-[420px] overflow-hidden lg:h-auto">
          <AdminMap
            center={INDONESIA_CENTER}
            zoom={4.5}
            points={points}
            selectedId={selected}
            onSelect={select}
            label="Peta SOS di wilayah tugas"
          />
          <div className="pointer-events-none absolute left-3 top-3 mr-14 flex flex-wrap gap-x-3 gap-y-1 rounded-lg bg-white/95 px-3 py-2 text-xs font-medium text-[#1A1D21] shadow-sm">
            <span className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-full bg-awas" aria-hidden /> Menunggu penolong
            </span>
            <span className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-full bg-info" aria-hidden /> Penolong menuju
            </span>
            <span className="flex items-center gap-1.5">
              <span className="size-2.5 rounded-full border-2 border-navy bg-navy" aria-hidden /> Lokasi tepat kasus terbuka
            </span>
          </div>
        </Card>

        {selected ? (
          <SosDetailPanel key={selected} id={selected} onClose={close} onChanged={onChanged} />
        ) : (
          <Card as="aside" className="flex min-h-0 flex-col">
            <div className="space-y-3 border-b border-border-neutral p-4">
              <Segmented label="Saring status SOS" value={filter} options={FILTERS} onChange={setFilter} />
              {filter === 'OPEN' && rows ? (
                <p className="text-sm text-muted">
                  <span className="font-bold text-awas">{counts.active}</span> menunggu penolong,{' '}
                  <span className="font-bold text-info">{counts.claimed}</span> penolong menuju
                </p>
              ) : null}
            </div>
            <div className="min-h-0 flex-1 overflow-y-auto">
              {rows === null ? (
                <SkeletonRows />
              ) : rows.length === 0 ? (
                <EmptyState icon={Siren} title={filter === 'OPEN' ? 'Tidak ada SOS aktif' : 'Tidak ada kasus'}>
                  {filter === 'OPEN' ? 'Kasus baru akan muncul otomatis.' : 'Belum ada kasus dengan status ini di wilayah Anda.'}
                </EmptyState>
              ) : (
                <ul aria-label="Daftar kasus SOS" className="divide-y divide-border-neutral">
                  {rows.map((r) => (
                    <li key={r.id}>
                      <button type="button" onClick={() => select(r.id)} className="w-full px-4 py-3.5 text-left hover:bg-cream/60 focus-visible:bg-cream">
                        <div className="flex items-center justify-between gap-2">
                          <span className="font-semibold text-navy">{r.victim_first_name}</span>
                          <span className="text-xs tabular-nums text-muted">{formatAgo(r.created_at)}</span>
                        </div>
                        <div className="mt-1.5 flex flex-wrap items-center gap-2">
                          <SosStatusPill status={r.status} />
                          <span className="text-xs text-muted">
                            {MODE_LABEL[r.mode]}, tahap {r.stage}, {r.responders} penolong{r.inside_region ? '' : ', zona penyangga'}
                          </span>
                        </div>
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </Card>
        )}
      </div>
    </>
  );
}
