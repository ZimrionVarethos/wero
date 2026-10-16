import 'dart:convert';

import 'package:http/http.dart' as http;

/// Application configuration and environment constants for Wero.
///
/// Can be overridden via --dart-define at build/run time:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract final class AppConfig {
  static const String appName = 'Wero';

  /// Supabase project URL.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rxoqjkgfldnicjaxsygt.supabase.co',
  );

  /// Supabase public anonymous/publishable API key.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_SuO6iZs_gLX8WA3daPRhMA_rFDnUYXK',
  );

  /// Whether Supabase client has been configured with real credentials.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      supabaseUrl != 'https://placeholder-project.supabase.co';

  /// Web backend server URL for secure AI assistant and geocoding operations.
  /// Defaults to official production deployment at https://wero-mu.vercel.app
  static const String webBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://wero-mu.vercel.app',
  );

  /// Whether AI Disaster Assistant backend is configured.
  static bool get isGeminiConfigured => webBackendUrl.isNotEmpty;

  static String _dynamicMapboxToken = '';

  /// Mapbox public access token for high-accuracy outdoor and street maps.
  /// Prioritizes dynamic token fetched securely from web backend over hardcoded strings.
  static String get mapboxToken {
    if (_dynamicMapboxToken.isNotEmpty) return _dynamicMapboxToken;
    return const String.fromEnvironment('MAPBOX_TOKEN', defaultValue: '');
  }

  /// Whether Mapbox token is configured.
  static bool get isMapboxConfigured =>
      mapboxToken.isNotEmpty && mapboxToken.startsWith('pk.');

  /// Cache storage keys.
  static const String cachedCommunityPrefix = 'siagaku_community_cache_';
  static const String lastSyncedTimestampKey = 'siagaku_last_synced_at';
  static const String offlineModePrefKey = 'siagaku_offline_mode';

  /// Dynamically loads runtime public configuration from web backend.
  static Future<void> loadDynamicConfig({http.Client? client}) async {
    if (webBackendUrl.isEmpty) return;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse('$webBackendUrl/api/config'))
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['mapboxToken'] as String?;
        if (token != null && token.isNotEmpty) {
          _dynamicMapboxToken = token;
        }
      }
    } catch (_) {
      // Graceful fallback to CartoDB/OSM
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
