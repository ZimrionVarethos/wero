import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { writeAudit } from '@/lib/admin/audit';
import { errorResponse, HttpError, isUuid, regionScope, requireAdmin } from '@/lib/admin/session';
import { SOS_INSIDE_REGION, SOS_SCOPE_CTE, SOS_SCOPE_JOIN, SOS_SCOPE_WHERE } from '@/lib/admin/scope';

type Params = { params: Promise<{ id: string }> };

async function loadDetail(scope: string | null, id: string) {
  const { rows } = await pool.query(
    `${SOS_SCOPE_CTE}
     select
       s.id, s.mode, s.escalation, s.stage, s.status, s.note, s.accuracy_m,
       s.created_at, s.stage_changed_at, s.resolved_at,
       st_y(s.location::geometry) as lat,
       st_x(s.location::geometry) as lng,
       coalesce(p.display_name, 'Warga') as victim_name,
       ${SOS_INSIDE_REGION} as inside_region
     from public.sos_events s
     ${SOS_SCOPE_JOIN}
     where s.id = $2 and ${SOS_SCOPE_WHERE}`,
    [scope, id],
  );
  if (!rows[0]) throw new HttpError(404, 'Kasus SOS tidak ditemukan di wilayah Anda.');

  const responders = await pool.query(
    `select coalesce(pr.display_name, 'Relawan') as name, rc.status, rc.claimed_at, rc.updated_at
     from public.responder_claims rc
     left join public.profiles pr on pr.id = rc.responder_id
     where rc.sos_id = $1 and rc.status in ('EN_ROUTE', 'ARRIVED')
     order by rc.claimed_at`,
    [id],
  );
  return { ...rows[0], responders: responders.rows };
}

// Opening a case reveals the exact location, so the audit row is written before the data is returned.
export async function GET(_req: NextRequest, { params }: Params) {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const { id } = await params;
    if (!isUuid(id)) throw new HttpError(400, 'ID kasus tidak valid.');

    const detail = await loadDetail(scope, id);
    await writeAudit({
      actorId: session.userId,
      action: 'SOS_VIEWED',
      targetType: 'SOS',
      targetId: id,
      metadata: { status: detail.status, inside_region: detail.inside_region },
    });
    return NextResponse.json({ success: true, data: detail });
  } catch (error) {
    return errorResponse(error, 'Gagal memuat detail SOS');
  }
}

const ADMIN_TRANSITIONS = new Set(['RESOLVED', 'CANCELLED']);

export async function PATCH(req: NextRequest, { params }: Params) {
  const client = await pool.connect();
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const { id } = await params;
    if (!isUuid(id)) throw new HttpError(400, 'ID kasus tidak valid.');

    const body = (await req.json().catch(() => ({}))) as { status?: string; reason?: string };
    const status = body.status ?? '';
    const reason = (body.reason ?? '').trim();
    if (!ADMIN_TRANSITIONS.has(status)) throw new HttpError(400, 'Status tujuan tidak dikenali.');
    if (reason.length < 3 || reason.length > 500) {
      throw new HttpError(400, 'Alasan wajib diisi, 3 sampai 500 karakter.');
    }

    // Scope check and update in one transaction with the audit row.
    await client.query('BEGIN');
    const { rows } = await client.query(
      `${SOS_SCOPE_CTE}
       update public.sos_events s2
       set status = $3,
           stage_changed_at = now(),
           resolved_at = case when $3 = 'RESOLVED' then now() else s2.resolved_at end
       from public.sos_events s
       ${SOS_SCOPE_JOIN}
       where s2.id = s.id and s.id = $2 and s.status in ('ACTIVE', 'CLAIMED') and ${SOS_SCOPE_WHERE}
       returning s.status as previous_status`,
      [scope, id, status],
    );
    if (!rows[0]) throw new HttpError(409, 'Kasus tidak ditemukan atau sudah tidak aktif.');

    await writeAudit(
      {
        actorId: session.userId,
        action: 'SOS_STATUS_CHANGED',
        targetType: 'SOS',
        targetId: id,
        metadata: { from: rows[0].previous_status, to: status, reason },
      },
      client,
    );
    await client.query('COMMIT');

    return NextResponse.json({ success: true, data: await loadDetail(scope, id) });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => undefined);
    return errorResponse(error, 'Gagal memperbarui status SOS');
  } finally {
    client.release();
  }
}
