import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../core/config/app_config.dart';
import '../models/region.dart';
import 'location_service.dart';

/// Result of a reverse-geocoded live location detection.
final class RegionDetectionResult {
  const RegionDetectionResult({
    required this.regionId,
    required this.regionName,
    required this.fullAddress,
    required this.coordinates,
  });

  final String regionId;
  final String regionName;
  final String fullAddress;
  final LatLng coordinates;
}

/// Service to detect the user's current city/kabupaten via live GPS and Web API.
class RegionDetectorService {
  RegionDetectorService({
    LocationService? locationService,
    http.Client? httpClient,
  }) : _locationService = locationService ?? const LocationService(),
       _httpClient = httpClient ?? http.Client();

  final LocationService _locationService;
  final http.Client _httpClient;

  /// Fetch live GPS and match to the registered regions via web geocode API.
  Future<RegionDetectionResult> detectLiveRegion({
    required List<Region> availableRegions,
  }) async {
    final pos = await _locationService.determinePosition();

    // 1. Call Web Geocode endpoint
    try {
      final uri = Uri.parse(
        '${AppConfig.webBackendUrl}/api/geocode?lat=${pos.latitude}&lng=${pos.longitude}',
      );
      final res = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final returnedRegionId = data['regionId'] as String?;
          final returnedRegionName = data['regionName'] as String?;
          final fullAddress =
              data['fullAddress'] as String? ?? 'Koordinat terdeteksi';

          // Match with local available regions list
          Region? matched;
          if (returnedRegionId != null) {
            matched = availableRegions
                .where((r) => r.id == returnedRegionId)
                .firstOrNull;
          }
          if (matched == null && returnedRegionName != null) {
            matched = availableRegions
                .where(
                  (r) =>
                      r.name.toLowerCase().contains(
                        returnedRegionName.toLowerCase(),
                      ) ||
                      returnedRegionName.toLowerCase().contains(
                        r.name.toLowerCase(),
                      ),
                )
                .firstOrNull;
          }

          if (matched != null) {
            return RegionDetectionResult(
              regionId: matched.id,
              regionName: matched.name,
              fullAddress: fullAddress,
              coordinates: pos,
            );
          }
        }
      }
    } catch (_) {
      // Fall through to fallback
    }

    // 2. Local Fallback based on approximate coordinates if web backend unreachable
    final fallbackRegion = _matchByCoordinates(pos, availableRegions);
    return RegionDetectionResult(
      regionId: fallbackRegion.id,
      regionName: fallbackRegion.name,
      fullAddress:
          'Lokasi GPS: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
      coordinates: pos,
    );
  }

  static const Map<String, LatLng> _cityCoordinates = {
    'Bogor': LatLng(-6.5971, 106.8060),
    'Depok': LatLng(-6.4025, 106.7942),
    'Bekasi': LatLng(-6.2383, 106.9756),
    'Tangerang': LatLng(-6.1783, 106.6319),
    'Bandung': LatLng(-6.9175, 107.6191),
    'Jakarta': LatLng(-6.2088, 106.8456),
    'Semarang': LatLng(-7.0051, 110.4381),
    'Surakarta': LatLng(-7.5666, 110.8166),
    'Yogyakarta': LatLng(-7.7956, 110.3695),
    'Sleman': LatLng(-7.7156, 110.3556),
    'Bantul': LatLng(-7.8900, 110.3300),
    'Surabaya': LatLng(-7.2575, 112.7521),
    'Malang': LatLng(-7.9666, 112.6326),
    'Denpasar': LatLng(-8.6705, 115.2126),
    'Badung': LatLng(-8.5833, 115.1833),
    'Medan': LatLng(3.5952, 98.6722),
    'Palembang': LatLng(-2.9761, 104.7754),
    'Padang': LatLng(-0.9471, 100.4172),
    'Makassar': LatLng(-5.1477, 119.4327),
    'Manado': LatLng(1.4748, 124.8421),
    'Balikpapan': LatLng(-1.2379, 116.8289),
  };

  Region _matchByCoordinates(LatLng pos, List<Region> regions) {
    if (regions.isEmpty) {
      return const Region(
        id: 'default',
        name: 'Wilayah Terdeteksi',
        level: 'kabupaten',
      );
    }

    // Find closest Indonesian city anchor
    double minDistance = double.infinity;
    String closestCity = '';

    for (final entry in _cityCoordinates.entries) {
      final dLat = pos.latitude - entry.value.latitude;
      final dLng = pos.longitude - entry.value.longitude;
      final distance = (dLat * dLat) + (dLng * dLng);
      if (distance < minDistance) {
        minDistance = distance;
        closestCity = entry.key;
      }
    }

    if (closestCity.isNotEmpty) {
      final matched = regions
          .where(
            (r) => r.name.toLowerCase().contains(closestCity.toLowerCase()),
          )
          .firstOrNull;
      if (matched != null) return matched;
    }

    return regions.first;
  }
}
