/// Model representing a nearby public SOS event for volunteer assistance.
final class PublicSosEvent {
  const PublicSosEvent({
    required this.id,
    required this.victimId,
    required this.victimName,
    required this.latitude,
    required this.longitude,
    this.distanceM,
    this.note,
    this.accuracyM,
    this.respondersCount = 0,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String victimId;
  final String victimName;
  final double latitude;
  final double longitude;
  final double? distanceM;
  final String? note;
  final double? accuracyM;
  final int respondersCount;
  final String status;
  final DateTime createdAt;

  bool get isClaimed => status == 'CLAIMED' || respondersCount > 0;

  factory PublicSosEvent.fromJson(Map<String, dynamic> json) {
    return PublicSosEvent(
      id: json['id'] as String,
      victimId: (json['victim_id'] as String?) ?? '',
      victimName: (json['victim_name'] as String?) ?? 'Warga Sekitar',
      latitude: (json['lat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble() ??
          0.0,
      longitude: (json['lng'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble() ??
          0.0,
      distanceM: (json['distance_m'] as num?)?.toDouble(),
      note: json['note'] as String?,
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      respondersCount: (json['responders_count'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'ACTIVE',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'victim_id': victimId,
    'victim_name': victimName,
    'lat': latitude,
    'lng': longitude,
    'distance_m': distanceM,
    'note': note,
    'accuracy_m': accuracyM,
    'responders_count': respondersCount,
    'status': status,
    'created_at': createdAt.toIso8601String(),
  };
}
