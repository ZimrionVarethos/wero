import { NextRequest, NextResponse } from 'next/server';
import { pool } from '@/lib/db';

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

    const mapboxToken = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || '';

    // 1. Query Mapbox Reverse Geocoding
    const geocodeUrl = `https://api.mapbox.com/geocoding/v5/mapbox.places/${lng},${lat}.json?types=place,district,locality,region&language=id&access_token=${mapboxToken}`;

    let detectedPlaceName = '';
    let detectedCity = '';

    try {
      const geoRes = await fetch(geocodeUrl, { next: { revalidate: 60 } });
      if (geoRes.ok) {
        const geoJson = await geoRes.json();
        const features = geoJson.features || [];
        if (features.length > 0) {
          detectedPlaceName = features[0].place_name || '';
          // Extract city or district
          const placeFeature = features.find(
            (f: any) => f.place_type.includes('place') || f.place_type.includes('district')
          );
          detectedCity = placeFeature?.text || features[0].text || '';
        }
      }
    } catch (e) {
      console.warn('Mapbox reverse geocode fallback:', e);
    }

    // 2. Query available regions from Supabase database
    const regionsRes = await pool.query(
      `SELECT id, name, code, level FROM public.regions WHERE is_active = true ORDER BY name`
    );
    const allRegions = regionsRes.rows;

    // 3. Match detected city to closest region in database
    let matchedRegion = null;

    if (detectedCity) {
      const cleanCity = detectedCity.toLowerCase().replace(/^(kota|kabupaten|kab\.?)\s+/i, '');
      matchedRegion = allRegions.find((r) => {
        const cleanRegion = r.name.toLowerCase().replace(/^(kota|kabupaten|kab\.?)\s+/i, '');
        return (
          cleanRegion.includes(cleanCity) ||
          cleanCity.includes(cleanRegion) ||
          detectedPlaceName.toLowerCase().includes(cleanRegion)
        );
      });
    }

    // Fallback: Default to nearest prominent center if direct text match fails
    if (!matchedRegion && allRegions.length > 0) {
      // Check for Jogja / Sleman / DIY proximity (~ -7.7, 110.3)
      if (lat >= -8.2 && lat <= -7.5 && lng >= 110.0 && lng <= 110.7) {
        matchedRegion =
          allRegions.find((r) => r.name.includes('Yogyakarta')) ||
          allRegions.find((r) => r.name.includes('Sleman')) ||
          allRegions[0];
      } else {
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
