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
    <div className="grid min-h-screen bg-cream lg:grid-cols-[minmax(0,5.5fr)_minmax(0,5fr)]">
      {/* Kolom Kiri: Gambar Ornamen & Brand Panel */}
      <section className="relative hidden flex-col justify-between overflow-hidden bg-[#faf8f5] p-10 xl:p-14 lg:flex border-r border-[#12263F]/10">
        {/* Gambar Ornamen Penuh Mengisi Kolom Kiri */}
        <div className="absolute inset-0 z-0">
          <Image
            src="/ornamen.png"
            alt="Ornamen Wero"
            fill
            priority
            sizes="(max-width: 1024px) 100vw, 50vw"
            className="object-cover object-center"
          />
        </div>

        {/* Brand Header */}
        <div className="relative z-10 flex items-center gap-3">
          <span className="grid size-11 place-items-center rounded-xl bg-white/90 p-2 shadow-sm border border-[#12263F]/10 backdrop-blur">
            <Image src="/logo.png" alt="Wero" width={32} height={32} className="h-auto w-full" />
          </span>
          <div className="flex flex-col">
            <span className="text-xl font-black tracking-tight text-[#12263F]">Wero</span>
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#12263F]/70">Portal Petugas & Relawan</span>
          </div>
        </div>

        {/* Kartu Informasi di Atas Ornamen */}
        <div className="relative z-10 max-w-md rounded-2xl border border-white/80 bg-white/85 p-6 backdrop-blur-md shadow-[0_8px_30px_rgb(0,0,0,0.06)]">
          <span className="inline-block rounded-full bg-accent/15 px-3 py-1 text-xs font-bold uppercase tracking-wider text-accent">
            Dasbor Petugas
          </span>
          <h1 className="mt-2.5 text-2xl xl:text-3xl font-black leading-snug tracking-tight text-[#12263F]">
            Pantau SOS dan kelola evakuasi di wilayah Anda.
          </h1>
          <ul className="mt-5 space-y-3 text-xs xl:text-sm text-[#12263F]/85">
            <li className="flex gap-2.5 items-start">
              <ShieldCheck className="mt-0.5 size-4.5 shrink-0 text-accent" aria-hidden />
              <span>Data yang tampil dibatasi sesuai wilayah tugas akun Anda.</span>
            </li>
            <li className="flex gap-2.5 items-start">
              <LockKeyhole className="mt-0.5 size-4.5 shrink-0 text-accent" aria-hidden />
              <span>Setiap pembukaan lokasi tepat dan perubahan data tercatat di log audit.</span>
            </li>
          </ul>
        </div>

        {/* Footer Note */}
        <p className="relative z-10 text-xs font-semibold text-[#12263F]/60">
          Hanya untuk petugas dan relawan berwenang.
        </p>
      </section>

      {/* Kolom Kanan: Form */}
      <section className="flex flex-col justify-between px-6 py-8 sm:px-12 bg-cream min-h-screen">
        <Link href="/" className="inline-flex min-h-12 w-fit items-center gap-2 text-sm font-semibold text-muted hover:text-navy transition-colors">
          <ArrowLeft className="size-4" aria-hidden /> Kembali ke beranda
        </Link>

        {/* Mobile-only Ornamen Banner */}
        <div className="relative mt-4 overflow-hidden rounded-2xl border border-border-neutral lg:hidden h-24 w-full">
          <Image
            src="/ornamen.png"
            alt="Ornamen Wero"
            fill
            className="object-cover object-center"
          />
          <div className="absolute inset-0 bg-white/60 backdrop-blur-[2px]" />
          <div className="relative z-10 flex h-full items-center gap-3 px-5">
            <span className="grid size-10 place-items-center rounded-xl bg-white p-2 shadow-sm border border-border-neutral">
              <Image src="/logo.png" alt="Wero" width={28} height={28} className="h-auto w-full" />
            </span>
            <div>
              <span className="text-base font-black tracking-tight text-navy">Wero</span>
              <p className="text-[11px] font-bold text-accent">Portal Petugas & Relawan</p>
            </div>
          </div>
        </div>

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
