import '../data/emergency_guides_data.dart';
import '../models/chat_message.dart';
import '../models/emergency_guide.dart';

/// Predefined responses and action templates for the disaster assistant.
class AiDisasterResponses {
  const AiDisasterResponses._();

  static EmergencyGuide? _find(String id) {
    try {
      return defaultEmergencyGuides.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  static ChatMessage earthquake(String id) {
    final guide = _find('guide-gempa');
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          '⚠️ **Protokol Penyelamatan Gempa Bumi (BNPB/BMKG):**\n\n'
          '1. **Drop, Cover, Hold On:** Segera jatuhkan diri ke lantai, lindungi kepala & leher.\n'
          '2. **Berlindung:** Masuk ke bawah meja kokoh dan pegang kakinya sampai guncangan reda.\n'
          '3. **Jauhi Bahaya:** Hindari jendela kaca, lemari tinggi, dan lampu gantung.\n'
          '4. **Setelah Guncangan:** Matikan kompor gas & meteran listrik utama, gunakan tangga darurat (JANGAN pakai lift).\n'
          '5. **Waspadai:** Gempa susulan (*aftershock*) berpotensi meruntuhkan struktur retak.',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      relatedGuideId: 'guide-gempa',
      suggestedActions: [
        if (guide != null)
          ChatAction(
            label: 'Panduan Gempa Lengkap',
            route: '/guides/detail',
            routeExtra: guide,
            iconName: 'menu_book',
          ),
        const ChatAction(
          label: 'Panggil 115 Basarnas',
          phoneNumber: '115',
          iconName: 'phone',
        ),
      ],
    );
  }

  static ChatMessage flood(String id) {
    final guide = _find('guide-banjir');
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          '🌊 **Protokol Evakuasi Banjir & Cuaca Ekstrem:**\n\n'
          '1. **Matikan Listrik:** Segera turunkan sakelar MCB listrik utama rumah.\n'
          '2. **Amankan Dokumen:** Bawa Tas Siaga Bencana (Go-Bag) dalam kantong plastik kedap air.\n'
          '3. **Hindari Arus:** Jangan berjalan atau berkendara di arus air setinggi lebih dari 15 cm.\n'
          '4. **Gunakan Tongkat:** Raba pijakan untuk mendeteksi saluran air atau lubang terbuka.\n'
          '5. **Evakuasi:** Utamakan lansia, anak-anak, dan ibu hamil ke tempat aman.',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      relatedGuideId: 'guide-banjir',
      suggestedActions: [
        if (guide != null)
          ChatAction(
            label: 'Panduan Banjir Lengkap',
            route: '/guides/detail',
            routeExtra: guide,
            iconName: 'menu_book',
          ),
        const ChatAction(
          label: 'Peta Titik Evakuasi',
          route: '/evacuation',
          iconName: 'map',
        ),
      ],
    );
  }

