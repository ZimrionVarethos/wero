'use client';

import { useState, type FormEvent } from 'react';
import { useAdminData } from '@/lib/admin/use-admin-data';
import { Download, Link2, Link2Off, ScrollText, Search, ShieldCheck } from 'lucide-react';
import { useAdmin } from '@/components/admin/AdminShell';
import { Alert, Button, Card, CardHeader, ConfirmDialog, EmptyState, PageHeader, SkeletonRows, TextField } from '@/components/admin/ui';
import { adminFetch, errorMessage } from '@/lib/admin/client';
import { AUDIT_ACTION_LABEL, formatDateTime, shortId } from '@/lib/admin/format';
import type { AuditRow } from '@/lib/admin/types';

interface ChainResult {
  ok: boolean;
  checked: number;
  unsigned: number;
  brokenAtId: number | null;
}

const TARGET_LABEL: Record<string, string> = {
  SOS: 'SOS',
  EVACUATION_POINT: 'Titik evakuasi',
  DISASTER_EVENT: 'Siaran',
  COMMUNITY_POST: 'Unggahan',
  AUDIT: 'Audit',
};

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export default function AuditPage() {
  const me = useAdmin();
  const [targetInput, setTargetInput] = useState('');
  const [target, setTarget] = useState('');
  const audit = useAdminData<AuditRow[]>(`/api/audit?limit=200${target ? `&target_id=${encodeURIComponent(target)}` : ''}`);
  const rows = audit.loading ? null : (audit.data ?? []);
  const [chain, setChain] = useState<ChainResult | null>(null);
  const [checking, setChecking] = useState(false);
  const [exportOpen, setExportOpen] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [inputError, setInputError] = useState<string | null>(null);


  const search = (e: FormEvent) => {
    e.preventDefault();
    const id = targetInput.trim();
    if (id && !UUID.test(id)) return setInputError('Masukkan ID lengkap, 36 karakter.');
    setInputError(null);
    setTarget(id);
  };

  const verify = async () => {
    setChecking(true);
    try {
      setChain(await adminFetch<ChainResult>('/api/audit?verify=1'));
    } catch (e) {
      setError(errorMessage(e));
    } finally {
      setChecking(false);
    }
  };

  const exportCase = async () => {
    setExporting(true);
    try {
      const data = await adminFetch<object>(`/api/audit?export=1&target_id=${encodeURIComponent(target)}`);
      const url = URL.createObjectURL(new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' }));
      const a = document.createElement('a');
      a.href = url;
      a.download = `audit-${target}.json`;
      a.click();
      URL.revokeObjectURL(url);
      setExportOpen(false);
      audit.reload();
    } catch (e) {
      setError(errorMessage(e));
      setExportOpen(false);
    } finally {
      setExporting(false);
    }
  };

  return (
    <>
      <PageHeader
        title="Log audit"
        description="Catatan hanya dapat ditambah. Setiap baris dari dasbor ditandatangani dengan rantai hash yang terhubung ke baris sebelumnya."
        actions={
          me.isSuper ? (
            <Button variant="secondary" icon={ShieldCheck} onClick={verify} loading={checking}>
              Periksa rantai hash
            </Button>
          ) : null
        }
      />

      <div className="mb-4 space-y-3">
        {error || audit.error ? (
          <Alert tone="error" onDismiss={() => setError(null)}>
            {error ?? audit.error}
          </Alert>
        ) : null}
        {chain ? (
          <Alert tone={chain.ok ? 'success' : 'error'} onDismiss={() => setChain(null)}>
            {chain.ok
              ? `Rantai utuh. ${chain.checked} baris bertanda tangan diperiksa, ${chain.unsigned} baris sistem tanpa tanda tangan.`
              : `Rantai terputus di baris ${chain.brokenAtId} setelah ${chain.checked} baris valid. Laporkan ke tim teknis.`}
          </Alert>
        ) : null}
      </div>

      <Card className="mb-6">
        <form onSubmit={search} className="flex flex-wrap items-end gap-3 p-5" noValidate>
          <div className="min-w-[260px] flex-1">
            <TextField
              label="ID kasus atau objek"
              value={targetInput}
              error={inputError}
              onChange={(e) => setTargetInput(e.target.value)}
              placeholder="Tempel ID kasus SOS, titik evakuasi, atau siaran"
              hint="Kosongkan untuk menampilkan aktivitas terbaru"
            />
          </div>
          <div className="flex gap-2 pb-6">
            <Button type="submit" icon={Search}>
              Tampilkan
            </Button>
            <Button type="button" variant="secondary" icon={Download} disabled={!target} onClick={() => setExportOpen(true)}>
              Ekspor
            </Button>
          </div>
        </form>
      </Card>

      <Card>
        <CardHeader title={target ? `Catatan untuk ${shortId(target)}` : 'Aktivitas terbaru'} description={me.isSuper ? 'Semua wilayah' : 'SOS di wilayah Anda dan tindakan Anda sendiri'} />
        {rows === null ? (
          <SkeletonRows rows={6} />
        ) : rows.length === 0 ? (
          <EmptyState icon={ScrollText} title="Belum ada catatan" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full min-w-[720px] text-left text-sm">
              <thead>
                <tr className="border-b border-border-neutral text-xs uppercase tracking-wider text-muted">
                  <th scope="col" className="px-5 py-3 font-semibold">Waktu</th>
                  <th scope="col" className="px-5 py-3 font-semibold">Tindakan</th>
                  <th scope="col" className="px-5 py-3 font-semibold">Objek</th>
                  <th scope="col" className="px-5 py-3 font-semibold">Pelaku</th>
                  <th scope="col" className="px-5 py-3 font-semibold">Tanda tangan</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border-neutral">
                {rows.map((r) => (
                  <tr key={r.id} className="hover:bg-cream/50">
                    <td className="whitespace-nowrap px-5 py-3 tabular-nums text-muted">{formatDateTime(r.occurred_at)}</td>
                    <td className="px-5 py-3 font-semibold text-navy">{AUDIT_ACTION_LABEL[r.action] ?? r.action}</td>
                    <td className="px-5 py-3">
                      <span className="text-muted">{TARGET_LABEL[r.target_type] ?? r.target_type} </span>
                      {r.target_id ? (
                        <button
                          type="button"
                          onClick={() => {
                            setTargetInput(r.target_id!);
                            setTarget(r.target_id!);
                          }}
                          className="font-mono text-xs text-navy underline-offset-2 hover:underline"
                          aria-label={`Tampilkan catatan untuk ${r.target_id}`}
                        >
                          {shortId(r.target_id)}
                        </button>
                      ) : null}
                    </td>
                    <td className="px-5 py-3">{r.actor_name}</td>
                    <td className="px-5 py-3">
                      {r.signed ? (
                        <span className="inline-flex items-center gap-1 text-xs font-semibold text-aman">
                          <Link2 className="size-3.5" aria-hidden /> Bertanda tangan
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs font-semibold text-muted">
                          <Link2Off className="size-3.5" aria-hidden /> Sistem
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      <ConfirmDialog
        open={exportOpen}
        title="Ekspor catatan kasus?"
        confirmLabel="Unduh berkas JSON"
        busy={exporting}
        onClose={() => setExportOpen(false)}
        onConfirm={() => void exportCase()}
      >
        Ekspor tercatat di log audit atas nama Anda. Serahkan data hanya atas permintaan resmi aparat penegak hukum atau instansi berwenang.
      </ConfirmDialog>
    </>
  );
}
