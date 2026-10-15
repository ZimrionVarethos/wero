import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

function normalizeSeverity(val: string): 'AWAS' | 'SIAGA' | 'WASPADA' | 'INFO' {
  const upper = (val || '').toUpperCase().trim();
  if (upper === 'AWAS' || upper === 'CRITICAL' || upper === 'DANGER') return 'AWAS';
  if (upper === 'SIAGA' || upper === 'WARNING') return 'SIAGA';
  if (upper === 'WASPADA' || upper === 'ADVISORY') return 'WASPADA';
  if (upper === 'INFO') return 'INFO';
  return 'SIAGA';
}

export async function GET(_req: NextRequest) {
  try {
    const result = await pool.query(`
      SELECT 
        id, source, source_event_id, disaster_type, severity,
        magnitude, depth_km, headline, source_url, occurred_at,
        is_published, region_id, source_payload, created_at, updated_at
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
      severity = 'SIAGA',
      source = 'PUSKODALOPS BPBD DIY',
      source_event_id = `MANUAL-${Date.now()}`,
      magnitude,
      depth_km,
      source_url,
      target_type = 'ALL',
      target_region_ids = [],
      target_regions = [],
    } = body;

    if (!headline || !headline.trim()) {
      return NextResponse.json(
        { success: false, error: 'Judul peringatan (headline) wajib diisi' },
        { status: 400 }
      );
    }

    const safeSeverity = normalizeSeverity(severity);
    const primaryRegionId =
      target_type === 'SPECIFIC' && Array.isArray(target_region_ids) && target_region_ids.length === 1
        ? target_region_ids[0]
        : null;

    const sourcePayloadObj = {
      broadcasted_by: 'Web Admin Portal',
      target_type: target_type === 'SPECIFIC' ? 'SPECIFIC' : 'ALL',
      target_region_ids: Array.isArray(target_region_ids) ? target_region_ids : [],
      target_regions: Array.isArray(target_regions) ? target_regions : [],
      issued_at: new Date().toISOString(),
    };

    const query = `
      INSERT INTO public.disaster_events (
        headline, disaster_type, severity, source, source_event_id,
        magnitude, depth_km, source_url, is_published,
        region_id, source_payload, occurred_at, created_at, updated_at
      )
      VALUES (
        $1, $2, $3, $4, $5,
        $6, $7, $8, true,
        $9, $10, NOW(), NOW(), NOW()
      )
      RETURNING *
    `;

    const result = await pool.query(query, [
      headline.trim(),
      disaster_type,
      safeSeverity,
      source,
      source_event_id,
      magnitude ? parseFloat(magnitude) : null,
      depth_km ? parseFloat(depth_km) : null,
      source_url || null,
      primaryRegionId,
      JSON.stringify(sourcePayloadObj),
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
