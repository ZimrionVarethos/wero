import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { writeAudit } from '@/lib/admin/audit';
import { parseEvacInput } from '@/lib/admin/evac-input';
import { EVAC_SCOPE_WHERE } from '@/lib/admin/scope';
import { errorResponse, HttpError, isUuid, regionScope, requireAdmin } from '@/lib/admin/session';

type Params = { params: Promise<{ id: string }> };

export async function PUT(req: NextRequest, { params }: Params) {
  const client = await pool.connect();
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const { id } = await params;
    if (!isUuid(id)) throw new HttpError(400, 'ID titik tidak valid.');
    const input = parseEvacInput(await req.json().catch(() => ({})), true);

    await client.query('BEGIN');
    // A government admin editing an unassigned point takes it into their region.
    const { rows } = await client.query(
      `update public.evacuation_points e
       set name = $3, kind = $4, description = $5, address = $6, capacity = $7,
           geom = st_setsrid(st_makepoint($9, $8), 4326),
           is_active = coalesce($10, e.is_active),
           region_id = coalesce(e.region_id, $1::uuid),
           updated_at = now()
       where e.id = $2 and ${EVAC_SCOPE_WHERE}
       returning e.id, e.name, e.kind, e.is_active`,
      [scope, id, input.name, input.kind, input.description, input.address, input.capacity, input.lat, input.lng, input.isActive],
    );
    if (!rows[0]) throw new HttpError(404, 'Titik evakuasi tidak ditemukan di wilayah Anda.');

    await writeAudit(
      {
        actorId: session.userId,
        action: 'EVAC_UPDATED',
        targetType: 'EVACUATION_POINT',
        targetId: id,
        metadata: { name: rows[0].name, kind: rows[0].kind, is_active: rows[0].is_active },
      },
      client,
    );
    await client.query('COMMIT');
    return NextResponse.json({ success: true, data: rows[0] });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => undefined);
    return errorResponse(error, 'Gagal memperbarui titik evakuasi');
  } finally {
    client.release();
  }
}

export async function DELETE(_req: NextRequest, { params }: Params) {
  const client = await pool.connect();
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const { id } = await params;
    if (!isUuid(id)) throw new HttpError(400, 'ID titik tidak valid.');

    await client.query('BEGIN');
    const { rows } = await client.query(
      `delete from public.evacuation_points e
       where e.id = $2 and ${EVAC_SCOPE_WHERE}
       returning e.id, e.name, e.kind`,
      [scope, id],
    );
    if (!rows[0]) throw new HttpError(404, 'Titik evakuasi tidak ditemukan di wilayah Anda.');

    await writeAudit(
      {
        actorId: session.userId,
        action: 'EVAC_DELETED',
        targetType: 'EVACUATION_POINT',
        targetId: id,
        metadata: { name: rows[0].name, kind: rows[0].kind },
      },
      client,
    );
    await client.query('COMMIT');
    return NextResponse.json({ success: true });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => undefined);
    return errorResponse(error, 'Gagal menghapus titik evakuasi');
  } finally {
    client.release();
  }
}
