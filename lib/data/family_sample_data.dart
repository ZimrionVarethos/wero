import '../models/emergency_contact.dart';
import '../models/family_checkin.dart';

/// Pre-seeded offline fallback sample data for emergency contacts and check-ins.
abstract final class FamilySampleData {
  static final defaultSampleContacts = [
    EmergencyContact(
      id: 'sample-1',
      userId: 'system',
      name: 'Ibu (Rumah Sleman)',
      phoneNumber: '081234567890',
      relationship: 'Orang Tua',
      status: 'SAFE',
      statusNote: 'Kondisi aman bersama adik di rumah',
      statusUpdatedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      createdAt: DateTime.now(),
    ),
    EmergencyContact(
      id: 'sample-2',
      userId: 'system',
      name: 'Pak RT RW 05 Merapi',
      phoneNumber: '081398765432',
      relationship: 'Tetangga / Aparat Desa',
      status: 'EVACUATING',
      statusNote: 'Membantu warga menuju Barak Purwobinangun',
      statusUpdatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now(),
    ),
  ];

  static final defaultSampleCheckins = [
    FamilyCheckin(
      id: 'chk-1',
      userId: 'usr-1',
      userName: 'Siti Rahma (Ibu)',
      status: 'SAFE',
      note: 'Alhamdulillah sudah aman di rumah kerabat.',
      address: 'Jl. Kaliurang KM 12, Sleman',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    FamilyCheckin(
      id: 'chk-2',
      userId: 'usr-2',
      userName: 'Budi Santoso (Adik)',
      status: 'EVACUATING',
      note: 'Sedang menuju posko pengungsian Stadion Maguwoharjo.',
      address: 'Maguwoharjo, Sleman',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];
}
