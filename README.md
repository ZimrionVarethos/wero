<p align="center">
  <img src="assets/images/logodantulisan.png" alt="Wero - Emergency & Disaster Preparedness" width="300">
</p>

<h3 align="center">Tahu apa yang terjadi. Tahu ke mana harus pergi.</h3>

<p align="center">
  Platform kesiapsiagaan dan tanggap darurat bencana berbasis spasial dan komunitas untuk Indonesia.<br>
  Peringatan dini otomatis BMKG, peta evakuasi offline mandiri sinyal, tombol darurat SOS relawan terdekat, serta dasbor komando terverifikasi.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.24+-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Next.js-16.4-black?style=flat-square&logo=nextdotjs&logoColor=white" alt="Next.js">
  <img src="https://img.shields.io/badge/Supabase-PostGIS-3ECF8E?style=flat-square&logo=supabase&logoColor=white" alt="Supabase">
  <img src="https://img.shields.io/badge/Google_Gemini-Flash_AI-4285F4?style=flat-square&logo=google&logoColor=white" alt="Google Gemini">
  <img src="https://img.shields.io/badge/Firebase-FCM_v1-FFCA28?style=flat-square&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat-square" alt="License">
</p>

<p align="center">
  <a href="#-latar-belakang--masalah">Latar Belakang</a> ·
  <a href="#-alur-kerja-sistem-architecture--flow">Arsitektur & Flow</a> ·
  <a href="#-fitur-unggulan">Fitur Unggulan</a> ·
  <a href="#-tech-stack">Tech Stack</a> ·
  <a href="#-dasbor-petugas--pusat-komando">Dasbor Petugas</a> ·
  <a href="#-instalasi--panduan-menjalankan">Panduan Menjalankan</a> ·
  <a href="#-keamanan--privasi-data">Keamanan & Privasi</a>
</p>

---

## 📌 Latar Belakang & Masalah

Indonesia berada di kawasan *Ring of Fire* yang setiap saat menghadapi ancaman gempa bumi tektonik, tsunami, banjir bandang, erupsi vulkanik, dan tanah longsor. Dalam penanganan darurat bencana di lapangan, terdapat 3 kendala fatal:

1. **Infrastruktur Telekomunikasi Runtuh (Zero Signal Dilemma)**: Sesaat setelah bencana besar, BTS seluler roboh atau listrik padam. Aplikasi pemetaan umum gagal memuat peta dan rute evakuasi.
2. **Keterlambatan Penolong Pertama (Golden Time Loss)**: Petugas evakuasi resmi (Basarnas/BPBD) membutuhkan waktu mobilisasi ke titik lokasi. Korban paling berpeluang selamat apabila ditolong oleh warga atau relawan dalam radius terdekat di jam pertama.
3. **Peringatan yang Terlambat & Tidak Terarah**: Notifikasi sering terlambat masuk, atau berupa informasi umum yang tidak memberikan instruksi taktis tindakan langsung.

**Wero** (*We Relief Operations*) dirancang sebagai ekosistem penyelamatan terintegrasi antara **Warga**, **Relawan Sekitar**, dan **Pusat Komando Petugas** yang tetap berfungsi optimal bahkan saat koneksi internet terputus total.

---

## 🔄 Alur Kerja Sistem (Architecture & Flow)

### 1. Siklus Peringatan Otomatis BMKG & Push Alert 4-Tier
```mermaid
sequenceDiagram
    autonumber
    participant BMKG as Server BMKG TEWS
    participant Cron as Supabase pg_cron (2 Menit)
    participant API as Web API /api/bmkg/cron
    participant DB as Supabase PostgreSQL
    participant FCM as Firebase Cloud Messaging
    participant Mobile as Aplikasi Wero Warga

    Cron->>API: HTTP Trigger autonomous check
    API->>BMKG: Fetch autogempa.json terkini
    BMKG-->>API: Data magnitudo, koordinat, potensi tsunami
    API->>DB: Ingest ke public.disaster_events
    API->>FCM: Dispatch push notifikasi darurat (HTTP v1)
    FCM-->>Mobile: High-priority Push (Heads-up alert)
    DB-->>Mobile: Realtime WebSocket Postgres Changes
    Note over Mobile: Deduplikasi ID mencegah sirine ganda.<br>Aktifkan audio sirine + getaran hardware ritmik.<br>Log masuk seketika tanpa jeda.
```

