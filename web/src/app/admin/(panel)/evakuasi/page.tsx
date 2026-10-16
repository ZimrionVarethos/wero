'use client';

import { useMemo, useState, type FormEvent } from 'react';
import { useAdminData } from '@/lib/admin/use-admin-data';
import { ArrowLeft, MapPin, MapPinned, Pencil, Plus, Search, Trash2 } from 'lucide-react';
import { useAdmin } from '@/components/admin/AdminShell';
import { AdminMap, INDONESIA_CENTER, type MapPoint } from '@/components/admin/Map';
import { Alert, Button, Card, ConfirmDialog, EmptyState, PageHeader, SelectField, SkeletonRows, TextArea, TextField } from '@/components/admin/ui';
import { adminFetch, errorMessage } from '@/lib/admin/client';
import { EVAC_KIND_LABEL, formatDateTime } from '@/lib/admin/format';
import type { EvacKind, EvacPoint } from '@/lib/admin/types';

const FORM_KINDS: EvacKind[] = ['ASSEMBLY', 'SHELTER', 'HEALTH', 'WATER', 'OTHER'];

// Assembly points use the AMAN green, consistent with the mobile map. Other kinds use navy.
const KIND_COLOR: Record<EvacKind, string> = {
  ASSEMBLY: '#2E7D32',
  SHELTER: '#12263F',
  HEALTH: '#12263F',
  WATER: '#12263F',
  OTHER: '#12263F',
  ROUTE: '#12263F',
};

interface FormState {
  id: string | null;
  name: string;
  kind: EvacKind;
  capacity: string;
  address: string;
  description: string;
  isActive: boolean;
  point: { lng: number; lat: number } | null;
}

const EMPTY_FORM: FormState = { id: null, name: '', kind: 'ASSEMBLY', capacity: '', address: '', description: '', isActive: true, point: null };

