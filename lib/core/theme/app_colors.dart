import 'package:flutter/material.dart';

/// Centralized color palette defined by the FloraScan Field-Ready AgriTech design system.
///
/// Follows Single Source of Truth (SSOT) for all brand and telemetry colors.
abstract final class AppColors {
  // Brand & Foundation
  static const Color primary = Color(0xFF012D1D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1B4332);
  static const Color onPrimaryContainer = Color(0xFF86AF99);

  static const Color secondary = Color(0xFF116C4A);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFA1F4C8);
  static const Color onSecondaryContainer = Color(0xFF1B724F);

  static const Color tertiary = Color(0xFF3D1F00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF59330B);
  static const Color onTertiaryContainer = Color(0xFFD29B6B);

  // Surfaces & Backgrounds
  static const Color surface = Color(0xFFFAF8FF);
  static const Color onSurface = Color(0xFF131B2E);
  static const Color surfaceDim = Color(0xFFD2D9F4);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFF414844);

  static const Color outline = Color(0xFF717973);
  static const Color outlineVariant = Color(0xFFC1C8C2);

  // Errors & Alerts
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Domain Telemetry & Agronomy Palette
  static const Color foliageMid = Color(0xFF2D6A4F);
  static const Color bioLeafEmerald = Color(0xFF40916C);
  static const Color leafBright = Color(0xFF52B788);

  static const Color richOchreSoil = Color(0xFFB07D4F);
  static const Color soilAmberLight = Color(0xFFD4A373);

  static const Color moistureCyan = Color(0xFF0284C7);
  static const Color ambientTeal = Color(0xFF0D9488);
  static const Color solarAmber = Color(0xFFE9C46A);
  static const Color canopyCoral = Color(0xFFE76F51);

  // Pathological Risk Matrix
  static const Color healthyVigor = Color(0xFF16A34A);
  static const Color cautionStress = Color(0xFFF97316);
  static const Color severeOutbreak = Color(0xFFDC2626);
}
