/// Application configuration and environment constants for Siagaku / Wero.
///
/// Can be overridden via --dart-define at build/run time:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
abstract final class AppConfig {
  static const String appName = 'Siagaku';

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
  static const String webBackendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  /// Whether AI Disaster Assistant backend is configured.
  static bool get isGeminiConfigured => webBackendUrl.isNotEmpty;

  /// Mapbox public access token for high-accuracy outdoor and street maps.
  static const String mapboxToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
    defaultValue: '',
  );

  /// Whether Mapbox token is configured.
  static bool get isMapboxConfigured =>
      mapboxToken.isNotEmpty && mapboxToken.startsWith('pk.');

  /// Cache storage keys.
  static const String cachedCommunityPrefix = 'siagaku_community_cache_';
  static const String lastSyncedTimestampKey = 'siagaku_last_synced_at';
  static const String offlineModePrefKey = 'siagaku_offline_mode';
}
