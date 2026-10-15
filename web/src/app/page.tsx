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
  WifiOff,
} from "lucide-react";
import HeroScene from "@/components/landing/HeroScene";

// Tautan unduhan APK. Atur NEXT_PUBLIC_APK_URL saat build rilis.
const APK_URL = process.env.NEXT_PUBLIC_APK_URL ?? "/siagaku.apk";

const CAPABILITIES = [
  {
    icon: BellRing,
    title: "Peringatan sesuai lokasi",
    body: "Informasi gempa dan cuaca dari BMKG disaring berdasarkan wilayah Anda, lengkap dengan tingkat status dan langkah yang perlu dilakukan.",
  },
  {
    icon: Map,
    title: "Peta evakuasi offline",
    body: "Unduh peta wilayah saat ada sinyal. Saat jaringan terputus, titik kumpul dan shelter yang sudah tersimpan tetap bisa dibuka.",
  },
  {
    icon: LifeBuoy,
    title: "Bantuan SOS",
    body: "Kirim permintaan bantuan dalam mode publik atau privat. Jangkauan diperluas bertahap dan lokasi tepat hanya terlihat oleh pihak berwenang.",
  },
  {
    icon: BookOpenCheck,
    title: "Asisten pengetahuan bencana",
    body: "Tanyakan cara menghadapi gempa, banjir, atau tsunami. Jawaban bersumber dari panduan terkurasi dan tersedia versi offline.",
  },
] as const;

const STEPS = [
  { title: "Pasang dan pilih wilayah", body: "Tentukan lokasi tinggal agar peringatan yang masuk relevan." },
  { title: "Simpan peta offline", body: "Unduh peta evakuasi wilayah Anda selagi koneksi tersedia." },
  { title: "Terima peringatan", body: "Notifikasi menampilkan status, wilayah terdampak, dan tindakan." },
  { title: "Bergerak atau minta bantuan", body: "Ikuti jalur ke titik evakuasi atau kirim SOS bila terjebak." },
] as const;

const STATUS_LEVELS = [
  { label: "AWAS", color: "bg-awas" },
  { label: "SIAGA", color: "bg-siaga" },
  { label: "WASPADA", color: "bg-waspada" },
  { label: "AMAN", color: "bg-aman" },
] as const;

const PRINCIPLES = [
  {
    icon: EyeOff,
    title: "Lokasi tepat dilindungi",
    body: "Warga lain hanya melihat perkiraan area. Lokasi tepat terbuka untuk korban dan petugas berwenang di wilayahnya, dan setiap akses tercatat.",
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
    q: "Apakah Siagaku bisa dipakai tanpa internet?",
    a: "Peta evakuasi yang sudah diunduh dan panduan dasar tetap bisa dibuka tanpa internet. Peringatan baru dan pengiriman SOS membutuhkan koneksi data atau sinyal.",
  },
  {
    q: "Dari mana sumber informasi peringatan?",
    a: "Peringatan gempa dan cuaca mengacu pada informasi publik BMKG. Siagaku menyaring informasi tersebut berdasarkan wilayah yang Anda pilih.",
  },
  {
    q: "Siapa yang bisa melihat lokasi saya saat mengirim SOS?",
    a: "Mode privat hanya membagikan lokasi tepat kepada petugas berwenang di wilayah Anda. Mode publik menampilkan perkiraan area kepada warga sekitar tanpa koordinat tepat.",
  },
  {
    q: "Apakah jawaban asisten bisa dijadikan acuan resmi?",
    a: "Tidak. Asisten merangkum panduan terkurasi untuk edukasi. Keputusan saat darurat tetap mengikuti arahan BPBD, BNPB, dan petugas di lapangan.",
  },
] as const;

