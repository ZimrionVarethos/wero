/// Community post category model corresponding to public.community_categories.
final class CommunityCategory {
  const CommunityCategory({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.sortOrder = 0,
  });

  final String id;
  final String slug;
  final String name;
  final String? description;
  final int sortOrder;

  factory CommunityCategory.fromJson(Map<String, dynamic> json) {
    return CommunityCategory(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'slug': slug,
    'name': name,
    'description': description,
    'sort_order': sortOrder,
  };
}
