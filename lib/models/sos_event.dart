/// SOS event domain model corresponding to public.sos_events.
final class SosEvent {
  const SosEvent({
    required this.id,
    required this.victimId,
    required this.mode,
    required this.status,
    this.stage = 1,
    this.note,
    this.latitude,
    this.longitude,
    this.accuracyM,
    required this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final String victimId;
  final String mode; // 'PUBLIC' | 'PRIVATE'
  final String
  status; // 'ACTIVE' | 'CLAIMED' | 'RESOLVED' | 'CANCELLED' | 'EXPIRED'
  final int stage;
  final String? note;
  final double? latitude;
  final double? longitude;
  final double? accuracyM;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  bool get isActive => status == 'ACTIVE' || status == 'CLAIMED';
  bool get isClaimed => status == 'CLAIMED';
  bool get isPublic => mode == 'PUBLIC';

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    return SosEvent(
      id: json['id'] as String,
      victimId: (json['victim_id'] as String?) ?? '',
      mode: (json['mode'] as String?) ?? 'PUBLIC',
      status: (json['status'] as String?) ?? 'ACTIVE',
      stage: (json['stage'] as num?)?.toInt() ?? 1,
      note: json['note'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'victim_id': victimId,
    'mode': mode,
    'status': status,
    'stage': stage,
    'note': note,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy_m': accuracyM,
    'created_at': createdAt.toIso8601String(),
    'resolved_at': resolvedAt?.toIso8601String(),
  };
}
