import 'dart:convert';

import 'package:wero/models/user_profile.dart';

/// Disaster event alert model corresponding to public.disaster_events.
final class DisasterEvent {
  const DisasterEvent({
    required this.id,
    required this.source,
    required this.sourceEventId,
    required this.disasterType,
    required this.severity,
    this.magnitude,
    this.depthKm,
    required this.headline,
    this.occurredAt,
    this.sourceUrl,
    this.regionId,
    this.targetType = 'ALL',
    this.targetRegionIds = const [],
    this.targetRegions = const [],
  });

  final String id;
  final String source;
  final String sourceEventId;
  final String disasterType;
  final String severity; // 'AWAS' | 'SIAGA' | 'WASPADA' | 'INFO' | 'UNKNOWN'
  final double? magnitude;
  final double? depthKm;
  final String headline;
  final DateTime? occurredAt;
  final String? sourceUrl;
  final String? regionId;
  final String targetType; // 'ALL' or 'SPECIFIC'
  final List<String> targetRegionIds;
  final List<String> targetRegions;

  bool get isAwas => severity == 'AWAS';
  bool get isSiaga => severity == 'SIAGA';
  bool get isWaspada => severity == 'WASPADA';

  bool isTargetedFor(UserProfile? profile) {
    // 1. National broadcasts target every citizen.
    if (targetType == 'ALL') {
      return true;
    }

    // 2. If marked SPECIFIC but no regions configured, fallback to true.
    final hasTargets =
        targetRegionIds.isNotEmpty ||
        targetRegions.isNotEmpty ||
        (regionId != null && regionId!.isNotEmpty);
    if (!hasTargets) {
      return true;
    }

    // 3. For specific regional broadcasts, if user has no profile or no region,
    // do not trigger siren/vibration for another region.
    if (profile == null) {
      return false;
    }

    // 4. Match by region ID
    if (profile.regionId != null && profile.regionId!.isNotEmpty) {
      if (regionId != null && profile.regionId == regionId) {
        return true;
      }
      if (targetRegionIds.contains(profile.regionId)) {
        return true;
      }
    }

    // 5. Match by region name (with city/regency normalization)
    if (profile.regionName != null && profile.regionName!.trim().isNotEmpty) {
      final userReg = profile.regionName!.trim().toLowerCase();
      final userRegClean = userReg
          .replaceAll('kota', '')
          .replaceAll('kabupaten', '')
          .replaceAll('kab.', '')
          .trim();

      for (final tr in targetRegions) {
        final t = tr.trim().toLowerCase();
        final tClean = t
            .replaceAll('kota', '')
            .replaceAll('kabupaten', '')
            .replaceAll('kab.', '')
            .trim();

        if (t == userReg ||
            userReg.contains(t) ||
            t.contains(userReg) ||
            (userRegClean.isNotEmpty &&
                tClean.isNotEmpty &&
                (userRegClean == tClean ||
                    userReg.contains(tClean) ||
                    t.contains(userRegClean)))) {
          return true;
        }
      }
    }

    return false;
  }

  factory DisasterEvent.fromJson(Map<String, dynamic> json) {
    final rawSeverity = ((json['severity'] as String?) ?? 'INFO').toUpperCase();
    final normalizedSeverity = switch (rawSeverity) {
      'CRITICAL' || 'AWAS' => 'AWAS',
      'WARNING' || 'SIAGA' => 'SIAGA',
      'ADVISORY' || 'WASPADA' => 'WASPADA',
      _ => 'INFO',
    };

    Map<String, dynamic> payload = {};
    final rawPayload = json['source_payload'];
    if (rawPayload is Map<String, dynamic>) {
      payload = rawPayload;
    } else if (rawPayload is Map) {
      payload = Map<String, dynamic>.from(rawPayload);
    } else if (rawPayload is String && rawPayload.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPayload);
        if (decoded is Map<String, dynamic>) {
          payload = decoded;
        } else if (decoded is Map) {
          payload = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }

    final targetType =
        (payload['target_type'] as String?) ??
        (json['region_id'] != null ? 'SPECIFIC' : 'ALL');

    final targetRegionIds =
        (payload['target_region_ids'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];

    final targetRegions =
        (payload['target_regions'] as List?)
            ?.map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList() ??
        <String>[];

    final mainRegId = json['region_id'] as String?;
    if (mainRegId != null &&
        mainRegId.isNotEmpty &&
        !targetRegionIds.contains(mainRegId)) {
      targetRegionIds.add(mainRegId);
    }

    return DisasterEvent(
      id: json['id'] as String,
      source: (json['source'] as String?) ?? 'BMKG',
      sourceEventId: (json['source_event_id'] as String?) ?? '',
      disasterType: (json['disaster_type'] as String?) ?? 'Peringatan',
      severity: normalizedSeverity,
      magnitude: (json['magnitude'] as num?)?.toDouble(),
      depthKm: (json['depth_km'] as num?)?.toDouble(),
      headline: (json['headline'] as String?) ?? '',
      occurredAt: json['occurred_at'] != null
          ? DateTime.tryParse(json['occurred_at'] as String)
          : null,
      sourceUrl: json['source_url'] as String?,
      regionId: mainRegId,
      targetType: targetType,
      targetRegionIds: targetRegionIds,
      targetRegions: targetRegions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source,
    'source_event_id': sourceEventId,
    'disaster_type': disasterType,
    'severity': severity,
    'magnitude': magnitude,
    'depth_km': depthKm,
    'headline': headline,
    'occurred_at': occurredAt?.toIso8601String(),
    'source_url': sourceUrl,
    'region_id': regionId,
    'target_type': targetType,
    'target_region_ids': targetRegionIds,
    'target_regions': targetRegions,
  };
}
