'use client';

import Link from 'next/link';
import { ArrowRight, ClipboardList, Inbox, RefreshCw, Siren } from 'lucide-react';
import { useAdmin } from '@/components/admin/AdminShell';
import { Alert, Button, Card, CardHeader, EmptyState, PageHeader, SkeletonRows, SosStatusPill } from '@/components/admin/ui';
import { useAdminData } from '@/lib/admin/use-admin-data';
import { AUDIT_ACTION_LABEL, formatAgo, formatTime, MODE_LABEL } from '@/lib/admin/format';
import type { AuditRow, DashboardStats, SosRow } from '@/lib/admin/types';

const REFRESH_MS = 30_000;

function Stat({ label, value, detail, emphasis, href }: { label: string; value: number | string; detail?: string; emphasis?: boolean; href: string }) {
  return (
    <Link
      href={href}
      className={`group rounded-xl border bg-white p-5 transition-colors hover:border-navy ${emphasis ? 'border-awas/40 ring-1 ring-awas/20' : 'border-border-neutral'}`}
    >
      <p className="text-sm font-semibold text-muted">{label}</p>
      <p className={`mt-2 text-3xl font-extrabold tabular-nums tracking-tight ${emphasis ? 'text-awas' : 'text-navy'}`}>{value}</p>
      {detail ? <p className="mt-1 text-xs text-muted">{detail}</p> : null}
    </Link>
  );
}

export default function OverviewPage() {
  const me = useAdmin();
  const statsQ = useAdminData<DashboardStats>('/api/stats', REFRESH_MS);
  const openQ = useAdminData<SosRow[]>('/api/sos?status=OPEN', REFRESH_MS);
  const activityQ = useAdminData<AuditRow[]>('/api/audit?limit=8', REFRESH_MS);
  const stats = statsQ.data;
  const open = openQ.loading ? null : (openQ.data ?? []);
  const activity = activityQ.loading ? null : (activityQ.data ?? []);
  const error = statsQ.error ?? openQ.error ?? activityQ.error;
  const updatedAt = statsQ.updatedAt;
  const refreshing = statsQ.refreshing || openQ.refreshing || activityQ.refreshing;
  const load = () => {
    statsQ.reload();
    openQ.reload();
    activityQ.reload();
  };

  const waiting = stats?.sos.waiting ?? 0;

  return (
    <>
      <PageHeader
        title="Ringkasan"
        description={`${me.isSuper ? 'Seluruh wilayah' : `Wilayah ${me.regionName ?? 'belum ditetapkan'}`}. Diperbarui otomatis setiap 30 detik${updatedAt ? `, terakhir pukul ${formatTime(updatedAt)}` : ''}.`}
        actions={
          <Button variant="secondary" icon={RefreshCw} onClick={load} loading={refreshing}>
            Muat ulang
          </Button>
        }
      />

      {error ? (
        <div className="mb-6">
          <Alert tone="error">{error}</Alert>
        </div>
      ) : null}

      <div className="grid grid-cols-2 gap-4 lg:grid-cols-3 xl:grid-cols-6">
        <Stat
          label="Menunggu penolong"
          value={stats ? waiting : '-'}
          detail={stats?.sos.oldest_waiting_at ? `Terlama ${formatAgo(stats.sos.oldest_waiting_at)}` : 'Tidak ada yang menunggu'}
          emphasis={waiting > 0}
          href="/admin/sos"
        />
        <Stat label="Penolong menuju" value={stats?.sos.claimed ?? '-'} detail="SOS sudah diklaim relawan" href="/admin/sos" />
        <Stat label="Selesai 24 jam" value={stats?.sos.resolved_24h ?? '-'} detail="SOS ditutup" href="/admin/sos" />
        <Stat
          label="Titik evakuasi aktif"
          value={stats?.evacuation.active ?? '-'}
          detail={stats ? `Kapasitas ${stats.evacuation.capacity.toLocaleString('id-ID')} orang` : undefined}
          href="/admin/evakuasi"
        />
        <Stat label="Siaran 7 hari" value={stats?.broadcasts7d ?? '-'} detail="Peringatan dari petugas" href="/admin/siaran" />
        <Stat label="Laporan komunitas" value={stats?.pendingReports ?? '-'} detail="Menunggu moderasi" href="/admin/moderasi" />
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-[minmax(0,3fr)_minmax(0,2fr)]">
        <Card>
          <CardHeader
            title="SOS yang perlu ditindak"
            description="Menunggu penolong ditampilkan paling atas"
            actions={
              <Link href="/admin/sos" className="inline-flex min-h-10 items-center gap-1 text-sm font-semibold text-navy hover:underline">
                Buka peta SOS <ArrowRight className="size-4" aria-hidden />
              </Link>
            }
          />
          {open === null ? (
            <SkeletonRows rows={3} />
          ) : open.length === 0 ? (
            <EmptyState icon={Siren} title="Tidak ada SOS aktif">
              Kasus baru akan muncul di sini dan di halaman pemantauan SOS.
            </EmptyState>
          ) : (
            <ul className="divide-y divide-border-neutral">
              {open.slice(0, 6).map((s) => (
                <li key={s.id}>
                  <Link href={`/admin/sos?kasus=${s.id}`} className="flex flex-wrap items-center gap-x-4 gap-y-1 px-5 py-4 hover:bg-cream/60">
                    <SosStatusPill status={s.status} />
                    <span className="font-semibold text-navy">{s.victim_first_name}</span>
                    <span className="text-sm text-muted">
                      Mode {MODE_LABEL[s.mode]}, tahap {s.stage}, {s.responders} penolong
                      {s.inside_region ? '' : ', zona penyangga'}
                    </span>
                    <span className="ml-auto text-sm tabular-nums text-muted">{formatAgo(s.created_at)}</span>
                  </Link>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card>
          <CardHeader
            title="Aktivitas terbaru"
            actions={
              <Link href="/admin/audit" className="inline-flex min-h-10 items-center gap-1 text-sm font-semibold text-navy hover:underline">
                Log audit <ArrowRight className="size-4" aria-hidden />
              </Link>
            }
          />
          {activity === null ? (
            <SkeletonRows rows={4} />
          ) : activity.length === 0 ? (
            <EmptyState icon={Inbox} title="Belum ada aktivitas" />
          ) : (
            <ol className="divide-y divide-border-neutral">
              {activity.map((a) => (
                <li key={a.id} className="flex items-start gap-3 px-5 py-3">
                  <ClipboardList className="mt-0.5 size-4 shrink-0 text-muted" aria-hidden />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-semibold text-navy">{AUDIT_ACTION_LABEL[a.action] ?? a.action}</p>
                    <p className="truncate text-xs text-muted">{a.actor_name}</p>
                  </div>
                  <time dateTime={a.occurred_at} className="shrink-0 text-xs tabular-nums text-muted">
                    {formatAgo(a.occurred_at)}
                  </time>
                </li>
              ))}
            </ol>
          )}
        </Card>
      </div>
    </>
  );
}
