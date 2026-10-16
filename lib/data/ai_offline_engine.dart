import '../models/chat_message.dart';
import 'ai_disaster_responses.dart';

/// Heuristic offline engine routing disaster queries to official BNPB/BMKG responses.
class AiOfflineEngine {
  const AiOfflineEngine._();

  /// Matches user query against offline disaster protocol responses.
  static ChatMessage match(String query, String messageId) {
    if (_matches(query, ['gempa', 'guncang', 'lindung', 'meja', 'runtuh'])) {
      return AiDisasterResponses.earthquake(messageId);
    }
    if (_matches(query, ['banjir', 'genang', 'air naik', 'sungai', 'hujan'])) {
      return AiDisasterResponses.flood(messageId);
    }
    if (_matches(query, ['kebakaran', 'api', 'asap', 'terbakar', 'damkar'])) {
      return AiDisasterResponses.fire(messageId);
    }
    if (_matches(query, ['tsunami', 'laut surut', 'gelombang', 'pesisir'])) {
      return AiDisasterResponses.tsunami(messageId);
    }
    if (_matches(query, [
      'p3k',
      'luka',
      'darah',
      'pendarahan',
      'bakar',
      'patah',
      'cpr',
    ])) {
      return AiDisasterResponses.firstAid(messageId);
    }
    if (_matches(query, [
      'tas siaga',
      'go-bag',
      'ransel',
      'perbekalan',
      'dokumen',
    ])) {
      return AiDisasterResponses.goBag(messageId);
    }
    if (_matches(query, [
      'nomor darurat',
      'telepon darurat',
      'kontak penting',
      'call center',
    ])) {
      return AiDisasterResponses.emergencyNumbers(messageId);
    }
    if (_matches(query, [
      'evakuasi',
      'titik kumpul',
      'shelter',
      'pengungsian',
      'peta',
    ])) {
      return ChatMessage(
        id: messageId,
        role: ChatRole.assistant,
        text:
            '🗺️ **Informasi Lokasi Evakuasi & Titik Kumpul:**\n\n'
            'Aplikasi Wero memetakan shelter resmi, titik kumpul aman, dan faskes darurat.\n\n'
            'Peta interaktif dapat diakses lengkap dengan rute offline.',
        timestamp: DateTime.now(),
        isOfflineFallback: true,
        suggestedActions: const [
          ChatAction(
            label: 'Buka Peta Evakuasi',
            route: '/evacuation',
            iconName: 'map',
          ),
        ],
      );
    }
    return AiDisasterResponses.general(messageId);
  }

  static bool _matches(String query, List<String> keywords) {
    return keywords.any((k) => query.contains(k));
  }
}