  static ChatMessage fire(String id) {
    final guide = _find('guide-kebakaran');
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          '🔥 **Protokol Evakuasi Kebakaran & Asap Tebal:**\n\n'
          '1. **Merayap Rendah:** Udara bersih berada di bawah lantai, merayaplah serendah mungkin.\n'
          '2. **Tutup Hidung & Mulut:** Gunakan kain basah atau masker lembap.\n'
          '3. **Periksa Pintu:** Sentuh gagang pintu dengan punggung tangan. Jika panas, JANGAN dibuka!\n'
          '4. **Tutup Pintu di Belakang:** Memperlambat pasokan oksigen ke titik api.\n'
          '5. **Jika Pakaian Terbakar:** Berhenti, Jatuhkan Diri, dan Berguling (*Stop, Drop, Roll*).',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      relatedGuideId: 'guide-kebakaran',
      suggestedActions: [
        if (guide != null)
          ChatAction(
            label: 'Panduan Kebakaran',
            route: '/guides/detail',
            routeExtra: guide,
            iconName: 'menu_book',
          ),
        const ChatAction(
          label: 'Panggil 113 Damkar',
          phoneNumber: '113',
          iconName: 'phone',
        ),
      ],
    );
  }

  static ChatMessage tsunami(String id) {
    final guide = _find('guide-tsunami');
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          '🚨 **Protokol Evakuasi Cepat Tsunami (Golden Time 20 Menit):**\n\n'
          '1. **Tanda Awal:** Gempa pesisir kuat >20 detik atau air laut surut drastis.\n'
          '2. **Lari Segera:** Lari ke tempat tinggi (minimal 20 meter dpl) atau 2 km ke daratan.\n'
          '3. **Hindari Mobil:** Gunakan jalan kaki atau lari untuk menghindari macet pesisir.\n'
          '4. **Waspadai Gelombang Lanjutan:** Gelombang kedua seringkali lebih merusak.',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      relatedGuideId: 'guide-tsunami',
      suggestedActions: [
        if (guide != null)
          ChatAction(
            label: 'Panduan Tsunami',
            route: '/guides/detail',
            routeExtra: guide,
            iconName: 'menu_book',
          ),
        const ChatAction(
          label: 'Peta Dataran Tinggi',
          route: '/evacuation',
          iconName: 'map',
        ),
      ],
    );
  }

  static ChatMessage firstAid(String id) {
    final guide = _find('guide-p3k');
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          '🩹 **Protokol Pertolongan Pertama Gawat Darurat (P3K):**\n\n'
          '• **Pendarahan:** Tekan luka dengan kain bersih minimal 10 menit terus menerus.\n'
          '• **Benda Tertancap:** JANGAN mencabut benda tajam; ganjal di sekelilingnya.\n'
          '• **Luka Bakar:** Aliri air bersih normal 15-20 menit. Hindari pasta gigi atau es.\n'
          '• **Patah Tulang:** Pasang bidai darurat dan jangan paksa meluruskan anggota gerak.',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      relatedGuideId: 'guide-p3k',
      suggestedActions: [
        if (guide != null)
          ChatAction(
            label: 'Buku Saku P3K',
            route: '/guides/detail',
            routeExtra: guide,
            iconName: 'menu_book',
          ),
        const ChatAction(
          label: 'Panggil 119 Medis',
          phoneNumber: '119',
          iconName: 'phone',
        ),
      ],
    );
  }

  static ChatMessage goBag(String id) {
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          '🎒 **Isi Wajib Tas Siaga Bencana (Go-Bag 72 Jam):**\n\n'
          '1. **Dokumen:** KTP, KK, akta dalam kantong kedap air.\n'
          '2. **Konsumsi:** Air minum 3L/orang dan makanan instan tahan lama.\n'
          '3. **P3K & Obat:** Antiseptik, perban, obat pribadi rutin.\n'
          '4. **Alat:** Senter LED + baterai cadangan, peluit darurat.\n'
          '5. **Pakaian & Higienitas:** Pakaian 3 hari, jas hujan, masker medis, uang tunai.',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      suggestedActions: const [
        ChatAction(
          label: 'Semua Panduan Bencana',
          route: '/guides',
          iconName: 'menu_book',
        ),
      ],
    );
  }

  static ChatMessage emergencyNumbers(String id) {
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          '📞 **Nomor Panggilan Darurat Nasional Indonesia:**\n\n'
          '• **112** — Panggilan Darurat Terpadu (Bebas Pulsa)\n'
          '• **115** — Basarnas (Pencarian & Pertolongan)\n'
          '• **113** — Pemadam Kebakaran & Penyelamatan\n'
          '• **119** — Layanan Medis Darurat & Ambulans\n'
          '• **117** — Pusdalops BNPB Bencana\n'
          '• **110** — Kepolisian Republik Indonesia',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      suggestedActions: const [
        ChatAction(
          label: 'Panggil 112 (Bebas Pulsa)',
          phoneNumber: '112',
          iconName: 'phone',
        ),
        ChatAction(
          label: 'Panggil 115 Basarnas',
          phoneNumber: '115',
          iconName: 'phone',
        ),
      ],
    );
  }

  static ChatMessage general(String id) {
    return ChatMessage(
      id: id,
      role: ChatRole.assistant,
      text:
          'Halo! Saya **Asisten Siaga AI**, siap membantu Anda memahami protokol penyelamatan resmi BNPB & BMKG.\n\n'
          'Tanyakan seputar:\n'
          '• Gempa bumi & evakuasi tsunami\n'
          '• Antisipasi banjir & kebakaran\n'
          '• Pertolongan pertama luka (P3K)\n'
          '• Isi Tas Siaga Bencana (Go-Bag)\n'
          '• Nomor darurat & titik kumpul aman',
      timestamp: DateTime.now(),
      isOfflineFallback: true,
      suggestedActions: const [
        ChatAction(label: 'Panduan Gempa', route: '/guides'),
        ChatAction(label: 'Nomor Darurat', phoneNumber: '112'),
      ],
    );
  }
}
