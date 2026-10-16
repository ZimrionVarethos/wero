/// Central registry of all remote image URLs used in the Wero prototype.
///
/// Replace each URL with a local asset path (e.g. 'assets/images/...') when
/// proper licensed assets are available. Screen and widget code must import
/// only from this file — no inline URL strings allowed.
///
/// Sources: Unsplash (unsplash.com) — free to use for development.
/// Replace before production with properly licensed assets.
abstract final class ImageSources {
  /// Onboarding hero — person running / active lifestyle illustration.
  static const String onboardingHero =
      'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b'
      '?w=800&q=80&fit=crop';

  /// Activity: Swimming.
  static const String activitySwimming =
      'https://images.unsplash.com/photo-1560090995-30b4c9b35e6e'
      '?w=800&q=80&fit=crop';

  /// Activity: Playing Tennis.
  static const String activityTennis =
      'https://images.unsplash.com/photo-1535131749006-b7f58c99034b'
      '?w=800&q=80&fit=crop';

  /// Activity: Running.
  static const String activityRunning =
      'https://images.unsplash.com/photo-1476480862126-209bfaa8edc8'
      '?w=800&q=80&fit=crop';

  /// Activity: Cycling.
  static const String activityCycling =
      'https://images.unsplash.com/photo-1544191696-102dbdaeeaa0'
      '?w=800&q=80&fit=crop';

  /// User avatar placeholder.
  static const String avatarPlaceholder =
      'https://images.unsplash.com/photo-1633332755192-727a05c4013d'
      '?w=200&q=80&fit=crop&crop=face';
}
