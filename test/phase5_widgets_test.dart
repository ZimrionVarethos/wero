import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wero/models/evacuation_point.dart';
import 'package:wero/screens/operations/widgets/facility_card.dart';
import 'package:wero/screens/operations/widgets/map_location_button.dart';

void main() {
  group('Phase 5 Facility Widgets Tests', () {
    testWidgets('FacilityCard displays facility name, kind, and address', (
      tester,
    ) async {
      const point = EvacuationPoint(
        id: 'evac-test-1',
        kind: 'SHELTER',
        name: 'GOR KONI Baleendah',
        description: 'Posko Pengungsian Utama dan Dapur Umum',
        address: 'Jl. Adipati Agung No. 12',
        capacity: 500,
        latitude: -6.9942,
        longitude: 107.6288,
      );

      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FacilityCard(point: point, onTap: () => tapped = true),
          ),
        ),
      );

      expect(find.text('GOR KONI Baleendah'), findsOneWidget);
      expect(find.text('Shelter Pengungsian'), findsOneWidget);
      expect(find.text('Kapasitas: 500 jiwa'), findsOneWidget);
      expect(find.text('Jl. Adipati Agung No. 12'), findsOneWidget);

      await tester.tap(find.byType(FacilityCard));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MapLocationButton renders sync label and icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MapLocationButton(onLocationSynced: (_) {})),
        ),
      );

      expect(find.text('Sinkron Lokasi Saya'), findsOneWidget);
      expect(find.byIcon(Icons.gps_fixed_rounded), findsOneWidget);
    });
  });
}
