'use client';

import React, { useState } from 'react';
import { createClient } from '@/lib/supabase/client';
import { ShieldCheck, Lock, Mail, AlertCircle, ArrowRight, Sparkles, Building2 } from 'lucide-react';
import type { User } from '@supabase/supabase-js';

interface AdminLoginFormProps {
  onLoginSuccess: (user: User) => void;
}

export default function AdminLoginForm({ onLoginSuccess }: AdminLoginFormProps) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const supabase = createClient();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setLoading(true);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password: password,
      });

      if (error) {
        throw error;
      }

      if (data?.user) {
        onLoginSuccess(data.user);
      }
    } catch (err: any) {
      setErrorMsg(err?.message || 'Gagal masuk. Periksa email dan password Anda.');
    } finally {
      setLoading(false);
    }
  };

  const handleQuickDemoLogin = async () => {
    setEmail('siagaku.admin@gmail.com');
    setPassword('PasswordSiagaku123!');
    setErrorMsg(null);
    setLoading(true);

    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: 'siagaku.admin@gmail.com',
        password: 'PasswordSiagaku123!',
      });

      if (error) throw error;
      if (data?.user) {
        onLoginSuccess(data.user);
      }
    } catch (err: any) {
      setErrorMsg(err?.message || 'Login akun demo gagal.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 flex items-center justify-center p-4 sm:p-6 font-sans relative overflow-hidden">
      {/* Background Ambience */}
      <div className="absolute -top-40 -left-40 w-96 h-96 bg-sky-600/20 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 bg-indigo-600/20 rounded-full blur-3xl pointer-events-none" />

      <div className="w-full max-w-md bg-slate-800/90 backdrop-blur-xl border border-slate-700/80 rounded-3xl p-6 sm:p-8 shadow-2xl relative z-10">
        {/* Header Branding */}
        <div className="flex flex-col items-center text-center mb-6">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-sky-600 to-indigo-500 text-white flex items-center justify-center shadow-lg shadow-sky-500/20 mb-3 border border-sky-400/30">
            <Building2 className="w-7 h-7" />
          </div>
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold tracking-wider uppercase bg-sky-500/10 text-sky-400 border border-sky-500/20 mb-2">
            <ShieldCheck className="w-3.5 h-3.5" /> PUSDALOPS BPBD & SAR
          </span>
          <h1 className="text-xl sm:text-2xl font-black tracking-tight text-white">
            Portal Operasi Darurat
          </h1>
          <p className="text-xs sm:text-sm text-slate-400 mt-1 max-w-xs">
            Masuk untuk mengakses sistem komando, manajemen shelter, dan monitoring SOS Siagaku.
          </p>
        </div>

        {/* Error Alert */}
        {errorMsg && (
          <div className="mb-5 p-3.5 rounded-2xl bg-rose-500/15 border border-rose-500/30 text-rose-300 text-xs flex items-start gap-2.5">
            <AlertCircle className="w-4 h-4 text-rose-400 shrink-0 mt-0.5" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Form */}
        <form onSubmit={handleLogin} className="space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Email Petugas / Admin
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <Mail className="w-4 h-4" />
              </div>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="petugas@bpbd.go.id"
                className="w-full pl-10 pr-4 py-2.5 bg-slate-900/80 border border-slate-700 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-hidden focus:border-sky-500 focus:ring-1 focus:ring-sky-500 transition"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-300 mb-1.5">
              Kata Sandi
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <Lock className="w-4 h-4" />
              </div>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-10 pr-4 py-2.5 bg-slate-900/80 border border-slate-700 rounded-xl text-sm text-white placeholder-slate-500 focus:outline-hidden focus:border-sky-500 focus:ring-1 focus:ring-sky-500 transition"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 px-4 bg-sky-500 hover:bg-sky-400 text-white font-bold rounded-xl text-sm transition shadow-lg shadow-sky-500/25 flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed mt-2"
          >
            {loading ? (
              <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
            ) : (
              <>
                <span>Masuk Portal Operasi</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        {/* Divider */}
        <div className="relative my-6 text-center">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-slate-700/80"></div>
          </div>
          <span className="relative bg-slate-800 px-3 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
            Atau Pengujian Juri / Demo
          </span>
        </div>

        {/* Quick Demo Login */}
        <button
          type="button"
          onClick={handleQuickDemoLogin}
          disabled={loading}
          className="w-full py-2.5 px-4 bg-slate-700/60 hover:bg-slate-700 text-slate-200 border border-slate-600/60 font-semibold rounded-xl text-xs transition flex items-center justify-center gap-2 cursor-pointer disabled:opacity-50"
        >
          <Sparkles className="w-3.5 h-3.5 text-amber-400" />
          <span>Masuk Cepat (Akun Demo Petugas)</span>
        </button>

        <div className="mt-6 pt-4 border-t border-slate-700/60 text-center">
          <p className="text-[11px] text-slate-400">
            Kredensial demo: <code className="text-sky-400 font-mono">siagaku.admin@gmail.com</code>
          </p>
        </div>
      </div>
    </div>
  );
}
