'use client';

import React, { useEffect, useRef, useState, useCallback } from 'react';
import mapboxgl from 'mapbox-gl';
import {
  ShieldAlert,
  Building,
  RefreshCw,
  Layers,
  MapPin,
  CheckCircle,
  ExternalLink,
  Phone,
  Maximize2,
  Navigation,
  Eye,
  AlertTriangle,
} from 'lucide-react';

interface SosMarkerData {
  id: string;
  victim_id: string;
  victim_name: string | null;
  victim_phone?: string | null;
  mode: string;
  escalation: string;
  status: string;
  note: string | null;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
}

interface CheckinMarkerData {
  id: string;
  user_name: string | null;
  status: string;
  note: string | null;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
}

interface ShelterMarkerData {
  id: string;
  name: string;
  kind: string;
  capacity_total: number;
  capacity_current: number;
  status: string;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
}

export default function OperationsMap({
  initialFocusId,
  onResolveSos,
}: {
  initialFocusId?: string;
  onResolveSos?: (id: string) => Promise<void>;
}) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<mapboxgl.Map | null>(null);
  const markersRef = useRef<mapboxgl.Marker[]>([]);

  const [loading, setLoading] = useState(true);
  const [sosList, setSosList] = useState<SosMarkerData[]>([]);
  const [checkins, setCheckins] = useState<CheckinMarkerData[]>([]);
  const [shelters, setShelters] = useState<ShelterMarkerData[]>([]);

  // Toggles
  const [showSos, setShowSos] = useState(true);
  const [showCheckins, setShowCheckins] = useState(true);
  const [showShelters, setShowShelters] = useState(true);
  const [activeOnly, setActiveOnly] = useState(false);
  const [mapStyle, setMapStyle] = useState<'streets' | 'satellite' | 'dark'>('streets');
  const [enable3d, setEnable3d] = useState(true);
  const [selectedIncident, setSelectedIncident] = useState<SosMarkerData | null>(null);

  // Style URLs
  const styleUrls = {
    streets: 'mapbox://styles/mapbox/streets-v12',
    satellite: 'mapbox://styles/mapbox/satellite-streets-v12',
    dark: 'mapbox://styles/mapbox/dark-v11',
  };

  // Fetch telemetry
  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      const [sosRes, shelterRes] = await Promise.all([
        fetch('/api/sos'),
        fetch('/api/shelters'),
      ]);

      const sosJson = await sosRes.json();
      const shelterJson = await shelterRes.json();

      if (sosJson.success) {
        setSosList(sosJson.sosEvents || []);
        setCheckins(sosJson.urgentCheckins || []);
      }
      if (shelterJson.success) {
        setShelters(shelterJson.shelters || []);
      }
    } catch (e) {
      console.error('Error fetching map operations data:', e);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
    const interval = setInterval(loadData, 15000);
    return () => clearInterval(interval);
  }, [loadData]);

  // Initialize Mapbox
  useEffect(() => {
    if (!mapContainerRef.current) return;

    const token = process.env.NEXT_PUBLIC_MAPBOX_TOKEN || '';
    mapboxgl.accessToken = token;

    const map = new mapboxgl.Map({
      container: mapContainerRef.current,
      style: styleUrls[mapStyle],
      center: [110.3672, -7.7828], // Default to Yogyakarta / Central Java
      zoom: 11,
      pitch: 45,
      bearing: -10,
    });

    map.addControl(new mapboxgl.NavigationControl(), 'top-right');
    map.addControl(new mapboxgl.FullscreenControl(), 'top-right');

    map.on('style.load', () => {
      if (enable3d) {
        // Add 3D building layer
        const layers = map.getStyle().layers;
        const labelLayerId = layers?.find(
          (layer) => layer.type === 'symbol' && layer.layout?.['text-field']
        )?.id;

        if (!map.getLayer('3d-buildings')) {
          map.addLayer(
            {
              id: '3d-buildings',
              source: 'composite',
              'source-layer': 'building',
              filter: ['==', 'extrude', 'true'],
              type: 'fill-extrusion',
              minzoom: 14,
              paint: {
                'fill-extrusion-color': '#aaa',
                'fill-extrusion-height': ['get', 'height'],
                'fill-extrusion-base': ['get', 'min_height'],
                'fill-extrusion-opacity': 0.6,
              },
            },
            labelLayerId
          );
        }
      }
    });

    mapRef.current = map;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  // Handle map style changes
  useEffect(() => {
    if (mapRef.current) {
      mapRef.current.setStyle(styleUrls[mapStyle]);
    }
  }, [mapStyle]);

  // Update Markers
  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    // Clear old markers
    markersRef.current.forEach((m) => m.remove());
    markersRef.current = [];

    const bounds = new mapboxgl.LngLatBounds();
    let hasCoords = false;

    // 1. Render SOS Markers
    if (showSos) {
      sosList.forEach((sos) => {
        if (!sos.latitude || !sos.longitude) return;
        const isActive = sos.status !== 'RESOLVED' && sos.status !== 'CANCELLED';
        if (activeOnly && !isActive) return;

        hasCoords = true;
        bounds.extend([sos.longitude, sos.latitude]);

        const el = document.createElement('div');
        el.className = 'cursor-pointer group flex flex-col items-center';

        if (isActive) {
          el.innerHTML = `
            <div class="relative flex items-center justify-center">
              <span class="animate-ping absolute inline-flex h-8 w-8 rounded-full bg-rose-500 opacity-75"></span>
              <div class="relative z-10 w-8 h-8 rounded-full bg-rose-600 border-2 border-white shadow-lg flex items-center justify-center text-white text-xs font-black">
                🚨
              </div>
            </div>
            <div class="mt-1 px-2 py-0.5 bg-rose-700/90 text-white font-bold text-[10px] rounded-md shadow whitespace-nowrap">
              SOS: ${sos.victim_name || 'Warga'}
            </div>
          `;
        } else {
          el.innerHTML = `
            <div class="w-6 h-6 rounded-full bg-slate-400 border border-white shadow flex items-center justify-center text-white text-[10px]">
              ✓
            </div>
            <div class="mt-0.5 px-1.5 py-0.5 bg-slate-700/80 text-slate-100 text-[9px] rounded shadow whitespace-nowrap">
              ${sos.victim_name || 'Selesai'}
            </div>
          `;
        }

        const popupContent = `
          <div style="font-family: sans-serif; padding: 6px; max-width: 240px;">
            <div style="display: flex; align-items: center; gap: 6px; margin-bottom: 6px;">
              <span style="font-size: 11px; font-weight: 800; padding: 2px 6px; border-radius: 9999px; background: ${
                isActive ? '#e11d48' : '#64748b'
              }; color: white;">
                ${isActive ? '🚨 SOS AKTIF' : 'RESOLVED'}
              </span>
              <span style="font-size: 10px; color: #64748b;">${new Date(sos.created_at).toLocaleTimeString('id-ID')} WIB</span>
            </div>
            <div style="font-size: 14px; font-weight: 700; color: #0f172a; margin-bottom: 2px;">
              ${sos.victim_name || 'Warga Terdaftar'}
            </div>
            <div style="font-size: 11px; color: #475569; margin-bottom: 6px;">
              ${sos.note || 'Sinyal darurat dipicu dari aplikasi mobile warga.'}
            </div>
            <div style="font-size: 10px; color: #64748b; background: #f8fafc; padding: 4px; border-radius: 6px; margin-bottom: 8px;">
              <strong>GPS:</strong> ${sos.latitude.toFixed(5)}, ${sos.longitude.toFixed(5)}
            </div>
            <a href="https://www.google.com/maps/search/?api=1&query=${sos.latitude},${sos.longitude}" 
               target="_blank" 
               style="display: inline-block; font-size: 11px; font-weight: 600; color: #0284c7; text-decoration: none;">
              📍 Buka di Google Maps ↗
            </a>
          </div>
        `;

        const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(popupContent);

        el.addEventListener('click', () => {
          setSelectedIncident(sos);
        });

        const marker = new mapboxgl.Marker(el)
          .setLngLat([sos.longitude, sos.latitude])
          .setPopup(popup)
          .addTo(map);

        markersRef.current.push(marker);
      });
    }

    // 2. Render Check-in Markers
    if (showCheckins) {
      checkins.forEach((c) => {
        if (!c.latitude || !c.longitude) return;
        hasCoords = true;
        bounds.extend([c.longitude, c.latitude]);

        const el = document.createElement('div');
        el.className = 'cursor-pointer flex flex-col items-center';
        el.innerHTML = `
          <div class="w-6 h-6 rounded-full bg-amber-500 border-2 border-white shadow flex items-center justify-center text-white text-xs">
            🆘
          </div>
          <div class="mt-0.5 px-1.5 py-0.5 bg-amber-800/80 text-white text-[9px] rounded shadow whitespace-nowrap">
            ${c.user_name || 'Keluarga'}
          </div>
        `;

        const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(`
          <div style="font-family: sans-serif; padding: 6px; max-width: 220px;">
            <div style="font-size: 10px; font-weight: bold; color: #d97706; margin-bottom: 4px;">
              ⚠️ BUTUH BANTUAN KELUARGA
            </div>
            <div style="font-size: 13px; font-weight: 700; color: #0f172a;">${c.user_name || 'Anggota'}</div>
            <div style="font-size: 11px; color: #475569; margin-top: 4px;">${c.note || '-'}</div>
            <div style="font-size: 10px; color: #64748b; margin-top: 6px;">
              GPS: ${c.latitude.toFixed(5)}, ${c.longitude.toFixed(5)}
            </div>
          </div>
        `);

        const marker = new mapboxgl.Marker(el)
          .setLngLat([c.longitude, c.latitude])
          .setPopup(popup)
          .addTo(map);

        markersRef.current.push(marker);
      });
    }

    // 3. Render Shelter Markers
    if (showShelters) {
      shelters.forEach((s) => {
        if (!s.latitude || !s.longitude) return;
        hasCoords = true;
        bounds.extend([s.longitude, s.latitude]);

        const el = document.createElement('div');
        el.className = 'cursor-pointer flex flex-col items-center';
        el.innerHTML = `
          <div class="w-7 h-7 rounded-full bg-sky-600 border-2 border-white shadow flex items-center justify-center text-white text-xs font-bold">
            🏠
          </div>
          <div class="mt-0.5 px-1.5 py-0.5 bg-slate-900/80 text-white text-[9px] rounded shadow max-w-[100px] truncate">
            ${s.name}
          </div>
        `;

        const popup = new mapboxgl.Popup({ offset: 25 }).setHTML(`
          <div style="font-family: sans-serif; padding: 6px; max-width: 240px;">
            <div style="font-size: 10px; font-weight: bold; color: #0284c7; text-transform: uppercase;">
              ${s.kind} • ${s.status}
            </div>
            <div style="font-size: 13px; font-weight: 700; color: #0f172a; margin-top: 2px;">${s.name}</div>
            <div style="font-size: 11px; color: #475569; margin-top: 4px;">${s.address || '-'}</div>
            <div style="font-size: 10px; color: #64748b; margin-top: 6px;">
              Daya Tampung: ${s.capacity_current} / ${s.capacity_total} orang
            </div>
          </div>
        `);

        const marker = new mapboxgl.Marker(el)
          .setLngLat([s.longitude, s.latitude])
          .setPopup(popup)
          .addTo(map);

        markersRef.current.push(marker);
      });
    }

    // Fit bounds if incidents found
    if (hasCoords && !initialFocusId) {
      map.fitBounds(bounds, { padding: 80, maxZoom: 14, duration: 1000 });
    }
  }, [sosList, checkins, shelters, showSos, showCheckins, showShelters, activeOnly, initialFocusId]);

  // Focus action helper
  const focusOnCoordinates = (lat: number, lng: number) => {
    if (mapRef.current) {
      mapRef.current.flyTo({
        center: [lng, lat],
        zoom: 15,
        pitch: 55,
        duration: 1500,
      });
    }
  };

  const activeSosCount = sosList.filter((s) => s.status !== 'RESOLVED' && s.status !== 'CANCELLED').length;

  return (
    <div className="space-y-4">
      {/* Top Banner Control Strip */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <span className="flex h-3 w-3 relative">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-rose-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-3 w-3 bg-rose-500"></span>
            </span>
            <h2 className="text-lg font-bold text-slate-900">Peta Taktis Operasi & Titik Sinyal SOS</h2>
          </div>
          <p className="text-xs text-slate-500 mt-0.5">
            Visualisasi spasial koordinat GPS asli dari warga yang memicu panggilan darurat SOS & posko shelter evakuasi.
          </p>
        </div>

        {/* Filter and Layer Actions */}
        <div className="flex flex-wrap items-center gap-2">
          {/* Layer toggles */}
          <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl text-xs font-semibold text-slate-700">
            <button
              onClick={() => setShowSos(!showSos)}
              className={`px-2.5 py-1.5 rounded-lg transition flex items-center gap-1.5 ${
                showSos ? 'bg-rose-600 text-white shadow-2xs' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              🚨 SOS ({activeSosCount})
            </button>
            <button
              onClick={() => setShowCheckins(!showCheckins)}
              className={`px-2.5 py-1.5 rounded-lg transition flex items-center gap-1.5 ${
                showCheckins ? 'bg-amber-500 text-white shadow-2xs' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              🆘 Keluarga ({checkins.length})
            </button>
            <button
              onClick={() => setShowShelters(!showShelters)}
              className={`px-2.5 py-1.5 rounded-lg transition flex items-center gap-1.5 ${
                showShelters ? 'bg-sky-600 text-white shadow-2xs' : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              🏠 Shelter ({shelters.length})
            </button>
          </div>

          {/* Style Selector */}
          <select
            value={mapStyle}
            onChange={(e) => setMapStyle(e.target.value as any)}
            className="px-2.5 py-1.5 text-xs font-semibold rounded-xl border border-slate-200 bg-white text-slate-700 hover:bg-slate-50"
          >
            <option value="streets">Peta Jalan (Streets)</option>
            <option value="satellite">Satelit (Aerial)</option>
            <option value="dark">Mode Gelap (Dark Ops)</option>
          </select>

          {/* Refresh button */}
          <button
            onClick={loadData}
            disabled={loading}
            className="p-2 rounded-xl border border-slate-200 text-slate-600 hover:bg-slate-50 transition"
            title="Sinkronisasi Data"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      </div>

      {/* Main Map Box */}
      <div className="relative w-full h-[580px] rounded-2xl overflow-hidden border border-slate-200 shadow-md">
        <div ref={mapContainerRef} className="w-full h-full" />

        {/* Floating Quick Action Overlay */}
        <div className="absolute top-4 left-4 z-10 flex flex-col gap-2">
          {activeSosCount > 0 ? (
            <div className="bg-rose-600 text-white text-xs font-bold px-3 py-2 rounded-xl shadow-lg flex items-center gap-2 animate-pulse">
              <ShieldAlert className="w-4 h-4" />
              <span>{activeSosCount} Panggilan SOS Aktif di Lapangan</span>
            </div>
          ) : (
            <div className="bg-emerald-600/90 text-white text-xs font-semibold px-3 py-1.5 rounded-xl shadow-lg flex items-center gap-1.5 backdrop-blur-xs">
              <CheckCircle className="w-3.5 h-3.5" />
              <span>Semua zona aman / Tidak ada SOS aktif</span>
            </div>
          )}
        </div>

        {/* Selected Incident Drawer */}
        {selectedIncident && (
          <div className="absolute bottom-4 left-4 right-4 md:right-auto md:w-96 bg-white/95 backdrop-blur-md p-4 rounded-2xl border border-slate-200 shadow-2xl z-20">
            <div className="flex items-center justify-between pb-2 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping"></span>
                <span className="text-xs font-bold text-rose-600 uppercase">Insiden Terpilih</span>
              </div>
              <button
                onClick={() => setSelectedIncident(null)}
                className="text-xs text-slate-400 hover:text-slate-600 font-bold"
              >
                ✕
              </button>
            </div>

            <div className="mt-2.5 space-y-1.5">
              <div className="font-bold text-slate-900 text-base">{selectedIncident.victim_name || 'Warga'}</div>
              <div className="text-xs text-slate-600">{selectedIncident.note || 'Panggilan darurat SOS aktif.'}</div>
              {selectedIncident.latitude && selectedIncident.longitude && (
                <div className="text-[11px] font-mono text-slate-500 bg-slate-50 p-1.5 rounded-lg border border-slate-100">
                  Koordinat: {selectedIncident.latitude.toFixed(5)}, {selectedIncident.longitude.toFixed(5)}
                </div>
              )}
            </div>

            <div className="mt-3 flex items-center gap-2">
              {selectedIncident.latitude && selectedIncident.longitude && (
                <button
                  onClick={() => focusOnCoordinates(selectedIncident.latitude!, selectedIncident.longitude!)}
                  className="flex-1 py-1.5 px-3 bg-sky-50 text-sky-700 hover:bg-sky-100 rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 transition"
                >
                  <Navigation className="w-3.5 h-3.5" /> Arahkan Kamera
                </button>
              )}
              {selectedIncident.status !== 'RESOLVED' && onResolveSos && (
                <button
                  onClick={async () => {
                    await onResolveSos(selectedIncident.id);
                    setSelectedIncident(null);
                    loadData();
                  }}
                  className="py-1.5 px-3 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 transition shadow-xs"
                >
                  <CheckCircle className="w-3.5 h-3.5" /> Selesaikan
                </button>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Incident Quick Roster List under the Map */}
      <div className="bg-white rounded-2xl border border-slate-200 p-4 shadow-xs">
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center gap-1.5">
            <MapPin className="w-3.5 h-3.5 text-sky-600" /> Daftar Koordinat Sinyal SOS Terkini
          </h3>
          <span className="text-xs text-slate-400">Klik item untuk meluncur ke titik peta</span>
        </div>

        {sosList.length === 0 ? (
          <div className="text-xs text-slate-400 text-center py-4">Belum ada riwayat SOS pada sistem.</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2.5">
            {sosList.slice(0, 6).map((item) => {
              const isActive = item.status !== 'RESOLVED' && item.status !== 'CANCELLED';
              return (
                <div
                  key={item.id}
                  onClick={() => {
                    if (item.latitude && item.longitude) {
                      focusOnCoordinates(item.latitude, item.longitude);
                      setSelectedIncident(item);
                    }
                  }}
                  className={`p-3 rounded-xl border text-left cursor-pointer transition flex items-start justify-between gap-2 ${
                    isActive
                      ? 'border-rose-200 bg-rose-50/50 hover:bg-rose-100/50'
                      : 'border-slate-100 bg-slate-50/50 hover:bg-slate-100/50'
                  }`}
                >
                  <div className="space-y-0.5">
                    <div className="flex items-center gap-1.5">
                      <span
                        className={`w-2 h-2 rounded-full ${isActive ? 'bg-rose-500 animate-ping' : 'bg-slate-400'}`}
                      />
                      <span className="text-xs font-bold text-slate-900">{item.victim_name || 'Warga'}</span>
                    </div>
                    <div className="text-[11px] text-slate-500 line-clamp-1">{item.note || 'Sinyal SOS darurat'}</div>
                    <div className="text-[10px] text-slate-400 font-mono">
                      {item.latitude ? `${item.latitude.toFixed(4)}, ${item.longitude?.toFixed(4)}` : 'Lokasi nihil'}
                    </div>
                  </div>
                  <span
                    className={`text-[9px] px-1.5 py-0.5 rounded font-bold uppercase ${
                      isActive ? 'bg-rose-600 text-white' : 'bg-slate-200 text-slate-600'
                    }`}
                  >
                    {item.status}
                  </span>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
