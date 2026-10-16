/// Activity model representing a single fitness activity.
final class Activity {
  const Activity({
    required this.name,
    required this.imageUrl,
    required this.calories,
    required this.category,
  });

  final String name;
  final String imageUrl;

  /// Calorie estimate in Kcal/hr — placeholder data only, not medical guidance.
  final int calories;
  final ActivityCategory category;
}

/// Activity category used for tab filtering.
enum ActivityCategory { popular, moderate, intensive }
