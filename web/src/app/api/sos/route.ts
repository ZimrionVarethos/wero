import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { errorResponse, regionScope, requireAdmin } from '@/lib/admin/session';
import { SOS_INSIDE_REGION, SOS_SCOPE_CTE, SOS_SCOPE_JOIN, SOS_SCOPE_WHERE } from '@/lib/admin/scope';

const STATUSES = new Set(['ACTIVE', 'CLAIMED', 'RESOLVED', 'CANCELLED', 'EXPIRED']);

// The list only exposes the approximate location. Exact coordinates are released by
// GET /api/sos/[id], which records the access in the audit log first.
export async function GET(req: NextRequest) {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const status = req.nextUrl.searchParams.get('status');

    const params: unknown[] = [scope];
    let filter = '';
    if (status === 'OPEN') {
      filter = `and s.status in ('ACTIVE', 'CLAIMED')`;
    } else if (status && STATUSES.has(status)) {
      params.push(status);
      filter = `and s.status = $2`;
    }

    const { rows } = await pool.query(
      `${SOS_SCOPE_CTE}
       select
         s.id, s.mode, s.escalation, s.stage, s.status, s.created_at, s.stage_changed_at, s.resolved_at,
         st_y(s.approx_location::geometry) as approx_lat,
         st_x(s.approx_location::geometry) as approx_lng,
         split_part(coalesce(p.display_name, 'Warga'), ' ', 1) as victim_first_name,
         (select count(*)::int from public.responder_claims rc
            where rc.sos_id = s.id and rc.status in ('EN_ROUTE', 'ARRIVED')) as responders,
         ${SOS_INSIDE_REGION} as inside_region
       from public.sos_events s
       ${SOS_SCOPE_JOIN}
       where ${SOS_SCOPE_WHERE} ${filter}
       order by (s.status in ('ACTIVE', 'CLAIMED')) desc, s.created_at desc
       limit 200`,
      params,
    );

    return NextResponse.json({ success: true, data: rows });
  } catch (error) {
    return errorResponse(error, 'Gagal mengambil daftar SOS');
  }
}
