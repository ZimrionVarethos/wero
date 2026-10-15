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
    if (targetType == 'ALL' ||
        (targetRegionIds.isEmpty && targetRegions.isEmpty && regionId == null)) {
      return true;
    }
    if (profile == null) return true;
    if (regionId != null && profile.regionId == regionId) return true;
    if (profile.regionId != null && targetRegionIds.contains(profile.regionId)) {
      return true;
    }
    if (profile.regionName != null) {
      final userReg = profile.regionName!.trim().toLowerCase();
      for (final tr in targetRegions) {
        final t = tr.trim().toLowerCase();
        if (t == userReg || userReg.contains(t) || t.contains(userReg)) {
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

    final payload = json['source_payload'] is Map<String, dynamic>
        ? json['source_payload'] as Map<String, dynamic>
        : <String, dynamic>{};

    final targetType = (payload['target_type'] as String?) ??
        (json['region_id'] != null ? 'SPECIFIC' : 'ALL');

    final targetRegionIds = (payload['target_region_ids'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final targetRegions = (payload['target_regions'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

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
      regionId: json['region_id'] as String?,
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
