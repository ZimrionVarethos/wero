import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/emergency_contact.dart';
import '../../models/family_checkin.dart';
import '../../services/family_service.dart';
import 'supabase_providers.dart';

/// Provider exposing [FamilyService] backed by the Supabase client.
final familyServiceProvider = Provider<FamilyService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return FamilyService(client);
});

/// Provider for user's emergency contacts list.
final emergencyContactsProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
      final service = ref.watch(familyServiceProvider);
      final user = ref.watch(currentUserProvider);
      final userId = user?.id ?? 'guest_user';
      return service.fetchContacts(userId);
    });

/// Provider for community / family recent safety check-ins.
final familyCheckinsProvider = FutureProvider.autoDispose<List<FamilyCheckin>>((
  ref,
) async {
  final service = ref.watch(familyServiceProvider);
  return service.fetchRecentCheckins();
});
