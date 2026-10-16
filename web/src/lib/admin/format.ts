import type { EvacKind, SosStatus } from './types';

const pad = (n: number) => String(n).padStart(2, '0');
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/** "14.30", because UI copy avoids colons (siagaku_design_skills/SKILL.md). */
export function formatTime(iso: string | Date): string {
  const d = new Date(iso);
  return `${pad(d.getHours())}.${pad(d.getMinutes())}`;
}

export function formatDateTime(iso: string | Date): string {
  const d = new Date(iso);
  return `${d.getDate()} ${MONTHS[d.getMonth()]} ${d.getFullYear()}, ${formatTime(d)}`;
}

/** "5 menit lalu", for case lists where recency matters more than the exact time. */
export function formatAgo(iso: string | Date, now = Date.now()): string {
  const mins = Math.max(0, Math.round((now - new Date(iso).getTime()) / 60000));
  if (mins < 1) return 'baru saja';
  if (mins < 60) return `${mins} menit lalu`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours} jam lalu`;
  return `${Math.floor(hours / 24)} hari lalu`;
}

export const SOS_STATUS_LABEL: Record<SosStatus, string> = {
  ACTIVE: 'Menunggu penolong',
  CLAIMED: 'Penolong menuju',
  RESOLVED: 'Selesai',
  CANCELLED: 'Dibatalkan',
  EXPIRED: 'Kedaluwarsa',
};

export const MODE_LABEL: Record<string, string> = { PUBLIC: 'Publik', PRIVATE: 'Privat' };

export const EVAC_KIND_LABEL: Record<EvacKind, string> = {
  ASSEMBLY: 'Titik kumpul',
  SHELTER: 'Shelter',
  HEALTH: 'Fasilitas kesehatan',
  WATER: 'Sumber air',
  OTHER: 'Lainnya',
  ROUTE: 'Rute',
};

export const HAZARD_LABEL: Record<string, string> = {
  EARTHQUAKE: 'Gempa bumi',
  TSUNAMI: 'Tsunami',
  FLOOD: 'Banjir',
  LANDSLIDE: 'Tanah longsor',
  VOLCANO: 'Erupsi gunung api',
  EXTREME_WEATHER: 'Cuaca ekstrem',
  FIRE: 'Kebakaran',
  OTHER: 'Lainnya',
};

export const AUDIT_ACTION_LABEL: Record<string, string> = {
  TRIGGER_SOS: 'SOS dibuat warga',
  CANCEL_SOS: 'SOS dibatalkan warga',
  RESOLVE_SOS: 'SOS diselesaikan warga',
  SOS_VIEWED: 'Lokasi tepat dibuka',
  SOS_STATUS_CHANGED: 'Status SOS diubah',
  EVAC_CREATED: 'Titik evakuasi ditambah',
  EVAC_UPDATED: 'Titik evakuasi diubah',
  EVAC_DELETED: 'Titik evakuasi dihapus',
  ADMIN_BROADCAST: 'Siaran peringatan',
  BROADCAST_DELETED: 'Hapus siaran',
  MODERATION_ACTION: 'Tindakan moderasi',
  AUDIT_EXPORTED: 'Log kasus diekspor',
};

export const REPORT_REASON_LABEL: Record<string, string> = {
  MISLEADING_DANGEROUS: 'Menyesatkan atau berbahaya',
  SPAM: 'Spam',
  HARASSMENT: 'Pelecehan',
  PRIVACY: 'Melanggar privasi',
  IRRELEVANT: 'Tidak relevan',
  OTHER: 'Lainnya',
};

export function shortId(id: string | null | undefined) {
  return id ? id.slice(0, 8) : '-';
}
