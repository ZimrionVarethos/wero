'use client';

import { useState } from 'react';
import { CheckCircle2, Megaphone, Trash2 } from 'lucide-react';
import { Button, Card, CardHeader, ConfirmDialog, EmptyState, SeverityBadge, SkeletonRows } from '@/components/admin/ui';
import { adminFetch, errorMessage } from '@/lib/admin/client';
import { formatDateTime, HAZARD_LABEL } from '@/lib/admin/format';
import type { BroadcastRow } from '@/lib/admin/types';

interface BroadcastHistoryCardProps {
  history: BroadcastRow[] | null;
  loading: boolean;
  isSuper: boolean;
  regionName: string | null;
  onReload: () => void;
  onError: (msg: string) => void;
}

export function BroadcastHistoryCard({
  history,
  loading,
  isSuper,
  regionName,
  onReload,
  onError,
}: BroadcastHistoryCardProps) {
  const [selectedItemToDelete, setSelectedItemToDelete] = useState<BroadcastRow | null>(null);
  const [deletingAll, setDeletingAll] = useState(false);
  const [deletingBusy, setDeletingBusy] = useState(false);

  const deleteBroadcast = async (id: string) => {
    setDeletingBusy(true);
    try {
      await adminFetch(`/api/broadcast?id=${id}`, { method: 'DELETE' });
      setSelectedItemToDelete(null);
      onReload();
    } catch (e) {
      onError(errorMessage(e));
    } finally {
      setDeletingBusy(false);
    }
  };

  const clearAllBroadcasts = async () => {
    setDeletingBusy(true);
    try {
      await adminFetch('/api/broadcast?all=true', { method: 'DELETE' });
      setDeletingAll(false);
      onReload();
    } catch (e) {
      onError(errorMessage(e));
    } finally {
      setDeletingBusy(false);
    }
  };

  return (
    <>
      <Card>
        <CardHeader
          title="Riwayat siaran"
          description={isSuper ? 'Semua wilayah & siaran BMKG' : `Wilayah ${regionName ?? ''}`}
          actions={
            history && history.length > 0 ? (
              <Button
                type="button"
                variant="danger"
                size="sm"
                icon={Trash2}
                onClick={() => setDeletingAll(true)}
              >
                Hapus Semua Log
              </Button>
            ) : null
          }
        />
        {loading || history === null ? (
          <SkeletonRows rows={3} />
        ) : history.length === 0 ? (
          <EmptyState icon={Megaphone} title="Belum ada siaran" />
        ) : (
          <ul className="divide-y divide-border-neutral max-h-[600px] overflow-y-auto">
            {history.map((b) => (
              <li
                key={b.id}
                className="group flex items-start justify-between gap-3 px-5 py-4 hover:bg-cream/40 transition-colors"
              >
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <SeverityBadge level={b.severity} />
                    <span className="text-xs font-semibold text-muted">
                      {HAZARD_LABEL[b.disaster_type] ?? b.disaster_type}
                    </span>
                    <span className="ml-auto inline-flex items-center gap-1 text-xs font-semibold text-aman">
                      <CheckCircle2 className="size-3.5" aria-hidden /> Terkirim
                    </span>
                  </div>
                  <p className="mt-1.5 font-semibold text-navy">{b.headline}</p>
                  {b.message ? <p className="mt-0.5 text-sm text-muted">{b.message}</p> : null}
                  <p className="mt-1.5 text-xs text-muted">
                    {formatDateTime(b.created_at)}
                    {b.sent_by ? `, oleh ${b.sent_by}` : ''}, tujuan{' '}
                    {b.target_type === 'ALL'
                      ? 'nasional'
                      : b.target_regions?.length
                        ? b.target_regions.join(', ')
                        : 'tidak tercatat'}
                    {b.fcm && !b.fcm.delivered ? ', push gagal' : ''}
                  </p>
                </div>
                <button
                  type="button"
                  title="Hapus siaran ini"
                  onClick={() => setSelectedItemToDelete(b)}
                  className="mt-1 rounded-lg p-2 text-muted hover:bg-awas/10 hover:text-awas transition-colors shrink-0"
                >
                  <Trash2 className="size-4" aria-hidden />
                </button>
              </li>
            ))}
          </ul>
        )}
      </Card>

      <ConfirmDialog
        open={Boolean(selectedItemToDelete)}
        title="Hapus siaran ini?"
        confirmLabel="Hapus siaran"
        tone="danger"
        busy={deletingBusy}
        onClose={() => setSelectedItemToDelete(null)}
        onConfirm={() => selectedItemToDelete && void deleteBroadcast(selectedItemToDelete.id)}
      >
        <p className="text-sm">
          Apakah Anda yakin ingin menghapus log siaran{' '}
          <strong className="text-navy font-bold">{selectedItemToDelete?.headline}</strong>? Tindakan
          ini akan menghapus log secara permanen.
        </p>
      </ConfirmDialog>

      <ConfirmDialog
        open={deletingAll}
        title="Hapus semua riwayat siaran?"
        confirmLabel="Hapus semua"
        tone="danger"
        busy={deletingBusy}
        onClose={() => setDeletingAll(false)}
        onConfirm={() => void clearAllBroadcasts()}
      >
        <p className="text-sm">
          Apakah Anda yakin ingin menghapus semua riwayat siaran{' '}
          {isSuper ? 'di seluruh sistem' : `di wilayah ${regionName ?? ''}`}? Semua entri log siaran
          akan dibersihkan.
        </p>
      </ConfirmDialog>
    </>
  );
}
