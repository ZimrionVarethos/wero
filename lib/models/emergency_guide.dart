/// Severity or disaster type for offline emergency guide.
enum GuideCategory { earthquake, flood, fire, tsunami, landslide, firstAid }

/// Action steps grouped by phase (Before, During, After).
final class GuidePhase {
  const GuidePhase({required this.phaseName, required this.instructions});

  final String phaseName; // 'Sebelum' | 'Saat Terjadi' | 'Setelah'
  final List<String> instructions;
}

/// Emergency survival guide domain model, fully available offline.
final class EmergencyGuide {
  const EmergencyGuide({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.phases,
    required this.emergencyNumbers,
    required this.iconName,
  });

  final String id;
  final String title;
  final GuideCategory category;
  final String summary;
  final List<GuidePhase> phases;
  final List<String> emergencyNumbers;
  final String iconName;

  String get categoryLabel {
    return switch (category) {
      GuideCategory.earthquake => 'Gempa Bumi',
      GuideCategory.flood => 'Banjir & Cuaca',
      GuideCategory.fire => 'Kebakaran',
      GuideCategory.tsunami => 'Tsunami',
      GuideCategory.landslide => 'Tanah Longsor',
      GuideCategory.firstAid => 'Pertolongan Pertama (P3K)',
    };
  }
}
