import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { writeAudit } from '@/lib/admin/audit';
import { errorResponse, isUuid, regionScope, requireAdmin } from '@/lib/admin/session';
import { EVAC_SCOPE_WHERE } from '@/lib/admin/scope';
import { parseEvacInput } from '@/lib/admin/evac-input';

const SELECT_COLUMNS = `
  e.id, e.kind, e.name, e.description, e.address, e.capacity, e.is_active,
  e.latitude, e.longitude, e.source, e.verified_at, e.region_id, r.name as region_name,
  e.created_at, e.updated_at`;

export async function GET(req: NextRequest) {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const kind = req.nextUrl.searchParams.get('kind');
    const search = req.nextUrl.searchParams.get('search')?.trim();

    const params: unknown[] = [scope];
    let filter = '';
    if (kind && kind !== 'ALL') {
      params.push(kind);
      filter += ` and e.kind = $${params.length}`;
    }
    if (search) {
      params.push(`%${search}%`);
      filter += ` and (e.name ilike $${params.length} or e.address ilike $${params.length})`;
    }

    const { rows } = await pool.query(
      `select ${SELECT_COLUMNS}
       from public.evacuation_points e
       left join public.regions r on r.id = e.region_id
       where ${EVAC_SCOPE_WHERE} ${filter}
       order by e.is_active desc, e.updated_at desc
       limit 500`,
      params,
    );
    return NextResponse.json({ success: true, data: rows });
  } catch (error) {
    return errorResponse(error, 'Gagal mengambil titik evakuasi');
  }
}

export async function POST(req: NextRequest) {
  const client = await pool.connect();
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const input = parseEvacInput(await req.json().catch(() => ({})), true);

    // Government admins always create inside their own region. Super admins may pick one.
    const regionId = scope ?? (isUuid(input.regionId) ? input.regionId : null);

    await client.query('BEGIN');
    const { rows } = await client.query(
      `insert into public.evacuation_points
         (name, kind, description, address, capacity, geom, is_active, source, region_id, verified_at)
       values ($1, $2, $3, $4, $5, st_setsrid(st_makepoint($7, $6), 4326), $8, $9, $10, now())
       returning id, name, kind`,
      [input.name, input.kind, input.description, input.address, input.capacity, input.lat, input.lng, input.isActive ?? true, input.source, regionId],
    );
    await writeAudit(
      {
        actorId: session.userId,
        action: 'EVAC_CREATED',
        targetType: 'EVACUATION_POINT',
        targetId: rows[0].id,
        metadata: { name: rows[0].name, kind: rows[0].kind },
      },
      client,
    );
    await client.query('COMMIT');
    return NextResponse.json({ success: true, data: rows[0] });
  } catch (error) {
    await client.query('ROLLBACK').catch(() => undefined);
    return errorResponse(error, 'Gagal menyimpan titik evakuasi');
  } finally {
    client.release();
  }
}
