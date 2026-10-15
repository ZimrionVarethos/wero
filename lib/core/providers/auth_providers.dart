import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/region.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import 'supabase_providers.dart';

/// Provider exposing the [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});

/// Provider fetching active regencies and cities for region selection.
final regionsListProvider = FutureProvider<List<Region>>((ref) async {
  final service = ref.watch(authServiceProvider);
  return service.fetchRegions();
});

/// Async notifier managing the currently signed-in user's profile.
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final service = ref.watch(authServiceProvider);
    // React to auth state changes.
    ref.watch(authStateChangesProvider);
    return service.fetchProfile();
  }

  /// Update display name and/or region.
  Future<void> updateProfile({String? displayName, String? regionId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(authServiceProvider);
      return service.updateProfile(
        displayName: displayName,
        regionId: regionId,
      );
    });
  }

  /// Manually refresh profile.
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Provider for user profile state.
final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
      UserProfileNotifier.new,
    );
