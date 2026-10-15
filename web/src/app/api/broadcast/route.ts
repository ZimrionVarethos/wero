import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function GET(_req: NextRequest) {
  try {
    const result = await pool.query(`
      SELECT 
        id, source, source_event_id, disaster_type, severity,
        magnitude, depth_km, headline, source_url, occurred_at,
        is_published, created_at, updated_at
      FROM public.disaster_events
      ORDER BY occurred_at DESC, created_at DESC
      LIMIT 20
    `);

    return NextResponse.json({ success: true, data: result.rows });
  } catch (error: any) {
    console.error('Failed to fetch disaster events:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal mengambil data peristiwa bencana' },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      headline,
      disaster_type = 'EARTHQUAKE',
      severity = 'WARNING',
      source = 'PUSKODALOPS_BPBD',
      source_event_id = `MANUAL-${Date.now()}`,
      magnitude,
      depth_km,
      source_url,
    } = body;

    if (!headline) {
      return NextResponse.json(
        { success: false, error: 'Judul peringatan (headline) wajib diisi' },
        { status: 400 }
      );
    }

    const query = `
      INSERT INTO public.disaster_events (
        headline, disaster_type, severity, source, source_event_id,
        magnitude, depth_km, source_url, is_published,
        source_payload, occurred_at, created_at, updated_at
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, $8, true,
        $9, NOW(), NOW(), NOW()
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      headline.trim(),
      disaster_type,
      severity,
      source,
      source_event_id,
      magnitude ? parseFloat(magnitude) : null,
      depth_km ? parseFloat(depth_km) : null,
      source_url || null,
      JSON.stringify({ broadcasted_by: 'Web Admin Portal', issued_at: new Date().toISOString() }),
    ]);

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error: any) {
    console.error('Failed to broadcast disaster alert:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal menyiarkan peringatan bencana' },
      { status: 500 }
    );
  }
}
