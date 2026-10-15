import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

export async function PUT(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const body = await req.json();
    const {
      name,
      kind,
      description,
      address,
      capacity,
      latitude,
      longitude,
      is_active,
      source,
    } = body;

    const lat = latitude !== undefined ? parseFloat(latitude) : null;
    const lng = longitude !== undefined ? parseFloat(longitude) : null;

    let updateQuery = `
      UPDATE public.evacuation_points
      SET
        name = COALESCE($1, name),
        kind = COALESCE($2, kind),
        description = COALESCE($3, description),
        address = COALESCE($4, address),
        capacity = COALESCE($5, capacity),
        is_active = COALESCE($6, is_active),
        source = COALESCE($7, source),
        updated_at = NOW()
    `;

    const queryParams: unknown[] = [
      name?.trim(),
      kind,
      description?.trim(),
      address?.trim(),
      capacity !== undefined ? parseInt(capacity, 10) : null,
      is_active !== undefined ? Boolean(is_active) : null,
      source?.trim(),
    ];

    if (lat !== null && lng !== null && !isNaN(lat) && !isNaN(lng)) {
      queryParams.push(lat, lng);
      updateQuery += `,
        geom = ST_SetSRID(ST_MakePoint($${queryParams.length}, $${queryParams.length - 1}), 4326)
      `;
    }

    queryParams.push(id);
    updateQuery += ` WHERE id = $${queryParams.length} RETURNING *`;

    const result = await pool.query(updateQuery, queryParams);

    if (result.rowCount === 0) {
      return NextResponse.json(
        { success: false, error: 'Data shelter tidak ditemukan' },
        { status: 404 }
      );
    }

    return NextResponse.json({ success: true, data: result.rows[0] });
  } catch (error: any) {
    console.error('Failed to update shelter:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal memperbarui shelter' },
      { status: 500 }
    );
  }
}

export async function DELETE(
  _req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const result = await pool.query(
      `DELETE FROM public.evacuation_points WHERE id = $1 RETURNING id, name`,
      [id]
    );

    if (result.rowCount === 0) {
      return NextResponse.json(
        { success: false, error: 'Data shelter tidak ditemukan' },
        { status: 404 }
      );
    }

    return NextResponse.json({
      success: true,
      message: `Posko ${result.rows[0].name} berhasil dihapus`,
    });
  } catch (error: any) {
    console.error('Failed to delete shelter:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal menghapus shelter' },
      { status: 500 }
    );
  }
}
