import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wero/models/disaster_event.dart';
import 'package:wero/models/sos_event.dart';
import 'package:wero/screens/operations/widgets/disaster_alert_banner.dart';
import 'package:wero/screens/operations/widgets/sos_active_card.dart';

void main() {
  group('Operations & SOS Widget Tests', () {
    testWidgets(
      'DisasterAlertBanner displays headline and opens modal detail',
      (tester) async {
        final event = DisasterEvent(
          id: 'alert-1',
          source: 'BMKG',
          sourceEventId: 'bmkg-001',
          disasterType: 'Gempa Bumi',
          severity: 'AWAS',
          headline: 'Gempa M5.6 Kedalaman 10 km',
          magnitude: 5.6,
          depthKm: 10.0,
          occurredAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: DisasterAlertBanner(event: event)),
          ),
        );

        expect(find.text('AWAS'), findsOneWidget);
        expect(find.text('Gempa M5.6 Kedalaman 10 km'), findsOneWidget);

        // Tap to open bottom sheet detail
        await tester.tap(find.byType(DisasterAlertBanner));
        await tester.pumpAndSettle();

        expect(find.text('Sumber resmi: BMKG'), findsOneWidget);
        expect(find.text('Tutup'), findsOneWidget);

        // Dismiss bottom sheet
        await tester.tap(find.text('Tutup'));
        await tester.pumpAndSettle();
        expect(find.text('Sumber resmi: BMKG'), findsNothing);
      },
    );

    testWidgets('SosActiveCard renders active status and note correctly', (
      tester,
    ) async {
      final event = SosEvent(
        id: 'sos-1',
        victimId: 'user-1',
        mode: 'PUBLIC',
        status: 'ACTIVE',
        stage: 1,
        note: 'Air sungai meluap ke atap rumah',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SosActiveCard(event: event)),
          ),
        ),
      );

      expect(find.text('STATUS: SOS DARURAT AKTIF'), findsOneWidget);
      expect(
        find.text('Catatan: "Air sungai meluap ke atap rumah"'),
        findsOneWidget,
      );
      expect(find.text('Sudah Aman'), findsOneWidget);
      expect(find.text('Batalkan'), findsOneWidget);
    });
  });
}
