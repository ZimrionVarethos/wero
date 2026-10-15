import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

/// Provider exposing the active [SupabaseClient].
///
/// Returns [Supabase.instance.client] when initialized, or null when
/// running without a configured backend (e.g. offline/prototype mode).
final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
});

/// Stream of auth state changes from Supabase.
final authStateChangesProvider = StreamProvider<AuthState?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    return Stream.value(null);
  }
  return client.auth.onAuthStateChange;
});

/// Provider for the currently signed-in Supabase [User].
/// Reactively updates whenever authentication state changes (sign in, sign out, token refresh).
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final client = ref.watch(supabaseClientProvider);
  return authState.value?.session?.user ?? client?.auth.currentUser;
});

/// Convenience provider indicating whether a user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Flag indicating whether Supabase is running with live backend configuration.
final isLiveBackendProvider = Provider<bool>((ref) {
  return AppConfig.isSupabaseConfigured &&
      ref.watch(supabaseClientProvider) != null;
});
