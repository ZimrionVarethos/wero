import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wero/data/emergency_hotlines_data.dart';
import 'package:wero/models/emergency_contact.dart';
import 'package:wero/models/family_checkin.dart';
import 'package:wero/screens/family/widgets/checkin_status_selector.dart';
import 'package:wero/screens/family/widgets/contact_card.dart';
import 'package:wero/screens/family/widgets/emergency_hotline_tile.dart';
import 'package:wero/screens/family/widgets/family_checkin_card.dart';

void main() {
  group('Phase 7 EmergencyContact Model Tests', () {
    test('fromJson and toJson works as expected', () {
      final json = {
        'id': 'contact-1',
        'user_id': 'user-1',
        'name': 'Bapak',
        'phone_number': '08123456789',
        'relationship': 'Ayah',
        'is_trusted': true,
        'status': 'SAFE',
        'status_note': 'Aman di rumah',
        'status_updated_at': '2026-10-15T08:00:00Z',
      };

      final contact = EmergencyContact.fromJson(json);
      expect(contact.id, 'contact-1');
      expect(contact.userId, 'user-1');
      expect(contact.name, 'Bapak');
      expect(contact.phoneNumber, '08123456789');
      expect(contact.relationship, 'Ayah');
      expect(contact.isTrusted, isTrue);
      expect(contact.status, 'SAFE');
      expect(contact.statusLabel, 'Aman');

      final serialized = contact.toJson();
      expect(serialized['name'], 'Bapak');
      expect(serialized['relationship'], 'Ayah');
      expect(serialized['status'], 'SAFE');
    });

    test('statusLabel handles all status types', () {
      const c1 = EmergencyContact(
        id: '1',
        userId: 'u1',
        name: 'A',
        phoneNumber: '1',
        relationship: 'Ayah',
        status: 'SAFE',
      );
      const c2 = EmergencyContact(
        id: '2',
        userId: 'u1',
        name: 'B',
        phoneNumber: '2',
        relationship: 'Ibu',
        status: 'EVACUATING',
      );
      const c3 = EmergencyContact(
        id: '3',
        userId: 'u1',
        name: 'C',
        phoneNumber: '3',
        relationship: 'Kakak',
        status: 'NEED_HELP',
      );
      const c4 = EmergencyContact(
        id: '4',
        userId: 'u1',
        name: 'D',
        phoneNumber: '4',
        relationship: 'Adik',
        status: 'UNKNOWN',
      );

      expect(c1.statusLabel, 'Aman');
      expect(c2.statusLabel, 'Mengungsi');
      expect(c3.statusLabel, 'Butuh Bantuan');
      expect(c4.statusLabel, 'Belum Ada Status');
    });
  });

  group('Phase 7 FamilyCheckin Model Tests', () {
    test('fromJson and toJson serializes GPS and status', () {
      final json = {
        'id': 'chk-1',
        'user_id': 'usr-1',
        'user_name': 'Ahmad',
        'status': 'SAFE',
        'note': 'Keluarga berkumpul di posko',
        'latitude': -7.7956,
        'longitude': 110.3695,
        'address': 'Kraton, Yogyakarta',
        'created_at': '2026-10-15T08:30:00Z',
      };

      final checkin = FamilyCheckin.fromJson(json);
      expect(checkin.id, 'chk-1');
      expect(checkin.userId, 'usr-1');
      expect(checkin.userName, 'Ahmad');
      expect(checkin.status, 'SAFE');
      expect(checkin.latitude, -7.7956);
      expect(checkin.longitude, 110.3695);
      expect(checkin.address, 'Kraton, Yogyakarta');
      expect(checkin.statusLabel, 'Saya Aman');

      final serialized = checkin.toJson();
      expect(serialized['user_name'], 'Ahmad');
      expect(serialized['latitude'], -7.7956);
    });
  });

  group('Phase 7 Emergency Hotlines Data Tests', () {
    test('Contains official Indonesian emergency hotlines', () {
      expect(nationalEmergencyHotlines.length, greaterThanOrEqualTo(7));
      final numbers = nationalEmergencyHotlines.map((h) => h.number).toList();
      expect(numbers, contains('112'));
      expect(numbers, contains('115'));
      expect(numbers, contains('119'));
      expect(numbers, contains('117'));
      expect(numbers, contains('110'));
      expect(numbers, contains('113'));
      expect(numbers, contains('129'));
    });
  });

  group('Phase 7 Widgets Tests', () {
    testWidgets('EmergencyHotlineTile displays hotline agency and number', (
      tester,
    ) async {
      const hotline = EmergencyHotline(
        number: '115',
        title: 'Pencarian & Pertolongan (SAR)',
        agency: 'Basarnas Indonesia',
        description: 'Operasi SAR darurat',
        category: 'RESCUE',
      );

      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmergencyHotlineTile(
              hotline: hotline,
              onCall: () => called = true,
            ),
          ),
        ),
      );

      expect(find.text('Pencarian & Pertolongan (SAR)'), findsOneWidget);
      expect(find.text('Basarnas Indonesia'), findsOneWidget);
      expect(find.text('115'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.phone_in_talk_rounded));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('ContactCard renders contact details and actions', (
      tester,
    ) async {
      final contact = EmergencyContact(
        id: 'c-test',
        userId: 'u1',
        name: 'Rina (Ibu)',
        phoneNumber: '081234567890',
        relationship: 'Ibu',
        isTrusted: true,
        status: 'SAFE',
        statusNote: 'Sudah di rumah kakek',
        statusUpdatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContactCard(contact: contact, onEdit: () {}, onDelete: () {}),
          ),
        ),
      );

      expect(find.text('Rina (Ibu)'), findsOneWidget);
      expect(find.text('Ibu • 081234567890'), findsOneWidget);
      expect(find.text('Aman'), findsOneWidget);
      expect(find.text('Telepon'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
    });

    testWidgets('CheckinStatusSelector allows selection of statuses', (
      tester,
    ) async {
      String selected = 'SAFE';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CheckinStatusSelector(
                  selectedStatus: selected,
                  onChanged: (val) => setState(() => selected = val),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Saya Aman'), findsOneWidget);
      expect(find.text('Mengungsi'), findsOneWidget);
      expect(find.text('Butuh Bantuan'), findsOneWidget);

      await tester.tap(find.text('Butuh Bantuan'));
      await tester.pump();
      expect(selected, 'NEED_HELP');

      await tester.tap(find.text('Mengungsi'));
      await tester.pump();
      expect(selected, 'EVACUATING');
    });

    testWidgets('FamilyCheckinCard displays checkin details and note', (
      tester,
    ) async {
      final checkin = FamilyCheckin(
        id: 'chk-test',
        userId: 'u1',
        userName: 'Budi Santoso',
        status: 'EVACUATING',
        note: 'Menuju GOR KONI bersama keluarga',
        address: 'Baleendah, Bandung',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FamilyCheckinCard(checkin: checkin)),
        ),
      );

      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Sedang Mengungsi'), findsOneWidget);
      expect(find.text('Menuju GOR KONI bersama keluarga'), findsOneWidget);
      expect(find.text('Baleendah, Bandung'), findsOneWidget);
    });
  });
}