export default function EvacuationPage() {
  const me = useAdmin();
  const evac = useAdminData<EvacPoint[]>('/api/shelters');
  const items = useMemo(() => (evac.loading ? null : (evac.data ?? [])), [evac.loading, evac.data]);
  const [kind, setKind] = useState<EvacKind | 'ALL'>('ALL');
  const [query, setQuery] = useState('');
  const [form, setForm] = useState<FormState | null>(null);
  const [errors, setErrors] = useState<Partial<Record<'name' | 'point' | 'capacity', string>>>({});
  const [saving, setSaving] = useState(false);
  const [deleting, setDeleting] = useState<EvacPoint | null>(null);
  const [busyDelete, setBusyDelete] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);


  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    return (items ?? []).filter(
      (p) => (kind === 'ALL' || p.kind === kind) && (!q || p.name.toLowerCase().includes(q) || p.address?.toLowerCase().includes(q)),
    );
  }, [items, kind, query]);

  const points: MapPoint[] = useMemo(
    () =>
      visible.map((p) => ({
        id: p.id,
        lng: Number(p.longitude),
        lat: Number(p.latitude),
        color: KIND_COLOR[p.kind] ?? '#12263F',
        muted: !p.is_active,
      })),
    [visible],
  );

  const startEdit = (p: EvacPoint) => {
    setErrors({});
    setNotice(null);
    setForm({
      id: p.id,
      name: p.name,
      kind: FORM_KINDS.includes(p.kind) ? p.kind : 'OTHER',
      capacity: p.capacity?.toString() ?? '',
      address: p.address ?? '',
      description: p.description ?? '',
      isActive: p.is_active,
      point: { lng: Number(p.longitude), lat: Number(p.latitude) },
    });
  };

  const save = async (e: FormEvent) => {
    e.preventDefault();
    if (!form) return;
    const next: typeof errors = {};
    if (form.name.trim().length < 3) next.name = 'Nama minimal 3 karakter.';
    if (!form.point) next.point = 'Klik peta untuk menentukan lokasi titik.';
    if (form.capacity && (!/^\d+$/.test(form.capacity) || Number(form.capacity) > 1_000_000)) next.capacity = 'Isi angka bulat.';
    setErrors(next);
    if (Object.keys(next).length) return;

    setSaving(true);
    try {
      await adminFetch(form.id ? `/api/shelters/${form.id}` : '/api/shelters', {
        method: form.id ? 'PUT' : 'POST',
        body: JSON.stringify({
          name: form.name,
          kind: form.kind,
          capacity: form.capacity === '' ? null : Number(form.capacity),
          address: form.address,
          description: form.description,
          is_active: form.isActive,
          latitude: form.point!.lat,
          longitude: form.point!.lng,
        }),
      });
      setNotice(form.id ? 'Perubahan titik disimpan.' : 'Titik evakuasi ditambahkan.');
      setForm(null);
      evac.reload();
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setSaving(false);
    }
  };

  const remove = async () => {
    if (!deleting) return;
    setBusyDelete(true);
    try {
      await adminFetch(`/api/shelters/${deleting.id}`, { method: 'DELETE' });
      setNotice(`${deleting.name} dihapus dari peta evakuasi.`);
      setDeleting(null);
      setForm(null);
      evac.reload();
    } catch (err) {
      setError(errorMessage(err));
      setDeleting(null);
    } finally {
      setBusyDelete(false);
    }
  };

  const activeCount = items?.filter((p) => p.is_active).length ?? 0;

  return (
    <>
      <PageHeader
        title="Titik evakuasi"
        description="Titik kumpul, shelter, dan fasilitas pendukung yang diunduh warga untuk peta offline. Perubahan baru diterima warga saat aplikasi mereka tersinkron."
        actions={
          !form ? (
            <Button
              variant="accent"
              icon={Plus}
              onClick={() => {
                setErrors({});
                setNotice(null);
                setForm(EMPTY_FORM);
              }}
            >
              Tambah titik
            </Button>
          ) : null
        }
      />

      <div className="mb-4 space-y-3">
        {error || evac.error ? (
          <Alert tone="error" onDismiss={() => setError(null)}>
            {error ?? evac.error}
          </Alert>
        ) : null}
        {notice ? (
          <Alert tone="success" onDismiss={() => setNotice(null)}>
            {notice}
          </Alert>
        ) : null}
      </div>

      <div className="grid gap-4 lg:h-[calc(100vh-13rem)] lg:min-h-[560px] lg:grid-cols-[minmax(0,1fr)_420px]">
        <Card className="relative h-[420px] overflow-hidden lg:h-auto">
          <AdminMap
            center={INDONESIA_CENTER}
            zoom={4.5}
            points={points}
            selectedId={form?.id ?? null}
            onSelect={(id) => {
              const p = items?.find((i) => i.id === id);
              if (p && !form) startEdit(p);
            }}
            pick={form?.point ?? null}
            onPick={form ? (pt) => setForm((f) => (f ? { ...f, point: pt } : f)) : undefined}
            label="Peta titik evakuasi"
          />
          <div className="pointer-events-none absolute left-3 top-3 mr-14 flex flex-col items-start gap-2">
            <div className="flex flex-wrap gap-x-3 gap-y-1 rounded-lg bg-white/95 px-3 py-2 text-xs font-medium shadow-sm">
              <span className="flex items-center gap-1.5">
                <span className="size-2.5 rounded-full bg-aman" aria-hidden /> Titik kumpul
              </span>
              <span className="flex items-center gap-1.5">
                <span className="size-2.5 rounded-full bg-navy" aria-hidden /> Shelter dan fasilitas
              </span>
              <span className="flex items-center gap-1.5">
                <span className="size-2.5 rounded-full bg-navy/40" aria-hidden /> Nonaktif
              </span>
            </div>
            {form ? (
              <p role="status" className="rounded-lg bg-navy px-3 py-2 text-xs font-semibold text-white shadow-sm">
                Klik peta untuk {form.point ? 'memindahkan' : 'menentukan'} lokasi titik
              </p>
            ) : null}
          </div>
        </Card>

        {form ? (
          <Card as="aside" className="flex min-h-0 flex-col">
            <div className="flex items-center gap-2 border-b border-border-neutral px-3 py-2">
              <Button variant="ghost" size="sm" icon={ArrowLeft} onClick={() => setForm(null)}>
                Daftar titik
              </Button>
              <span className="ml-auto pr-2 text-sm font-bold text-navy">{form.id ? 'Ubah titik' : 'Titik baru'}</span>
            </div>
            <form onSubmit={save} className="min-h-0 flex-1 space-y-4 overflow-y-auto p-5" noValidate>
              <TextField label="Nama titik" value={form.name} maxLength={120} error={errors.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
              <SelectField label="Jenis" value={form.kind} onChange={(e) => setForm({ ...form, kind: e.target.value as EvacKind })}>
                {FORM_KINDS.map((k) => (
                  <option key={k} value={k}>
                    {EVAC_KIND_LABEL[k]}
                  </option>
                ))}
              </SelectField>
              <TextField
                label="Kapasitas orang"
                inputMode="numeric"
                value={form.capacity}
                error={errors.capacity}
                hint="Kosongkan bila belum diketahui"
                onChange={(e) => setForm({ ...form, capacity: e.target.value })}
              />
              <div>
                <p className="mb-1.5 text-sm font-semibold text-navy">Lokasi</p>
                <div className={`flex items-center gap-2 rounded-lg border px-3 py-3 text-sm ${errors.point ? 'border-awas/50 bg-awas/5' : 'border-border-neutral bg-cream/60'}`}>
                  <MapPin className="size-4 shrink-0 text-muted" aria-hidden />
                  {form.point ? (
                    <span className="font-mono">
                      {form.point.lat.toFixed(5)}, {form.point.lng.toFixed(5)}
                    </span>
                  ) : (
                    <span className="text-muted">Belum dipilih, klik peta</span>
                  )}
                </div>
                {errors.point ? (
                  <p role="alert" className="mt-1.5 text-xs font-medium text-awas">
                    {errors.point}
                  </p>
                ) : null}
              </div>
              <TextField label="Alamat" value={form.address} maxLength={300} onChange={(e) => setForm({ ...form, address: e.target.value })} />
              <TextArea label="Keterangan" rows={3} maxLength={1000} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} hint="Misalnya akses jalan, fasilitas, atau penanggung jawab" />
              <label className="flex min-h-12 cursor-pointer items-center gap-3 rounded-lg border border-border-neutral px-3">
                <input type="checkbox" checked={form.isActive} onChange={(e) => setForm({ ...form, isActive: e.target.checked })} className="size-5 accent-[#12263F]" />
                <span className="text-sm font-semibold text-navy">Aktif dan tampil di aplikasi warga</span>
              </label>
              {!me.isSuper ? <p className="text-xs text-muted">Titik disimpan untuk wilayah {me.regionName ?? 'tugas Anda'}.</p> : null}

              <div className="flex flex-wrap gap-2 border-t border-border-neutral pt-4">
                <Button type="submit" loading={saving} className="flex-1">
                  {form.id ? 'Simpan perubahan' : 'Simpan titik'}
                </Button>
                {form.id ? (
                  <Button
                    type="button"
                    variant="danger"
                    icon={Trash2}
                    onClick={() => setDeleting(items?.find((i) => i.id === form.id) ?? null)}
                  >
                    Hapus
                  </Button>
                ) : null}
              </div>
            </form>
          </Card>
        ) : (
          <Card as="aside" className="flex min-h-0 flex-col">
            <div className="space-y-3 border-b border-border-neutral p-4">
              <div className="relative">
                <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted" aria-hidden />
                <label htmlFor="cari-titik" className="sr-only">
                  Cari titik evakuasi
                </label>
                <input
                  id="cari-titik"
                  type="search"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Cari nama atau alamat"
                  className="min-h-12 w-full rounded-lg border border-border-neutral bg-white pl-9 pr-3 text-sm outline-none focus:border-navy focus:ring-2 focus:ring-navy/15"
                />
              </div>
              <label htmlFor="jenis-titik" className="sr-only">
                Saring jenis
              </label>
              <select
                id="jenis-titik"
                value={kind}
                onChange={(e) => setKind(e.target.value as EvacKind | 'ALL')}
                className="min-h-12 w-full rounded-lg border border-border-neutral bg-white px-3 text-sm outline-none focus:border-navy"
              >
                <option value="ALL">Semua jenis</option>
                {FORM_KINDS.map((k) => (
                  <option key={k} value={k}>
                    {EVAC_KIND_LABEL[k]}
                  </option>
                ))}
              </select>
              {items ? (
                <p className="text-xs text-muted">
                  {activeCount} aktif dari {items.length} titik
                </p>
              ) : null}
            </div>
            <div className="min-h-0 flex-1 overflow-y-auto">
              {items === null ? (
                <SkeletonRows />
              ) : visible.length === 0 ? (
                <EmptyState icon={MapPinned} title={items.length === 0 ? 'Belum ada titik evakuasi' : 'Tidak ada yang cocok'}>
                  {items.length === 0 ? 'Tambahkan titik kumpul pertama untuk wilayah Anda.' : 'Ubah kata kunci atau jenis titik.'}
                </EmptyState>
              ) : (
                <ul aria-label="Daftar titik evakuasi" className="divide-y divide-border-neutral">
                  {visible.map((p) => (
                    <li key={p.id} className="flex items-start gap-3 px-4 py-3.5">
                      <span className="mt-1.5 size-2.5 shrink-0 rounded-full" style={{ background: KIND_COLOR[p.kind], opacity: p.is_active ? 1 : 0.4 }} aria-hidden />
                      <div className="min-w-0 flex-1">
                        <p className="truncate font-semibold text-navy">{p.name}</p>
                        <p className="text-xs text-muted">
                          {EVAC_KIND_LABEL[p.kind] ?? p.kind}
                          {p.capacity != null ? `, ${p.capacity.toLocaleString('id-ID')} orang` : ''}
                          {p.is_active ? '' : ', nonaktif'}
                        </p>
                        <p className="mt-0.5 text-xs text-muted/80">Diperbarui {formatDateTime(p.updated_at)}</p>
                      </div>
                      <Button variant="ghost" size="sm" icon={Pencil} onClick={() => startEdit(p)} aria-label={`Ubah ${p.name}`}>
                        Ubah
                      </Button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </Card>
        )}
      </div>

      <ConfirmDialog
        open={deleting !== null}
        title="Hapus titik evakuasi?"
        confirmLabel="Hapus titik"
        tone="danger"
        busy={busyDelete}
        onClose={() => setDeleting(null)}
        onConfirm={() => void remove()}
      >
        <strong className="text-navy">{deleting?.name}</strong> akan dihapus permanen. Warga yang sudah mengunduh peta tetap melihat titik ini sampai peta mereka diperbarui. Jika hanya
        sementara tidak dipakai, nonaktifkan titik ini sebagai gantinya.
      </ConfirmDialog>
    </>
  );
}
