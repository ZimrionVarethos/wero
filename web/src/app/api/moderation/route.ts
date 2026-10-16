import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { writeAudit } from '@/lib/admin/audit';
import { errorResponse, HttpError, isUuid, MODERATION_ROLES, requireAdmin } from '@/lib/admin/session';

const STATUSES = new Set(['PENDING', 'REVIEWED_ACTION', 'DISMISSED']);

export async function GET(req: NextRequest) {
  try {
    await requireAdmin(MODERATION_ROLES);
    const status = req.nextUrl.searchParams.get('status') ?? 'PENDING';

    const params: unknown[] = [];
    let filter = '';
    if (STATUSES.has(status)) {
      params.push(status);
      filter = 'where r.status = $1';
    }

    const [reports, history] = await Promise.all([
      pool.query(
        `select
           r.id as report_id, r.post_id, r.reason_code, r.details, r.status as report_status,
           r.created_at as report_created_at, r.reviewed_at, r.resolution,
           p.title as post_title, p.body as post_body, p.status as post_status, p.created_at as post_created_at,
           (select count(*)::int from public.community_reports cr where cr.post_id = p.id) as post_report_count,
           pr.display_name as author_name
         from public.community_reports r
         left join public.community_posts p on p.id = r.post_id
         left join public.profiles pr on pr.id = p.author_id
         ${filter}
         order by r.created_at desc
         limit 100`,
        params,
      ),
      pool.query(
        `select a.id, a.post_id, a.action, a.reason, a.created_at,
                p.title as post_title, m.display_name as moderator_name
         from public.community_moderation_actions a
         left join public.community_posts p on p.id = a.post_id
         left join public.profiles m on m.id = a.moderator_id
         order by a.created_at desc
         limit 20`,
      ),
    ]);

    return NextResponse.json({ success: true, reports: reports.rows, history: history.rows });
  } catch (error) {
    return errorResponse(error, 'Gagal mengambil data moderasi');
  }
}

// Values must match the check constraint on community_moderation_actions.action.
const ACTIONS = {
  REMOVE: { post: 'REMOVED', report: 'REVIEWED_ACTION' },
  MARK_NO_VIOLATION: { post: 'PUBLISHED', report: 'DISMISSED' },
} as const;

export async function POST(req: NextRequest) {
  const client = await pool.connect();
  try {
    const session = await requireAdmin(MODERATION_ROLES);
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;
    const action = String(body.action ?? '') as keyof typeof ACTIONS;
    const reason = String(body.reason ?? '').trim();
    if (!isUuid(body.reportId) || !isUuid(body.postId)) throw new HttpError(400, 'Laporan tidak valid.');
    if (!(action in ACTIONS)) throw new HttpError(400, 'Tindakan tidak dikenali.');
    if (reason.length < 3 || reason.length > 500) throw new HttpError(400, 'Alasan wajib 3 sampai 500 karakter.');
    const target = ACTIONS[action];

    await client.query('BEGIN');
    const report = await client.query(
      `update public.community_reports
       set status = $1, reviewed_at = now(), reviewer_id = $5, resolution = $2
       where id = $3 and post_id = $4
       returning id`,
      [target.report, reason, body.reportId, body.postId, session.userId],
    );
    if (!report.rows[0]) throw new HttpError(404, 'Laporan tidak ditemukan.');
    await client.query('update public.community_posts set status = $1, updated_at = now() where id = $2', [target.post, body.postId]);
    await client.query(
      `insert into public.community_moderation_actions (post_id, moderator_id, action, reason)
       values ($1, $2, $3, $4)`,
      [body.postId, session.userId, action, reason],
    );
    await writeAudit(
      {
        actorId: session.userId,
        action: 'MODERATION_ACTION',
        targetType: 'COMMUNITY_POST',
        targetId: body.postId as string,
        metadata: { action, reason, report_id: body.reportId as string },
      },
      client,
    );
    await client.query('COMMIT');

    return NextResponse.json({ success: true });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => undefined);
    return errorResponse(error, 'Gagal memproses tindakan moderasi');
  } finally {
    client.release();
  }
}
