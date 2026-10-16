import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { sendFcmBroadcast } from '@/lib/fcm';
import { writeAudit } from '@/lib/admin/audit';
import { requireAdmin, errorResponse } from '@/lib/admin/session';

// Server-side in-memory cache for BMKG feeds
let cachedLatest: { data: any; timestamp: number } | null = null;
let cachedFelt: { data: any; timestamp: number } | null = null;

const CACHE_TTL_MS = 25000; // 25 seconds TTL

/**
 * Maps BMKG earthquake data to Wero 4-tier alert level:
 * - AWAS: M >= 7.0 or Tsunami potential (Ancaman sedang terjadi, segera bertindak)
 * - SIAGA: M >= 6.0 (Ancaman dekat, bersiap evakuasi)
 * - WASPADA: M >= 5.0 or felt quake (Potensi ancaman, pantau perkembangan)
 * - INFO: M < 5.0 (Informasi umum tanpa tindakan segera)
 */
export function resolveBmkgSeverity(
  magStr: string | number,
  potensi: string = '',
): 'AWAS' | 'SIAGA' | 'WASPADA' | 'INFO' {
  const mag = typeof magStr === 'number' ? magStr : parseFloat(magStr) || 0;
  const isTsunami = /tsunami/i.test(potensi);
  if (isTsunami || mag >= 7.0) return 'AWAS';
  if (mag >= 6.0) return 'SIAGA';
  if (mag >= 5.0) return 'WASPADA';
  return 'INFO';
}

/**
 * Ingests a BMKG earthquake into public.disaster_events and optionally sends push notification.
 */