### 2. Siklus SOS Warga & Respon Relawan Terdekat
```mermaid
flowchart TD
    A[Warga Dalam Bahaya] -->|Tekan Tahan Tombol SOS 2 Detik| B(GPS Terkunci Presisi)
    B --> C{Pilihan Mode SOS}
    C -->|Publik| D[Siaran Radius 100 Meter]
    C -->|Privat| E[Hanya Masuk ke Dasbor Petugas]

    D --> F[Marker Merah Berdenyut di Peta Warga Lain]
    F --> G[Warga/Relawan Ketuk Titik Korban]
    G --> H[Pilih: Ambil Aksi Tolong]
    H --> I[Navigasi Rute Langsung ke Korban]
    
    D --> J[Dasbor Petugas BPBD/Relawan]
    E --> J
    J --> K[Petugas Verifikasi & Kerahkan Bantuan]
    K --> L[Admin Tandai: Bantuan Tuntas]
    L -->|Sinkronisasi Realtime| M[Status SOS di HP Korban Otomatis Selesai & Aman]
```

### 3. Arsitektur Peta Evakuasi Offline (Zero-Signal Resilience)
```mermaid
graph LR
    Online[Saat Terhubung Internet] -->|Unduh Radius 15 KM| CacheEngine[EvacuationCacheService]
    CacheEngine --> MapTiles[(Cache Mapbox Tiles)]
    CacheEngine --> Shelters[(Cache Posko & Faskes)]
    CacheEngine --> Guides[(Cache Panduan Darurat)]

    Offline[Saat Sinyal Hilang Total] --> Reader[Offline Map View]
    MapTiles -.-> Reader
    Shelters -.-> Reader
    Guides -.-> Reader
    Reader --> SafeAction[Warga Tetap Tahu Arah Shelter & Titik Kumpul Aman]
```

---

## ✨ Fitur Unggulan

| Modul | Deskripsi Solusi | Implementasi Teknis |
| :--- | :--- | :--- |
| **Peta Evakuasi Offline** | Mengunduh peta ubin (tile) radius 15 km beserta metadata posko evakuasi & rute. Tetap interaktif dan akurat saat sinyal mati. | `flutter_map_cache`, local storage caching, spatial distance sorting. |
| **Multi-Tier BMKG Early Warning** | Klasifikasi ancaman otomatis 4 tingkat: **AWAS** (M≥7.0 / Tsunami), **SIAGA** (M≥6.0), **WASPADA** (M≥5.0), dan **INFO** disertai instruksi penyelamatan BNPB. | Parsing real-time BMKG TEWS, kalkulasi magnitudo & kedalaman, audio loop alarm, hardware vibrator channel. |
| **Tombol Darurat SOS & Relawan** | Mode publik membunyikan radar 100m ke sesama warga sekitar. Relawan dapat mengambil misi tolong dan menerima navigasi rute langsung ke titik korban. | PostGIS spatial queries, animated pulse markers, Realtime broadcast synchronizer. |
| **Asisten Siaga AI (Gemini Flash)** | Tanya-jawab taktis pertolongan pertama, simulasi gempa, atau panduan evakuasi. Dilengkapi fallback panduan offline saat internet padam. | Google Gemini Flash via backend proxy API, context-grounded prompt, offline protocol fallback. |
| **Log Notifikasi Interaktif** | Riwayat siaran dapat dibaca per balok dan mendukung gestur geser untuk menghapus (*swipe-to-dismiss*), yang seketika mengheningkan sirine aktif. | Dismissible card, atomic deduplication, `NotificationDismissService` persistent storage. |
| **Dasbor Komando Multi-Peran** | Monitoring SOS terpusat, siaran manual per wilayah, manajemen titik evakuasi spasial, serta audit trail dengan rantai kriptografi hash. | Next.js 16, MapLibre GL, Three.js 3D Coastal Simulation, Role-Based Access Control (RBAC). |

---

## 💻 Tech Stack

### 📱 Mobile Application (Flutter)
- **Framework**: Flutter 3.24+ (Dart 3.5+)
- **State Management**: Flutter Riverpod 2.5 (`NotifierProvider`, `AsyncNotifier`, family providers)
- **Routing**: GoRouter (Declarative typed routing)
- **Mapping & Geospasial**: `flutter_map` v7, `latlong2`, Mapbox GL Raster Tiles, `geolocator`
- **Audio & Haptic**: `audioplayers` (Streamed loop alarm), Android Native MethodChannel (`com.siagaku.wero/vibration`)
- **Desain & Tipografi**: Google Fonts Poppins, Desain visual bertema Navy & Safety Orange

### 🌐 Web & Dasbor Komando (Next.js)
- **Framework**: Next.js 16.4 (App Router, Turbopack) & React 19
- **Styling**: Tailwind CSS 4, Vanilla CSS Design Tokens
- **Peta Dasbor**: MapLibre GL, Mapbox API
- **Visualisasi 3D**: Three.js (Simulasi kota pesisir, tsunami, dan gempa)
- **Koneksi Database**: `pg` Connection Pooler via Port 6543 (Transaction Mode)

