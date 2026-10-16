'use client';

import { useCallback, useEffect, useState } from 'react';
import { adminFetch, errorMessage } from './client';

interface State<T> {
  url: string;
  data: T | null;
  error: string | null;
  updatedAt: Date | null;
}

/**
 * Loads an admin API resource, optionally polling it. Changing `url` (for example a filter)
 * shows the loading state again instead of stale rows from the previous filter.
 */
export function useAdminData<T>(url: string, refreshMs?: number) {
  const [state, setState] = useState<State<T>>({ url, data: null, error: null, updatedAt: null });
  const [tick, setTick] = useState(0);
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const run = () =>
      adminFetch<T>(url).then(
        (data) => {
          if (cancelled) return;
          setState({ url, data, error: null, updatedAt: new Date() });
          setRefreshing(false);
        },
        (e: unknown) => {
          if (cancelled) return;
          setState((s) => ({ url, data: s.url === url ? s.data : null, error: errorMessage(e), updatedAt: s.updatedAt }));
          setRefreshing(false);
        },
      );
    void run();
    const timer = refreshMs ? setInterval(() => void run(), refreshMs) : undefined;
    return () => {
      cancelled = true;
      if (timer) clearInterval(timer);
    };
  }, [url, tick, refreshMs]);

  const reload = useCallback(() => {
    setRefreshing(true);
    setTick((n) => n + 1);
  }, []);

  /** Local update after a mutation, until the next fetch confirms it. */
  const mutate = useCallback((fn: (data: T) => T) => {
    setState((s) => (s.data === null ? s : { ...s, data: fn(s.data) }));
  }, []);

  const current = state.url === url;
  return {
    data: current ? state.data : null,
    error: current ? state.error : null,
    loading: !current || (state.data === null && state.error === null),
    updatedAt: state.updatedAt,
    refreshing,
    reload,
    mutate,
  };
}
