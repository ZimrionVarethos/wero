import { HttpError } from '@/lib/admin/session';

export const EVAC_KINDS = ['ASSEMBLY', 'SHELTER', 'HEALTH', 'WATER', 'OTHER'] as const;

export interface EvacInput {
  name: string;
  kind: string;
  description: string | null;
  address: string | null;
  capacity: number | null;
  lat: number;
  lng: number;
  isActive: boolean | null;
  source: string;
  regionId: unknown;
}

function text(value: unknown, max: number): string | null {
  if (typeof value !== 'string') return null;
  const t = value.trim();
  return t ? t.slice(0, max) : null;
}

/** Validates the evacuation point form. Indonesia spans roughly 6N to 11S and 95E to 141E. */
export function parseEvacInput(body: Record<string, unknown>, requireAll: boolean): EvacInput {
  const name = text(body.name, 120);
  if (requireAll && (!name || name.length < 3)) throw new HttpError(400, 'Nama titik minimal 3 karakter.');

  const kind = typeof body.kind === 'string' ? body.kind : 'ASSEMBLY';
  if (!(EVAC_KINDS as readonly string[]).includes(kind)) throw new HttpError(400, 'Jenis titik tidak dikenali.');

  const lat = Number(body.latitude);
  const lng = Number(body.longitude);
  if (!Number.isFinite(lat) || !Number.isFinite(lng) || lat < -11.5 || lat > 6.5 || lng < 94.5 || lng > 141.5) {
    throw new HttpError(400, 'Pilih lokasi titik di peta wilayah Indonesia.');
  }

  let capacity: number | null = null;
  if (body.capacity !== undefined && body.capacity !== null && body.capacity !== '') {
    capacity = Number(body.capacity);
    if (!Number.isInteger(capacity) || capacity < 0 || capacity > 1_000_000) {
      throw new HttpError(400, 'Kapasitas harus bilangan bulat positif.');
    }
  }

  return {
    name: name ?? '',
    kind,
    description: text(body.description, 1000),
    address: text(body.address, 300),
    capacity,
    lat,
    lng,
    isActive: typeof body.is_active === 'boolean' ? body.is_active : null,
    source: text(body.source, 120) ?? 'Petugas wilayah',
    regionId: body.region_id,
  };
}
