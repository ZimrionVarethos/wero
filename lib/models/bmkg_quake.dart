import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Domain model representing a verified earthquake event from BMKG open data.
class BmkgQuake {
  const BmkgQuake({
    required this.tanggal,
    required this.jam,
    required this.dateTime,
    required this.coordinates,
    required this.latitude,
    required this.longitude,
    required this.magnitude,
    required this.kedalaman,
    required this.wilayah,
    required this.potensi,
    this.dirasakan,
    this.shakemapUrl,
  });

  final String tanggal;
  final String jam;
  final DateTime dateTime;
  final String coordinates;
  final double latitude;
  final double longitude;
  final double magnitude;
  final String kedalaman;
  final String wilayah;
  final String potensi;
  final String? dirasakan;
  final String? shakemapUrl;

  factory BmkgQuake.fromJson(Map<String, dynamic> json) {
    final coords = (json['Coordinates'] as String? ?? '0,0').split(',');
    final lat = double.tryParse(coords.first.trim()) ?? 0.0;
    final lng = coords.length > 1
        ? double.tryParse(coords[1].trim()) ?? 0.0
        : 0.0;

    final magStr = json['Magnitude']?.toString() ?? '0.0';
    final mag = double.tryParse(magStr) ?? 0.0;

    DateTime dt;
    if (json['DateTime'] != null) {
      dt = DateTime.tryParse(json['DateTime'] as String) ?? DateTime.now();
    } else {
      dt = DateTime.now();
    }

    final shakeFile = json['Shakemap'] as String?;
    final fullShakeUrl = (shakeFile != null && shakeFile.isNotEmpty)
        ? 'https://data.bmkg.go.id/DataMKG/TEWS/$shakeFile'
        : null;

    return BmkgQuake(
      tanggal: (json['Tanggal'] as String?) ?? '',
      jam: (json['Jam'] as String?) ?? '',
      dateTime: dt,
      coordinates: (json['Coordinates'] as String?) ?? '0,0',
      latitude: lat,
      longitude: lng,
      magnitude: mag,
      kedalaman: (json['Kedalaman'] as String?) ?? '-',
      wilayah: (json['Wilayah'] as String?) ?? 'Wilayah Indonesia',
      potensi: (json['Potensi'] as String?) ?? 'Tidak berpotensi tsunami',
      dirasakan: json['Dirasakan'] as String?,
      shakemapUrl: fullShakeUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'Tanggal': tanggal,
    'Jam': jam,
    'DateTime': dateTime.toIso8601String(),
    'Coordinates': coordinates,
    'Magnitude': magnitude.toString(),
    'Kedalaman': kedalaman,
    'Wilayah': wilayah,
    'Potensi': potensi,
    if (dirasakan != null) 'Dirasakan': dirasakan,
    if (shakemapUrl != null) 'Shakemap': shakemapUrl,
  };

  bool get isTsunamiPotential {
    final lower = potensi.toLowerCase();
    return !lower.contains('tidak') &&
        (lower.contains('berpotensi tsunami') ||
            lower.contains('potensi tsunami'));
  }

  String get severity {
    if (isTsunamiPotential || magnitude >= 6.5) return 'AWAS';
    if (magnitude >= 5.0) return 'SIAGA';
    return 'WASPADA';
  }

  Color get severityColor {
    return switch (severity) {
      'AWAS' => AppColors.awas,
      'SIAGA' => AppColors.siaga,
      'WASPADA' => AppColors.waspada,
      'AMAN' => AppColors.aman,
      _ => AppColors.info,
    };
  }

  String get formattedMagnitude => 'M ${magnitude.toStringAsFixed(1)}';
}
