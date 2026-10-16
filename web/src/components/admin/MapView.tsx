'use client';

import * as maplibregl from 'maplibre-gl';
import type { GeoJSONSource, Map as MLMap, MapMouseEvent } from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { useEffect, useRef } from 'react';

// Raster OSM base without API keys. For production traffic, point this at self-hosted or paid tiles.
const STYLE: maplibregl.StyleSpecification = {
  version: 8,
  sources: {
    osm: {
      type: 'raster',
      tiles: ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
      tileSize: 256,
      maxzoom: 19,
      attribution: '&copy; OpenStreetMap contributors',
    },
  },
  layers: [
    { id: 'osm', type: 'raster', source: 'osm', paint: { 'raster-saturation': -0.35, 'raster-contrast': 0.05 } },
  ],
};

export interface MapPoint {
  id: string;
  lng: number;
  lat: number;
  color: string;
  /** Draws a translucent area around the point to show the location is approximate. */
  approximate?: boolean;
  muted?: boolean;
}

const EMPTY: GeoJSON.FeatureCollection = { type: 'FeatureCollection', features: [] };

function toCollection(points: MapPoint[], selectedId: string | null): GeoJSON.FeatureCollection {
  return {
    type: 'FeatureCollection',
    features: points
      .filter((p) => Number.isFinite(p.lng) && Number.isFinite(p.lat))
      .map((p) => ({
        type: 'Feature',
        geometry: { type: 'Point', coordinates: [p.lng, p.lat] },
        properties: { id: p.id, color: p.color, approximate: Boolean(p.approximate), muted: Boolean(p.muted), selected: p.id === selectedId },
      })),
  };
}

export default function MapView({
  center,
  zoom = 11,
  points,
  selectedId = null,
  onSelect,
  pick,
  onPick,
  label,
  className = '',
}: {
  center: [number, number];
  zoom?: number;
  points: MapPoint[];
  selectedId?: string | null;
  onSelect?: (id: string) => void;
  /** Marker for a location being picked in a form. */
  pick?: { lng: number; lat: number } | null;
  onPick?: (lngLat: { lng: number; lat: number }) => void;
  label: string;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const mapRef = useRef<MLMap | null>(null);
  const readyRef = useRef(false);
  const fittedRef = useRef(false);
  const latest = useRef({ points, selectedId, pick, onSelect, onPick });

  const sync = () => {
    const map = mapRef.current;
    if (!map || !readyRef.current) return;
    const { points: pts, selectedId: sel, pick: pk } = latest.current;
    (map.getSource('points') as GeoJSONSource | undefined)?.setData(toCollection(pts, sel));
    (map.getSource('pick') as GeoJSONSource | undefined)?.setData(
      pk ? { type: 'FeatureCollection', features: [{ type: 'Feature', geometry: { type: 'Point', coordinates: [pk.lng, pk.lat] }, properties: {} }] } : EMPTY,
    );
    // Frame the data the first time it arrives, then leave the view to the operator.
    if (!fittedRef.current && pts.length > 0) {
      fittedRef.current = true;
      const bounds = new maplibregl.LngLatBounds();
      pts.forEach((p) => bounds.extend([p.lng, p.lat]));
      map.fitBounds(bounds, { padding: 64, maxZoom: 14, duration: 0 });
    }
  };

  useEffect(() => {
    if (!ref.current) return;
    const map = new maplibregl.Map({ container: ref.current, style: STYLE, center, zoom, attributionControl: { compact: true } });
    map.addControl(new maplibregl.NavigationControl({ showCompass: false }), 'top-right');
    mapRef.current = map;

    map.on('load', () => {
      map.addSource('points', { type: 'geojson', data: EMPTY });
      map.addSource('pick', { type: 'geojson', data: EMPTY });
      // Approximate area, roughly a few hundred metres across at city zoom levels.
      map.addLayer({
        id: 'points-area',
        type: 'circle',
        source: 'points',
        filter: ['==', ['get', 'approximate'], true],
        paint: {
          'circle-color': ['get', 'color'],
          'circle-opacity': 0.16,
          'circle-stroke-color': ['get', 'color'],
          'circle-stroke-opacity': 0.45,
          'circle-stroke-width': 1,
          'circle-radius': ['interpolate', ['exponential', 2], ['zoom'], 10, 6, 14, 40, 17, 300],
        },
      });
      map.addLayer({
        id: 'points-dot',
        type: 'circle',
        source: 'points',
        paint: {
          'circle-color': ['get', 'color'],
          'circle-opacity': ['case', ['get', 'muted'], 0.45, 1],
          'circle-radius': ['case', ['get', 'selected'], 10, 7],
          'circle-stroke-color': ['case', ['get', 'selected'], '#12263F', '#FFFFFF'],
          'circle-stroke-width': ['case', ['get', 'selected'], 3, 2],
        },
      });
      map.addLayer({
        id: 'pick',
        type: 'circle',
        source: 'pick',
        paint: { 'circle-radius': 9, 'circle-color': '#FFFFFF', 'circle-stroke-color': '#E8590C', 'circle-stroke-width': 4 },
      });
      readyRef.current = true;
      sync();
    });

    map.on('mouseenter', 'points-dot', () => (map.getCanvas().style.cursor = 'pointer'));
    map.on('mouseleave', 'points-dot', () => (map.getCanvas().style.cursor = latest.current.onPick ? 'crosshair' : ''));
    map.on('click', (e: MapMouseEvent) => {
      const hit = readyRef.current ? map.queryRenderedFeatures(e.point, { layers: ['points-dot'] })[0] : undefined;
      if (hit && latest.current.onSelect) {
        latest.current.onSelect(String(hit.properties?.id));
        return;
      }
      latest.current.onPick?.({ lng: e.lngLat.lng, lat: e.lngLat.lat });
    });

    const ro = new ResizeObserver(() => map.resize());
    ro.observe(ref.current);
    return () => {
      ro.disconnect();
      map.remove();
      mapRef.current = null;
      readyRef.current = false;
    };
    // The map is created once. Data flows through the effect below.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Map event handlers read the newest props through this ref.
  useEffect(() => {
    latest.current = { points, selectedId, pick, onSelect, onPick };
  });

  useEffect(sync, [points, selectedId, pick]);

  useEffect(() => {
    if (mapRef.current) mapRef.current.getCanvas().style.cursor = onPick ? 'crosshair' : '';
  }, [onPick]);

  return <div ref={ref} role="region" aria-label={label} className={`h-full w-full overflow-hidden ${className}`} />;
}
