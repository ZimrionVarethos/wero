/// Indonesian administrative region model.
final class Region {
  const Region({
    required this.id,
    required this.name,
    required this.level,
    this.code,
  });

  final String id;
  final String name;
  final String level;
  final String? code;

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as String,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    if (code != null) 'code': code,
  };
}
