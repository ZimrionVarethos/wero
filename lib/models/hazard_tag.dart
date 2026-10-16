/// Hazard tag model corresponding to public.hazard_tags.
final class HazardTag {
  const HazardTag({required this.id, required this.slug, required this.name});

  final String id;
  final String slug;
  final String name;

  factory HazardTag.fromJson(Map<String, dynamic> json) {
    return HazardTag(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'name': name};
}
