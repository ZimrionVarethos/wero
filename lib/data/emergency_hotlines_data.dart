/// Static repository of verified national emergency hotline services in Indonesia.
class EmergencyHotline {
  const EmergencyHotline({
    required this.number,
    required this.title,
    required this.agency,
    required this.description,
    required this.category,
  });

  final String number;
  final String title;
  final String agency;
  final String description;
  final String category;
}

const nationalEmergencyHotlines = <EmergencyHotline>[
  EmergencyHotline(
    number: '112',
    title: 'Layanan Darurat Terpadu',
    agency: 'Kemenkominfo & Pemerintah Daerah',
    description: 'Panggilan tunggal darurat kebakaran, medis, dan bencana (Bebas pulsa).',
    category: 'INTEGRATED',
  ),
  EmergencyHotline(
    number: '115',
    title: 'Pencarian & Pertolongan (SAR)',
    agency: 'Basarnas Indonesia',
    description:
        'Evakuasi darurat korban tenggelam, longsor, dan reruntuhan bencana.',
    category: 'RESCUE',
  ),
  EmergencyHotline(
    number: '119',
    title: 'Ambulans & Gawat Darurat Medis',
    agency: 'Kementerian Kesehatan RI',
    description:
        'Bantuan medis darurat, pertolongan pertama, dan armada ambulans.',
    category: 'MEDICAL',
  ),
  EmergencyHotline(
    number: '117',
    title: 'Posko Penanggulangan Bencana',
    agency: 'BNPB (Badan Nasional Penanggulangan Bencana)',
    description:
        'Pusdalops BNPB untuk koordinasi tanggap darurat dan logistik.',
    category: 'DISASTER',
  ),
  EmergencyHotline(
    number: '110',
    title: 'Kepolisian RI',
    agency: 'Polri',
    description:
        'Laporan keamanan, pengamanan jalur evakuasi, dan darurat hukum.',
    category: 'POLICE',
  ),
  EmergencyHotline(
    number: '113',
    title: 'Pemadam Kebakaran',
    agency: 'Dinas Pemadam Kebakaran & Penyelamatan',
    description: 'Kebakaran pemukiman/hutan, evakuasi pohon tumbang, penyelamatan darurat.',
    category: 'FIRE',
  ),
  EmergencyHotline(
    number: '129',
    title: 'Posko Bencana Geologi & Vulkanologi',
    agency: 'PVMBG / Badan Geologi ESDM',
    description:
        'Informasi aktivitas gunung api, gempa bumi, dan tanah longsor.',
    category: 'DISASTER',
  ),
];
