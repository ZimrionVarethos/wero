'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Plus,
  Search,
  RefreshCw,
  MapPin,
  ExternalLink,
  Edit2,
  Trash2,
  CheckCircle,
  XCircle,
  AlertTriangle,
  Building,
  HeartPulse,
  Navigation,
  Box,
} from 'lucide-react';

export interface ShelterItem {
  id: string;
  name: string;
  kind: string;
  description: string | null;
  address: string | null;
  capacity: number | null;
  latitude: number | null;
  longitude: number | null;
  is_active: boolean;
  source: string | null;
  updated_at: string;
}

export default function ShelterManager() {
  const [shelters, setShelters] = useState<ShelterItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [kindFilter, setKindFilter] = useState('ALL');
  const [modalOpen, setModalOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<ShelterItem | null>(null);
  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  // Form State
  const [formData, setFormData] = useState({
    name: '',
    kind: 'SHELTER',
    description: '',
    address: '',
    capacity: 250,
    latitude: -7.7956,
    longitude: 110.3695,
    is_active: true,
    source: 'BPBD D.I. Yogyakarta (Terverifikasi)',
  });

  const fetchShelters = useCallback(async () => {
    setLoading(true);
    try {
      const res = await fetch(`/api/shelters?kind=${kindFilter}&search=${encodeURIComponent(search)}`);
      const json = await res.json();
      if (json.success) {
        setShelters(json.data);
      }
    } catch (err) {
      console.error(err);
      showToast('Gagal memuat daftar shelter', 'error');
    } finally {
      setLoading(false);
    }
  }, [kindFilter, search]);

  useEffect(() => {
    fetchShelters();
  }, [fetchShelters]);

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const openCreateModal = () => {
    setEditingItem(null);
    setFormData({
      name: '',
      kind: 'SHELTER',
      description: '',
      address: '',
      capacity: 300,
      latitude: -7.7956,
      longitude: 110.3695,
      is_active: true,
      source: 'BPBD D.I. Yogyakarta (Terverifikasi)',
    });
    setModalOpen(true);
  };

  const openEditModal = (item: ShelterItem) => {
    setEditingItem(item);
    setFormData({
      name: item.name,
      kind: item.kind,
      description: item.description || '',
      address: item.address || '',
      capacity: item.capacity || 0,
      latitude: item.latitude || -7.7956,
      longitude: item.longitude || 110.3695,
      is_active: item.is_active,
      source: item.source || 'BPBD Terverifikasi',
    });
    setModalOpen(true);
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      if (editingItem) {
        // Update
        const res = await fetch(`/api/shelters/${editingItem.id}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData),
        });
        const json = await res.json();
        if (json.success) {
          showToast(`Shelter "${formData.name}" berhasil diperbarui`, 'success');
          setModalOpen(false);
          fetchShelters();
        } else {
          showToast(json.error || 'Gagal menyimpan', 'error');
        }
      } else {
        // Create
        const res = await fetch('/api/shelters', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(formData),
        });
        const json = await res.json();
        if (json.success) {
          showToast(`Posko "${formData.name}" berhasil ditambahkan`, 'success');
          setModalOpen(false);
          fetchShelters();
        } else {
          showToast(json.error || 'Gagal menambahkan posko', 'error');
        }
      }
    } catch (err) {
      console.error(err);
      showToast('Terjadi kesalahan jaringan', 'error');
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (item: ShelterItem) => {
    if (!confirm(`Hapus fasilitas/posko "${item.name}"? Data tidak dapat dipulihkan.`)) {
      return;
    }
    try {
      const res = await fetch(`/api/shelters/${item.id}`, { method: 'DELETE' });
      const json = await res.json();
      if (json.success) {
        showToast(json.message || 'Shelter berhasil dihapus', 'success');
        fetchShelters();
      } else {
        showToast(json.error || 'Gagal menghapus', 'error');
      }
    } catch {
      showToast('Gagal menghapus shelter', 'error');
    }
  };

  const getKindBadge = (kind: string) => {
    switch (kind) {
      case 'SHELTER':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <Building className="w-3 h-3" /> Posko / Barak
          </span>
        );
      case 'ASSEMBLY':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-sky-50 text-sky-700 border border-sky-200">
            <Navigation className="w-3 h-3" /> Titik Kumpul
          </span>
        );
      case 'HEALTH':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-200">
            <HeartPulse className="w-3 h-3" /> Faskes / RS
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
            <Box className="w-3 h-3" /> {kind}
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* Toast Notification */}
      {toast && (
        <div
          className={`fixed bottom-6 right-6 z-50 px-4 py-3 rounded-xl shadow-lg border text-sm font-medium flex items-center gap-2 animate-fade-in ${
            toast.type === 'success'
              ? 'bg-emerald-900 text-white border-emerald-700'
              : 'bg-rose-900 text-white border-rose-700'
          }`}
        >
          {toast.type === 'success' ? <CheckCircle className="w-4 h-4 text-emerald-400" /> : <AlertTriangle className="w-4 h-4 text-rose-400" />}
          {toast.message}
        </div>
      )}

      {/* Action Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
        <div>
          <h2 className="text-xl font-bold text-slate-900">Manajemen Fasilitas & Shelter Evakuasi</h2>
          <p className="text-xs text-slate-500 mt-1">
            Validasi lokasi, kapasitas tampung, serta ketersediaan fasilitas darurat untuk respon bencana warga.
          </p>
        </div>
        <div className="flex items-center gap-2.5">
          <button
            onClick={fetchShelters}
            disabled={loading}
            className="p-2.5 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 transition"
            title="Muat Ulang Data"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          </button>
          <button
            onClick={openCreateModal}
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-sky-600 text-white font-semibold text-sm hover:bg-sky-700 shadow-sm transition"
          >
            <Plus className="w-4 h-4" /> Tambah Posko / Shelter
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col md:flex-row gap-3 items-center justify-between bg-white p-4 rounded-2xl border border-slate-200">
        <div className="relative w-full md:w-80">
          <Search className="w-4 h-4 absolute left-3.5 top-3 text-slate-400" />
          <input
            type="text"
            placeholder="Cari posko, alamat, atau wilayah..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:border-sky-500 focus:ring-1 focus:ring-sky-500"
          />
        </div>
        <div className="flex flex-wrap items-center gap-2 w-full md:w-auto">
          {['ALL', 'SHELTER', 'ASSEMBLY', 'HEALTH'].map((tab) => (
            <button
              key={tab}
              onClick={() => setKindFilter(tab)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition ${
                kindFilter === tab
                  ? 'bg-slate-900 text-white'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              {tab === 'ALL'
                ? 'Semua Kategori'
                : tab === 'SHELTER'
                ? 'Posko & Barak'
                : tab === 'ASSEMBLY'
                ? 'Titik Kumpul'
                : 'Fasilitas Medis'}
            </button>
          ))}
        </div>
      </div>

      {/* Table List */}
      <div className="bg-white rounded-2xl border border-slate-200 overflow-hidden shadow-xs">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-100 bg-slate-50/75 text-slate-500 text-xs uppercase font-semibold">
                <th className="py-3 px-4">Nama Posko / Fasilitas</th>
                <th className="py-3 px-4">Kategori</th>
                <th className="py-3 px-4">Kapasitas</th>
                <th className="py-3 px-4">Koordinat GPS</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 text-sm">
              {loading && shelters.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2 text-sky-500" />
                    Memuat data shelter dari database...
                  </td>
                </tr>
              ) : shelters.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    Tidak ada fasilitas shelter yang sesuai dengan pencarian.
                  </td>
                </tr>
              ) : (
                shelters.map((item) => (
                  <tr key={item.id} className="hover:bg-slate-50/60 transition">
                    <td className="py-3.5 px-4">
                      <div className="font-semibold text-slate-900">{item.name}</div>
                      <div className="text-xs text-slate-500 line-clamp-1 mt-0.5">
                        {item.address || item.description || 'Tidak ada keterangan alamat'}
                      </div>
                    </td>
                    <td className="py-3.5 px-4">{getKindBadge(item.kind)}</td>
                    <td className="py-3.5 px-4">
                      <span className="font-bold text-slate-800">
                        {item.capacity ? item.capacity.toLocaleString('id-ID') : '-'}
                      </span>
                      <span className="text-xs text-slate-400 ml-1">jiwa</span>
                    </td>
                    <td className="py-3.5 px-4">
                      {item.latitude && item.longitude ? (
                        <a
                          href={`https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}`}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center gap-1 font-mono text-xs text-sky-600 hover:text-sky-800 bg-sky-50 px-2 py-1 rounded-md"
                        >
                          <MapPin className="w-3 h-3" />
                          {item.latitude.toFixed(4)}, {item.longitude.toFixed(4)}
                          <ExternalLink className="w-2.5 h-2.5 ml-0.5" />
                        </a>
                      ) : (
                        <span className="text-xs text-slate-400">Belum disetel</span>
                      )}
                    </td>
                    <td className="py-3.5 px-4">
                      {item.is_active ? (
                        <span className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600">
                          <CheckCircle className="w-3.5 h-3.5" /> Siap Digunakan
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs font-semibold text-slate-400">
                          <XCircle className="w-3.5 h-3.5" /> Ditutup Sementara
                        </span>
                      )}
                    </td>
                    <td className="py-3.5 px-4 text-right">
                      <div className="inline-flex items-center gap-1">
                        <button
                          onClick={() => openEditModal(item)}
                          className="p-1.5 rounded-lg text-slate-600 hover:bg-slate-100 transition"
                          title="Edit Posko"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(item)}
                          className="p-1.5 rounded-lg text-rose-600 hover:bg-rose-50 transition"
                          title="Hapus Posko"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Add / Edit */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl max-w-lg w-full p-6 shadow-2xl border border-slate-100 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <h3 className="font-bold text-lg text-slate-900">
                {editingItem ? 'Edit Posko / Fasilitas' : 'Tambah Fasilitas Baru'}
              </h3>
              <button
                onClick={() => setModalOpen(false)}
                className="w-8 h-8 rounded-full bg-slate-100 text-slate-500 hover:bg-slate-200 flex items-center justify-center text-sm font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSave} className="mt-4 space-y-4">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Nama Posko / Fasilitas *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Misal: Barak Pengungsian Purwobinangun"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className="w-full px-3.5 py-2.5 text-sm rounded-xl border border-slate-200 focus:outline-none focus:border-sky-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                    Jenis Fasilitas
                  </label>
                  <select
                    value={formData.kind}
                    onChange={(e) => setFormData({ ...formData, kind: e.target.value })}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:border-sky-500 bg-white"
                  >
                    <option value="SHELTER">SHELTER (Posko Pengungsian)</option>
                    <option value="ASSEMBLY">ASSEMBLY (Titik Kumpul Lapangan)</option>
                    <option value="HEALTH">HEALTH (Rumah Sakit / Puskesmas)</option>
                    <option value="LOGISTICS">LOGISTICS (Gudang Bantuan)</option>
                  </select>
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                    Kapasitas (Jiwa)
                  </label>
                  <input
                    type="number"
                    min="1"
                    value={formData.capacity}
                    onChange={(e) => setFormData({ ...formData, capacity: parseInt(e.target.value, 10) || 0 })}
                    className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:border-sky-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Alamat Lengkap
                </label>
                <input
                  type="text"
                  placeholder="Nama jalan, kelurahan, kecamatan, kabupaten"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:border-sky-500"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                  Keterangan & Fasilitas
                </label>
                <textarea
                  rows={2}
                  placeholder="Dapur umum, tenda keluarga, ketersediaan air bersih, genset..."
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 focus:outline-none focus:border-sky-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                    Latitude (Lintang) *
                  </label>
                  <input
                    type="number"
                    step="0.000001"
                    required
                    value={formData.latitude}
                    onChange={(e) => setFormData({ ...formData, latitude: parseFloat(e.target.value) })}
                    className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 font-mono focus:outline-none focus:border-sky-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase tracking-wider mb-1">
                    Longitude (Bujur) *
                  </label>
                  <input
                    type="number"
                    step="0.000001"
                    required
                    value={formData.longitude}
                    onChange={(e) => setFormData({ ...formData, longitude: parseFloat(e.target.value) })}
                    className="w-full px-3.5 py-2 text-sm rounded-xl border border-slate-200 font-mono focus:outline-none focus:border-sky-500"
                  />
                </div>
              </div>

              {/* Quick Template Preset Buttons for Demo */}
              <div className="bg-slate-50 p-3 rounded-xl border border-slate-200/80">
                <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider block mb-2">
                  Template Koordinat Posko DIY (Demo Cepat):
                </span>
                <div className="flex flex-wrap gap-1.5">
                  <button
                    type="button"
                    onClick={() =>
                      setFormData({
                        ...formData,
                        name: 'Barak Pengungsian Purwobinangun (Merapi)',
                        latitude: -7.6368,
                        longitude: 110.4045,
                        address: 'Jl. Boyong, Purwobinangun, Pakem, Sleman',
                        capacity: 600,
                      })
                    }
                    className="px-2 py-1 bg-white border border-slate-200 text-slate-700 rounded-md text-[11px] font-medium hover:bg-sky-50 hover:text-sky-700"
                  >
                    Purwobinangun Pakem
                  </button>
                  <button
                    type="button"
                    onClick={() =>
                      setFormData({
                        ...formData,
                        name: 'Stadion Maguwoharjo & Helipad Logistik',
                        latitude: -7.7533,
                        longitude: 110.4285,
                        address: 'Jl. Kepuhsari, Maguwoharjo, Depok, Sleman',
                        capacity: 5000,
                      })
                    }
                    className="px-2 py-1 bg-white border border-slate-200 text-slate-700 rounded-md text-[11px] font-medium hover:bg-sky-50 hover:text-sky-700"
                  >
                    Maguwoharjo Sleman
                  </button>
                  <button
                    type="button"
                    onClick={() =>
                      setFormData({
                        ...formData,
                        name: 'GOR Amongrogo Shelter Indoor',
                        latitude: -7.7997,
                        longitude: 110.3888,
                        address: 'Jl. Kenari No. 1, Umbulharjo, Kota Yogyakarta',
                        capacity: 2500,
                      })
                    }
                    className="px-2 py-1 bg-white border border-slate-200 text-slate-700 rounded-md text-[11px] font-medium hover:bg-sky-50 hover:text-sky-700"
                  >
                    Amongrogo Kota Jogja
                  </button>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <input
                  type="checkbox"
                  id="is_active"
                  checked={formData.is_active}
                  onChange={(e) => setFormData({ ...formData, is_active: e.target.checked })}
                  className="rounded text-sky-600 focus:ring-sky-500"
                />
                <label htmlFor="is_active" className="text-sm font-semibold text-slate-700 cursor-pointer">
                  Posko Aktif & Siap Menerima Pengungsi
                </label>
              </div>

              <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setModalOpen(false)}
                  className="px-4 py-2.5 rounded-xl border border-slate-200 text-slate-600 text-sm font-semibold hover:bg-slate-50 transition"
                >
                  Batal
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="px-5 py-2.5 rounded-xl bg-sky-600 text-white text-sm font-semibold hover:bg-sky-700 transition flex items-center gap-2"
                >
                  {saving && <RefreshCw className="w-4 h-4 animate-spin" />}
                  {editingItem ? 'Simpan Perubahan' : 'Tambahkan Posko'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
