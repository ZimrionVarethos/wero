import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen bg-[#EAF6FF] text-[#111111] flex flex-col justify-between">
      {/* Header */}
      <header className="w-full max-w-6xl mx-auto px-6 py-6 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#20A8F5] flex items-center justify-center text-white font-bold text-xl shadow-sm">
            S
          </div>
          <div>
            <span className="text-xl font-bold tracking-tight">Siagaku</span>
            <span className="text-xs ml-1.5 px-2 py-0.5 rounded-full bg-[#CDEBFF] text-[#20A8F5] font-medium">
              Wero
            </span>
          </div>
        </div>
        <nav className="flex items-center gap-4">
          <Link
            href="/admin"
            className="text-sm font-semibold px-4 py-2 rounded-xl bg-white border border-[#D9E0E5] hover:bg-gray-50 transition shadow-xs"
          >
            Dashboard Admin
          </Link>
        </nav>
      </header>

      {/* Hero Section */}
      <main className="w-full max-w-6xl mx-auto px-6 py-12 flex-1 flex flex-col justify-center">
        <div className="max-w-2xl">
          <span className="text-xs uppercase tracking-widest font-semibold text-[#F07800] bg-[#FFF3E6] px-3 py-1 rounded-full">
            Platform Kesiapsiagaan Bencana
          </span>
          <h1 className="mt-4 text-4xl sm:text-5xl font-bold tracking-tight leading-tight">
            Siap Siaga Bersama Komunitas & Informasi Terpercaya
          </h1>
          <p className="mt-4 text-base sm:text-lg text-[#858585] leading-relaxed">
            Menghubungkan peringatan resmi, rute evakuasi offline, pengetahuan
            komunitas lokal, dan respon darurat terkoordinasi untuk keselamatan warga.
          </p>

          <div className="mt-8 flex flex-wrap items-center gap-4">
            <Link
              href="/admin"
              className="px-6 py-3.5 rounded-2xl bg-[#111111] text-white font-medium hover:bg-black transition shadow-sm text-sm"
            >
              Masuk ke Admin Dashboard
            </Link>
            <a
              href="#fitur"
              className="px-6 py-3.5 rounded-2xl bg-white text-[#111111] border border-[#D9E0E5] font-medium hover:bg-gray-50 transition text-sm shadow-xs"
            >
              Pelajari Fitur
            </a>
          </div>
        </div>

        {/* Feature Cards Grid */}
        <div id="fitur" className="mt-16 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          <div className="bg-white p-6 rounded-2xl border border-[#D9E0E5]/60 shadow-xs">
            <div className="w-10 h-10 rounded-xl bg-[#CDEBFF] text-[#20A8F5] flex items-center justify-center font-bold text-lg mb-4">
              🚨
            </div>
            <h3 className="font-bold text-base mb-1.5">Peringatan Terkini</h3>
            <p className="text-sm text-[#858585]">
              Informasi terverifikasi dari sumber resmi seperti BMKG dan BNPB.
            </p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-[#D9E0E5]/60 shadow-xs">
            <div className="w-10 h-10 rounded-xl bg-[#DDF6C5] text-[#77E600] flex items-center justify-center font-bold text-lg mb-4">
              📍
            </div>
            <h3 className="font-bold text-base mb-1.5">Peta & Rute Evakuasi</h3>
            <p className="text-sm text-[#858585]">
              Titik kumpul, shelter, dan fasilitas kesehatan dengan dukungan offline.
            </p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-[#D9E0E5]/60 shadow-xs">
            <div className="w-10 h-10 rounded-xl bg-[#FFF3E6] text-[#F07800] flex items-center justify-center font-bold text-lg mb-4">
              👥
            </div>
            <h3 className="font-bold text-base mb-1.5">Komunitas Siaga</h3>
            <p className="text-sm text-[#858585]">
              Feed lokal & nasional terkurasi dengan sistem moderasi terpercaya.
            </p>
          </div>

          <div className="bg-white p-6 rounded-2xl border border-[#D9E0E5]/60 shadow-xs">
            <div className="w-10 h-10 rounded-xl bg-[#FFD9D9] text-[#FF4D52] flex items-center justify-center font-bold text-lg mb-4">
              🆘
            </div>
            <h3 className="font-bold text-base mb-1.5">Respon Cepat SOS</h3>
            <p className="text-sm text-[#858585]">
              Bantuan darurat terverifikasi dengan perlindungan privasi lokasi tepat.
            </p>
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full border-t border-[#D9E0E5] bg-white py-6">
        <div className="max-w-6xl mx-auto px-6 flex flex-col sm:flex-row items-center justify-between text-xs text-[#858585] gap-3">
          <p>© 2026 Siagaku / Wero. Seluruh hak cipta dilindungi.</p>
          <div className="flex gap-4">
            <span>Flutter Mobile App</span>
            <span>•</span>
            <span>Next.js Admin</span>
            <span>•</span>
            <span>Supabase Backend</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
