'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  LayoutDashboard,
  Building,
  Flame,
  ShieldAlert,
  Radio,
  ExternalLink,
  ChevronRight,
  Menu,
  X,
  Smartphone,
  MapPin,
  LogOut,
  ShieldCheck,
} from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import type { User } from '@supabase/supabase-js';
import DashboardOverview from '@/components/admin/DashboardOverview';
import ShelterManager from '@/components/admin/ShelterManager';
import SosMonitor from '@/components/admin/SosMonitor';
import ModerationCenter from '@/components/admin/ModerationCenter';
import BroadcastManager from '@/components/admin/BroadcastManager';
import OperationsMap from '@/components/admin/OperationsMap';
import AdminLoginForm from '@/components/admin/AdminLoginForm';

type AdminTab = 'OVERVIEW' | 'MAP' | 'SHELTER' | 'SOS' | 'MODERATION' | 'BROADCAST';

export default function AdminDashboardPage() {
  const [currentTab, setCurrentTab] = useState<AdminTab>('OVERVIEW');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [loadingAuth, setLoadingAuth] = useState(true);

  const supabase = createClient();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      setLoadingAuth(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null);
      setLoadingAuth(false);
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [supabase]);

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    setUser(null);
  };

  const navItems = [
    { id: 'OVERVIEW', label: 'Ringkasan Operasi', icon: LayoutDashboard },
    { id: 'MAP', label: 'Peta Taktis Operasi', icon: MapPin },
    { id: 'SHELTER', label: 'Fasilitas & Shelter', icon: Building },
    { id: 'SOS', label: 'Monitoring SOS', icon: Flame },
    { id: 'MODERATION', label: 'Moderasi Komunitas', icon: ShieldAlert },
    { id: 'BROADCAST', label: 'Peringatan & Siaran', icon: Radio },
  ];

  if (loadingAuth) {
    return (
      <div className="min-h-screen bg-slate-900 flex flex-col items-center justify-center text-slate-300">
        <div className="w-8 h-8 border-3 border-sky-400/30 border-t-sky-400 rounded-full animate-spin mb-3" />
        <p className="text-sm font-semibold tracking-wide">Memverifikasi otentikasi petugas...</p>
      </div>
    );
  }

  if (!user) {
    return <AdminLoginForm onLoginSuccess={(loggedInUser) => setUser(loggedInUser)} />;
  }

  return (
    <div className="min-h-screen bg-slate-100/70 text-slate-900 flex flex-col font-sans">
      {/* Top Header */}
      <header className="h-16 bg-white border-b border-slate-200 px-4 sm:px-6 flex items-center justify-between sticky top-0 z-40 shadow-2xs">
        <div className="flex items-center gap-3">
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 rounded-xl text-slate-600 hover:bg-slate-100"
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>

          <Link href="/" className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-sky-600 to-sky-400 text-white font-extrabold text-base flex items-center justify-center shadow-xs">
              S
            </div>
            <div>
              <span className="font-extrabold text-slate-900 tracking-tight text-base sm:text-lg">
                Siagaku<span className="text-sky-600 font-normal"> / Wero</span>
              </span>
              <span className="hidden sm:inline-block text-[10px] ml-2 px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 font-bold uppercase tracking-wider">
                Ops Portal
              </span>
            </div>
          </Link>
        </div>

        {/* Right Admin Profile & Logout */}
        <div className="flex items-center gap-3 sm:gap-4">
          <Link
            href="/"
            className="hidden sm:flex items-center gap-1.5 text-xs font-semibold text-slate-600 hover:text-slate-900 bg-slate-50 px-3 py-1.5 rounded-xl border border-slate-200 transition"
          >
            <Smartphone className="w-3.5 h-3.5" /> Portal Depan
            <ExternalLink className="w-3 h-3 text-slate-400" />
          </Link>

          <div className="flex items-center gap-2.5 pl-3 border-l border-slate-200">
            <div className="w-8 h-8 rounded-full bg-sky-100 text-sky-700 font-bold text-xs flex items-center justify-center border border-sky-200 uppercase">
              {user.email ? user.email.slice(0, 2) : 'BP'}
            </div>
            <div className="hidden sm:block text-left">
              <div className="text-xs font-bold text-slate-800 leading-tight truncate max-w-[160px]">
                {user.email || 'Admin BPBD'}
              </div>
              <div className="text-[10px] text-emerald-600 font-semibold flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span> Super Coordinator
              </div>
            </div>
            <button
              onClick={handleSignOut}
              title="Keluar dari Portal Operasi"
              className="ml-1 sm:ml-2 p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition cursor-pointer"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </header>

      {/* Main Container */}
      <div className="flex-1 flex flex-col md:flex-row">
        {/* Sidebar Navigation */}
        <aside
          className={`fixed inset-y-0 left-0 z-30 w-64 bg-white border-r border-slate-200 p-4 transform transition-transform duration-200 ease-in-out md:translate-x-0 md:static md:block ${
            mobileMenuOpen ? 'translate-x-0 top-16' : '-translate-x-full'
          }`}
        >
          <div className="text-[11px] font-bold text-slate-400 uppercase tracking-wider px-3 py-2">
            Menu Operasional
          </div>

          <nav className="space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const active = currentTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => {
                    setCurrentTab(item.id as AdminTab);
                    setMobileMenuOpen(false);
                  }}
                  className={`w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs sm:text-sm font-semibold transition cursor-pointer ${
                    active
                      ? 'bg-sky-50 text-sky-700 font-bold border border-sky-200/80 shadow-2xs'
                      : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <Icon className={`w-4 h-4 ${active ? 'text-sky-600' : 'text-slate-400'}`} />
                    <span>{item.label}</span>
                  </div>
                  {active && <ChevronRight className="w-4 h-4 text-sky-500" />}
                </button>
              );
            })}
          </nav>

          <div className="mt-8 pt-4 border-t border-slate-100 px-3">
            <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">
              Koneksi Real-time
            </div>
            <div className="p-3 rounded-xl bg-slate-50 border border-slate-100 text-[11px] text-slate-600 space-y-1">
              <div className="font-semibold text-slate-800">Database Supabase</div>
              <div className="flex items-center gap-1.5 text-emerald-600">
                <span className="w-2 h-2 rounded-full bg-emerald-500"></span> Active & Synchronized
              </div>
            </div>
          </div>
        </aside>

        {/* Content Viewport */}
        <main className="flex-1 p-4 sm:p-6 md:p-8 max-w-7xl mx-auto w-full">
          {currentTab === 'OVERVIEW' && (
            <DashboardOverview onNavigateTab={(tab) => setCurrentTab(tab as AdminTab)} />
          )}
          {currentTab === 'MAP' && <OperationsMap />}
          {currentTab === 'SHELTER' && <ShelterManager />}
          {currentTab === 'SOS' && (
            <SosMonitor onNavigateToMap={() => setCurrentTab('MAP')} />
          )}
          {currentTab === 'MODERATION' && <ModerationCenter />}
          {currentTab === 'BROADCAST' && <BroadcastManager />}
        </main>
      </div>
    </div>
  );
}
