import 'package:flutter/material.dart';

/// Centralized color tokens for the Wero design system.
/// All color references in the app must use these constants.
abstract final class AppColors {
  // Page/canvas backgrounds
  static const Color canvasBlue = Color(0xFFEAF6FF);
  static const Color surface = Color(0xFFFFFFFF);

  // Typography
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF858585);

  // Borders and dividers
  static const Color border = Color(0xFFD9E0E5);

  // Accents
  static const Color accentOrange = Color(0xFFF07800);

  // Chart bar colors
  static const Color chartBlue = Color(0xFF20A8F5);
  static const Color chartGreen = Color(0xFF77E600);
  static const Color chartRed = Color(0xFFFF4D52);

  // Soft icon backgrounds
  static const Color softGreen = Color(0xFFDDF6C5);
  static const Color softRed = Color(0xFFFFD9D9);
  static const Color softBlue = Color(0xFFCDEBFF);
}
