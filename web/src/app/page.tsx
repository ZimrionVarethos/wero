import Image from "next/image";
import Link from "next/link";
import {
  BellRing,
  BookOpenCheck,
  ChevronDown,
  Download,
  EyeOff,
  LifeBuoy,
  Map,
  MapPinned,
  ShieldCheck,
  Smartphone,
  Sparkles,
  WifiOff,
} from "lucide-react";
import PhoneMockup from "@/components/landing/PhoneMockup";
import SimulationCard from "@/components/landing/SimulationCard";
import IosDownloadModal from "@/components/landing/IosDownloadModal";

// Tautan unduhan APK.
const APK_URL = process.env.NEXT_PUBLIC_APK_URL ?? "/wero.apk";

const CAPABILITIES = [
  {
    icon: BellRing,
    title: "Peringatan sesuai lokasi",
    body: "Gempa terbaru dari BMKG dan siaran resmi petugas untuk wilayah Anda, lengkap dengan tingkat status dan langkah yang perlu dilakukan.",
  },
  {
    icon: Map,
    title: "Peta evakuasi offline",
    body: "Unduh peta wilayah saat ada sinyal. Saat jaringan terputus, titik kumpul dan shelter yang sudah tersimpan tetap bisa dibuka.",
  },
  {
    icon: LifeBuoy,
    title: "Bantuan SOS",
    body: "Kirim permintaan bantuan dalam mode publik atau privat. Lokasi tepat hanya terlihat oleh petugas wilayah yang berwenang.",
  },
  {
    icon: BookOpenCheck,
    title: "Asisten pengetahuan bencana",
    body: "Tanyakan cara menghadapi gempa, banjir, atau tsunami. Jawaban mengikuti protokol BNPB dan BMKG, dan panduan dasar tetap tersedia saat offline.",
  },
] as const;

const STEPS = [
  { title: "Pasang dan pilih wilayah", body: "Tentukan lokasi tinggal agar peringatan yang masuk relevan." },
  { title: "Simpan peta offline", body: "Unduh peta evakuasi wilayah Anda selagi koneksi tersedia." },
  { title: "Terima peringatan", body: "Notifikasi menampilkan status, wilayah terdampak, dan tindakan." },
  { title: "Bergerak atau minta bantuan", body: "Ikuti jalur ke titik evakuasi atau kirim SOS bila terjebak." },
] as const;

const PRINCIPLES = [
  {
    icon: EyeOff,
    title: "Lokasi tepat dilindungi",
    body: "Lokasi tepat hanya terbuka untuk korban dan petugas berwenang di wilayahnya, dan setiap akses tercatat.",
  },
  {
    icon: WifiOff,
    title: "Jujur soal kondisi offline",
    body: "Saat offline, aplikasi menandai data sebagai tersimpan, bukan langsung. Peta tidak menampilkan pembaruan yang belum diterima.",
  },
  {
    icon: ShieldCheck,
    title: "Bukan pengganti petugas",
    body: "Asisten membantu memahami panduan. Untuk keadaan darurat, tetap hubungi 112 dan ikuti arahan petugas resmi setempat.",
  },
] as const;

const FAQ = [
  {
    q: "Apakah Wero bisa dipakai tanpa internet?",
    a: "Peta evakuasi yang sudah diunduh dan panduan dasar tetap bisa dibuka tanpa internet. Peringatan baru dan pengiriman SOS membutuhkan koneksi data atau sinyal.",
  },
  {
    q: "Dari mana sumber informasi peringatan?",
    a: "Data gempa mengacu pada informasi publik BMKG. Siaran peringatan wilayah dikirim petugas ke pengguna yang memilih wilayah tersebut.",
  },
  {
    q: "Siapa yang bisa melihat lokasi saya saat mengirim SOS?",
    a: "Lokasi publik bisa dibuka oleh petugas berwenang dan orang sekitar di wilayah Anda, tapi private hanya dapat dibuka oleh petugas dan orang terdekat yang masuk dalam list, dan setiap pembukaan lokasi tercatat di log audit.",
  },
  {
    q: "Apakah jawaban asisten bisa dijadikan acuan resmi?",
    a: "Tidak. Asisten merangkum protokol keselamatan untuk edukasi. Keputusan saat darurat tetap mengikuti arahan BPBD, BNPB, dan petugas di lapangan.",
  },
] as const;

