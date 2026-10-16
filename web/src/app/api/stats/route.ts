import { NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { errorResponse, regionScope, requireAdmin } from '@/lib/admin/session';
import { EVAC_SCOPE_WHERE, SOS_SCOPE_CTE, SOS_SCOPE_JOIN, SOS_SCOPE_WHERE } from '@/lib/admin/scope';

export async function GET() {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);

    const [sos, evac, reports, broadcasts] = await Promise.all([
      pool.query(
        `${SOS_SCOPE_CTE}
         select
           count(*) filter (where s.status = 'ACTIVE')::int as waiting,
           count(*) filter (where s.status = 'CLAIMED')::int as claimed,
           count(*) filter (where s.status = 'RESOLVED' and s.resolved_at > now() - interval '24 hours')::int as resolved_24h,
           min(s.created_at) filter (where s.status = 'ACTIVE') as oldest_waiting_at
         from public.sos_events s
         ${SOS_SCOPE_JOIN}
         where ${SOS_SCOPE_WHERE}`,
        [scope],
      ),
      pool.query(
        `select
           count(*) filter (where e.is_active)::int as active,
           count(*) filter (where not e.is_active)::int as inactive,
           coalesce(sum(e.capacity) filter (where e.is_active), 0)::int as capacity
         from public.evacuation_points e
         where ${EVAC_SCOPE_WHERE}`,
        [scope],
      ),
      pool.query(`select count(*)::int as pending from public.community_reports where status = 'PENDING'`),
      pool.query(
        `select count(*)::int as last_7d
         from public.disaster_events d
         where d.source_event_id like 'MANUAL-%' and d.created_at > now() - interval '7 days'
           and ($1::uuid is null or d.region_id = $1::uuid or d.source_payload->'target_region_ids' ? $1::text)`,
        [scope],
      ),
    ]);

    return NextResponse.json({
      success: true,
      data: {
        sos: sos.rows[0],
        evacuation: evac.rows[0],
        pendingReports: reports.rows[0].pending,
        broadcasts7d: broadcasts.rows[0].last_7d,
      },
    });
  } catch (error) {
    return errorResponse(error, 'Gagal menghitung ringkasan');
  }
}