export async function syncBmkgToDatabase(
  quake: {
    Tanggal?: string;
    Jam?: string;
    DateTime?: string;
    Coordinates?: string;
    Magnitude?: string;
    Kedalaman?: string;
    Wilayah?: string;
    Potensi?: string;
    Dirasakan?: string;
    Shakemap?: string;
  },
  overrideSeverity?: string,
  actorId?: string,
) {
  const mag = parseFloat(quake.Magnitude || '0') || null;
  const depth = parseFloat((quake.Kedalaman || '').replace(/[^0-9.]/g, '')) || null;
  const potensi = quake.Potensi || 'Gempa bumi tektonik';
  const severity = overrideSeverity || resolveBmkgSeverity(quake.Magnitude || 0, potensi);
  const headline = `Gempa M ${quake.Magnitude || '0'} - ${quake.Wilayah || 'Wilayah Indonesia'}`;
  const isTsunami = /tsunami/i.test(potensi);
  const disasterType = isTsunami ? 'TSUNAMI' : 'EARTHQUAKE';
  const sourceEventId = `BMKG-${quake.DateTime || `${quake.Tanggal}-${quake.Jam}`}`;

  const payload = {
    message: potensi,
    target_type: 'ALL',
    target_regions: ['Seluruh Wilayah Indonesia'],
    broadcasted_by: 'BMKG Indonesia (TEWS)',
    actor_id: actorId || null,
    coordinates: quake.Coordinates,
    shakemap: quake.Shakemap,
    dirasakan: quake.Dirasakan,
    bmkg_raw: quake,
  };

  const occurredAt = quake.DateTime ? new Date(quake.DateTime).toISOString() : new Date().toISOString();

  const { rows } = await pool.query<{ id: string }>(
    `insert into public.disaster_events
       (headline, disaster_type, severity, source, source_event_id, is_published,
        region_id, magnitude, depth_km, occurred_at, source_payload)
     values ($1, $2, $3, 'BMKG TEWS', $4, true, null, $5, $6, $7, $8)
     on conflict (source, source_event_id) do update
     set severity = excluded.severity,
         headline = excluded.headline,
         source_payload = public.disaster_events.source_payload || excluded.source_payload,
         updated_at = now()
     returning id`,
    [
      headline,
      disasterType,
      severity,
      sourceEventId,
      mag,
      depth,
      occurredAt,
      JSON.stringify(payload),
    ],
  );

  const eventId = rows[0]?.id;

  // Dispatch FCM push to mobile users
  const fcm = await sendFcmBroadcast({
    headline,
    severity,
    targetType: 'ALL',
    targetRegions: ['Seluruh Wilayah Indonesia'],
  }).catch((err) => {
    console.error('[FCM] Error dispatching BMKG broadcast:', err);
    return { success: false };
  });

  const delivered = Boolean((fcm as { success?: boolean })?.success);

  if (eventId) {
    await pool.query(
      `update public.disaster_events set source_payload = source_payload || $2::jsonb where id = $1`,
      [eventId, JSON.stringify({ fcm: { delivered } })],
    );
  }

  if (actorId && eventId) {
    await writeAudit({
      actorId,
      action: 'ADMIN_BROADCAST',
      targetType: 'DISASTER_EVENT',
      targetId: eventId,
      metadata: {
        source: 'BMKG TEWS',
        severity,
        headline,
        magnitude: quake.Magnitude ?? null,
        push_delivered: delivered,
      },
    });
  }

  return { id: eventId, delivered, severity, headline };
}

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const type = searchParams.get('type') || 'latest';
    const autoSync = searchParams.get('sync') === 'true';
    const now = Date.now();

    if (type === 'latest') {
      let json = cachedLatest && now - cachedLatest.timestamp < CACHE_TTL_MS ? cachedLatest.data : null;

      if (!json) {
        const res = await fetch('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json', {
          headers: { 'User-Agent': 'Wero-Operations-Server/1.0' },
          next: { revalidate: 25 },
        });

        if (!res.ok) throw new Error(`BMKG server error: ${res.status}`);
        json = await res.json();
        cachedLatest = { data: json, timestamp: now };
      }

      const quake = json?.Infogempa?.gempa;
      const severity = quake ? resolveBmkgSeverity(quake.Magnitude, quake.Potensi) : 'INFO';

      let syncResult = null;
      if (autoSync && quake) {
        try {
          syncResult = await syncBmkgToDatabase(quake);
        } catch (e) {
          console.warn('Auto-sync BMKG error:', e);
        }
      }

      return NextResponse.json({
        success: true,
        data: json,
        quake,
        severity,
        synced: Boolean(syncResult),
        event: syncResult,
      }, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=25',
        },
      });
    }

    if (type === 'felt') {
      let json = cachedFelt && now - cachedFelt.timestamp < CACHE_TTL_MS ? cachedFelt.data : null;

      if (!json) {
        const res = await fetch('https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json', {
          headers: { 'User-Agent': 'Wero-Operations-Server/1.0' },
          next: { revalidate: 35 },
        });

        if (!res.ok) throw new Error(`BMKG server error: ${res.status}`);
        json = await res.json();
        cachedFelt = { data: json, timestamp: now };
      }

      return NextResponse.json(json, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=25',
        },
      });
    }

    return NextResponse.json(
      { error: 'Tipe BMKG tidak valid. Gunakan type=latest atau type=felt' },
      { status: 400, headers: { 'Access-Control-Allow-Origin': '*' } },
    );
  } catch (err: any) {
    console.error('BMKG proxy error:', err);
    if (cachedLatest?.data) {
      const quake = cachedLatest.data?.Infogempa?.gempa;
      return NextResponse.json({
        success: true,
        data: cachedLatest.data,
        quake,
        severity: quake ? resolveBmkgSeverity(quake.Magnitude, quake.Potensi) : 'INFO',
        cached: true,
      }, {
        headers: { 'Access-Control-Allow-Origin': '*' },
      });
    }
    return NextResponse.json(
      { error: err.message || 'Gagal mengambil data BMKG' },
      { status: 502, headers: { 'Access-Control-Allow-Origin': '*' } },
    );
  }
}

export async function POST(req: NextRequest) {
  try {
    const session = await requireAdmin();
    const body = (await req.json().catch(() => ({}))) as Record<string, any>;

    // If quake data is provided in body, use it; otherwise fetch fresh from BMKG
    let quake = body.quake;
    if (!quake) {
      const res = await fetch('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json', {
        headers: { 'User-Agent': 'Wero-Operations-Server/1.0' },
      });
      if (!res.ok) throw new Error('Gagal mengambil data terkini dari server BMKG.');
      const json = await res.json();
      quake = json?.Infogempa?.gempa;
    }

    if (!quake) {
      return NextResponse.json(
        { success: false, error: 'Data gempa BMKG tidak ditemukan.' },
        { status: 400 },
      );
    }

    const result = await syncBmkgToDatabase(quake, body.severity, session.userId);
    return NextResponse.json({ success: true, data: result });
  } catch (error) {
    return errorResponse(error, 'Gagal menyiarkan sinyal BMKG');
  }
}
