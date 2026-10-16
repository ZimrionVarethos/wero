/// Model representing a disaster safety check-in record.
class FamilyCheckin {
  const FamilyCheckin({
    required this.id,
    required this.userId,
    required this.userName,
    required this.status,
    this.note,
    this.latitude,
    this.longitude,
    this.address,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String status;
  final String? note;
  final double? latitude;
  final double? longitude;
  final String? address;
  final DateTime createdAt;

  factory FamilyCheckin.fromJson(Map<String, dynamic> json) {
    return FamilyCheckin(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      userName: json['user_name'] as String? ?? 'Warga',
      status: json['status'] as String? ?? 'SAFE',
      note: json['note'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'status': status,
      'note': note,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusLabel {
    return switch (status) {
      'SAFE' => 'Saya Aman',
      'EVACUATING' => 'Sedang Mengungsi',
      'NEED_HELP' => 'Butuh Bantuan Ringan',
      _ => 'Status Tidak Diketahui',
    };
  }
}
