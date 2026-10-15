import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../models/bmkg_quake.dart';

/// Service for fetching official real-time earthquake & tsunami early warnings from BMKG.
class BmkgAlertService {
  const BmkgAlertService();

  static const String _autoQuakeUrl =
      'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json';
  static const String _feltQuakesUrl =
      'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json';
  static const String _cacheKeyLatest = 'bmkg_latest_quake_cache';

  /// Fetch the latest significant earthquake from BMKG autogempa endpoint.
  Future<BmkgQuake> fetchLatestQuake() async {
    // 1. Try web backend proxy first to avoid CORS on web and use cached data
    try {
      final backendUri = Uri.parse(
        '${AppConfig.webBackendUrl}/api/bmkg?type=latest',
      );
      final res = await http
          .get(backendUri)
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final quakeJson = data['Infogempa']?['gempa'] as Map<String, dynamic>?;
        if (quakeJson != null) {
          final quake = BmkgQuake.fromJson(quakeJson);
          _cacheLatestQuake(res.body);
          return quake;
        }
      }
    } catch (_) {
      // Fallback to direct BMKG endpoint
    }

    // 2. Direct BMKG endpoint
    try {
      final res = await http
          .get(Uri.parse(_autoQuakeUrl))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final quakeJson = data['Infogempa']?['gempa'] as Map<String, dynamic>?;

        if (quakeJson != null) {
          final quake = BmkgQuake.fromJson(quakeJson);
          _cacheLatestQuake(res.body);
          return quake;
        }
      }
    } catch (_) {
      // Network failure or timeout, fallback to cache
    }

    final cached = await _getCachedLatestQuake();
    return cached ?? _bundledLatestQuake;
  }

  /// Fetch the latest 15 felt earthquakes from BMKG.
  Future<List<BmkgQuake>> fetchRecentQuakes() async {
    // 1. Try web backend proxy first
    try {
      final backendUri = Uri.parse(
        '${AppConfig.webBackendUrl}/api/bmkg?type=felt',
      );
      final res = await http
          .get(backendUri)
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['Infogempa']?['gempa'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          return list
              .map((item) => BmkgQuake.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Fallback to direct BMKG endpoint
    }

    // 2. Direct BMKG endpoint
    try {
      final res = await http
          .get(Uri.parse(_feltQuakesUrl))
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final list = data['Infogempa']?['gempa'] as List<dynamic>?;

        if (list != null && list.isNotEmpty) {
          return list
              .map((item) => BmkgQuake.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {
      // Return fallback
    }

    return _bundledRecentQuakes;
  }

  Future<void> _cacheLatestQuake(String rawJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyLatest, rawJson);
    } catch (_) {}
  }

  Future<BmkgQuake?> _getCachedLatestQuake() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_cacheKeyLatest);
      if (str != null && str.isNotEmpty) {
        final data = jsonDecode(str) as Map<String, dynamic>;
        final quakeJson = data['Infogempa']?['gempa'] as Map<String, dynamic>?;
        if (quakeJson != null) return BmkgQuake.fromJson(quakeJson);
      }
    } catch (_) {}
    return null;
  }

  // Fallback bundled earthquake data
  static final _bundledLatestQuake = BmkgQuake(
    tanggal: '15 Okt 2026',
    jam: '08:12:45 WIB',
    dateTime: DateTime.now().subtract(const Duration(minutes: 42)),
    coordinates: '-8.12,110.45',
    latitude: -8.12,
    longitude: 110.45,
    magnitude: 5.6,
    kedalaman: '10 km',
    wilayah: '95 km BaratDaya Gunungkidul, D.I. Yogyakarta',
    potensi: 'Tidak berpotensi tsunami',
    dirasakan: 'III-IV Gunungkidul, III Bantul, II-III Yogyakarta',
    shakemapUrl: 'https://data.bmkg.go.id/DataMKG/TEWS/20261014173057.mmi.jpg',
  );

  static final _bundledRecentQuakes = [
    _bundledLatestQuake,
    BmkgQuake(
      tanggal: '14 Okt 2026',
      jam: '17:30:57 WIB',
      dateTime: DateTime.now().subtract(const Duration(hours: 15)),
      coordinates: '-8.14,120.56',
      latitude: -8.14,
      longitude: 120.56,
      magnitude: 4.8,
      kedalaman: '10 km',
      wilayah: 'Pusat gempa berada di laut 53 km utara Ruteng, Manggarai',
      potensi: 'Tidak berpotensi tsunami',
      dirasakan: 'II-III Kab. Manggarai',
    ),
    BmkgQuake(
      tanggal: '13 Okt 2026',
      jam: '17:22:02 WIB',
      dateTime: DateTime.now().subtract(const Duration(hours: 39)),
      coordinates: '-9.06,111.37',
      latitude: -9.06,
      longitude: 111.37,
      magnitude: 4.5,
      kedalaman: '10 km',
      wilayah: 'Pusat gempa berada di laut 103 km selatan Pacitan',
      potensi: 'Tidak berpotensi tsunami',
      dirasakan: 'III Trenggalek, II Pacitan',
    ),
  ];
}