export default function Home() {
  return (
    <div className="min-h-screen bg-cream text-foreground">
      <a
        href="#konten"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-white focus:px-4 focus:py-3 focus:text-sm focus:font-semibold shadow-md"
      >
        Lewati ke konten
      </a>

      {/* 1. Navbar Paling Atas */}
      <header className="sticky top-0 z-50 border-b border-border-neutral bg-white/90 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-5 sm:px-8">
          <Link href="/" className="flex items-center gap-3" aria-label="Beranda Wero">
            <Image src="/logo-wero.png" alt="Wero" width={110} height={44} priority className="h-9 w-auto" />
          </Link>
          <nav aria-label="Navigasi utama" className="flex items-center gap-1 sm:gap-2">
            <a href="#fitur" className="hidden md:inline-flex min-h-12 items-center px-3 text-sm font-medium text-muted hover:text-navy">
              Fitur
            </a>
            <a href="#demo-simulasi" className="hidden md:inline-flex min-h-12 items-center px-3 text-sm font-medium text-muted hover:text-navy">
              Demo & Simulasi
            </a>
            <a href="#cara-kerja" className="hidden md:inline-flex min-h-12 items-center px-3 text-sm font-medium text-muted hover:text-navy">
              Cara kerja
            </a>
            <a href="#privasi" className="hidden md:inline-flex min-h-12 items-center px-3 text-sm font-medium text-muted hover:text-navy">
              Privasi
            </a>
            <a href="#faq" className="hidden md:inline-flex min-h-12 items-center px-3 text-sm font-medium text-muted hover:text-navy">
              FAQ
            </a>
            <Link
              href="/admin/login"
              className="hidden sm:inline-flex min-h-11 items-center px-3 text-sm font-semibold text-navy hover:text-accent transition-colors"
            >
              Portal Petugas
            </Link>
            <a
              href={APK_URL}
              download="wero.apk"
              className="hidden sm:inline-flex min-h-11 items-center gap-2 rounded-xl border border-accent/25 bg-accent/10 px-3.5 text-sm font-semibold text-accent hover:bg-accent/20 transition-colors"
            >
              <Download className="size-4" aria-hidden />
              Unduh APK
            </a>
            <IosDownloadModal className="ml-1 sm:ml-2" />
          </nav>
        </div>
      </header>

      <main id="konten">
        {/* 2. Section Utama (Hero Persis Gambar) */}
        <section className="relative overflow-hidden bg-white border-b border-border-neutral min-h-[580px] sm:min-h-[660px] lg:min-h-[720px] flex items-center justify-center">
          {/* Background Ornamen Sungai, Gunung, Matahari di sudut-sudut persis gambar */}
          <div
            className="absolute inset-0 bg-contain bg-center bg-no-repeat pointer-events-none opacity-95"
            style={{ backgroundImage: `url('/hero-frame.png')` }}
          />

          {/* Konten Utama di Tengah */}
          <div className="relative z-10 mx-auto flex max-w-4xl flex-col items-center px-5 py-16 text-center sm:py-24">
            {/* Logo Wero */}
            <div className="relative">
              <Image
                src="/logo-wero.png"
                alt="Wero Logo"
                width={260}
                height={100}
                priority
                className="h-20 sm:h-28 md:h-32 w-auto object-contain drop-shadow-sm"
              />
            </div>

            {/* Slogan "We are Hero" */}
            <h1 className="mt-4 text-4xl sm:text-5xl md:text-6xl font-black tracking-tight text-[#12263F]">
              We are Hero
            </h1>

            {/* Deskripsi */}
            <p className="mt-3.5 max-w-xl text-base sm:text-lg md:text-xl font-medium text-[#12263F]/85 leading-relaxed">
              Wero dirancang sebagai aplikasi peringatan dini dengan support komunitas
            </p>

            {/* Tombol Download dengan Robot Android Lucu di Sebelah Kiri */}
            <div className="mt-8 flex items-center justify-center">
              <a
                href={APK_URL}
                download="wero.apk"
                className="group relative flex items-center justify-center rounded-2xl bg-[#f8a56a] hover:bg-[#f39755] px-8 sm:px-12 py-3.5 sm:py-4 shadow-[0_8px_24px_rgba(248,165,106,0.35)] transition-all hover:scale-105 active:scale-95"
              >
                {/* Robot Android Hijau di Kiri Tombol */}
                <div className="absolute -left-7 sm:-left-8 top-1/2 -translate-y-1/2">
                  <Image
                    src="/android-robot.png"
                    alt="Android Robot"
                    width={72}
                    height={80}
                    priority
                    className="h-16 sm:h-20 w-auto object-contain drop-shadow-md"
                  />
                </div>

                {/* Teks Download */}
                <span className="ml-8 sm:ml-10 text-2xl sm:text-3xl font-black tracking-wide text-[#12263F]">
                  Download
                </span>
              </a>
            </div>

          </div>
        </section>

        {/* 3. Section Kedua: Demo di Kiri & Simulasi 3D di Kanan */}
        <section id="demo-simulasi" className="scroll-mt-16 bg-navy text-white py-16 sm:py-24">
          <div className="mx-auto max-w-7xl px-5 sm:px-8">
            {/* Header Section */}
            <div className="text-center max-w-3xl mx-auto mb-12 sm:mb-16">
              <span className="inline-flex items-center gap-1.5 rounded-full bg-accent/20 px-3.5 py-1 text-xs font-semibold uppercase tracking-wider text-accent border border-accent/30">
                <Sparkles className="size-3.5" aria-hidden />
                Interaktif & Realtime
              </span>
              <h2 className="mt-4 text-3xl font-extrabold tracking-tight sm:text-4xl lg:text-5xl">
                Coba Langsung Aplikasi & Pantau Simulasi Bencana
              </h2>
              <p className="mt-3.5 text-base sm:text-lg text-white/75 leading-relaxed">
                Di sebelah kiri, Anda dapat berinteraksi langsung dengan aplikasi mobile Wero pada mockup smartphone. Di sebelah kanan, putar sudut pandang simulasi visual skenario bencana 3D.
              </p>
            </div>

            {/* Grid 2 Kolom: Kiri Demo HP, Kanan Simulasi 3D */}
            <div className="grid gap-8 lg:grid-cols-2 items-start">
              {/* Kolom Kiri: Demo Mockup HP */}
              <div className="flex flex-col items-center rounded-3xl border border-white/10 bg-white/[0.03] p-5 sm:p-6 backdrop-blur shadow-xl">
                <div className="mb-4 text-center">
                  <span className="inline-flex items-center gap-1.5 text-sm font-bold text-accent">
                    <Smartphone className="size-4" /> Mockup Ponsel Interaktif
                  </span>
                  <p className="mt-1 text-xs text-white/60">
                    Aplikasi live berjalan di dalam layar smartphone. Klik menu untuk bernavigasi.
                  </p>
                </div>
                <PhoneMockup demoUrl="/app/index.html" />
              </div>

              {/* Kolom Kanan: Simulasi 3D Bencana */}
              <div className="flex flex-col items-center rounded-3xl border border-white/10 bg-white/[0.03] p-5 sm:p-6 backdrop-blur shadow-xl">
                <div className="mb-4 text-center">
                  <span className="inline-flex items-center gap-1.5 text-sm font-bold text-white">
                    <LifeBuoy className="size-4 text-[#C62828]" /> Simulasi 3D Dampak Bencana
                  </span>
                  <p className="mt-1 text-xs text-white/60">
                    Pilih skenario bencana dan putar sudut pandang kamera dengan kursor mouse Anda.
                  </p>
                </div>
                <SimulationCard />
              </div>
            </div>
          </div>
        </section>

        {/* 4. Empat kemampuan inti */}
        <section id="fitur" className="scroll-mt-16">
          <div className="mx-auto max-w-7xl px-5 py-20 sm:px-8">
            <div className="grid gap-12 lg:grid-cols-[minmax(0,4fr)_minmax(0,8fr)]">
              <div className="lg:sticky lg:top-28 lg:self-start">
                <p className="text-sm font-semibold text-accent">Fitur inti</p>
                <h2 className="mt-2 text-3xl font-extrabold tracking-tight text-navy sm:text-4xl">
                  Empat hal yang paling dibutuhkan saat bencana
                </h2>
                <p className="mt-4 text-base leading-relaxed text-muted">
                  Tidak ada menu berbelit. Setiap fitur dirancang agar mudah digunakan dalam keadaan darurat, dengan tombol yang jelas dan informasi yang akurat.
                </p>
              </div>
              <ol className="divide-y divide-border-neutral border-y border-border-neutral">
                {CAPABILITIES.map(({ icon: Icon, title, body }, i) => (
                  <li key={title} className="grid grid-cols-[auto_1fr] gap-5 py-7 sm:grid-cols-[3rem_auto_1fr] sm:gap-6">
                    <span className="hidden pt-1 text-sm font-semibold tabular-nums text-muted sm:block">
                      0{i + 1}
                    </span>
                    <span className="grid size-12 place-items-center rounded-xl bg-navy text-white">
                      <Icon className="size-5" aria-hidden />
                    </span>
                    <div>
                      <h3 className="text-lg font-bold text-navy">{title}</h3>
                      <p className="mt-1.5 max-w-2xl leading-relaxed text-muted">{body}</p>
                    </div>
                  </li>
                ))}
              </ol>
            </div>
          </div>
        </section>

        {/* 5. Cara kerja */}
        <section id="cara-kerja" className="scroll-mt-16 border-y border-border-neutral bg-white">
          <div className="mx-auto max-w-7xl px-5 py-20 sm:px-8">
            <h2 className="text-3xl font-extrabold tracking-tight text-navy sm:text-4xl">Cara kerja</h2>
            <p className="mt-3 max-w-2xl text-muted">Siapkan sekali saat kondisi aman, gunakan saat dibutuhkan.</p>
            <ol className="mt-12 grid gap-8 sm:grid-cols-2 lg:grid-cols-4 lg:gap-0">
              {STEPS.map((step, i) => (
                <li key={step.title} className="relative lg:pr-8">
                  <div className="flex items-center gap-3">
                    <span className="grid size-10 shrink-0 place-items-center rounded-full border-2 border-navy text-sm font-bold text-navy">
                      {i + 1}
                    </span>
                    {i < STEPS.length - 1 && <span className="hidden h-px flex-1 bg-border-neutral lg:block" aria-hidden />}
                  </div>
                  <h3 className="mt-5 font-bold text-navy">{step.title}</h3>
                  <p className="mt-1.5 text-sm leading-relaxed text-muted">{step.body}</p>
                </li>
              ))}
            </ol>
          </div>
        </section>

        {/* 6. Privasi dan keandalan */}
        <section id="privasi" className="scroll-mt-16">
          <div className="mx-auto max-w-7xl px-5 py-20 sm:px-8">
            <div className="overflow-hidden rounded-2xl bg-navy text-white">
              <div className="grid lg:grid-cols-[minmax(0,5fr)_minmax(0,7fr)]">
                <div className="border-b border-white/10 p-8 sm:p-12 lg:border-b-0 lg:border-r">
                  <MapPinned className="size-8 text-white/60" aria-hidden />
                  <h2 className="mt-6 text-3xl font-extrabold tracking-tight sm:text-4xl">Privasi dan keandalan</h2>
                  <p className="mt-4 text-base leading-relaxed text-white/75">
                    Data darurat warga diperlakukan dengan penuh kehati-hatian. Kami menjaga kerahasiaan lokasi Anda dan memastikan setiap akses oleh petugas tercatat.
                  </p>
                </div>
                <div className="divide-y divide-white/10">
                  {PRINCIPLES.map(({ icon: Icon, title, body }) => (
                    <div key={title} className="p-8 sm:p-10">
                      <div className="flex items-center gap-3">
                        <Icon className="size-5 text-white/60" aria-hidden />
                        <h3 className="text-lg font-bold">{title}</h3>
                      </div>
                      <p className="mt-3 text-sm leading-relaxed text-white/70">{body}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </section>

        {/* 7. FAQ */}
        <section id="faq" className="scroll-mt-16 border-t border-border-neutral bg-white">
          <div className="mx-auto max-w-4xl px-5 py-20 sm:px-8">
            <h2 className="text-center text-3xl font-extrabold tracking-tight text-navy sm:text-4xl">
              Pertanyaan yang sering diajukan
            </h2>
            <div className="mt-12 space-y-4">
              {FAQ.map(({ q, a }) => (
                <details
                  key={q}
                  className="group rounded-xl border border-border-neutral bg-cream/50 p-5 transition-colors open:bg-cream"
                >
                  <summary className="flex cursor-pointer items-center justify-between font-bold text-navy">
                    <span>{q}</span>
                    <ChevronDown className="size-5 text-muted transition-transform group-open:rotate-180" aria-hidden />
                  </summary>
                  <p className="mt-3 text-sm leading-relaxed text-muted">{a}</p>
                </details>
              ))}
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-border-neutral bg-cream py-12 text-sm text-muted">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-6 px-5 sm:flex-row sm:px-8">
          <div className="flex items-center gap-3">
            <Image src="/logo-wero.png" alt="Wero" width={80} height={32} className="h-6 w-auto" />
            <span>&copy; {new Date().getFullYear()} Wero. Aplikasi Kesiapsiagaan Bencana.</span>
          </div>
          <div className="flex gap-6">
            <a href="#fitur" className="hover:text-navy">Fitur</a>
            <a href="#demo-simulasi" className="hover:text-navy">Demo & Simulasi</a>
            <a href="#cara-kerja" className="hover:text-navy">Cara Kerja</a>
            <a href="#privasi" className="hover:text-navy">Privasi</a>
            <Link href="/admin/login" className="font-semibold text-navy hover:text-accent">Login Petugas</Link>
          </div>
        </div>
      </footer>
    </div>
  );
}
