'use client';

import React, { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import AdminLoginForm from '@/components/admin/AdminLoginForm';

export default function AdminLoginPage() {
  const router = useRouter();
  const [checking, setChecking] = useState(true);
  const supabase = createClient();

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      if (session?.user) {
        router.replace('/admin');
      } else {
        setChecking(false);
      }
    });
  }, [router, supabase]);

  if (checking) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center text-slate-400">
        <div className="flex items-center gap-3">
          <div className="w-5 h-5 border-2 border-sky-400/30 border-t-sky-400 rounded-full animate-spin" />
          <span className="text-sm font-semibold">Memeriksa sesi...</span>
        </div>
      </div>
    );
  }

  return (
    <AdminLoginForm
      onLoginSuccess={() => {
        router.replace('/admin');
      }}
    />
  );
}
