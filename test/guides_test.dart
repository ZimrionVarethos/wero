import 'package:flutter_test/flutter_test.dart';
import 'package:wero/data/emergency_guides_data.dart';
import 'package:wero/models/emergency_guide.dart';
import 'package:wero/services/offline_guide_service.dart';

void main() {
  group('Offline Survival Guides Tests', () {
    const service = OfflineGuideService();

    test('Default bundled emergency guides are present and complete', () {
      expect(defaultEmergencyGuides.length, greaterThanOrEqualTo(5));

      for (final guide in defaultEmergencyGuides) {
        expect(guide.id, isNotEmpty);
        expect(guide.title, isNotEmpty);
        expect(guide.summary, isNotEmpty);
        expect(guide.phases, isNotEmpty);
        expect(guide.emergencyNumbers, isNotEmpty);
        for (final phase in guide.phases) {
          expect(phase.phaseName, isNotEmpty);
          expect(phase.instructions, isNotEmpty);
        }
      }
    });

    test('Filter guides by category', () {
      final earthquakeGuides = service.getGuides(
        category: GuideCategory.earthquake,
      );
      expect(earthquakeGuides.length, 1);
      expect(earthquakeGuides.first.id, 'guide-gempa');
      expect(earthquakeGuides.first.categoryLabel, 'Gempa Bumi');

      final floodGuides = service.getGuides(category: GuideCategory.flood);
      expect(floodGuides.length, 1);
      expect(floodGuides.first.id, 'guide-banjir');
    });

    test('Search guides by keyword in title, summary, or steps', () {
      final searchDrop = service.getGuides(searchQuery: 'Drop');
      expect(
        searchDrop.length,
        2,
      ); // Gempa (Drop Cover Hold) & Kebakaran (Stop Drop Roll)

      final searchTsunami = service.getGuides(searchQuery: 'laut');
      expect(searchTsunami.any((g) => g.id == 'guide-tsunami'), isTrue);

      final searchP3K = service.getGuides(searchQuery: 'pendarahan');
      expect(searchP3K.length, 1);
      expect(searchP3K.first.id, 'guide-p3k');
    });
  });
}
