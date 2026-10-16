'use client';

import Image from 'next/image';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import {
  ClipboardList,
  LayoutDashboard,
  LoaderCircle,
  LogOut,
  MapPinned,
  Megaphone,
  Menu,
  ShieldAlert,
  ShieldX,
  Siren,
  X,
  type LucideIcon,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { adminFetch, ApiError } from '@/lib/admin/client';
import type { AdminMe, AdminRole } from '@/lib/admin/types';
import { Alert, Button } from './ui';

const AdminContext = createContext<AdminMe | null>(null);

export function useAdmin(): AdminMe {
  const me = useContext(AdminContext);
  if (!me) throw new Error('useAdmin must be used inside AdminShell');
  return me;
}

const PANEL: AdminRole[] = ['SUPER_ADMIN', 'GOVERNMENT_ADMIN'];
const MODERATION: AdminRole[] = ['SUPER_ADMIN', 'GOVERNMENT_ADMIN', 'COMMUNITY_MODERATOR'];

const NAV: { href: string; label: string; icon: LucideIcon; roles: AdminRole[] }[] = [
  { href: '/admin', label: 'Ringkasan', icon: LayoutDashboard, roles: PANEL },
  { href: '/admin/sos', label: 'Pemantauan SOS', icon: Siren, roles: PANEL },
  { href: '/admin/evakuasi', label: 'Titik evakuasi', icon: MapPinned, roles: PANEL },
  { href: '/admin/siaran', label: 'Siaran peringatan', icon: Megaphone, roles: PANEL },
  { href: '/admin/moderasi', label: 'Moderasi komunitas', icon: ShieldAlert, roles: MODERATION },
  { href: '/admin/audit', label: 'Log audit', icon: ClipboardList, roles: PANEL },
];

const ROLE_LABEL: Record<AdminRole, string> = {
  SUPER_ADMIN: 'Super admin',
  GOVERNMENT_ADMIN: 'Admin wilayah',
  COMMUNITY_MODERATOR: 'Moderator komunitas',
};

function primaryRole(roles: AdminRole[]): AdminRole {
  return (['SUPER_ADMIN', 'GOVERNMENT_ADMIN', 'COMMUNITY_MODERATOR'] as const).find((r) => roles.includes(r)) ?? 'COMMUNITY_MODERATOR';
}

function Wordmark() {
  return (
    <Link href="/admin" className="flex items-center gap-3 rounded-lg focus-visible:outline-2 focus-visible:outline-white">
      <span className="grid size-9 place-items-center rounded-lg bg-white p-1">
        <Image src="/logo.png" alt="" width={28} height={28} className="h-auto w-full" />
      </span>
      <span className="leading-tight">
        <span className="block text-base font-extrabold tracking-tight text-white">Wero</span>
        <span className="block text-xs font-medium text-white/60">Dasbor petugas</span>
      </span>
    </Link>
  );
}

function FullScreen({ children }: { children: ReactNode }) {
  return <div className="grid min-h-screen place-items-center bg-cream p-6">{children}</div>;
}

export function AdminShell({ children }: { children: ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [me, setMe] = useState<AdminMe | null>(null);
  const [state, setState] = useState<'loading' | 'ready' | 'forbidden' | 'error'>('loading');
  const [message, setMessage] = useState('');
  const [drawer, setDrawer] = useState(false);
  const [signingOut, setSigningOut] = useState(false);

  const [attempt, setAttempt] = useState(0);

  useEffect(() => {
    let cancelled = false;
    adminFetch<AdminMe>('/api/admin/me')
      .then((data) => {
        if (cancelled) return;
        setMe(data);
        setState('ready');
      })
      .catch((e: unknown) => {
        if (cancelled || (e instanceof ApiError && e.status === 401)) return; // adminFetch already redirects
        setMessage(e instanceof Error ? e.message : '');
        setState(e instanceof ApiError && e.status === 403 ? 'forbidden' : 'error');
      });
    return () => {
      cancelled = true;
    };
  }, [attempt]);

  const retry = () => {
    setState('loading');
    setAttempt((n) => n + 1);
  };

  const nav = useMemo(() => (me ? NAV.filter((n) => n.roles.some((r) => me.roles.includes(r))) : []), [me]);
  const allowedHere = useMemo(() => {
    if (!me) return false;
    const item = [...NAV].sort((a, b) => b.href.length - a.href.length).find((n) => pathname === n.href || pathname.startsWith(`${n.href}/`));
    return !item || item.roles.some((r) => me.roles.includes(r));
  }, [me, pathname]);

  // Moderator-only accounts land on the moderation queue.
  useEffect(() => {
    if (me && !allowedHere && nav[0]) router.replace(nav[0].href);
  }, [me, allowedHere, nav, router]);

  const signOut = async () => {
    setSigningOut(true);
    await createClient().auth.signOut().catch(() => undefined);
    window.location.replace('/admin/login');
  };

  if (state === 'loading') {
    return (
      <FullScreen>
        <p role="status" className="flex items-center gap-2 text-sm font-semibold text-muted">
          <LoaderCircle className="size-5 animate-spin" aria-hidden /> Memeriksa akses petugas
        </p>
      </FullScreen>
    );
  }

  if (state === 'forbidden' || state === 'error') {
    return (
      <FullScreen>
        <div className="w-full max-w-md rounded-xl border border-border-neutral bg-white p-8 text-center">
          <span className="mx-auto grid size-12 place-items-center rounded-full bg-awas/10 text-awas">
            <ShieldX className="size-6" aria-hidden />
          </span>
          <h1 className="mt-4 text-xl font-bold text-navy">{state === 'forbidden' ? 'Akses belum diberikan' : 'Dasbor tidak dapat dimuat'}</h1>
          <p className="mt-2 text-sm text-muted">
            {state === 'forbidden'
              ? 'Akun ini belum memiliki peran petugas. Minta super admin menetapkan peran dan wilayah tugas Anda.'
              : message || 'Periksa koneksi lalu coba lagi.'}
          </p>
          <div className="mt-6 flex justify-center gap-2">
            {state === 'error' ? <Button onClick={retry}>Coba lagi</Button> : null}
            <Button variant="secondary" icon={LogOut} onClick={signOut} loading={signingOut}>
              Keluar
            </Button>
          </div>
        </div>
      </FullScreen>
    );
  }

  if (!me) return null;
  const role = primaryRole(me.roles);

  const sidebar = (
    <div className="flex h-full flex-col bg-navy text-white">
      <div className="flex h-16 items-center justify-between px-5">
        <Wordmark />
        <button type="button" onClick={() => setDrawer(false)} aria-label="Tutup menu" className="grid size-11 place-items-center rounded-lg hover:bg-white/10 lg:hidden">
          <X className="size-5" aria-hidden />
        </button>
      </div>

      <div className="mx-4 rounded-lg border border-white/10 bg-white/5 px-4 py-3">
        <p className="text-[11px] font-semibold uppercase tracking-wider text-white/50">Wilayah tugas</p>
        <p className="mt-0.5 font-bold">{me.isSuper ? 'Semua wilayah' : me.regionName ?? 'Belum ditetapkan'}</p>
        <p className="mt-0.5 text-xs text-white/60">{ROLE_LABEL[role]}</p>
      </div>

      <nav aria-label="Menu dasbor" className="mt-5 flex-1 space-y-1 overflow-y-auto px-3">
        {nav.map(({ href, label, icon: Icon }) => {
          const active = href === '/admin' ? pathname === '/admin' : pathname === href || pathname.startsWith(`${href}/`);
          return (
            <Link
              key={href}
              href={href}
              aria-current={active ? 'page' : undefined}
              onClick={() => setDrawer(false)}
              className={`flex min-h-12 items-center gap-3 rounded-lg px-3 text-sm font-semibold transition-colors ${
                active ? 'bg-white text-navy' : 'text-white/75 hover:bg-white/10 hover:text-white'
              }`}
            >
              <Icon className="size-5" aria-hidden />
              {label}
            </Link>
          );
        })}
      </nav>

      <div className="border-t border-white/10 p-4">
        <p className="truncate text-sm font-semibold">{me.displayName}</p>
        {me.email ? <p className="truncate text-xs text-white/55">{me.email}</p> : null}
        <button
          type="button"
          onClick={signOut}
          disabled={signingOut}
          className="mt-3 flex min-h-11 w-full items-center justify-center gap-2 rounded-lg border border-white/20 text-sm font-semibold text-white/85 hover:bg-white/10 disabled:opacity-60"
        >
          {signingOut ? <LoaderCircle className="size-4 animate-spin" aria-hidden /> : <LogOut className="size-4" aria-hidden />}
          Keluar
        </button>
      </div>
    </div>
  );

  return (
    <AdminContext.Provider value={me}>
      <div className="min-h-screen bg-cream lg:pl-64">
        <a href="#isi-dasbor" className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-[60] focus:rounded-lg focus:bg-white focus:px-4 focus:py-3 focus:text-sm focus:font-semibold">
          Lewati ke isi
        </a>

        {/* Desktop rail */}
        <aside className="fixed inset-y-0 left-0 z-40 hidden w-64 lg:block">{sidebar}</aside>

        {/* Mobile and tablet drawer */}
        {drawer ? (
          <div className="fixed inset-0 z-50 lg:hidden">
            <button type="button" aria-label="Tutup menu" className="absolute inset-0 bg-[#0b1a2c]/55" onClick={() => setDrawer(false)} />
            <aside className="absolute inset-y-0 left-0 w-72 max-w-[85vw]">{sidebar}</aside>
          </div>
        ) : null}

        <header className="sticky top-0 z-30 flex h-14 items-center gap-3 border-b border-border-neutral bg-white px-4 lg:hidden">
          <button type="button" onClick={() => setDrawer(true)} aria-label="Buka menu" className="grid size-11 place-items-center rounded-lg text-navy hover:bg-cream">
            <Menu className="size-5" aria-hidden />
          </button>
          <span className="font-extrabold text-navy">Wero</span>
          <span className="ml-auto truncate text-sm font-semibold text-muted">{me.isSuper ? 'Semua wilayah' : me.regionName}</span>
        </header>

        <main id="isi-dasbor" className="mx-auto w-full max-w-[1400px] px-4 py-6 sm:px-6 lg:px-8 lg:py-8">
          {!me.isSuper && !me.regionId && me.roles.includes('GOVERNMENT_ADMIN') ? (
            <div className="mb-6">
              <Alert tone="error">Akun Anda belum ditetapkan ke wilayah, sehingga data SOS dan evakuasi belum dapat ditampilkan.</Alert>
            </div>
          ) : null}
          {allowedHere ? children : null}
        </main>
      </div>
    </AdminContext.Provider>
  );
}
