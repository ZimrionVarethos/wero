# 🚨 Siagaku (Wero) — Integrated Disaster Emergency Response & Spatial Operations Platform

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-16_App_Router-000000?style=for-the-badge&logo=next.js&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL_PostGIS-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Mapbox](https://img.shields.io/badge/Mapbox-GL_JS_3D-000000?style=for-the-badge&logo=mapbox&logoColor=white)
![Gemini AI](https://img.shields.io/badge/Google_Gemini-2.5_Flash-8E75C2?style=for-the-badge&logo=google&logoColor=white)
![Tests](https://img.shields.io/badge/Tests-56%2F56_Passing-success?style=for-the-badge)
![Code Quality](https://img.shields.io/badge/Flutter_Analyze-0_Issues-brightgreen?style=for-the-badge)

**Platform Terintegrasi Kesiapsiagaan Bencana, Respon Cepat Darurat SOS, Peta Taktis Operasi, & AI Kebencanaan Berstandar BNPB, BMKG, dan BASARNAS**

[Ringkasan Eksekutif](#-ringkasan-eksekutif--latar-belakang) •
[Fitur Unggulan](#-fitur-unggulan) •
[Alur Kerja Pengguna](#-alur-kerja-aplikasi-user-flow) •
[Arsitektur Sistem](#-arsitektur-sistem--tech-stack) •
[Panduan Instalasi](#-panduan-instalasi--menjalankan-aplikasi)

</div>

---

## 📌 Ringkasan Eksekutif & Latar Belakang

Indonesia terletak di kawasan Cincin Api Pasifik (*Ring of Fire*) yang merupakan pertemuan tiga lempeng tektonik aktif dunia. Kondisi geologis ini menjadikan Indonesia rentan terhadap gempa bumi berkekuatan tinggi, potensi megathrust, tsunami, letusan gunung api, banjir bandang, dan tanah longsor.

### Masalah Nyata di Lapangan Saat Bencana:
1. **Kepanikan Keluarga & Kemacetan Sinyal:** Saat bencana terjadi, warga kesulitan mengetahui apakah anggota keluarga mereka selamat, sedang mengungsi, atau membutuhkan pertolongan medis darurat.
2. **Ketiadaan Koordinat Presisi pada Panggilan SOS:** Banyak panggilan darurat yang masuk ke tim penolong tanpa data lokasi yang akurat, memperlambat proses evakuasi di jam-jam emas (*golden hours*).
3. **Maraknya Berita Bohong & Hoaks:** Misinformasi mengenai prediksi gempa susulan atau kabar evakuasi palsu sering menyebar liar di media sosial, memicu kepanikan massal.
4. **Data Posko Pengungsian Terfragmentasi:** Warga sering mengungsi ke tempat yang sudah kelebihan kapasitas (*overcapacity*) karena tidak adanya visibilitas kapasitas real-time posko, fasilitas dapur umum, dan ketersediaan logistik.

### Solusi Inovatif Siagaku:
**Siagaku** hadir sebagai ekosistem digital kesiapsiagaan bencana komprehensif dua arah:
* **Mobile/Web Application Warga (Citizen & Volunteer Hub):** Menyediakan peringatan dini BMKG real-time, panduan mitigasi offline, asisten AI tanggap darurat, family check-in keluarga, tombol SOS wajib GPS, serta feed warta komunitas lokal.
* **Web Emergency Operations Center (EOC Portal Petugas):** Portal kendali komando bagi admin/BPBD/relawan untuk memantau radar panggilan SOS langsung di atas peta spasial Mapbox 3D, memvalidasi dan mengelola fasilitas posko evakuasi (CRUD), serta memoderasi laporan komunitas anti-hoaks.

---

## 🌟 Fitur Unggulan

### 1. Asisten AI Siaga Bencana (Siaga AI — Gemini 2.5 Flash)
* **Protokol Tanggap Darurat Resmi:** Ditenagai oleh Google Gemini Flash yang diprogram dengan *system instruction* khusus berstandar **BNPB, BMKG, dan BASARNAS**. Menyajikan instruksi taktis bernomor, tenang, dan menyertakan nomor darurat resmi Indonesia (112, 115, 113, 119, 117).
* **Keamanan Tanpa Kebocoran Kunci (Zero-Leak Security):** Backend obrolan AI dipindahkan ke server web Next.js (`/api/assistant/chat`). Kunci API tidak pernah terekspos di sisi client aplikasi mobile/web.
* **Offline Survival Fallback:** Tetap dapat memberikan panduan keselamatan gempa, tsunami, banjir, dan nomor telepon darurat penting secara instan meski jaringan internet padam pasca-bencana.

### 2. Peringatan Dini Real-Time BMKG & Shakemap TEWS
* **Integrasi Open Data BMKG:** Menghubungkan feed resmi BMKG TEWS (`autogempa.json` dan `gempadirasakan.json`).
* **Server-Side Proxy & Caching:** Endpoint `/api/bmkg` di server web menerapkan in-memory caching 25 detik untuk meringankan beban perangkat, menghemat kuota pengguna, serta mengatasi isu pembatasan CORS peramban.
* **Klasifikasi Bahaya Otomatis:**
  * **AWAS / AWAS TSUNAMI (Merah):** Magnitudo $\ge 6.5$ atau terdeteksi potensi tsunami.
  * **SIAGA (Oranye):** Magnitudo $5.0 \le M < 6.5$.
  * **WASPADA (Kuning):** Magnitudo $< 5.0$.
* **Protokol Keselamatan Terpadu:** Menyajikan visualisasi peta guncangan (*shakemap*) resolusi tinggi serta instruksi mitigasi resmi BNPB (*Drop, Cover, Hold On*).

### 3. Peta Taktis Operasi & Navigasi Posko Evakuasi (PostGIS & Mapbox 3D)
* **Pemetaan Fasilitas Evakuasi:** Titik posko pengungsian (`SHELTER`), titik kumpul terbuka (`ASSEMBLY`), fasilitas kesehatan/RS rujukan (`HEALTH`), dan gudang logistik (`LOGISTICS`).
* **Mapbox 3D Extrusion & Layer Interaktif:** Tampilan visual bangunan 3D, layer satelit, serta penyesuaian rute aman.
* **Sinkronisasi Geospasial PostGIS:** Perhitungan otomatis koordinat lintang/bujur dan radius jarak evakuasi dari posisi pengguna menggunakan PostgreSQL PostGIS spatial indexing.

### 4. Panggilan Darurat SOS dengan Penegakan GPS Wajib (*Hard Enforcement*)
* **Verifikasi GPS Keras:** Pengguna **dilarang mengirim sinyal SOS** jika layanan GPS perangkat mati atau izin lokasi ditolak. Aplikasi otomatis membuka pengaturan perangkat untuk mengaktifkan GPS.
* **Kunci Koordinat Asli Satelit:** Memastikan setiap sinyal darurat yang disiarkan ke pusat komando memuat koordinat satelit riil korban.
* **Radar Darurat Animasi:** Menampilkan sinyal SOS berkedip (*blinking red radar beacon*) secara live pada peta komando petugas.

### 5. Kerabat Siaga & Family Check-in
* **Jaringan Keselamatan Keluarga:** Pengguna dapat mendaftarkan kontak darurat keluarga dan memantau status keselamatan secara instan:
  * `SELAMAT` (Hijau)
  * `SEDANG EVAKUASI` (Oranye)
  * `BUTUH BANTUAN` (Merah — menyertakan koordinat GPS terkini)
* **Direktori Hotline Darurat Nasional:** Akses cepat satu ketukan untuk melakukan panggilan langsung ke 112 (Darurat Umum), 115 (Basarnas), 113 (Damkar), 119 (Medis/Ambulan), dan 117 (BNPB).

### 6. Web Emergency Operations Center (EOC Admin Portal)
* **CRUD Manajemen Posko Evakuasi:** Menambah, mengubah status kesiapan, kapasitas daya tampung, dan fasilitas shelter (dapur umum, genset, air bersih).
* **Live Monitoring SOS & Resolusi Kasus:** Memantau panggilan darurat masuk dan menandai status penanganan menjadi `RESOLVED` setelah tim penolong tiba di lokasi.
* **Siaran Darurat Wilayah (Broadcast Hazard):** BPBD/Petugas dapat menyiarkan instruksi evakuasi massal ke seluruh pengguna di wilayah terdampak.

### 7. Komunitas Siaga & Sistem Moderasi Anti-Hoaks
* **Feed Warta Warga Lokal:** Warga dapat membagikan laporan kondisi jalan, banjir, dan ketersediaan logistik di wilayahnya.
* **Mitigasi Hoaks Otomatis:** Sistem database Supabase memicu status `HIDDEN_PENDING_REVIEW` secara otomatis jika sebuah postingan menerima laporan warga mencapai ambang batas (*threshold* 5 akun).
* **Audit Trail Transparan:** Tim moderator dapat memeriksa bukti laporan, melakukan takedown konten, atau memulihkan postingan dengan catatan audit log yang terekam aman.

### 8. Deteksi Wilayah GPS Live pada Profil Pengguna
* **1-Tap Live City Sync:** Pengguna dapat mendeteksi kota/kabupaten domisili siaga bencana dengan satu ketukan tombol GPS.
* **Reverse Geocoding Cerdas:** Menggunakan endpoint `/api/geocode` yang memproses geocoding Mapbox dan mencocokkan (*fuzzy matching*) secara presisi ke tabel wilayah administrasi Indonesia (`public.regions`).

---

## 🔄 Alur Kerja Aplikasi (User Flow)

```mermaid
flowchart TD
    subgraph Warga [Aplikasi Mobile / Web Warga]
        A[Buka Aplikasi] --> B{Pilih Wilayah Siaga}
        B -->|GPS Live / Manual| C[Dashboard Utama]
        C --> D[Pantau Warta Komunitas Lokal]
        C --> E[Notifikasi Gempa Realtime BMKG]
        C --> F[Tanya Jawab Siaga AI]
        C --> G[Family Check-in Keluarga]
        
        E --> H{Status Bahaya?}
        H -->|Tinggi / Tsunami| I[Baca Protokol BNPB & Buka Peta Shelter]
        
        C --> J[Kondisi Kritis Darurat]
        J --> K[Tekan Tahan Tombol SOS 2.5s]
        K --> L{GPS Aktif?}
        L -->|Tidak| M[Wajibkan Pengguna Aktifkan GPS]
        M --> L
        L -->|Ya| N[Kunci Koordinat Asli & Siarkan Sinyal SOS]
    end

    subgraph Server [Backend & Integrasi Layanan]
        N --> O[(Supabase PostGIS DB)]
        O --> P[Trigger Sinyal Darurat Realtime]
        Q[Open Data BMKG] --> R[Web Cache Proxy /api/bmkg]
        R --> E
        S[Google Gemini Flash] --> T[Web API /api/assistant/chat]
        T --> F
    end

    subgraph Petugas [Web Emergency Operations Center]
        P --> U[Peta Taktis Operasi Mapbox 3D]
        U --> V[Radar Merah Berkedip di Titik Korban]
        V --> W[Buka Detail Korban & Navigasi Tim SAR]
        W --> X[Klik Resolve Kasus Darurat]
        
        Y[Kelola Posko Evakuasi CRUD] --> O
        Z[Moderasi Laporan Hoaks Komunitas] --> O
    end
```

### Penjelasan Rinci Alur Kerja:
1. **Fase Pra-Bencana (Kesiapsiagaan & Edukasi):**
   * Warga membuka aplikasi, menyinkronkan kabupaten/kota via deteksi lokasi GPS live, membaca panduan keselamatan offline, serta berkonsultasi mengenai tas siaga bencana dengan Siaga AI.
2. **Fase Saat Terjadi Bencana (Tanggap Darurat):**
   * Feed BMKG mendeteksi gempa bumi terkini secara otomatis. Layar Riwayat & Peringatan menampilkan parameter gempa, shakemap, dan protokol *Drop, Cover, Hold On*.
   * Warga melakukan *Family Check-in* untuk mengabari keluarga bahwa mereka aman atau sedang mengungsi.
   * Bila terjebak dalam reruntuhan atau terkepung banjir, warga menekan tombol SOS. Sistem memastikan GPS aktif, mengunci koordinat satelit, dan mengirim sinyal bahaya ke database PostGIS.
3. **Fase Komando Operasi (Respon Petugas):**
   * Petugas di posko/BPBD melihat sinyal SOS korban di layar monitor Web EOC dengan beacon merah beranimasi radar tepat di atas peta Mapbox 3D.
   * Petugas mengerahkan tim SAR ke titik koordinat, memverifikasi ketersediaan barak posko terdekat, dan menyelesaikan kasus darurat setelah korban dievakuasi.

---

## 🏗 Arsitektur Sistem & Tech Stack

```
wero2/
├── lib/                             # Flutter Mobile & Web Client
│   ├── core/                        # Konfigurasi, error handling, provider Riverpod
│   ├── data/                        # Panduan keselamatan offline, hotline resmi
│   ├── models/                      # Model entitas (BMKG, SOS, Shelter, Community, Family)
│   ├── routing/                     # Navigasi deklaratif terpusat berbasis GoRouter
│   ├── screens/
│   │   ├── activity/                # Beranda: warta komunitas lokal & akses cepat
│   │   ├── assistant/               # Siaga AI obrolan keselamatan BNPB
│   │   ├── community/               # Feed warta bencana, buat laporan, detail postingan
│   │   ├── family/                  # Kerabat Siaga, Family Check-in, Hotline 112
│   │   ├── guides/                  # Buku panduan evakuasi offline
│   │   ├── moderation/              # Antrean audit moderasi laporan komunitas
│   │   ├── operations/              # Peta evakuasi Mapbox, SOS, Riwayat BMKG TEWS
│   │   └── profile/                 # Profil pengguna & dialog pemilihan kota live GPS
│   ├── theme/                       # Design tokens resmi Wero (Warna, Spasi, Tipografi)
│   └── widgets/                     # Komponen UI modular terstandarisasi
├── web/                             # Next.js 16 Web Operations Portal & Backend API
│   ├── src/app/
│   │   ├── admin/                   # Dashboard Pusat Komando EOC (Peta Taktis 3D, SOS, Shelter)
│   │   └── api/
│   │       ├── assistant/chat/      # Server-side Gemini 2.5 Flash Proxy
│   │       ├── bmkg/                # In-memory cached proxy BMKG TEWS
│   │       ├── geocode/             # Reverse geocoding Mapbox + matching PostGIS
│   │       ├── shelters/            # REST API CRUD Posko Evakuasi
│   │       └── sos/                 # REST API Pemantauan Sinyal Darurat
│   └── src/components/admin/        # Komponen peta Mapbox GL JS, ShelterManager, SosMonitor
├── supabase/migrations/             # 9 File migrasi SQL (PostGIS, RLS, Triggers, Storage)
└── test/                            # 56 Pengujian otomatis unit & widget
```

### Komponen Teknologi:
* **Frontend Mobile / Web:** Flutter 3.x (Dart), Riverpod (State Management), GoRouter, LatLong2.
* **Web Portal & Backend Proxy:** Next.js 16 (App Router, React 19, TypeScript, Tailwind CSS, Mapbox GL JS).
* **Database & Geospasial:** Supabase PostgreSQL 15+ dengan ekstensi **PostGIS** untuk kalkulasi geometri spasial native.
* **Artificial Intelligence:** Google Gemini 2.5 Flash dengan sistem instruksi tanggap darurat BNPB/BMKG/BASARNAS.
* **Sumber Data Eksternal:** BMKG Open Data TEWS API & Mapbox Geocoding API.

---

## 🛡 Keamanan, Reliabilitas, & Kepatuhan Kode

1. **Keamanan Kunci Rahasia:** API Key Gemini dan kredensial sensitif diisolasi di lingkungan server web (`web/.env.local`). Tidak ada kunci rahasia yang di-hardcode pada kode aplikasi Flutter.
2. **Row-Level Security (RLS) PostgreSQL:** Setiap tabel dilindungi oleh kebijakan RLS berlapis, memastikan data kontak keluarga dan laporan privat tidak dapat diakses tanpa hak otorisasi yang sah.
3. **Standar Kerapian Kode (AGENTS.md):**
   * Target **$\le 250$ baris kode per file sumber Dart** diterapkan secara ketat.
   * Tidak ada widget raksasa (*god widget*) berkat pemecahan komponen modular dan prinsip tanggung jawab tunggal (*Single Responsibility Principle*).
4. **Verifikasi Kualitas Tanpa Cacat:**
   * Analisis Statis: `flutter analyze` $\rightarrow$ **0 Issues (Bersih)**.
   * Rangkaian Pengujian: `flutter test` $\rightarrow$ **56 / 56 Tests Passed (100% Lulus)**.

---

## 🚀 Panduan Instalasi & Menjalankan Aplikasi

### Prasyarat:
* Flutter SDK $\ge 3.24.0$
* Node.js $\ge 18.0.0$ dan npm
* Akun Supabase (Database PostgreSQL & PostGIS aktif)

### 1. Menjalankan Server Web Portal & Backend Proxy (Next.js)
```bash
# Masuk ke direktori web
cd web

# Instal dependensi
npm install

# Buat file konfigurasi lingkungan (.env.local)
# Pastikan NEXT_PUBLIC_SUPABASE_URL, NEXT_PUBLIC_SUPABASE_ANON_KEY, DATABASE_URL,
# NEXT_PUBLIC_MAPBOX_TOKEN, dan GEMINI_API_KEY telah terisi

# Jalankan server pengembangan
npm run dev
```
* Buka peramban di `http://localhost:3000` untuk Landing Page.
* Buka `http://localhost:3000/admin` untuk Portal Pusat Komando Operasi Tanggap Darurat.

### 2. Menjalankan Aplikasi Mobile / Web Warga (Flutter)
```bash
# Kembali ke direktori root proyek
cd ..

# Ambil paket dependensi Flutter
flutter pub get

# Jalankan analisis statis kode
flutter analyze

# Jalankan seluruh rangkaian pengujian unit & widget
flutter test

# Jalankan aplikasi (pilih target Chrome, Android emulator, atau perangkat fisik)
flutter run -d chrome
```

---

## 🏆 Kesiapan Penilaian Lomba

| Kriteria Penilaian | Implementasi Nyata pada Siagaku |
| :--- | :--- |
| **Relevansi & Dampak Sosial** | Menyelesaikan masalah kritis tanggap darurat bencana di Indonesia: keselamatan keluarga, pencegahan hoaks, dan kecepatan respon evakuasi korban. |
| **Inovasi Teknologi** | Integrasi holistik AI BNPB Gemini 2.5 Flash, Pemetaan Geospasial PostGIS + Mapbox 3D, Feed Realtime BMKG TEWS, dan penegakan GPS keras pada tombol SOS. |
| **Keamanan Data** | Isolasi API Key di server-side proxy, penerapan Row-Level Security (RLS), dan mekanisme perlindungan data darurat keluarga. |
| **Keandalan Saat Krisis** | Arsitektur *offline-first* dengan in-memory caching 25 detik dan panduan mitigasi bencana lokal yang tetap dapat diakses saat internet padam. |
| **Kualitas Rekayasa Perangkat Lunak** | 56 automated tests lulus 100%, 0 warning pada `flutter analyze`, arsitektur modular $\le 250$ baris per file, dan dokumentasi alur sistem yang transparan. |

---

<div align="center">

**Siagaku (Wero) — Tanggap Bersama, Selamatkan Sesama.**  
*Dikembangkan dengan dedikasi untuk ketangguhan bencana dan keselamatan bangsa Indonesia.*

</div>
