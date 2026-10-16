import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wero/core/providers/operations_providers.dart';
import 'package:wero/core/providers/volunteer_providers.dart';
import 'package:wero/models/public_sos_event.dart';
import 'package:wero/models/sos_event.dart';
import 'package:wero/widgets/app_header.dart';

void main() {
  group('PublicSosEvent Model Tests', () {
    test('fromJson parses API payload correctly', () {
      final json = {
        'id': 'sos-uuid-123',
        'victim_id': 'victim-456',
        'victim_name': 'Ahmad Fauzi',
        'lat': -7.7956,
        'lng': 110.3695,
        'distance_m': 145.5,
        'note': 'Butuh perahu karet evakuasi banjir',
        'responders_count': 1,
        'status': 'CLAIMED',
        'created_at': '2026-10-16T10:00:00Z',
      };

      final event = PublicSosEvent.fromJson(json);
      expect(event.id, 'sos-uuid-123');
      expect(event.victimId, 'victim-456');
      expect(event.victimName, 'Ahmad Fauzi');
      expect(event.latitude, -7.7956);
      expect(event.longitude, 110.3695);
      expect(event.distanceM, 145.5);
      expect(event.note, 'Butuh perahu karet evakuasi banjir');
      expect(event.respondersCount, 1);
      expect(event.status, 'CLAIMED');
      expect(event.isClaimed, isTrue);
    });

    test('toJson serializes public SOS event accurately', () {
      final event = PublicSosEvent(
        id: 'test-1',
        victimId: 'vic-1',
        victimName: 'Siti',
        latitude: -7.8,
        longitude: 110.4,
        distanceM: 80.0,
        status: 'ACTIVE',
        createdAt: DateTime(2026, 10, 16, 12, 0),
      );

      final json = event.toJson();
      expect(json['id'], 'test-1');
      expect(json['lat'], -7.8);
      expect(json['lng'], 110.4);
      expect(json['victim_name'], 'Siti');
      expect(json['distance_m'], 80.0);
    });
  });

  group('Volunteer Mission State Tests', () {
    test('ActiveVolunteerMission copyWith transitions status', () {
      final event = PublicSosEvent(
        id: 'sos-1',
        victimId: 'vic-1',
        victimName: 'Warga',
        latitude: -7.79,
        longitude: 110.36,
        status: 'ACTIVE',
        createdAt: DateTime.now(),
      );

      final mission = ActiveVolunteerMission(event: event, status: 'EN_ROUTE');
      expect(mission.status, 'EN_ROUTE');

      final arrived = mission.copyWith(status: 'ARRIVED');
      expect(arrived.status, 'ARRIVED');
      expect(arrived.event.id, 'sos-1');
    });
  });

  group('AppHeader SOS Alert Tests', () {
    testWidgets('AppHeader displays exclamation icon badge when SOS is active', (
      tester,
    ) async {
      final fakeSos = SosEvent(
        id: 'sos-active-1',
        victimId: 'my-user-id',
        mode: 'PUBLIC',
        status: 'ACTIVE',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSosProvider.overrideWith(
              () => _TestActiveSosNotifier(fakeSos),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: AppHeader(title: 'Home', showBackButton: false),
              body: SizedBox(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Exclamation badge icon should be present
      expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
      expect(find.byTooltip('Status SOS Darurat Aktif'), findsOneWidget);
    });

    testWidgets('AppHeader hides exclamation icon badge when SOS is inactive', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeSosProvider.overrideWith(
              () => _TestActiveSosNotifier(null),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              appBar: AppHeader(title: 'Home', showBackButton: false),
              body: SizedBox(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.priority_high_rounded), findsNothing);
    });
  });
}

class _TestActiveSosNotifier extends ActiveSosNotifier {
  _TestActiveSosNotifier(this.initialValue);
  final SosEvent? initialValue;

  @override
  Future<SosEvent?> build() async => initialValue;
}
