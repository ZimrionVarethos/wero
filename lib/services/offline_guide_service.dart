import 'package:shared_preferences/shared_preferences.dart';

import '../data/emergency_guides_data.dart';
import '../models/emergency_guide.dart';

/// Service managing offline survival guides and the Disaster Go-Bag checklist.
class OfflineGuideService {
  const OfflineGuideService();

  static const String _goBagPrefKey = 'siagaku_gobag_checklist_v1';

  static const List<String> defaultGoBagItems = [
    'Dokumen penting (KTP, KK, Surat Tanah) dalam plastik kedap air',
    'Air minum bersih botol kemasan (minimal 3 liter)',
    'Makanan tahan lama tanpa dimasak (biskuit, kalengan)',
    'Senter LED dan baterai cadangan',
    'Kotak P3K standar (kasa, plester, antiseptik, obat pribadi)',
    'Peluit darurat untuk sinyal penyelamatan',
    'Masker medis/partikulat dan tisu basah',
    'Pakaian ganti hangat dan jas hujan ponco',
    'Powerbank terisi penuh dan kabel pengisi daya',
    'Uang tunai pecahan kecil secukupnya',
  ];

  /// Get survival guides with optional category and search query filters.
  List<EmergencyGuide> getGuides({
    GuideCategory? category,
    String? searchQuery,
  }) {
    var list = defaultEmergencyGuides;
    if (category != null) {
      list = list.where((g) => g.category == category).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((g) {
        final inTitle = g.title.toLowerCase().contains(q);
        final inSummary = g.summary.toLowerCase().contains(q);
        final inInstructions = g.phases.any(
          (p) => p.instructions.any((i) => i.toLowerCase().contains(q)),
        );
        return inTitle || inSummary || inInstructions;
      }).toList();
    }
    return list;
  }

  /// Load checked Go-Bag items from persistent SharedPreferences.
  Future<Set<String>> loadCheckedGoBagItems() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_goBagPrefKey) ?? [];
    return list.toSet();
  }

  /// Save checked Go-Bag items to persistent SharedPreferences.
  Future<void> saveCheckedGoBagItems(Set<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_goBagPrefKey, items.toList());
  }
}
