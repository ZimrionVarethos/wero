import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:wero/models/evacuation_point.dart';
import 'package:wero/screens/operations/widgets/admin_facility_dialog.dart';
import 'package:wero/screens/operations/widgets/map_layer_button.dart';

void main() {
  group('Map Layer & Admin Facility Tests', () {
    testWidgets('MapLayerButton displays selected style and opens menu', (
      tester,
    ) async {
      EvacuationMapStyle selected = EvacuationMapStyle.satellite;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapLayerButton(
              selectedStyle: selected,
              onStyleChanged: (newStyle) => selected = newStyle,
            ),
          ),
        ),
      );

      expect(find.text('Satelit 3D'), findsOneWidget);

      await tester.tap(find.byType(MapLayerButton));
      await tester.pumpAndSettle();

      expect(find.text('Satelit 3D (Nyata)'), findsOneWidget);
      expect(find.text('Jalanan (Streets)'), findsOneWidget);
      expect(find.text('Topografi'), findsOneWidget);

      await tester.tap(find.text('Jalanan (Streets)'));
      await tester.pumpAndSettle();

      expect(selected, EvacuationMapStyle.streets);
    });

    testWidgets('AdminFacilityDialog renders Create form fields correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AdminFacilityDialog(
                currentLocation: LatLng(-7.7956, 110.3695),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tambah Posko Baru (Admin)'), findsOneWidget);
      expect(find.text('Nama Posko / Fasilitas *'), findsOneWidget);
      expect(find.text('Alamat Lengkap *'), findsOneWidget);
      expect(find.text('-7.7956'), findsOneWidget);
      expect(find.text('110.3695'), findsOneWidget);
      expect(find.text('Tambah'), findsOneWidget);
    });

    testWidgets(
      'AdminFacilityDialog renders Edit form fields with existing point',
      (tester) async {
        const testPoint = EvacuationPoint(
          id: 'posko-1',
          kind: 'SHELTER',
          name: 'Barak Purwobinangun Merapi',
          address: 'Jl. Kaliurang KM 19, Pakem, Sleman',
          capacity: 500,
          latitude: -7.6432,
          longitude: 110.3951,
        );

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: AdminFacilityDialog(pointToEdit: testPoint)),
            ),
          ),
        );

        expect(find.text('Kelola Posko (Admin)'), findsOneWidget);
        expect(find.text('Barak Purwobinangun Merapi'), findsOneWidget);
        expect(find.text('500'), findsOneWidget);
        expect(find.text('Simpan'), findsOneWidget);
        expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      },
    );
  });
}
