import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const kind = searchParams.get('kind');
    const search = searchParams.get('search');

    let query = `
      SELECT 
        id, kind, name, description, address, capacity, is_active,
        latitude, longitude, source, source_url, verified_at,
        created_at, updated_at
      FROM public.evacuation_points
      WHERE 1=1
    `;
    const params: unknown[] = [];

    if (kind && kind !== 'ALL') {
      params.push(kind);
      query += ` AND kind = $${params.length}`;
    }

    if (search && search.trim()) {
      params.push(`%${search.trim()}%`);
      query += ` AND (name ILIKE $${params.length} OR address ILIKE $${params.length} OR description ILIKE $${params.length})`;
    }

    query += ` ORDER BY updated_at DESC, created_at DESC`;

    const result = await pool.query(query, params);
    return NextResponse.json({ success: true, data: result.rows });
  } catch (error: any) {
    console.error('Failed to fetch shelters:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal mengambil data shelter' },
      { status: 500 }
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      name,
      kind = 'SHELTER',
      description = '',
      address = '',
      capacity = 100,
      latitude,
      longitude,
      is_active = true,
      source = 'BPBD / Pemda Terverifikasi',
    } = body;

    if (!name || latitude === undefined || longitude === undefined) {
      return NextResponse.json(
        { success: false, error: 'Nama dan koordinat latitude/longitude wajib diisi' },
        { status: 400 }
      );
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    const insertQuery = `
      INSERT INTO public.evacuation_points (
        name, kind, description, address, capacity,
        geom, is_active, source,
        verified_at, created_at, updated_at
      )
      VALUES (
        $1, $2, $3, $4, $5,
        ST_SetSRID(ST_MakePoint($7, $6), 4326), $8, $9,
        NOW(), NOW(), NOW()
      )
      RETURNING id, name, kind, description, address, capacity, latitude, longitude, is_active, source, created_at
    `;

    const result = await pool.query(insertQuery, [
      name.trim(),
      kind,
      description?.trim() || null,
      address?.trim() || null,
      parseInt(capacity, 10) || 0,
      lat,
      lng,
      Boolean(is_active),
      source,
    ]);

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error: any) {
    console.error('Failed to create shelter:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal menyimpan posko/shelter baru' },
      { status: 500 }
    );
  }
}
