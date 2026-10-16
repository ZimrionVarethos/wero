import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { writeAudit } from '@/lib/admin/audit';
import { isUuid } from '@/lib/admin/session';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const lat = parseFloat(searchParams.get('lat') || '');
    const lng = parseFloat(searchParams.get('lng') || '');
    const radiusMeters = parseFloat(searchParams.get('radius') || '10000'); // default 10km

    let query: string;
    let params: unknown[];

    if (!isNaN(lat) && !isNaN(lng)) {
      query = `
        select
          s.id, s.victim_id, s.mode, s.status, s.stage, s.note, s.accuracy_m, s.created_at,
          st_y(s.location::geometry) as lat,
          st_x(s.location::geometry) as lng,
          st_distance(s.location, st_setsrid(st_makepoint($1, $2), 4326)::geography) as distance_m,
          coalesce(p.display_name, 'Warga Sekitar') as victim_name,
          (select count(*)::int from public.responder_claims rc
           where rc.sos_id = s.id and rc.status in ('EN_ROUTE', 'ARRIVED')) as responders_count
        from public.sos_events s
        left join public.profiles p on p.id = s.victim_id
        where s.mode = 'PUBLIC'
          and s.status in ('ACTIVE', 'CLAIMED')
          and st_dwithin(s.location, st_setsrid(st_makepoint($1, $2), 4326)::geography, $3)
        order by distance_m asc, s.created_at desc
        limit 50
      `;
      params = [lng, lat, radiusMeters];
    } else {
      query = `
        select
          s.id, s.victim_id, s.mode, s.status, s.stage, s.note, s.accuracy_m, s.created_at,
          st_y(s.location::geometry) as lat,
          st_x(s.location::geometry) as lng,
          0 as distance_m,
          coalesce(p.display_name, 'Warga Sekitar') as victim_name,
          (select count(*)::int from public.responder_claims rc
           where rc.sos_id = s.id and rc.status in ('EN_ROUTE', 'ARRIVED')) as responders_count
        from public.sos_events s
        left join public.profiles p on p.id = s.victim_id
        where s.mode = 'PUBLIC'
          and s.status in ('ACTIVE', 'CLAIMED')
        order by s.created_at desc
        limit 50
      `;
      params = [];
    }

    const { rows } = await pool.query(query, params);
    return NextResponse.json({ success: true, data: rows }, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (error: any) {
    console.error('Error fetching public SOS:', error);
    return NextResponse.json({ success: false, error: error.message }, {
      status: 500,
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  }
}

export async function POST(req: NextRequest) {
  const client = await pool.connect();
  try {
    const body = (await req.json().catch(() => ({}))) as {
      sos_id?: string;
      responder_id?: string;
      responder_name?: string;
      status?: 'EN_ROUTE' | 'ARRIVED' | 'RELEASED';
    };

    const sosId = body.sos_id;
    const responderId = body.responder_id;
    const status = body.status || 'EN_ROUTE';

    if (!sosId || !isUuid(sosId)) {
      return NextResponse.json({ success: false, error: 'ID kasus SOS tidak valid' }, { status: 400 });
    }
    if (!responderId || !isUuid(responderId)) {
      return NextResponse.json({ success: false, error: 'ID relawan tidak valid' }, { status: 400 });
    }

    await client.query('BEGIN');

    // 1. Insert or update responder claim
    await client.query(
      `insert into public.responder_claims (sos_id, responder_id, status, claimed_at, updated_at)
       values ($1, $2, $3, now(), now())
       on conflict (sos_id, responder_id) do update
       set status = excluded.status, updated_at = now()`,
      [sosId, responderId, status],
    );

    // 2. If status is EN_ROUTE or ARRIVED, update SOS status to CLAIMED
    if (status === 'EN_ROUTE' || status === 'ARRIVED') {
      await client.query(
        `update public.sos_events
         set status = 'CLAIMED', stage_changed_at = now()
         where id = $1 and status = 'ACTIVE'`,
        [sosId],
      );
    } else if (status === 'RELEASED') {
      // If all responders released, revert back to ACTIVE
      await client.query(
        `update public.sos_events
         set status = 'ACTIVE', stage_changed_at = now()
         where id = $1 and status = 'CLAIMED'
           and not exists (
             select 1 from public.responder_claims
             where sos_id = $1 and status in ('EN_ROUTE', 'ARRIVED')
           )`,
        [sosId],
      );
    }

    await client.query('COMMIT');

    // Optional audit trail
    await writeAudit({
      actorId: responderId,
      action: 'SOS_STATUS_CHANGED',
      targetType: 'SOS',
      targetId: sosId,
      metadata: { responder_name: body.responder_name ?? null, status },
    }).catch(() => undefined);

    return NextResponse.json({
      success: true,
      message: `Status relawan berhasil diperbarui: ${status}`,
    }, {
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } catch (error: any) {
    await client.query('ROLLBACK');
    console.error('Error claiming SOS as volunteer:', error);
    return NextResponse.json({ success: false, error: error.message }, {
      status: 500,
      headers: { 'Access-Control-Allow-Origin': '*' },
    });
  } finally {
    client.release();
  }
}
