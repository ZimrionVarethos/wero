import 'package:flutter/material.dart';

/// Centralized color tokens for the Siagaku design system.
/// Single source of truth adhering strictly to SKILL.md.
abstract final class AppColors {
  // Brand Foundation
  static const Color primaryNavy = Color(
    0xFF12263F,
  ); // Navigation, structural backgrounds, key headings
  static const Color accentOrange = Color(
    0xFFE8590C,
  ); // Primary action buttons ONLY (never use as status color!)
  static const Color backgroundCream = Color(
    0xFFF4F2EE,
  ); // Canvas / Scaffold page background
  static const Color surfaceWhite = Color(
    0xFFFFFFFF,
  ); // Cards, panels, input surfaces
  static const Color borderNeutral = Color(
    0xFFD9D5CD,
  ); // Dividers, card borders, subtle separators
  static const Color primaryText = Color(
    0xFF1A1D21,
  ); // Headings, body text, primary labels
  static const Color mutedText = Color(
    0xFF5F6B76,
  ); // Supporting text, metadata, inactive controls

  // Semantic Disaster Status Colors (Immutable — never repurpose for decoration!)
  static const Color awas = Color(
    0xFFC62828,
  ); // Highest danger — immediate threat / evacuation
  static const Color siaga = Color(
    0xFFE65100,
  ); // Alert — prepare for possible escalation
  static const Color waspada = Color(
    0xFFF9A825,
  ); // Warning — increased vigilance
  static const Color aman = Color(
    0xFF2E7D32,
  ); // Safe / all clear / normal condition
  static const Color info = Color(0xFF1565C0); // Informational / BMKG advisory

  // Status Backgrounds (10-15% opacity tints for badges & warning panels)
  static const Color awasBg = Color(0xFFFFEBEE);
  static const Color siagaBg = Color(0xFFFFF3E0);
  static const Color waspadaBg = Color(0xFFFFFDE7);
  static const Color amanBg = Color(0xFFE8F5E9);
  static const Color infoBg = Color(0xFFE3F2FD);

  // Backward compatibility aliases for existing codebase
  static const Color surface = surfaceWhite;
  static const Color textPrimary = primaryText;
  static const Color textSecondary = mutedText;
  static const Color border = borderNeutral;
  static const Color canvasBlue = backgroundCream;
  static const Color chartBlue = info;
  static const Color chartGreen = aman;
  static const Color chartRed = awas;
  static const Color softGreen = amanBg;
  static const Color softRed = awasBg;
  static const Color softBlue = infoBg;
}
