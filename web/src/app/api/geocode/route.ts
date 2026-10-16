import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';
import { createClient } from '@/lib/supabase/client';

const REGION_COORDINATES: Record<string, { lat: number; lng: number }> = {
  'Kota Bogor': { lat: -6.5971, lng: 106.8060 },
  'Kabupaten Bogor': { lat: -6.4800, lng: 106.8500 },
  'Kota Depok': { lat: -6.4025, lng: 106.7942 },
  'Kota Bekasi': { lat: -6.2383, lng: 106.9756 },
  'Kabupaten Bekasi': { lat: -6.2650, lng: 107.1350 },
  'Kota Tangerang': { lat: -6.1783, lng: 106.6319 },
  'Kota Tangerang Selatan': { lat: -6.2889, lng: 106.7179 },
  'Kabupaten Tangerang': { lat: -6.2200, lng: 106.4500 },
  'Kota Bandung': { lat: -6.9175, lng: 107.6191 },
  'Kota Jakarta Pusat': { lat: -6.1805, lng: 106.8284 },
  'Kota Jakarta Selatan': { lat: -6.2615, lng: 106.8106 },
  'Kota Jakarta Timur': { lat: -6.2250, lng: 106.9004 },
  'Kota Jakarta Barat': { lat: -6.1683, lng: 106.7589 },
  'Kota Jakarta Utara': { lat: -6.1384, lng: 106.8640 },
  'Kota Semarang': { lat: -7.0051, lng: 110.4381 },
  'Kota Surakarta': { lat: -7.5666, lng: 110.8166 },
  'Kota Yogyakarta': { lat: -7.7956, lng: 110.3695 },
  'Kabupaten Sleman': { lat: -7.7156, lng: 110.3556 },
  'Kabupaten Bantul': { lat: -7.8900, lng: 110.3300 },
  'Kabupaten Kulon Progo': { lat: -7.7700, lng: 110.1500 },
  'Kabupaten Gunungkidul': { lat: -7.9600, lng: 110.6000 },
  'Kota Surabaya': { lat: -7.2575, lng: 112.7521 },
  'Kota Malang': { lat: -7.9666, lng: 112.6326 },
  'Kota Denpasar': { lat: -8.6705, lng: 115.2126 },
  'Kabupaten Badung': { lat: -8.5833, lng: 115.1833 },
  'Kota Medan': { lat: 3.5952, lng: 98.6722 },
  'Kota Palembang': { lat: -2.9761, lng: 104.7754 },
  'Kota Padang': { lat: -0.9471, lng: 100.4172 },
  'Kota Makassar': { lat: -5.1477, lng: 119.4327 },
  'Kota Manado': { lat: 1.4748, lng: 124.8421 },
  'Kota Balikpapan': { lat: -1.2379, lng: 116.8289 },
};

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const latStr = searchParams.get('lat');
    const lngStr = searchParams.get('lng');

    if (!latStr || !lngStr) {
      return NextResponse.json(
        { success: false, error: 'Parameter lat dan lng wajib diisi' },
        { status: 400, headers: { 'Access-Control-Allow-Origin': '*' } }
      );
    }

    const lat = parseFloat(latStr);
    const lng = parseFloat(lngStr);

    if (isNaN(lat) || isNaN(lng)) {
      return NextResponse.json(
        { success: false, error: 'Format koordinat lat/lng tidak valid' },
        { status: 400, headers: { 'Access-Control-Allow-Origin': '*' } }
      );
    }

    const mapboxToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || process.env.MAPBOX_TOKEN || '';

    let detectedPlaceName = '';
    let detectedCity = '';

    // 1. Try Mapbox Reverse Geocoding if token is present
    if (mapboxToken) {
      const geocodeUrl = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?types=place,district,locality,region&language=id&access_token=${mapboxToken}`;
      try {
        const geoRes = await fetch(geocodeUrl, { next: { revalidate: 60 } });
        if (geoRes.ok) {
          const geoJson = await geoRes.json();
          const features = geoJson.features || [];
          if (features.length > 0) {
            detectedPlaceName = features[0].place_name || '';
            const placeFeature = features.find(
              (f: any) => f.place_type.includes('place') || f.place_type.includes('district')
            );
            detectedCity = placeFeature?.text || features[0].text || '';
          }
        }
      } catch (e) {
        console.warn('Mapbox reverse geocode fallback:', e);
      }
    }

    // 2. Fallback to OpenStreetMap Nominatim if Mapbox didn't detect city
    if (!detectedCity) {
      try {
        const osmUrl = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=10&addressdetails=1`;
        const osmRes = await fetch(osmUrl, {
          headers: { 'User-Agent': 'WeroEmergencyOps/1.0' },
          next: { revalidate: 60 },
        });
        if (osmRes.ok) {
          const osmJson = await osmRes.json();
          const addr = osmJson.address || {};
          detectedCity =
            addr.city ||
            addr.county ||
            addr.municipality ||
            addr.town ||
            addr.suburb ||
            addr.state_district ||
            '';
          detectedPlaceName = osmJson.display_name || '';
        }
      } catch (e) {
        console.warn('OSM Nominatim reverse geocode fallback:', e);
      }
    }

    // 3. Load available regions (from Postgres pool or Supabase REST)
    let allRegions: any[] = [];
    try {
      const regionsRes = await pool.query(
        `SELECT id, name, code, level FROM public.regions WHERE is_active = true ORDER BY name`
      );
      allRegions = regionsRes.rows;
    } catch (_) {
      try {
        const supabase = createClient();
        const { data } = await supabase
          .from('regions')
          .select('id, name, code, level')
          .eq('is_active', true);
        if (data && data.length > 0) {
          allRegions = data;
        }
      } catch (err) {
        console.warn('Failed to load regions via Supabase REST:', err);
      }
    }

    // 4. Match detected city to closest region
    let matchedRegion = null;
    if (detectedCity && allRegions.length > 0) {
      const cleanCity = detectedCity.toLowerCase().replace(/^(kota|kabupaten|kab\.?)\s+/i, '').trim();
      const candidates = allRegions.filter((r) => {
        const cleanRegion = r.name.toLowerCase().replace(/^(kota|kabupaten|kab\.?)\s+/i, '').trim();
        return (
          cleanRegion === cleanCity ||
          cleanRegion.includes(cleanCity) ||
          cleanCity.includes(cleanRegion) ||
          detectedPlaceName.toLowerCase().includes(cleanRegion)
        );
      });

      if (candidates.length === 1) {
        matchedRegion = candidates[0];
      } else if (candidates.length > 1) {
        // Pick the candidate closest to user's coordinate
        let minD = Infinity;
        for (const cand of candidates) {
          const coords = REGION_COORDINATES[cand.name];
          const d = coords ? Math.pow(lat - coords.lat, 2) + Math.pow(lng - coords.lng, 2) : 999;
          if (d < minD) {
            minD = d;
            matchedRegion = cand;
          }
        }
      }
    }

    // 5. Intelligent coordinate proximity fallback (closest distance)
    if (!matchedRegion && allRegions.length > 0) {
      let minDistance = Infinity;
      let closestRegionName = '';

      for (const [name, coords] of Object.entries(REGION_COORDINATES)) {
        const d = Math.pow(lat - coords.lat, 2) + Math.pow(lng - coords.lng, 2);
        if (d < minDistance) {
          minDistance = d;
          closestRegionName = name;
        }
      }

      if (closestRegionName) {
        matchedRegion = allRegions.find((r) => r.name === closestRegionName);
      }
      if (!matchedRegion) {
        matchedRegion = allRegions[0];
      }
    }

    return NextResponse.json(
      {
        success: true,
        detectedCity: detectedCity || matchedRegion?.name || 'Wilayah Terdeteksi',
        fullAddress: detectedPlaceName || `${lat.toFixed(4)}, ${lng.toFixed(4)}`,
        regionId: matchedRegion?.id || null,
        regionName: matchedRegion?.name || null,
        coordinates: { lat, lng },
      },
      {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Cache-Control': 'public, s-maxage=300, stale-while-revalidate=600',
        },
      }
    );
  } catch (error: any) {
    console.error('Reverse geocode error:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Gagal memproses geocoding lokasi' },
      { status: 500, headers: { 'Access-Control-Allow-Origin': '*' } }
    );
  }
}

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    },
  });
}
