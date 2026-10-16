'use client';

import dynamic from 'next/dynamic';

export type { MapPoint } from './MapView';

// MapLibre touches window on import, so the map only renders in the browser.
export const AdminMap = dynamic(() => import('./MapView'), {
  ssr: false,
  loading: () => (
    <div className="grid h-full w-full place-items-center bg-cream text-sm text-muted" role="status">
      Memuat peta
    </div>
  ),
});

/** Default view when a region has no data yet, centred on Indonesia. */
export const INDONESIA_CENTER: [number, number] = [117.5, -2.5];
