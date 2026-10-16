/// User profile model corresponding to public.profiles.
final class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    this.avatarPath,
    this.regionId,
    this.regionName,
    this.createdAt,
  });

  final String id;
  final String displayName;
  final String? avatarPath;
  final String? regionId;
  final String? regionName;
  final DateTime? createdAt;

  UserProfile copyWith({
    String? displayName,
    String? avatarPath,
    String? regionId,
    String? regionName,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
      regionId: regionId ?? this.regionId,
      regionName: regionName ?? this.regionName,
      createdAt: createdAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    String? regName;
    if (json['regions'] is Map<String, dynamic>) {
      regName = json['regions']['name'] as String?;
    }
    return UserProfile(
      id: json['id'] as String,
      displayName: (json['display_name'] as String?) ?? 'Pengguna',
      avatarPath: json['avatar_path'] as String?,
      regionId: json['region_id'] as String?,
      regionName: regName,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'avatar_path': avatarPath,
    'region_id': regionId,
  };
}
