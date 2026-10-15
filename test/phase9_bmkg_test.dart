import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wero/models/bmkg_quake.dart';
import 'package:wero/screens/operations/widgets/bmkg_alert_detail_sheet.dart';
import 'package:wero/screens/operations/widgets/bmkg_live_warning_card.dart';
import 'package:wero/screens/operations/widgets/bmkg_playtest_dialog.dart';
import 'package:wero/screens/operations/widgets/playtest_scenario_card.dart';
import 'package:wero/screens/operations/widgets/quake_safety_protocol_box.dart';
import 'package:wero/theme/app_colors.dart';

void main() {
  group('Phase 9 BmkgQuake Model Tests', () {
    test('fromJson parses autogempa schema accurately', () {
      final json = {
        'Tanggal': '15 Okt 2026',
        'Jam': '09:45:12 WIB',
        'DateTime': '2026-10-15T02:45:12+00:00',
        'Coordinates': '-8.12,120.45',
        'Magnitude': '5.6',
        'Kedalaman': '10 km',
        'Wilayah': 'Pusat gempa berada di laut 38 km BaratDaya Ruteng',
        'Potensi': 'Tidak berpotensi tsunami',
        'Dirasakan': 'III Ruteng, II Labuan Bajo',
        'Shakemap': '20261015094512.mmi.jpg',
      };

      final quake = BmkgQuake.fromJson(json);
      expect(quake.tanggal, '15 Okt 2026');
      expect(quake.jam, '09:45:12 WIB');
      expect(quake.magnitude, 5.6);
      expect(quake.formattedMagnitude, 'M 5.6');
      expect(quake.kedalaman, '10 km');
      expect(quake.latitude, -8.12);
      expect(quake.longitude, 120.45);
      expect(quake.isTsunamiPotential, isFalse);
      expect(quake.severity, 'SIAGA');
      expect(quake.severityColor, AppColors.accentOrange);
      expect(
        quake.shakemapUrl,
        'https://data.bmkg.go.id/DataMKG/TEWS/20261015094512.mmi.jpg',
      );

      final out = quake.toJson();
      expect(out['Magnitude'], '5.6');
      expect(out['Potensi'], 'Tidak berpotensi tsunami');
      expect(out['Coordinates'], '-8.12,120.45');
    });

    test('isTsunamiPotential triggers AWAS severity level correctly', () {
      final json = {
        'Tanggal': '15 Okt 2026',
        'Jam': '10:00:00 WIB',
        'Coordinates': '-6.5,130.2',
        'Magnitude': '7.2',
        'Kedalaman': '15 km',
        'Wilayah': 'Laut Banda',
        'Potensi': 'BERPOTENSI TSUNAMI',
      };

      final quake = BmkgQuake.fromJson(json);
      expect(quake.isTsunamiPotential, isTrue);
      expect(quake.severity, 'AWAS');
      expect(quake.severityColor, AppColors.chartRed);
    });

    test(
      'moderate and minor magnitudes assign appropriate labels and colors',
      () {
        final minorQuake = BmkgQuake.fromJson({
          'Tanggal': '15 Okt 2026',
          'Jam': '08:00:00 WIB',
          'Coordinates': '-7.8,110.3',
          'Magnitude': '3.2',
          'Kedalaman': '5 km',
          'Wilayah': 'Yogyakarta',
          'Potensi': 'Tidak berpotensi tsunami',
        });
        expect(minorQuake.severity, 'WASPADA');
        expect(minorQuake.severityColor, const Color(0xFFF5A623));

        final severeQuake = BmkgQuake.fromJson({
          'Tanggal': '15 Okt 2026',
          'Jam': '07:00:00 WIB',
          'Coordinates': '-0.8,119.8',
          'Magnitude': '6.8',
          'Kedalaman': '20 km',
          'Wilayah': 'Palu',
          'Potensi': 'Tidak berpotensi tsunami',
        });
        expect(severeQuake.severity, 'AWAS');
        expect(severeQuake.severityColor, AppColors.chartRed);
      },
    );
  });

  group('Phase 9 QuakeSafetyProtocolBox Widget Tests', () {
    testWidgets('renders all 3 BNPB safety guidelines', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: QuakeSafetyProtocolBox())),
      );

      expect(find.text('Protokol Keselamatan (BNPB / BMKG):'), findsOneWidget);
      expect(find.textContaining('Drop, Cover, Hold On'), findsOneWidget);
      expect(find.textContaining('Jauhi jendela kaca'), findsOneWidget);
      expect(find.textContaining('evakuasi ke tempat tinggi'), findsOneWidget);
    });
  });

  group('Phase 9 BmkgLiveWarningCard Widget Tests', () {
    testWidgets('renders quake parameters and displays live info correctly', (
      tester,
    ) async {
      final quake = BmkgQuake(
        tanggal: '15 Okt 2026',
        jam: '09:45 WIB',
        dateTime: DateTime(2026, 10, 15, 9, 45),
        coordinates: '-8.12, 120.45',
        latitude: -8.12,
        longitude: 120.45,
        magnitude: 5.8,
        kedalaman: '12 km',
        wilayah: 'Pusat gempa 30 km Barat Daya Bantul DIY',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'IV Bantul, III Yogyakarta',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BmkgLiveWarningCard(quake: quake)),
        ),
      );

      expect(find.text('M 5.8'), findsOneWidget);
      expect(find.text('BMKG • SIAGA'), findsOneWidget);
      expect(find.text('09:45 WIB'), findsOneWidget);
      expect(
        find.textContaining('Pusat gempa 30 km Barat Daya Bantul DIY'),
        findsOneWidget,
      );
      expect(find.text('Tidak berpotensi tsunami'), findsOneWidget);
      expect(find.text('Daftar Gempa >'), findsOneWidget);
    });
  });

  group('Phase 9 BmkgAlertDetailSheet Widget Tests', () {
    testWidgets('displays full alert parameters, safety rules, and CTAs', (
      tester,
    ) async {
      final quake = BmkgQuake(
        tanggal: '15 Okt 2026',
        jam: '09:45 WIB',
        dateTime: DateTime(2026, 10, 15, 9, 45),
        coordinates: '-8.12, 120.45',
        latitude: -8.12,
        longitude: 120.45,
        magnitude: 5.8,
        kedalaman: '12 km',
        wilayah: 'Pusat gempa 30 km Barat Daya Bantul DIY',
        potensi: 'Tidak berpotensi tsunami',
        dirasakan: 'IV Bantul',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BmkgAlertDetailSheet(quake: quake)),
        ),
      );

      expect(find.text('Peringatan Dini Gempa Bumi'), findsOneWidget);
      expect(find.text('15 Okt 2026 • 09:45 WIB'), findsOneWidget);
      expect(find.text('Tidak berpotensi tsunami'), findsOneWidget);
      expect(find.text('12 km'), findsOneWidget);
      expect(find.text('-8.12, 120.45'), findsOneWidget);
      expect(find.text('IV Bantul'), findsOneWidget);
      expect(find.text('Family Check-in'), findsOneWidget);
      expect(find.text('Peta Shelter'), findsOneWidget);
      expect(find.byType(QuakeSafetyProtocolBox), findsOneWidget);
    });

    testWidgets('BmkgPlaytestDialog renders scenario options and alarm CTA', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: BmkgPlaytestDialog()),
          ),
        ),
      );

      expect(find.text('Simulasi Peringatan BMKG'), findsOneWidget);
      expect(find.text('BMKG LIVE'), findsOneWidget);
      expect(find.text('Skenario Tsunami'), findsOneWidget);
      expect(find.text('Skenario Gempa Darat'), findsOneWidget);
      expect(find.text('BUNYIKAN SIRINE & NOTIFIKASI'), findsOneWidget);
      expect(find.byType(PlaytestScenarioCard), findsOneWidget);

      await tester.tap(find.text('Skenario Gempa Darat'));
      await tester.pumpAndSettle();

      expect(find.text('Gempa Darat Sesar Aktif M 6.2'), findsOneWidget);
      expect(find.text('WASPADA GEMPA KUAT'), findsOneWidget);
    });
  });
}
