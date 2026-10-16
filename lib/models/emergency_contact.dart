/// Model representing a trusted emergency contact or relative.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.userId,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isTrusted = true,
    this.status = 'UNKNOWN',
    this.statusNote,
    this.statusUpdatedAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isTrusted;
  final String status;
  final String? statusNote;
  final DateTime? statusUpdatedAt;
  final DateTime? createdAt;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationship: json['relationship'] as String? ?? 'Keluarga',
      isTrusted: json['is_trusted'] as bool? ?? true,
      status: json['status'] as String? ?? 'UNKNOWN',
      statusNote: json['status_note'] as String?,
      statusUpdatedAt: json['status_updated_at'] != null
          ? DateTime.tryParse(json['status_updated_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'relationship': relationship,
      'is_trusted': isTrusted,
      'status': status,
      'status_note': statusNote,
      if (statusUpdatedAt != null)
        'status_updated_at': statusUpdatedAt!.toIso8601String(),
    };
  }

  EmergencyContact copyWith({
    String? id,
    String? userId,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isTrusted,
    String? status,
    String? statusNote,
    DateTime? statusUpdatedAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isTrusted: isTrusted ?? this.isTrusted,
      status: status ?? this.status,
      statusNote: statusNote ?? this.statusNote,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      createdAt: createdAt,
    );
  }

  String get statusLabel {
    return switch (status) {
      'SAFE' => 'Aman',
      'EVACUATING' => 'Mengungsi',
      'NEED_HELP' => 'Butuh Bantuan',
      _ => 'Belum Ada Status',
    };
  }
}