### ☁️ Backend, Cloud & Database
- **Database Utama**: Supabase PostgreSQL 15 dengan ekstensi **PostGIS**
- **Autonomous Worker**: Supabase `pg_cron` & `pg_net` (Pengecekan gempa berkala tiap 2 menit tanpa beban server eksternal)
- **Push Notification**: Firebase Cloud Messaging (FCM HTTP v1 via Service Account Admin)
- **Kecerdasan Buatan**: Google Gemini AI API (`gemini-flash-lite-latest`)
- **Hosting Web & API**: Vercel Serverless Platform
- **CI/CD Pipeline**: GitHub Actions (`build_ios.yml`, `bmkg_cron.yml`)

---

## 🛡️ Dasbor Petugas & Pusat Komando

Pusat kendali petugas dapat diakses melalui rute `/admin` pada web portal dengan sistem autentikasi dan peran berbasis wewenang:

1. **Role-Based Scoping**:
   - `SUPER_ADMIN`: Memantau dan mengelola siaran ke seluruh wilayah nasional Indonesia.
   - `GOVERNMENT_ADMIN` (BPBD Kota/Kabupaten): Hanya dapat menyiarkan informasi dan memantau status darurat di yurisdiksi wilayahnya.
   - `COMMUNITY_MODERATOR`: Mengelola pelaporan postingan warga di forum komunitas.
2. **Kerahasiaan Lokasi Korban (Privacy Safeguards)**:
   - Pada pemantauan umum, koordinat korban disamarkan (*fuzzy coordinates*).
   - Koordinat presisi hanya terbuka saat petugas resmi membuka detail kasus, dan setiap aksi pembukaan lokasi tepat dicatat ke tabel `audit_logs`.
3. **Audit Trail Berantai Kriptografi**:
   - Setiap aksi penting (siaran darurat, resolusi kasus SOS, penghapusan data) di-hash bersama hash rekaman sebelumnya (*cryptographic chain hash*) sehingga manipulasi log dapat dideteksi.

---

## 🚀 Panduan Menjalankan

### Persyaratan Lingkungan:
- Flutter SDK (≥ 3.24.0) & Dart SDK
- Node.js (≥ 20.0.0) & npm
- Akun Supabase (PostgreSQL)

### 1. Menjalankan Backend & Web Admin
```bash
# Masuk ke direktori web
cd web

# Pasang dependensi
npm install

# Buat file konfigurasi lokal
cp .env.example .env.local
```

Sesuaikan nilai environment di `web/.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
DATABASE_URL=postgresql://postgres.xxx:password@aws-0-ap-southeast-2.pooler.supabase.com:6543/postgres
NEXT_PUBLIC_MAPBOX_TOKEN=pk.your-mapbox-token
GEMINI_API_KEY=your-gemini-api-key
GEMINI_MODEL=gemini-flash-lite-latest
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}
```

Jalankan server pengembangan:
```bash
npm run dev
```
- Landing Page & APK Download: `http://localhost:3000`
- Dasbor Petugas: `http://localhost:3000/admin`

### 2. Mengaktifkan Autonomous Worker BMKG (Supabase SQL)
Jalankan skrip berikut di **SQL Editor Supabase**:
```sql
create extension if not exists pg_net;
create extension if not exists pg_cron;

select cron.schedule(
  'wero-bmkg-sync-every-2min',
  '*/2 * * * *',
  $$ select net.http_get(url := 'https://your-domain.vercel.app/api/bmkg/cron'); $$
);
```

### 3. Menjalankan Aplikasi Mobile (Flutter)
```bash
# Kembali ke direktori utama
cd ..

# Ambil dependensi
flutter pub get

# Jalankan pada Android Emulator / Device fisik
flutter run --dart-define=BACKEND_URL=https://wero-mu.vercel.app

# Atau compile Release APK
flutter build apk --release --no-tree-shake-icons
```
Output APK berada di `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔒 Keamanan & Privasi Data

- **Penyimpanan Kunci API Terlindungi**: Kredensial sensitif seperti Service Account Firebase, Database Pooler Connection, dan Gemini API Key tersimpan aman di environment server dan tidak pernah terekspos di sisi klien.
- **Enkripsi Transit & Istirahat**: Semua komunikasi mobile ke backend dilindungi enkripsi HTTPS / TLS 1.3, dan data tersimpan menerapkan Row Level Security (RLS) PostgreSQL.
- **Standar Protokol Kebencanaan**: Semua konten edukasi, respon peringatan dini, dan alur evakuasi diselaraskan dengan panduan resmi BNPB, BMKG, dan Basarnas.

---

<p align="center">
  <img src="assets/images/logo.png" alt="Wero Icon" width="48"><br>
  <b>Wero</b> · Tanggap Bersama, Selamatkan Sesama.<br>
  <sub>Dikembangkan untuk Solusi Kemanusiaan & Kesiapsiagaan Bencana Indonesia.</sub>
</p>
