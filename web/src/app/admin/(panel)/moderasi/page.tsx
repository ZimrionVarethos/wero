'use client';

import { useState } from 'react';
import { useAdminData } from '@/lib/admin/use-admin-data';
import { Flag, History, ShieldCheck, Trash2 } from 'lucide-react';
import { Alert, Button, Card, CardHeader, ConfirmDialog, EmptyState, PageHeader, Segmented, SkeletonRows } from '@/components/admin/ui';
import { adminFetch, errorMessage } from '@/lib/admin/client';
import { formatAgo, formatDateTime, REPORT_REASON_LABEL } from '@/lib/admin/format';
import type { ModerationHistory, ModerationReport } from '@/lib/admin/types';

type Tab = 'PENDING' | 'REVIEWED_ACTION' | 'DISMISSED';
type Action = 'REMOVE' | 'MARK_NO_VIOLATION';

const TABS: { value: Tab; label: string }[] = [
  { value: 'PENDING', label: 'Menunggu' },
  { value: 'REVIEWED_ACTION', label: 'Dihapus' },
  { value: 'DISMISSED', label: 'Tidak melanggar' },
];

const ACTION_LABEL: Record<string, string> = {
  REMOVE: 'Konten dihapus',
  MARK_NO_VIOLATION: 'Dinyatakan tidak melanggar',
  HIDE: 'Konten disembunyikan',
  RESTORE: 'Konten dipulihkan',
};

export default function ModerationPage() {
  const [tab, setTab] = useState<Tab>('PENDING');
  const queue = useAdminData<{ reports: ModerationReport[]; history: ModerationHistory[] }>(`/api/moderation?status=${tab}`);
  const reports = queue.loading ? null : (queue.data?.reports ?? []);
  const history = queue.data?.history ?? [];
  const [pending, setPending] = useState<{ report: ModerationReport; action: Action } | null>(null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);


  const act = async (reason: string) => {
    if (!pending) return;
    setBusy(true);
    try {
      await adminFetch('/api/moderation', {
        method: 'POST',
        body: JSON.stringify({ reportId: pending.report.report_id, postId: pending.report.post_id, action: pending.action, reason }),
      });
      setNotice(pending.action === 'REMOVE' ? 'Konten dihapus dari feed komunitas.' : 'Laporan ditutup, konten tetap tampil.');
      setPending(null);
      queue.reload();
    } catch (e) {
      setError(errorMessage(e));
      setPending(null);
    } finally {
      setBusy(false);
    }
  };

  return (
    <>
      <PageHeader title="Moderasi komunitas" description="Tinjau unggahan yang dilaporkan warga. Hapus konten yang menyesatkan atau membahayakan saat situasi darurat." />

      <div className="mb-4 space-y-3">
        {error || queue.error ? (
          <Alert tone="error" onDismiss={() => setError(null)}>
            {error ?? queue.error}
          </Alert>
        ) : null}
        {notice ? (
          <Alert tone="success" onDismiss={() => setNotice(null)}>
            {notice}
          </Alert>
        ) : null}
      </div>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,2fr)_minmax(0,1fr)]">
        <div className="space-y-4">
          <Segmented label="Saring status laporan" value={tab} options={TABS} onChange={setTab} />
          {reports === null ? (
            <Card>
              <SkeletonRows />
            </Card>
          ) : reports.length === 0 ? (
            <Card>
              <EmptyState icon={ShieldCheck} title={tab === 'PENDING' ? 'Tidak ada laporan menunggu' : 'Belum ada laporan'}>
                {tab === 'PENDING' ? 'Laporan baru dari warga akan muncul di sini.' : null}
              </EmptyState>
            </Card>
          ) : (
            <ul className="space-y-4">
              {reports.map((r) => (
                <li key={r.report_id}>
                  <Card as="div" className="p-5">
                    <div className="flex flex-wrap items-center gap-2 text-xs">
                      <span className="inline-flex items-center gap-1 rounded-full bg-siaga/10 px-2 py-0.5 font-semibold text-siaga">
                        <Flag className="size-3.5" aria-hidden />
                        {REPORT_REASON_LABEL[r.reason_code] ?? r.reason_code}
                      </span>
                      <span className="font-semibold text-muted">{r.post_report_count} laporan untuk unggahan ini</span>
                      <span className="ml-auto text-muted">{formatAgo(r.report_created_at)}</span>
                    </div>

                    <div className="mt-3 rounded-lg border border-border-neutral bg-cream/50 p-4">
                      <p className="text-xs text-muted">Unggahan {r.author_name ?? 'pengguna'}</p>
                      {r.post_title ? <p className="mt-1 font-semibold text-navy">{r.post_title}</p> : null}
                      <p className="mt-1 line-clamp-5 whitespace-pre-line text-sm text-[#1A1D21]">{r.post_body ?? 'Unggahan tidak ditemukan.'}</p>
                    </div>

                    {r.details ? (
                      <p className="mt-3 text-sm text-muted">
                        <span className="font-semibold text-navy">Catatan pelapor </span>
                        {r.details}
                      </p>
                    ) : null}
                    {r.resolution && tab !== 'PENDING' ? (
                      <p className="mt-3 text-sm text-muted">
                        <span className="font-semibold text-navy">Keputusan </span>
                        {r.resolution}
                      </p>
                    ) : null}

                    {tab === 'PENDING' ? (
                      <div className="mt-4 flex flex-wrap gap-2">
                        <Button variant="danger" icon={Trash2} onClick={() => setPending({ report: r, action: 'REMOVE' })}>
                          Hapus konten
                        </Button>
                        <Button variant="secondary" icon={ShieldCheck} onClick={() => setPending({ report: r, action: 'MARK_NO_VIOLATION' })}>
                          Tidak melanggar
                        </Button>
                      </div>
                    ) : null}
                  </Card>
                </li>
              ))}
            </ul>
          )}
        </div>

        <Card className="h-fit">
          <CardHeader title="Riwayat tindakan" />
          {history.length === 0 ? (
            <EmptyState icon={History} title="Belum ada tindakan" />
          ) : (
            <ol className="divide-y divide-border-neutral">
              {history.map((h) => (
                <li key={h.id} className="px-5 py-3">
                  <p className="text-sm font-semibold text-navy">{ACTION_LABEL[h.action] ?? h.action}</p>
                  <p className="truncate text-xs text-muted">{h.post_title ?? 'Unggahan tanpa judul'}</p>
                  <p className="mt-0.5 text-xs text-muted">
                    {formatDateTime(h.created_at)}
                    {h.moderator_name ? `, oleh ${h.moderator_name}` : ''}
                  </p>
                </li>
              ))}
            </ol>
          )}
        </Card>
      </div>

      <ConfirmDialog
        open={pending !== null}
        title={pending?.action === 'REMOVE' ? 'Hapus konten ini?' : 'Tandai tidak melanggar?'}
        confirmLabel={pending?.action === 'REMOVE' ? 'Hapus konten' : 'Tutup laporan'}
        tone={pending?.action === 'REMOVE' ? 'danger' : 'primary'}
        requireReason
        reasonLabel="Alasan keputusan"
        busy={busy}
        onClose={() => setPending(null)}
        onConfirm={(reason) => void act(reason)}
      >
        {pending?.action === 'REMOVE'
          ? 'Unggahan akan hilang dari feed komunitas untuk semua warga.'
          : 'Laporan ditutup dan unggahan tetap tampil di feed komunitas.'}
      </ConfirmDialog>
    </>
  );
}
