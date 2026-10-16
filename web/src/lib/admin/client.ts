'use client';

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

/**
 * JSON fetch for the admin API. Expired sessions bounce to the login page so a
 * stale tab never shows partial data.
 */
export async function adminFetch<T>(url: string, init?: RequestInit): Promise<T> {
  let res: Response;
  try {
    res = await fetch(url, {
      ...init,
      headers: { 'Content-Type': 'application/json', ...init?.headers },
      cache: 'no-store',
    });
  } catch {
    throw new ApiError(0, 'Tidak dapat terhubung ke server. Periksa koneksi internet.');
  }

  const json = (await res.json().catch(() => null)) as { success?: boolean; error?: string; data?: T } | null;
  if (res.status === 401 && typeof window !== 'undefined') {
    window.location.replace('/admin/login?sesi=berakhir');
  }
  if (!res.ok || !json?.success) {
    throw new ApiError(res.status, json?.error ?? 'Terjadi kesalahan. Coba lagi.');
  }
  return (json.data ?? json) as T;
}

export function errorMessage(error: unknown, fallback = 'Terjadi kesalahan. Coba lagi.') {
  return error instanceof Error ? error.message : fallback;
}
