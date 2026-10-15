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

  bool get isAwas => severity == 'AWAS';
  bool get isSiaga => severity == 'SIAGA';
  bool get isWaspada => severity == 'WASPADA';

  factory DisasterEvent.fromJson(Map<String, dynamic> json) {
    final rawSeverity = ((json['severity'] as String?) ?? 'INFO').toUpperCase();
    final normalizedSeverity = switch (rawSeverity) {
      'CRITICAL' || 'AWAS' => 'AWAS',
      'WARNING' || 'SIAGA' => 'SIAGA',
      'ADVISORY' || 'WASPADA' => 'WASPADA',
      _ => 'INFO',
    };

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
  };
}
