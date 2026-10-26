import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typographic hierarchy for FloraScan.
///
/// Features:
/// - Plus Jakarta Sans for structural headlines.
/// - Inter for high-legibility body and label elements.
/// - JetBrains Mono for jitter-free sensor and numeric telemetry readings.
abstract final class AppTypography {
  // Headlines - Plus Jakarta Sans
  static final TextStyle headlineXLarge = GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
        letterSpacing: -0.64,
      );

  static final TextStyle headlineLarge = GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 32 / 26,
        letterSpacing: -0.39,
      );

  static final TextStyle headlineMedium = GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 26 / 20,
      );

  static final TextStyle headlineSmall = GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 24 / 18,
      );

  // Body & Labels - Inter
  static final TextStyle bodyLarge = GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 24 / 16,
      );

  static final TextStyle bodyMedium = GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      );

  static final TextStyle bodySmall = GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      );

  static final TextStyle labelUi = GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 14 / 11,
        letterSpacing: 0.66,
      );

  // Numeric & Sensor Telemetry - JetBrains Mono
  static final TextStyle telemetryLarge = GoogleFonts.jetBrainsMono(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 32 / 28,
        letterSpacing: -0.56,
      );

  static final TextStyle telemetryMedium = GoogleFonts.jetBrainsMono(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 20 / 16,
      );

  static final TextStyle telemetrySmall = GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
      );
}
