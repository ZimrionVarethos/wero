/// Centralized spacing tokens for the Siagaku design system.
/// Uses an 8-point base scale with 4-point sub-steps (4, 8, 12, 16, 20, 24, 32 dp).
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  /// Standard horizontal page padding for mobile.
  static const double pagePadding = 20.0;
}

/// Centralized corner radius tokens for the Siagaku design system.
abstract final class AppRadius {
  /// Standard radius for cards and modal sheets (~12 dp).
  static const double card = 12.0;

  /// Standard radius for buttons (~12 dp).
  static const double button = 12.0;

  /// Standard radius for text fields and inputs (~10 dp).
  static const double input = 10.0;

  /// Standard radius for status badges and chips (~8 dp).
  static const double badge = 8.0;
  static const double chip = 8.0;

  /// Standard radius for icon tiles and small controls.
  static const double iconTile = 10.0;

  /// Radius for large curved hero banners and bottom arcs (~56 dp for dramatic curve).
  static const double heroCurve = 56.0;
}
