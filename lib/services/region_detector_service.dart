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

  Region _matchByCoordinates(LatLng pos, List<Region> regions) {
    if (regions.isEmpty) {
      return const Region(
        id: 'default',
        name: 'Wilayah Terdeteksi',
        level: 'kabupaten',
      );
    }

    // DIY Jogja approximation bounds
    if (pos.latitude >= -8.3 &&
        pos.latitude <= -7.4 &&
        pos.longitude >= 110.0 &&
        pos.longitude <= 110.8) {
      final jogja = regions
          .where((r) => r.name.contains('Yogyakarta'))
          .firstOrNull;
      if (jogja != null) return jogja;
      final sleman = regions
          .where((r) => r.name.contains('Sleman'))
          .firstOrNull;
      if (sleman != null) return sleman;
    }

    return regions.first;
  }
}
