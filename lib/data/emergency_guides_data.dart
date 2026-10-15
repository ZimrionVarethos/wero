import '../models/emergency_guide.dart';

/// Bundled offline survival and disaster guides according to official BNPB & BMKG standards.
/// Available 100% offline without requiring internet connectivity.
const List<EmergencyGuide> defaultEmergencyGuides = [
  EmergencyGuide(
    id: 'guide-gempa',
    title: 'Panduan Penyelamatan Gempa Bumi',
    category: GuideCategory.earthquake,
    iconName: 'landslide',
    summary: 'Protokol perlindungan diri saat guncangan gempa tektonik atau vulkanik.',
    emergencyNumbers: ['112 (Panggilan Darurat)', '115 (Basarnas)'],
    phases: [
      GuidePhase(
        phaseName: 'Saat Terjadi Gempa',
        instructions: [
          'Jatuhkan diri ke lantai, lindungi kepala dan leher (Drop, Cover, Hold On).',
          'Berlindung di bawah meja kokoh dan pegang kakinya hingga guncangan reda.',
          'Jauhi jendela kaca, cermin, lemari tinggi, dan benda menggantung.',
          'Jika di luar ruangan, cari tempat terbuka jauh dari tiang listrik dan pohon.',
          'Jangan gunakan lift; gunakan tangga darurat jika gedung dievakuasi.',
        ],
      ),
      GuidePhase(
        phaseName: 'Setelah Guncangan Berhenti',
        instructions: [
          'Periksa potensi kebocoran gas dan matikan meteran listrik utama.',
          'Waspadai gempa susulan (aftershock) yang berpotensi meruntuhkan struktur retak.',
          'Gunakan sepatu tebal untuk menghindari serpihan kaca dan puing tajam.',
          'Pantau informasi resmi BMKG dan jangan terpengaruh rumor hoaks.',
        ],
      ),
    ],
  ),
  EmergencyGuide(
    id: 'guide-banjir',
    title: 'Panduan Evakuasi Banjir & Cuaca Ekstrem',
    category: GuideCategory.flood,
    iconName: 'flood',
    summary:
        'Langkah mitigasi menghadapi kenaikan debit air dan evakuasi mandiri.',
    emergencyNumbers: ['112 (Darurat)', '115 (Basarnas)', '117 (BNPB)'],
    phases: [
      GuidePhase(
        phaseName: 'Sebelum Air Naik',
        instructions: [
          'Amankan dokumen penting dalam kantong plastik kedap air (Tas Siaga).',
          'Tinggikan barang elektronik dan perabotan ke lantai atas.',
          'Ketahui rute evakuasi menuju tempat penampungan sementara terdekat.',
        ],
      ),
      GuidePhase(
        phaseName: 'Saat Air Menggenang',
        instructions: [
          'Segera matikan sakelar meteran listrik rumah untuk cegah sengatan arus.',
          'Jangan berjalan atau berkendara di arus banjir setinggi lebih dari 15 cm.',
          'Gunakan tongkat untuk mendeteksi kedalaman dan lubang saluran air.',
          'Segera evakuasi anak-anak, lansia, dan kelompok rentan ke tempat aman.',
        ],
      ),
    ],
  ),
  EmergencyGuide(
    id: 'guide-kebakaran',
    title: 'Protokol Evakuasi Kebakaran & Asap',
    category: GuideCategory.fire,
    iconName: 'fire',
    summary:
        'Tindakan bertahan hidup saat terjadi kebakaran gedung atau pemukiman.',
    emergencyNumbers: ['113 (Pemadam Kebakaran)', '112 (Darurat Bebas Pulsa)'],
    phases: [
      GuidePhase(
        phaseName: 'Saat Muncul Api & Asap',
        instructions: [
          'Basahi kain atau masker dengan air lalu tutup hidung dan mulut.',
          'Merayap serendah mungkin dekat lantai karena udara bersih berada di bawah.',
          'Raba pintu dengan punggung tangan; jika panas, jangan dibuka!',
          'Tutup pintu di belakang Anda untuk memperlambat penyebaran api dan asap.',
          'Jika pakaian terbakar: Berhenti, Jatuhkan diri, dan Berguling (Stop, Drop, Roll).',
        ],
      ),
    ],
  ),
  EmergencyGuide(
    id: 'guide-tsunami',
    title: 'Protokol Evakuasi Cepat Tsunami',
    category: GuideCategory.tsunami,
    iconName: 'tsunami',
    summary:
        'Penyelamatan diri pasca gempa besar pesisir (Golden Time 20 Menit).',
    emergencyNumbers: ['112 (Darurat)', '115 (Basarnas)'],
    phases: [
      GuidePhase(
        phaseName: 'Tanda Peringatan Awal',
        instructions: [
          'Gempa kuat (>20 detik) di pesisir adalah peringatan alami tsunami pertama.',
          'Air laut surut drastis secara tiba-tiba dan bau asin menyengat.',
          'Suara gemuruh keras dari arah laut lepas.',
        ],
      ),
      GuidePhase(
        phaseName: 'Tindakan Evakuasi Segera',
        instructions: [
          'Segera lari menuju dataran tinggi (minimal 20 meter di atas laut) atau 2 km ke daratan.',
          'Jangan menunggu sirine resmi berbunyi jika sudah melihat tanda alam.',
          'Jangan gunakan mobil karena jalan pesisir rentan macet parah.',
        ],
      ),
    ],
  ),
  EmergencyGuide(
    id: 'guide-p3k',
    title: 'Pertolongan Pertama Darurat (P3K)',
    category: GuideCategory.firstAid,
    iconName: 'health',
    summary: 'Tindakan penanganan cepat pendarahan hebat, luka bakar, dan patah tulang.',
    emergencyNumbers: ['119 (Ambulans Darurat)', '112 (Layanan Darurat)'],
    phases: [
      GuidePhase(
        phaseName: 'Penanganan Pendarahan Luar',
        instructions: [
          'Tekan langsung luka dengan kain bersih atau kasa steril selama 10 menit.',
          'Posisikan bagian yang terluka lebih tinggi dari jantung jika memungkinkan.',
          'Jangan cabut benda tajam yang tertancap di tubuh; ganjal di sekelilingnya.',
        ],
      ),
      GuidePhase(
        phaseName: 'Luka Bakar Panas',
        instructions: [
          'Aliri luka dengan air bersih bersuhu normal selama 15-20 menit.',
          'Jangan gunakan es batu, pasta gigi, mentega, atau minyak karena memperparah luka.',
          'Tutup luka dengan kain bersih lembap dan bawa ke fasilitas medis.',
        ],
      ),
    ],
  ),
];
