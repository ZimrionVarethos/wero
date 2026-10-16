import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { verifyAuditChain, writeAudit } from '@/lib/admin/audit';
import { errorResponse, HttpError, isUuid, regionScope, requireAdmin } from '@/lib/admin/session';
import { SOS_SCOPE_CTE, SOS_SCOPE_JOIN, SOS_SCOPE_WHERE } from '@/lib/admin/scope';

// Government admins see audit rows for SOS cases in their region and rows they wrote themselves.
// $1 region scope, $2 caller id.
const AUDIT_SCOPE = `(
  $1::uuid is null
  or a.actor_id = $2::uuid
  or (a.target_type = 'SOS' and a.target_id in (
        select s.id from public.sos_events s ${SOS_SCOPE_JOIN} where ${SOS_SCOPE_WHERE}))
)`;

export async function GET(req: NextRequest) {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const sp = req.nextUrl.searchParams;

    if (sp.get('verify') === '1') {
      if (!session.isSuper) throw new HttpError(403, 'Pemeriksaan rantai hanya untuk super admin.');
      return NextResponse.json({ success: true, data: await verifyAuditChain() });
    }

    const targetId = sp.get('target_id')?.trim() || null;
    if (targetId && !isUuid(targetId)) throw new HttpError(400, 'ID target tidak valid.');
    const exporting = sp.get('export') === '1';
    if (exporting && !targetId) throw new HttpError(400, 'Isi ID kasus SOS untuk ekspor.');
    const limit = Math.min(Math.max(Number(sp.get('limit')) || 100, 1), 500);

    const { rows } = await pool.query(
      `${SOS_SCOPE_CTE}
       select a.id, a.occurred_at, a.action, a.target_type, a.target_id, a.metadata,
              a.actor_id, coalesce(pr.display_name, case when a.actor_id is null then 'Sistem' else 'Pengguna' end) as actor_name,
              a.row_hash is not null as signed
       from public.audit_logs a
       left join public.profiles pr on pr.id = a.actor_id
       where ${AUDIT_SCOPE} and ($3::uuid is null or a.target_id = $3::uuid)
       order by a.id desc
       limit ${exporting ? 5000 : limit}`,
      [scope, session.userId, targetId],
    );

    if (exporting) {
      if (rows.length === 0) throw new HttpError(404, 'Tidak ada catatan untuk kasus ini di wilayah Anda.');
      await writeAudit({
        actorId: session.userId,
        action: 'AUDIT_EXPORTED',
        targetType: 'SOS',
        targetId,
        metadata: { rows: rows.length },
      });
      return NextResponse.json({
        success: true,
        data: { target_id: targetId, exported_at: new Date().toISOString(), exported_by: session.userId, entries: rows },
      });
    }

    return NextResponse.json({ success: true, data: rows });
  } catch (error) {
    return errorResponse(error, 'Gagal mengambil log audit');
  }
}
