import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized text styles for the Siagaku design system.
/// Uses Plus Jakarta Sans with strict hierarchy and readability under stress.
abstract final class AppTextStyles {
  // Display & Main Titles
  static TextStyle get display => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryNavy,
    height: 1.2,
  );

  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryNavy,
  );

  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryNavy,
  );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  // Body Copy
  static TextStyle get body => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
    height: 1.4,
  );

  static TextStyle get bodySecondary => GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
    height: 1.4,
  );

  // Labels, Captions, Badges
  static TextStyle get label => GoogleFonts.plusJakartaSans(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mutedText,
  );

  static TextStyle get badge => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryText,
    letterSpacing: 0.5,
  );

  // Backward compatibility aliases
  static TextStyle get displayTitle => display;
  static TextStyle get displayEmphasis => display;
}
