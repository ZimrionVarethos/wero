import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { sendFcmBroadcast } from '@/lib/fcm';
import { writeAudit } from '@/lib/admin/audit';
import { errorResponse, HttpError, isUuid, regionScope, requireAdmin } from '@/lib/admin/session';

const SEVERITIES = new Set(['AWAS', 'SIAGA', 'WASPADA', 'INFO']);
const HAZARDS = new Set(['EARTHQUAKE', 'TSUNAMI', 'FLOOD', 'LANDSLIDE', 'VOLCANO', 'EXTREME_WEATHER', 'FIRE', 'OTHER']);

// History of manual broadcasts. Government admins only see broadcasts for their region.
export async function GET() {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const { rows } = await pool.query(
      `select d.id, d.disaster_type, d.severity, d.headline, d.source, d.region_id,
              d.source_payload->>'message' as message,
              d.source_payload->>'target_type' as target_type,
              d.source_payload->'target_regions' as target_regions,
              d.source_payload->'fcm' as fcm,
              coalesce(pr.display_name, d.source_payload->>'broadcasted_by', d.source) as sent_by,
              d.occurred_at, d.created_at
       from public.disaster_events d
       left join public.profiles pr on pr.id::text = d.source_payload->>'actor_id'
       where (d.source_event_id like 'MANUAL-%' or d.source_event_id like 'BMKG-%')
         and ($1::uuid is null or d.region_id = $1::uuid
              or d.source_payload->'target_region_ids' ? $1::text
              or d.source_payload->>'target_type' = 'ALL')
       order by coalesce(d.occurred_at, d.created_at) desc
       limit 60`,
      [scope],
    );
    return NextResponse.json({ success: true, data: rows });
  } catch (error) {
    return errorResponse(error, 'Gagal mengambil riwayat siaran');
  }
}

export async function POST(req: NextRequest) {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const body = (await req.json().catch(() => ({}))) as Record<string, unknown>;

    const severity = String(body.severity ?? '');
    const hazard = String(body.disaster_type ?? '');
    const headline = String(body.headline ?? '').trim();
    const message = String(body.message ?? '').trim();
    if (!SEVERITIES.has(severity)) throw new HttpError(400, 'Pilih tingkat status peringatan.');
    if (!HAZARDS.has(hazard)) throw new HttpError(400, 'Pilih jenis bencana.');
    if (headline.length < 5 || headline.length > 120) throw new HttpError(400, 'Judul wajib 5 sampai 120 karakter.');
    if (message.length > 500) throw new HttpError(400, 'Isi pesan maksimal 500 karakter.');

    // Government admins can only broadcast to their own region, whatever the client sends.
    let targetType: 'ALL' | 'SPECIFIC';
    let targetIds: string[];
    if (scope) {
      targetType = 'SPECIFIC';
      targetIds = [scope];
    } else if (body.target_type === 'ALL') {
      targetType = 'ALL';
      targetIds = [];
    } else {
      targetType = 'SPECIFIC';
      targetIds = Array.isArray(body.target_region_ids) ? body.target_region_ids.filter(isUuid) : [];
      if (targetIds.length === 0) throw new HttpError(400, 'Pilih minimal satu wilayah tujuan.');
    }

    const regions = targetIds.length
      ? (await pool.query<{ id: string; name: string }>('select id, name from public.regions where id = any($1::uuid[])', [targetIds])).rows
      : [];
    if (targetType === 'SPECIFIC' && regions.length !== targetIds.length) {
      throw new HttpError(400, 'Wilayah tujuan tidak ditemukan.');
    }

    const issuedAt = new Date().toISOString();
    const payload = {
      broadcasted_by: 'Dasbor Petugas',
      actor_id: session.userId,
      message: message || null,
      target_type: targetType,
      target_region_ids: regions.map((r) => r.id),
      target_regions: regions.map((r) => r.name),
      issued_at: issuedAt,
    };

    const { rows } = await pool.query(
      `insert into public.disaster_events
         (headline, disaster_type, severity, source, source_event_id, is_published,
          region_id, source_payload, occurred_at)
       values ($1, $2, $3, $4, $5, true, $6, $7, now())
       returning id`,
      [
        headline,
        hazard,
        severity,
        session.regionName ? `Petugas ${session.regionName}` : 'Petugas Wero',
        `MANUAL-${Date.now()}`,
        regions.length === 1 ? regions[0].id : null,
        JSON.stringify(payload),
      ],
    );
    const eventId: string = rows[0].id;

    const fcm = await sendFcmBroadcast({
      headline,
      severity,
      targetType,
      targetRegions: regions.map((r) => r.name),
      eventId,
    }).catch((err: unknown) => {
      console.error('[FCM] Error dispatching push:', err);
      return { success: false };
    });
    const delivered = Boolean((fcm as { success?: boolean }).success);

    await pool.query(
      `update public.disaster_events set source_payload = source_payload || $2::jsonb where id = $1`,
      [eventId, JSON.stringify({ fcm: { delivered } })],
    );
    await writeAudit({
      actorId: session.userId,
      action: 'ADMIN_BROADCAST',
      targetType: 'DISASTER_EVENT',
      targetId: eventId,
      metadata: { severity, hazard, headline, target_type: targetType, target_regions: regions.map((r) => r.name), push_delivered: delivered },
    });

    return NextResponse.json({ success: true, data: { id: eventId, delivered, targetType, targetRegions: regions.map((r) => r.name) } });
  } catch (error) {
    return errorResponse(error, 'Gagal mengirim siaran');
  }
}

export async function DELETE(req: NextRequest) {
  try {
    const session = await requireAdmin();
    const scope = regionScope(session);
    const url = new URL(req.url);
    const id = url.searchParams.get('id');
    const all = url.searchParams.get('all') === 'true';

    if (id) {
      if (!isUuid(id)) throw new HttpError(400, 'ID siaran tidak valid.');
      const res = await pool.query<{ id: string; headline: string }>(
        `delete from public.disaster_events
         where id = $1::uuid
           and (source_event_id like 'MANUAL-%' or source_event_id like 'BMKG-%')
           and ($2::uuid is null or region_id = $2::uuid or source_payload->'target_region_ids' ? $2::text or source_payload->>'target_type' = 'ALL')
         returning id, headline`,
        [id, scope],
      );
      if (res.rowCount === 0) {
        throw new HttpError(404, 'Siaran tidak ditemukan atau di luar wewenang Anda.');
      }
      await writeAudit({
        actorId: session.userId,
        action: 'BROADCAST_DELETED',
        targetType: 'DISASTER_EVENT',
        targetId: id,
        metadata: { headline: res.rows[0].headline },
      });
      return NextResponse.json({ success: true, message: 'Siaran berhasil dihapus.' });
    }

    if (all) {
      const res = await pool.query<{ id: string }>(
        `delete from public.disaster_events
         where (source_event_id like 'MANUAL-%' or source_event_id like 'BMKG-%')
           and ($1::uuid is null or region_id = $1::uuid or source_payload->'target_region_ids' ? $1::text or source_payload->>'target_type' = 'ALL')
         returning id`,
        [scope],
      );
      await writeAudit({
        actorId: session.userId,
        action: 'BROADCAST_DELETED',
        targetType: 'DISASTER_EVENT',
        metadata: { count: res.rowCount },
      });
      return NextResponse.json({
        success: true,
        message: `${res.rowCount ?? 0} siaran berhasil dihapus.`,
      });
    }

    throw new HttpError(400, 'Parameter id atau all=true wajib disertakan.');
  } catch (error) {
    return errorResponse(error, 'Gagal menghapus log siaran');
  }
}

