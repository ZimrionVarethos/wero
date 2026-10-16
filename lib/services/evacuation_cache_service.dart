import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/evacuation_point.dart';

/// Service managing offline persistence for evacuation shelters and assembly points.
class EvacuationCacheService {
  const EvacuationCacheService();

  static const String _cacheKey = 'wero_cached_evacuation_points_v1';
  static const String _lastLatKey = 'wero_last_synced_lat';
  static const String _lastLngKey = 'wero_last_synced_lng';

  /// Save last known or synced user location coordinates to local storage.
  Future<void> saveLastLocation(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_lastLatKey, lat);
      await prefs.setDouble(_lastLngKey, lng);
    } catch (_) {}
  }

  /// Retrieve last known or synced user coordinates if available.
  Future<({double lat, double lng})?> getLastLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_lastLatKey);
      final lng = prefs.getDouble(_lastLngKey);
      if (lat != null && lng != null) {
        return (lat: lat, lng: lng);
      }
    } catch (_) {}
    return null;
  }

  /// Save loaded evacuation points to persistent local cache.
  Future<void> cachePoints(List<EvacuationPoint> points) async {
    if (points.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = points.map((p) => p.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(list));
    } catch (_) {}
  }

  /// Retrieve cached evacuation points when offline or when network fails.
  Future<List<EvacuationPoint>> getCachedPoints({
    String? kind,
    String? searchQuery,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      List<EvacuationPoint> all = [];
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        all = decoded
            .map(
              (item) => EvacuationPoint.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      if (all.isEmpty) {
        all = _defaultOfflineShelters;
      }

      var filtered = all;
      if (kind != null && kind.isNotEmpty) {
        filtered = filtered.where((p) => p.kind == kind).toList();
      }
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        filtered = filtered.where((p) {
          final name = p.name.toLowerCase();
          final addr = p.address?.toLowerCase() ?? '';
          return name.contains(q) || addr.contains(q);
        }).toList();
      }
      return filtered;
    } catch (_) {
      return _defaultOfflineShelters;
    }
  }

  /// Bundled fallback evacuation shelters for critical offline scenarios.
  static const List<EvacuationPoint> _defaultOfflineShelters = [
    EvacuationPoint(
      id: 'offline-shelter-1',
      kind: 'SHELTER',
      name: 'Posko Pengungsian GOR Amongrogo',
      address: 'Jl. Kenari No.1, Semaki, Umbulharjo, Kota Yogyakarta',
      description:
          'Gedung olahraga indoor kapasitas besar dengan logistik darurat.',
      capacity: 1200,
      latitude: -7.7985,
      longitude: 110.3882,
    ),
    EvacuationPoint(
      id: 'offline-shelter-2',
      kind: 'HEALTH',
      name: 'RSUP Dr. Sardjito (Posko Medis Darurat)',
      address: 'Jl. Kesehatan No.1, Sekip, Sinduadi, Mlati, Sleman',
      description:
          'Fasilitas trauma center bencana dan unit gawat darurat 24 jam.',
      capacity: 500,
      latitude: -7.7686,
      longitude: 110.3734,
    ),
    EvacuationPoint(
      id: 'offline-shelter-3',
      kind: 'ASSEMBLY',
      name: 'Titik Kumpul Lapangan Denggung',
      address: 'Jl. Magelang KM 9.5, Tridadi, Sleman',
      description: 'Area terbuka aman bebas reruntuhan dan tiang listrik.',
      capacity: 2500,
      latitude: -7.7188,
      longitude: 110.3582,
    ),
    EvacuationPoint(
      id: 'offline-shelter-4',
      kind: 'SHELTER',
      name: 'Shelter Evakuasi Stadion Sultan Agung',
      address: 'Jl. Stadion Sultan Agung, Ponggok II, Trimulyo, Jetis, Bantul',
      description:
          'Posko utama penampungan korban gempa & logistik BPBD Bantul.',
      capacity: 3000,
      latitude: -7.8863,
      longitude: 110.3887,
    ),
    EvacuationPoint(
      id: 'offline-shelter-5',
      kind: 'ASSEMBLY',
      name: 'Titik Kumpul Lapangan Merdeka Medan',
      address: 'Jl. Balai Kota, Kesawan, Medan Barat, Kota Medan',
      description: 'Ruang terbuka evakuasi darurat kota Medan.',
      capacity: 4000,
      latitude: 3.5922,
      longitude: 98.6784,
    ),
  ];
}