export default function Home() {
  return (
    <div className="min-h-screen bg-cream text-foreground">
      <a
        href="#konten"
        className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-white focus:px-4 focus:py-3 focus:text-sm focus:font-semibold"
      >
        Lewati ke konten
      </a>

      {/* Header */}
      <header className="sticky top-0 z-40 border-b border-border-neutral bg-cream/90 backdrop-blur">
        <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-5 sm:px-8">
          <Link href="/" className="flex items-center gap-3" aria-label="Beranda Siagaku">
            <Image src="/logo-wero.png" alt="" width={104} height={42} priority className="h-8 w-auto" />
            <span className="hidden sm:inline border-l border-border-neutral pl-3 text-sm font-semibold text-navy">
              Siagaku
            </span>
          </Link>
          <nav aria-label="Navigasi utama" className="flex items-center gap-1 sm:gap-2">
            <a href="#fitur" className="hidden md:inline-flex min-h-12 items-center px-3 text-sm font-medium text-muted hover:text-navy">
              Fitur
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
            <a
              href={APK_URL}
              download
              className="ml-2 inline-flex min-h-11 items-center gap-2 rounded-lg bg-accent px-4 text-sm font-semibold text-white hover:bg-[#cf4f0a] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
            >
              <Download className="size-4" aria-hidden />
              Unduh APK
            </a>
          </nav>
        </div>
      </header>

      <main id="konten">
        {/* Hero */}
        <section className="bg-navy text-white">
          <div className="mx-auto grid max-w-7xl items-center gap-10 px-5 py-14 sm:px-8 lg:grid-cols-[minmax(0,5fr)_minmax(0,7fr)] lg:py-20">
            <div>
              <p className="inline-flex items-center gap-2 rounded-full border border-white/15 px-3 py-1 text-xs font-semibold uppercase tracking-wider text-white/70">
                <Smartphone className="size-3.5" aria-hidden />
                Aplikasi Android
              </p>
              <h1 className="mt-5 text-4xl font-extrabold leading-[1.1] tracking-tight sm:text-5xl lg:text-[3.4rem]">
                Tahu apa yang terjadi. Tahu ke mana harus pergi.
              </h1>
              <p className="mt-5 max-w-xl text-base leading-relaxed text-white/75 sm:text-lg">
                Siagaku mengumpulkan peringatan sesuai lokasi, peta evakuasi yang tetap terbuka saat offline,
                bantuan SOS, dan panduan kebencanaan dalam satu aplikasi.
              </p>
              <div className="mt-8 flex flex-wrap gap-3">
                <a
                  href={APK_URL}
                  download
                  className="inline-flex min-h-12 items-center gap-2 rounded-xl bg-accent px-6 text-base font-semibold text-white hover:bg-[#cf4f0a] focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
                >
                  <Download className="size-5" aria-hidden />
                  Unduh APK
                </a>
                <a
                  href="#cara-kerja"
                  className="inline-flex min-h-12 items-center rounded-xl border border-white/25 px-6 text-base font-semibold text-white hover:bg-white/10"
                >
                  Lihat cara kerja
                </a>
              </div>

              {/* Skala status, selalu label teks + warna */}
              <div className="mt-10 border-t border-white/10 pt-6">
                <p className="text-xs font-semibold uppercase tracking-wider text-white/50">Tingkat status peringatan</p>
                <ul className="mt-3 flex flex-wrap gap-2">
                  {STATUS_LEVELS.map((s) => (
                    <li key={s.label} className="inline-flex items-center gap-2 rounded-md bg-white/5 px-2.5 py-1.5 text-xs font-bold tracking-wide">
                      <span className={`size-2.5 rounded-full ${s.color}`} aria-hidden />
                      {s.label}
                    </li>
                  ))}
                </ul>
              </div>
            </div>

            <HeroScene />
          </div>
        </section>

        {/* Empat kemampuan inti */}
        <section id="fitur" className="scroll-mt-16">
          <div className="mx-auto max-w-7xl px-5 py-20 sm:px-8">
            <div className="grid gap-12 lg:grid-cols-[minmax(0,4fr)_minmax(0,8fr)]">
              <div className="lg:sticky lg:top-28 lg:self-start">
                <p className="text-sm font-semibold text-accent">Fitur inti</p>
                <h2 className="mt-2 text-3xl font-extrabold tracking-tight text-navy sm:text-4xl">
                  Empat hal yang paling dibutuhkan saat bencana
                </h2>
                <p className="mt-4 text-base leading-relaxed text-muted">
                  Tidak ada menu berlapis. Setiap fitur dirancang agar tetap mudah dipakai saat panik, dengan
                  tombol besar dan teks yang singkat.
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

        {/* Cara kerja */}
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

        {/* Privasi dan keandalan */}
        <section id="privasi" className="scroll-mt-16">
          <div className="mx-auto max-w-7xl px-5 py-20 sm:px-8">
            <div className="overflow-hidden rounded-2xl bg-navy text-white">
              <div className="grid lg:grid-cols-[minmax(0,5fr)_minmax(0,7fr)]">
                <div className="border-b border-white/10 p-8 sm:p-12 lg:border-b-0 lg:border-r">
                  <MapPinned className="size-8 text-white/60" aria-hidden />
                  <h2 className="mt-6 text-3xl font-extrabold tracking-tight sm:text-4xl">Privasi dan keandalan</h2>
                  <p className="mt-4 leading-relaxed text-white/70">
                    Data lokasi saat darurat sangat sensitif. Siagaku membatasi siapa yang bisa melihatnya dan
                    selalu terbuka tentang apa yang bisa dan tidak bisa dilakukan aplikasi.
                  </p>
                </div>
                <ul className="divide-y divide-white/10">
                  {PRINCIPLES.map(({ icon: Icon, title, body }) => (
                    <li key={title} className="flex gap-5 p-8 sm:px-12">
                      <Icon className="mt-0.5 size-6 shrink-0 text-white/70" aria-hidden />
                      <div>
                        <h3 className="font-bold">{title}</h3>
                        <p className="mt-1.5 text-sm leading-relaxed text-white/70">{body}</p>
                      </div>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* FAQ */}
        <section id="faq" className="scroll-mt-16">
          <div className="mx-auto grid max-w-7xl gap-10 px-5 pb-24 sm:px-8 lg:grid-cols-[minmax(0,4fr)_minmax(0,8fr)]">
            <h2 className="text-3xl font-extrabold tracking-tight text-navy sm:text-4xl">Pertanyaan umum</h2>
            <div className="divide-y divide-border-neutral border-y border-border-neutral">
              {FAQ.map((item) => (
                <details key={item.q} className="group">
                  <summary className="flex min-h-14 cursor-pointer list-none items-center justify-between gap-4 py-5 text-left font-semibold text-navy [&::-webkit-details-marker]:hidden">
                    {item.q}
                    <ChevronDown className="size-5 shrink-0 text-muted transition-transform group-open:rotate-180" aria-hidden />
                  </summary>
                  <p className="pb-6 pr-10 leading-relaxed text-muted">{item.a}</p>
                </details>
              ))}
            </div>
          </div>
        </section>
      </main>

      {/* Footer */}
      <footer className="border-t border-border-neutral bg-white">
        <div className="mx-auto flex max-w-7xl flex-col gap-8 px-5 py-10 sm:px-8 md:flex-row md:items-center md:justify-between">
          <div>
            <Image src="/logo-wero.png" alt="Wero" width={104} height={42} className="h-8 w-auto" />
            <p className="mt-3 text-sm text-muted">Siagaku, aplikasi kesiapsiagaan bencana untuk warga Indonesia.</p>
          </div>
          <nav aria-label="Tautan footer" className="flex flex-wrap items-center gap-x-6 gap-y-2 text-sm font-medium">
            <a href={APK_URL} download className="inline-flex min-h-12 items-center gap-2 text-navy hover:text-accent">
              <Download className="size-4" aria-hidden />
              Unduh APK
            </a>
            <a href="#privasi" className="inline-flex min-h-12 items-center text-muted hover:text-navy">
              Kebijakan Privasi
            </a>
            <span className="inline-flex min-h-12 items-center text-muted/60" aria-disabled="true">
              Ketentuan Penggunaan (segera)
            </span>
            <span className="inline-flex min-h-12 items-center text-muted/60" aria-disabled="true">
              Kontak (segera)
            </span>
            <Link href="/admin" className="inline-flex min-h-12 items-center text-muted hover:text-navy">
              Dasbor petugas
            </Link>
          </nav>
        </div>
        <div className="border-t border-border-neutral">
          <p className="mx-auto max-w-7xl px-5 py-5 text-xs text-muted sm:px-8">
            © 2026 Siagaku. Dalam keadaan darurat, hubungi 112.
          </p>
        </div>
      </footer>
    </div>
  );
}
