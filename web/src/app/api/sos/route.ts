import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function GET(_req: NextRequest) {
  try {
    // 1. Fetch SOS Events with PostGIS coordinates
    const sosRes = await pool.query(`
      SELECT 
        s.id, s.victim_id, s.mode, s.escalation, s.stage, s.status, s.note,
        s.accuracy_m, s.created_at, s.stage_changed_at, s.resolved_at,
        ST_Y(s.location::geometry) as latitude,
        ST_X(s.location::geometry) as longitude,
        p.display_name as victim_name
      FROM public.sos_events s
      LEFT JOIN public.profiles p ON s.victim_id = p.id
      ORDER BY s.created_at DESC
      LIMIT 50
    `);

    // 2. Fetch Urgent Family Check-ins (NEED_HELP or EVACUATING)
    const checkinRes = await pool.query(`
      SELECT 
        c.id, c.user_id, c.user_name, c.status, c.note, c.latitude, c.longitude,
        c.address, c.created_at
      FROM public.family_checkins c
      WHERE c.status IN ('NEED_HELP', 'EVACUATING')
      ORDER BY c.created_at DESC
      LIMIT 50
    `);

    return NextResponse.json({
      success: true,
      sosEvents: sosRes.rows,
      urgentCheckins: checkinRes.rows,
    });
  } catch (error: any) {
    console.error('Failed to fetch SOS operations:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal mengambil data monitoring SOS' },
      { status: 500 }
    );
  }
}

export async function PUT(req: NextRequest) {
  try {
    const body = await req.json();
    const { id, status, note } = body;

    if (!id || !status) {
      return NextResponse.json(
        { success: false, error: 'ID dan status wajib diisi' },
        { status: 400 }
      );
    }

    const isResolved = status === 'RESOLVED';
    const query = `
      UPDATE public.sos_events
      SET 
        status = $1,
        note = COALESCE($2, note),
        stage_changed_at = NOW(),
        resolved_at = CASE WHEN $3 = true THEN NOW() ELSE resolved_at END
      WHERE id = $4
      RETURNING *
    `;

    const result = await pool.query(query, [status, note, isResolved, id]);

    if (result.rowCount === 0) {
      return NextResponse.json(
        { success: false, error: 'Data SOS tidak ditemukan' },
        { status: 404 }
      );
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error: any) {
    console.error('Failed to update SOS status:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal memperbarui status SOS' },
      { status: 500 }
    );
  }
}
