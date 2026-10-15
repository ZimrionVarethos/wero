import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const status = searchParams.get('status') || 'ALL';

    let query = `
      SELECT 
        r.id as report_id,
        r.post_id,
        r.reporter_id,
        r.reason_code,
        r.details,
        r.status as report_status,
        r.created_at as report_created_at,
        r.reviewed_at,
        r.resolution,
        p.title as post_title,
        p.body as post_body,
        p.status as post_status,
        (SELECT COUNT(*)::int FROM public.community_reports cr WHERE cr.post_id = p.id) as post_report_count,
        p.created_at as post_created_at,
        pr.display_name as author_name
      FROM public.community_reports r
      LEFT JOIN public.community_posts p ON r.post_id = p.id
      LEFT JOIN public.profiles pr ON p.author_id = pr.id
      WHERE 1=1
    `;
    const params: unknown[] = [];

    if (status !== 'ALL') {
      params.push(status);
      query += ` AND r.status = $${params.length}`;
    }

    query += ` ORDER BY r.created_at DESC LIMIT 100`;

    const result = await pool.query(query, params);

    // Also fetch audit history
    const auditRes = await pool.query(`
      SELECT 
        a.id, a.post_id, a.action, a.reason, a.created_at,
        p.title as post_title
      FROM public.community_moderation_actions a
      LEFT JOIN public.community_posts p ON a.post_id = p.id
      ORDER BY a.created_at DESC
      LIMIT 20
    `);

    return NextResponse.json({
      success: true,
      reports: result.rows,
      auditHistory: auditRes.rows,
    });
  } catch (error: any) {
    console.error('Failed to fetch moderation reports:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal mengambil data moderasi' },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      reportId,
      postId,
      action, // 'REMOVE_TAKEDOWN' | 'APPROVE_RESTORE'
      resolutionNote = 'Tindakan moderasi disetujui via Web Admin Portal',
      moderatorId = '00000000-0000-0000-0000-000000000001',
    } = body;

    if (!reportId || !postId || !action) {
      return NextResponse.json(
        { success: false, error: 'reportId, postId, dan action wajib diisi' },
        { status: 400 }
      );
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const isTakedown = action === 'REMOVE_TAKEDOWN';
      const targetPostStatus = isTakedown ? 'REMOVED' : 'PUBLISHED';
      const targetReportStatus = isTakedown ? 'REVIEWED_ACTION' : 'DISMISSED';

      // 1. Update Post Status
      await client.query(
        `UPDATE public.community_posts SET status = $1, updated_at = NOW() WHERE id = $2`,
        [targetPostStatus, postId]
      );

      // 2. Update Report Status
      await client.query(
        `UPDATE public.community_reports 
         SET status = $1, reviewed_at = NOW(), resolution = $2 
         WHERE id = $3`,
        [targetReportStatus, resolutionNote, reportId]
      );

      // 3. Log into community_moderation_actions
      await client.query(
        `INSERT INTO public.community_moderation_actions 
         (post_id, moderator_id, action, reason, created_at)
         VALUES ($1, $2, $3, $4, NOW())`,
        [postId, moderatorId, action, resolutionNote]
      );

      await client.query('COMMIT');

      return NextResponse.json({
        success: true,
        message: isTakedown
          ? 'Konten berhasil di-takedown dari feed publik'
          : 'Konten berhasil dipulihkan ke status publik',
      });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (error: any) {
    console.error('Failed to execute moderation action:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal memproses tindakan moderasi' },
      { status: 500 }
    );
  }
}
