import 'package:flutter_test/flutter_test.dart';
import 'package:wero/models/disaster_event.dart';
import 'package:wero/models/evacuation_point.dart';
import 'package:wero/models/sos_event.dart';

void main() {
  group('Operations & SOS Models Tests', () {
    test('SosEvent parsing and status helpers', () {
      final json = {
        'id': 'sos-123',
        'victim_id': 'user-456',
        'mode': 'PUBLIC',
        'status': 'ACTIVE',
        'stage': 1,
        'note': 'Terjebak air banjir',
        'latitude': -6.9175,
        'longitude': 107.6191,
        'accuracy_m': 10.5,
        'created_at': '2026-10-14T10:00:00Z',
      };

      final sos = SosEvent.fromJson(json);

      expect(sos.id, 'sos-123');
      expect(sos.victimId, 'user-456');
      expect(sos.mode, 'PUBLIC');
      expect(sos.isPublic, isTrue);
      expect(sos.isActive, isTrue);
      expect(sos.isClaimed, isFalse);
      expect(sos.note, 'Terjebak air banjir');
      expect(sos.latitude, -6.9175);
      expect(sos.longitude, 107.6191);
      expect(sos.accuracyM, 10.5);

      final outMap = sos.toJson();
      expect(outMap['id'], 'sos-123');
      expect(outMap['status'], 'ACTIVE');
    });

    test('DisasterEvent parsing and severity handling', () {
      final json = {
        'id': 'disaster-789',
        'source': 'BMKG',
        'disaster_type': 'Gempa Bumi',
        'severity': 'AWAS',
        'headline': 'Gempa M5.6 Cianjur',
        'magnitude': 5.6,
        'depth_km': 10.0,
        'created_at': '2026-10-14T08:00:00Z',
      };

      final event = DisasterEvent.fromJson(json);

      expect(event.id, 'disaster-789');
      expect(event.source, 'BMKG');
      expect(event.disasterType, 'Gempa Bumi');
      expect(event.severity, 'AWAS');
      expect(event.headline, 'Gempa M5.6 Cianjur');
      expect(event.magnitude, 5.6);
      expect(event.depthKm, 10.0);
    });

    test('EvacuationPoint parsing and kind labels', () {
      final jsonShelter = {
        'id': 'evac-1',
        'kind': 'SHELTER',
        'name': 'GOR Baleendah',
        'address': 'Jl. Adipati Agung',
        'capacity': 500,
        'lat': -6.985,
        'lng': 107.625,
      };

      final shelter = EvacuationPoint.fromJson(jsonShelter);
      expect(shelter.kindLabel, 'Shelter Pengungsian');
      expect(shelter.name, 'GOR Baleendah');
      expect(shelter.capacity, 500);
      expect(shelter.latitude, -6.985);
      expect(shelter.longitude, 107.625);

      final jsonHealth = {
        'id': 'evac-2',
        'kind': 'HEALTH',
        'name': 'Puskesmas Ciparay',
      };
      final health = EvacuationPoint.fromJson(jsonHealth);
      expect(health.kindLabel, 'Posko Kesehatan');

      final jsonAssembly = {
        'id': 'evac-3',
        'kind': 'ASSEMBLY',
        'name': 'Lapangan Soreang',
      };
      final assembly = EvacuationPoint.fromJson(jsonAssembly);
      expect(assembly.kindLabel, 'Titik Kumpul');
    });
  });
}
