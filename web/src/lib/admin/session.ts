import 'server-only';
import { NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { createClient } from '@/lib/supabase/server';

export type AdminRole = 'SUPER_ADMIN' | 'GOVERNMENT_ADMIN' | 'COMMUNITY_MODERATOR';

export interface AdminSession {
  userId: string;
  email: string | null;
  displayName: string;
  roles: AdminRole[];
  isSuper: boolean;
  regionId: string | null;
  regionName: string | null;
}

/** Roles that may open the operations panel (SOS, evacuation, broadcast, audit). */
export const PANEL_ROLES: AdminRole[] = ['SUPER_ADMIN', 'GOVERNMENT_ADMIN'];
/** Community moderation is also open to dedicated moderators. */
export const MODERATION_ROLES: AdminRole[] = ['SUPER_ADMIN', 'GOVERNMENT_ADMIN', 'COMMUNITY_MODERATOR'];

const ADMIN_ROLES = new Set<string>(MODERATION_ROLES);

export class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

// Bootstrap allowlist for accounts that have not been granted a role in user_roles yet.
// Emails listed here are treated as SUPER_ADMIN. Leave empty in production once roles are seeded.
function allowlistedEmails(): Set<string> {
  return new Set(
    (process.env.ADMIN_EMAILS ?? '')
      .split(',')
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean),
  );
}

export async function getAdminSession(): Promise<AdminSession> {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) throw new HttpError(401, 'Sesi berakhir. Silakan masuk kembali.');

  const { rows } = await pool.query<{
    roles: string[];
    display_name: string | null;
    region_id: string | null;
    region_name: string | null;
  }>(
    `select
       coalesce((select array_agg(ur.role::text) from public.user_roles ur where ur.user_id = $1), '{}') as roles,
       p.display_name, p.region_id, r.name as region_name
     from (select $1::uuid as id) u
     left join public.profiles p on p.id = u.id
     left join public.regions r on r.id = p.region_id`,
    [user.id],
  );
  const row = rows[0];
  const roles = (row?.roles ?? []).filter((r): r is AdminRole => ADMIN_ROLES.has(r));
  if (user.email && allowlistedEmails().has(user.email.toLowerCase()) && !roles.includes('SUPER_ADMIN')) {
    roles.push('SUPER_ADMIN');
  }

  return {
    userId: user.id,
    email: user.email ?? null,
    displayName: row?.display_name ?? user.email ?? 'Petugas',
    roles,
    isSuper: roles.includes('SUPER_ADMIN'),
    regionId: row?.region_id ?? null,
    regionName: row?.region_name ?? null,
  };
}

/** Resolves the caller and rejects anyone without one of the allowed roles. */
export async function requireAdmin(allowed: AdminRole[] = PANEL_ROLES): Promise<AdminSession> {
  const session = await getAdminSession();
  if (!session.roles.some((r) => allowed.includes(r))) {
    throw new HttpError(403, 'Akun Anda belum memiliki akses ke modul ini.');
  }
  return session;
}

/**
 * Region filter for queries. SUPER_ADMIN sees every region (null).
 * A GOVERNMENT_ADMIN must be assigned to a region, otherwise there is nothing they may see.
 */
export function regionScope(session: AdminSession): string | null {
  if (session.isSuper) return null;
  if (!session.regionId) {
    throw new HttpError(403, 'Akun Anda belum ditetapkan ke wilayah. Hubungi super admin.');
  }
  return session.regionId;
}

/** Maps thrown errors to JSON without leaking database details to the browser. */
export function errorResponse(error: unknown, fallback: string) {
  if (error instanceof HttpError) {
    return NextResponse.json({ success: false, error: error.message }, { status: error.status });
  }
  console.error(fallback, error);
  return NextResponse.json({ success: false, error: fallback }, { status: 500 });
}

export function isUuid(value: unknown): value is string {
  return typeof value === 'string' && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
}
