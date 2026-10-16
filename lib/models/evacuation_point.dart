/// Evacuation point facility model corresponding to public.evacuation_points.
final class EvacuationPoint {
  const EvacuationPoint({
    required this.id,
    required this.kind,
    required this.name,
    this.description,
    this.address,
    this.capacity,
    this.latitude,
    this.longitude,
    this.regionId,
  });

  final String id;
  final String
  kind; // 'ASSEMBLY' | 'SHELTER' | 'HEALTH' | 'ROUTE' | 'WATER' | 'OTHER'
  final String name;
  final String? description;
  final String? address;
  final int? capacity;
  final double? latitude;
  final double? longitude;
  final String? regionId;

  String get kindLabel {
    return switch (kind) {
      'SHELTER' => 'Shelter Pengungsian',
      'HEALTH' => 'Posko Kesehatan',
      'ASSEMBLY' => 'Titik Kumpul',
      'ROUTE' => 'Jalur Evakuasi',
      'WATER' => 'Pasokan Air Bersih',
      _ => 'Fasilitas Terkait',
    };
  }

  factory EvacuationPoint.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;
    if (json['latitude'] != null) {
      lat = (json['latitude'] as num?)?.toDouble();
      lng = (json['longitude'] as num?)?.toDouble();
    } else if (json['lat'] != null) {
      lat = (json['lat'] as num?)?.toDouble();
      lng = (json['lng'] as num?)?.toDouble();
    } else if (json['geom'] is Map<String, dynamic>) {
      final coordinates = json['geom']['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        lng = (coordinates[0] as num).toDouble();
        lat = (coordinates[1] as num).toDouble();
      }
    }

    return EvacuationPoint(
      id: json['id'] as String,
      kind: (json['kind'] as String?) ?? 'OTHER',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      address: json['address'] as String?,
      capacity: (json['capacity'] as num?)?.toInt(),
      latitude: lat,
      longitude: lng,
      regionId: json['region_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'name': name,
    'description': description,
    'address': address,
    'capacity': capacity,
    'latitude': latitude,
    'longitude': longitude,
    'region_id': regionId,
  };
}
