import { NextRequest, NextResponse } from 'next/server';

// Server-side in-memory cache for BMKG feeds
let cachedLatest: { data: any; timestamp: number } | null = null;
let cachedFelt: { data: any; timestamp: number } | null = null;

const CACHE_TTL_MS = 25000; // 25 seconds TTL

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const type = searchParams.get('type') || 'latest';
    const now = Date.now();

    if (type === 'latest') {
      if (cachedLatest && now - cachedLatest.timestamp < CACHE_TTL_MS) {
        return NextResponse.json(cachedLatest.data, {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'public, max-age=25',
          },
        });
      }

      const res = await fetch('https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json', {
        headers: { 'User-Agent': 'Siagaku-Wero-Operations-Server/1.0' },
        next: { revalidate: 25 },
      });

      if (!res.ok) throw new Error(`BMKG server error: ${res.status}`);
      const json = await res.json();
      cachedLatest = { data: json, timestamp: now };

      return NextResponse.json(json, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=25',
        },
      });
    }

    if (type === 'felt') {
      if (cachedFelt && now - cachedFelt.timestamp < CACHE_TTL_MS) {
        return NextResponse.json(cachedFelt.data, {
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'public, max-age=25',
          },
        });
      }

      const res = await fetch('https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json', {
        headers: { 'User-Agent': 'Siagaku-Wero-Operations-Server/1.0' },
        next: { revalidate: 35 },
      });

      if (!res.ok) throw new Error(`BMKG server error: ${res.status}`);
      const json = await res.json();
      cachedFelt = { data: json, timestamp: now };

      return NextResponse.json(json, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, max-age=25',
        },
      });
    }

    return NextResponse.json(
      { error: 'Tipe BMKG tidak valid. Gunakan type=latest atau type=felt' },
      { status: 400, headers: { 'Access-Control-Allow-Origin': '*' } }
    );
  } catch (err: any) {
    console.error('BMKG proxy error:', err);
    // If upstream BMKG is momentarily unreachable, return stale cache if available
    if (cachedLatest?.data) {
      return NextResponse.json(cachedLatest.data, {
        headers: { 'Access-Control-Allow-Origin': '*' },
      });
    }
    return NextResponse.json(
      { error: err.message || 'Gagal mengambil data BMKG' },
      { status: 502, headers: { 'Access-Control-Allow-Origin': '*' } }
    );
  }
}
