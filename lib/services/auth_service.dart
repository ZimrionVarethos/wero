import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exceptions.dart';
import '../models/region.dart';
import '../models/user_profile.dart';

/// Authentication and Profile management service interacting with Supabase.
class AuthService {
  const AuthService(this._client);

  final SupabaseClient? _client;

  bool get isConfigured => _client != null;

  User? get currentUser => _client?.auth.currentUser;

  /// Register a new user with email, password, and display name.
  Future<AuthResponse?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final client = _client;
    if (client == null) {
      throw const NetworkException('Layanan Supabase belum dikonfigurasi.');
    }
    try {
      final res = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': displayName.trim()},
      );
      return res;
    } on AuthException catch (e) {
      throw ValidationException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal melakukan pendaftaran: $e', e);
    }
  }

  /// Sign in existing user with email and password.
  Future<AuthResponse?> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw const NetworkException('Layanan Supabase belum dikonfigurasi.');
    }
    try {
      final res = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      return res;
    } on AuthException catch (e) {
      throw ValidationException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal masuk: $e', e);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    final client = _client;
    if (client == null) return;
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServerException('Gagal keluar dari sesi: $e', e);
    }
  }

  /// Fetch profile of the signed-in user, joining region name.
  Future<UserProfile?> fetchProfile() async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) return null;

    try {
      final data = await client
          .from('profiles')
          .select(
            'id, display_name, avatar_path, region_id, created_at, regions(name)',
          )
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      throw ServerException('Gagal memuat profil pengguna: $e', e);
    }
  }

  /// Update display name and/or default region of the signed-in user.
  Future<UserProfile> updateProfile({
    String? displayName,
    String? regionId,
  }) async {
    final client = _client;
    final user = currentUser;
    if (client == null || user == null) {
      throw const AppAuthException(
        'Anda harus masuk untuk memperbarui profil.',
      );
    }

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName.trim();
    if (regionId != null) updates['region_id'] = regionId;
    if (updates.isEmpty) {
      final current = await fetchProfile();
      return current ?? UserProfile(id: user.id, displayName: 'Warga Siaga');
    }

    try {
      await client.from('profiles').update(updates).eq('id', user.id);
      final refreshed = await fetchProfile();
      if (refreshed == null) {
        throw const NotFoundException('Gagal membaca kembali data profil.');
      }
      return refreshed;
    } catch (e) {
      throw ServerException('Gagal memperbarui profil: $e', e);
    }
  }

  /// Fetch active regencies and cities for profile region selection.
  Future<List<Region>> fetchRegions() async {
    final client = _client;
    if (client == null) return const [];

    try {
      final data = await client
          .from('regions')
          .select('id, code, name, level')
          .eq('is_active', true)
          .order('name', ascending: true);

      return (data as List).map((item) => Region.fromJson(item)).toList();
    } catch (e) {
      throw ServerException('Gagal mengambil daftar wilayah: $e', e);
    }
  }
}
