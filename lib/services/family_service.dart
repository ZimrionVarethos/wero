import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exceptions.dart';
import '../data/family_sample_data.dart';
import '../models/emergency_contact.dart';
import '../models/family_checkin.dart';

/// Service managing trusted emergency contacts, hotlines, and family safety check-ins.
class FamilyService {
  const FamilyService(this._client);

  final SupabaseClient? _client;
  static const _cachedContactsKey = 'siagaku_family_contacts_cache';
  static const _cachedCheckinsKey = 'siagaku_family_checkins_cache';

  /// Fetch emergency contacts for the user with local fallback.
  Future<List<EmergencyContact>> fetchContacts(String userId) async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('emergency_contacts')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        final list = (res as List)
            .map((item) => EmergencyContact.fromJson(item))
            .toList();
        if (list.isNotEmpty) {
          await _cacheContacts(list);
          return list;
        }
      } catch (_) {
        // Fallback to offline cache
      }
    }
    return _getCachedContacts();
  }

  /// Add a new emergency contact.
  Future<EmergencyContact> addContact({
    required String userId,
    required String name,
    required String phoneNumber,
    required String relationship,
    bool isTrusted = true,
  }) async {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final contact = EmergencyContact(
      id: newId,
      userId: userId,
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      relationship: relationship.trim(),
      isTrusted: isTrusted,
      createdAt: DateTime.now(),
    );

    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('emergency_contacts')
            .insert({
              'user_id': userId,
              'name': contact.name,
              'phone_number': contact.phoneNumber,
              'relationship': contact.relationship,
              'is_trusted': contact.isTrusted,
              'status': 'UNKNOWN',
            })
            .select()
            .single();
        final created = EmergencyContact.fromJson(res);
        final cached = await _getCachedContacts();
        await _cacheContacts([created, ...cached]);
        return created;
      } catch (e) {
        // Fallback to local save
      }
    }

    final cached = await _getCachedContacts();
    final updated = [contact, ...cached];
    await _cacheContacts(updated);
    return contact;
  }

  /// Update an existing emergency contact.
  Future<bool> updateContact(EmergencyContact contact) async {
    final client = _client;
    if (client != null) {
      try {
        await client
            .from('emergency_contacts')
            .update({
              'name': contact.name,
              'phone_number': contact.phoneNumber,
              'relationship': contact.relationship,
              'is_trusted': contact.isTrusted,
              'status': contact.status,
              'status_note': contact.statusNote,
              'status_updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', contact.id);
      } catch (_) {}
    }

    final cached = await _getCachedContacts();
    final updated = cached
        .map((c) => c.id == contact.id ? contact : c)
        .toList();
    await _cacheContacts(updated);
    return true;
  }

  /// Delete an emergency contact.
  Future<bool> deleteContact(String contactId) async {
    final client = _client;
    if (client != null) {
      try {
        await client.from('emergency_contacts').delete().eq('id', contactId);
      } catch (_) {}
    }

    final cached = await _getCachedContacts();
    final updated = cached.where((c) => c.id != contactId).toList();
    await _cacheContacts(updated);
    return true;
  }

  /// Submit a safety check-in.
  Future<FamilyCheckin> submitCheckin({
    required String userId,
    required String userName,
    required String status,
    String? note,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final checkin = FamilyCheckin(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      status: status,
      note: note,
      latitude: latitude,
      longitude: longitude,
      address: address,
      createdAt: DateTime.now(),
    );

    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('family_checkins')
            .insert({
              'user_id': userId,
              'user_name': userName,
              'status': status,
              'note': note?.trim(),
              'latitude': latitude,
              'longitude': longitude,
              'address': address?.trim(),
            })
            .select()
            .single();
        final created = FamilyCheckin.fromJson(res);
        final cached = await _getCachedCheckins();
        await _cacheCheckins([created, ...cached]);
        return created;
      } catch (e) {
        throw ServerException('Gagal mengirim check-in: $e', e);
      }
    }

    final cached = await _getCachedCheckins();
    await _cacheCheckins([checkin, ...cached]);
    return checkin;
  }

  /// Fetch recent family safety check-ins.
  Future<List<FamilyCheckin>> fetchRecentCheckins() async {
    final client = _client;
    if (client != null) {
      try {
        final res = await client
            .from('family_checkins')
            .select()
            .order('created_at', ascending: false)
            .limit(25);
        final list = (res as List)
            .map((item) => FamilyCheckin.fromJson(item))
            .toList();
        if (list.isNotEmpty) {
          await _cacheCheckins(list);
          return list;
        }
      } catch (_) {}
    }
    return _getCachedCheckins();
  }

  Future<void> _cacheContacts(List<EmergencyContact> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((c) => c.toJson()).toList());
    await prefs.setString(_cachedContactsKey, raw);
  }

  Future<List<EmergencyContact>> _getCachedContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedContactsKey);
    if (raw != null) {
      try {
        final List decoded = jsonDecode(raw);
        return decoded.map((i) => EmergencyContact.fromJson(i)).toList();
      } catch (_) {}
    }
    return FamilySampleData.defaultSampleContacts;
  }

  Future<void> _cacheCheckins(List<FamilyCheckin> list) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(list.map((c) => c.toJson()).toList());
    await prefs.setString(_cachedCheckinsKey, raw);
  }

  Future<List<FamilyCheckin>> _getCachedCheckins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedCheckinsKey);
    if (raw != null) {
      try {
        final List decoded = jsonDecode(raw);
        return decoded.map((i) => FamilyCheckin.fromJson(i)).toList();
      } catch (_) {}
    }
    return FamilySampleData.defaultSampleCheckins;
  }
}
