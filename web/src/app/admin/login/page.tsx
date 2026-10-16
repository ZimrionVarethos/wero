'use client';

import Image from 'next/image';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useEffect, useState, type FormEvent } from 'react';
import { ArrowLeft, Eye, EyeOff, LoaderCircle, LockKeyhole, ShieldCheck } from 'lucide-react';
import { createClient } from '@/lib/supabase/client';
import { Alert, Button, TextField } from '@/components/admin/ui';

export default function AdminLoginPage() {
  const router = useRouter();
  const [checking, setChecking] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Only shown after the session check, so the server render never depends on it.
  const [expired] = useState(() => typeof window !== 'undefined' && new URLSearchParams(window.location.search).get('sesi') === 'berakhir');

  useEffect(() => {
    createClient()
      .auth.getSession()
      .then(({ data: { session } }) => {
        if (session?.user) router.replace('/admin');
        else setChecking(false);
      })
      .catch(() => setChecking(false));
  }, [router]);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    const { error: authError } = await createClient().auth.signInWithPassword({ email: email.trim(), password });
    if (authError) {
      setError('Email atau kata sandi tidak sesuai.');
      setSubmitting(false);
      return;
    }
    router.replace('/admin');
  };

  return (
    <div className="grid min-h-screen bg-cream lg:grid-cols-[minmax(0,5fr)_minmax(0,6fr)]">
      {/* Brand panel */}
      <section className="relative hidden flex-col justify-between overflow-hidden bg-navy p-12 text-white lg:flex">
        <div className="flex items-center gap-3">
          <span className="grid size-10 place-items-center rounded-lg bg-white p-1.5">
            <Image src="/logo.png" alt="" width={28} height={28} className="h-auto w-full" />
          </span>
          <span className="text-lg font-extrabold tracking-tight">Wero</span>
        </div>
        <div className="max-w-md">
          <p className="text-sm font-semibold uppercase tracking-wider text-white/50">Dasbor petugas</p>
          <h1 className="mt-3 text-4xl font-extrabold leading-tight tracking-tight">Pantau SOS dan kelola evakuasi di wilayah Anda.</h1>
          <ul className="mt-8 space-y-4 text-sm text-white/75">
            <li className="flex gap-3">
              <ShieldCheck className="mt-0.5 size-5 shrink-0 text-white/60" aria-hidden />
              Data yang tampil dibatasi sesuai wilayah tugas akun Anda.
            </li>
            <li className="flex gap-3">
              <LockKeyhole className="mt-0.5 size-5 shrink-0 text-white/60" aria-hidden />
              Setiap pembukaan lokasi tepat dan perubahan data tercatat di log audit.
            </li>
          </ul>
        </div>
        <p className="text-xs text-white/40">Hanya untuk petugas berwenang.</p>
      </section>

      {/* Form */}
      <section className="flex flex-col px-6 py-8 sm:px-12">
        <Link href="/" className="inline-flex min-h-12 w-fit items-center gap-2 text-sm font-semibold text-muted hover:text-navy">
          <ArrowLeft className="size-4" aria-hidden /> Kembali ke beranda
        </Link>

        <div className="mx-auto flex w-full max-w-sm flex-1 flex-col justify-center py-10">
          <h2 className="text-2xl font-extrabold tracking-tight text-navy">Masuk sebagai petugas</h2>
          <p className="mt-2 text-sm text-muted">Gunakan akun yang sudah diberi peran oleh super admin.</p>

          {checking ? (
            <p role="status" className="mt-10 flex items-center gap-2 text-sm text-muted">
              <LoaderCircle className="size-4 animate-spin" aria-hidden /> Memeriksa sesi
            </p>
          ) : (
            <form onSubmit={submit} className="mt-8 space-y-5" noValidate>
              {expired && !error ? <Alert tone="info">Sesi Anda berakhir. Silakan masuk kembali.</Alert> : null}
              {error ? <Alert tone="error">{error}</Alert> : null}
              <TextField label="Email" type="email" autoComplete="username" required value={email} onChange={(e) => setEmail(e.target.value)} />
              <div className="relative">
                <TextField
                  label="Kata sandi"
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="pr-12"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? 'Sembunyikan kata sandi' : 'Tampilkan kata sandi'}
                  className="absolute bottom-0 right-0 grid size-12 place-items-center text-muted hover:text-navy"
                >
                  {showPassword ? <EyeOff className="size-4" aria-hidden /> : <Eye className="size-4" aria-hidden />}
                </button>
              </div>
              <Button type="submit" variant="accent" className="w-full" loading={submitting} disabled={!email || !password}>
                Masuk
              </Button>
            </form>
          )}
        </div>
      </section>
    </div>
  );
}
