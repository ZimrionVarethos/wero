import { NextRequest, NextResponse } from 'next/server';
import { syncBmkgToDatabase, resolveBmkgSeverity } from '../route';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

/**
 * Autonomous Cron Worker for BMKG Real-time Disaster Alert Synchronization
 *
 * This endpoint is called automatically by Vercel Cron (or external cron runners)
 * every 2-5 minutes in the cloud, 24/7, without requiring an admin browser session.
 *
 * When a new significant earthquake or tsunami warning occurs:
 * 1. BMKG TEWS API is fetched.
 * 2. Event is ingested into public.disaster_events.
 * 3. High-priority FCM push notification with emergency vibration is broadcasted
 *    to all citizens' mobile devices immediately.
 */
export async function GET(req: NextRequest) {
  try {
    const authHeader = req.headers.get('authorization');
    const cronSecret = process.env.CRON_SECRET;

    // Optional verification if CRON_SECRET is set in Vercel environment
    if (cronSecret && authHeader !== `Bearer ${cronSecret}`) {
      const urlSecret = req.nextUrl.searchParams.get('key');
      if (urlSecret !== cronSecret) {
        return NextResponse.json({ error: 'Unauthorized cron request' }, { status: 401 });
      }
    }

    const res = await fetch('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json', {
      headers: {
        'User-Agent': 'Wero-Autonomous-Cron-Worker/1.0',
        'Cache-Control': 'no-cache',
      },
      cache: 'no-store',
    });

    if (!res.ok) {
      throw new Error(`BMKG returned HTTP ${res.status}`);
    }

    const json = await res.json();
    const quake = json?.Infogempa?.gempa;

    if (!quake) {
      return NextResponse.json({
        success: false,
        message: 'No earthquake payload found in BMKG response',
        timestamp: new Date().toISOString(),
      });
    }

    const severity = resolveBmkgSeverity(quake.Magnitude, quake.Potensi);
    const syncResult = await syncBmkgToDatabase(quake);

    if (syncResult.alreadyPushed) {
      return NextResponse.json({
        success: true,
        mode: 'autonomous_cron',
        action: 'skipped_duplicate',
        message: 'Data gempa BMKG sama dengan data terakhir di database. Push notifikasi dilewati (tidak ada spam/loop).',
        sourceEventId: syncResult.sourceEventId,
        severity,
        timestamp: new Date().toISOString(),
      });
    }

    return NextResponse.json({
      success: true,
      mode: 'autonomous_cron',
      action: 'broadcasted_new_event',
      timestamp: new Date().toISOString(),
      quake: {
        tanggal: quake.Tanggal,
        jam: quake.Jam,
        magnitude: quake.Magnitude,
        wilayah: quake.Wilayah,
        potensi: quake.Potensi,
        severity,
      },
      syncedEventId: syncResult.id,
      pushDelivered: syncResult.delivered,
    });
  } catch (error: any) {
    console.error('[BMKG Cron] Autonomous sync error:', error);
    return NextResponse.json(
      {
        success: false,
        error: error?.message || 'Failed to sync BMKG cron',
        timestamp: new Date().toISOString(),
      },
      { status: 500 },
    );
  }
}
