import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:wero/models/region.dart';
import 'package:wero/screens/profile/widgets/region_picker_dialog.dart';
import 'package:wero/services/location_service.dart';
import 'package:wero/services/region_detector_service.dart';

class _FakeLocationService implements LocationService {
  const _FakeLocationService(this.mockCoords);
  final LatLng mockCoords;

  @override
  Future<LatLng> determinePosition() async => mockCoords;

  @override
  Future<LatLng?> tryGetCurrentPosition({
    Duration timeout = const Duration(seconds: 4),
  }) async => mockCoords;
}

void main() {
  const testRegions = [
    Region(id: 'r-jogja', name: 'Kota Yogyakarta', level: 'kota'),
    Region(id: 'r-sleman', name: 'Kabupaten Sleman', level: 'kabupaten'),
    Region(id: 'r-bantul', name: 'Kabupaten Bantul', level: 'kabupaten'),
  ];

  group('RegionDetectorService Tests', () {
    test('Matches region via Web Geocode API response', () async {
      final mockHttpClient = MockClient((request) async {
        expect(request.url.path, equals('/api/geocode'));
        return http.Response(
          jsonEncode({
            'success': true,
            'regionId': 'r-jogja',
            'regionName': 'Kota Yogyakarta',
            'fullAddress': 'Jl. Malioboro, Kota Yogyakarta',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = RegionDetectorService(
        locationService: const _FakeLocationService(LatLng(-7.7828, 110.3672)),
        httpClient: mockHttpClient,
      );

      final result = await service.detectLiveRegion(
        availableRegions: testRegions,
      );

      expect(result.regionId, equals('r-jogja'));
      expect(result.regionName, equals('Kota Yogyakarta'));
      expect(result.fullAddress, contains('Malioboro'));
    });

    test(
      'Falls back gracefully to nearest coordinate region on network error',
      () async {
        final mockHttpClient = MockClient((request) async {
          return http.Response('Service unavailable', 503);
        });

        final service = RegionDetectorService(
          locationService: const _FakeLocationService(
            LatLng(-7.7828, 110.3672),
          ),
          httpClient: mockHttpClient,
        );

        final result = await service.detectLiveRegion(
          availableRegions: testRegions,
        );

        expect(result.regionId, equals('r-jogja'));
        expect(result.regionName, equals('Kota Yogyakarta'));
        expect(result.fullAddress, contains('Lokasi GPS: -7.7828'));
      },
    );
  });

  group('RegionPickerDialog Widget Tests', () {
    testWidgets('Renders GPS detection button and manual regions list', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RegionPickerDialog(
              regions: testRegions,
              selectedRegionId: 'r-sleman',
            ),
          ),
        ),
      );

      expect(find.text('Pilih Wilayah Siaga'), findsOneWidget);
      expect(find.text('Deteksi Lokasi GPS Live'), findsOneWidget);
      expect(find.text('Kota Yogyakarta'), findsOneWidget);
      expect(find.text('Kabupaten Sleman'), findsOneWidget);
      expect(find.text('Kabupaten Bantul'), findsOneWidget);

      // Verify that the currently selected region shows the check circle icon
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });
}
