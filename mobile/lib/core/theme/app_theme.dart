import 'package:flutter/material.dart';
import 'agri_theme_extension.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Centralized theme definition adhering to Material 3 and Stitch AgriTech tokens.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelUi,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            );
          }
          return AppTypography.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.onSecondaryContainer);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AgriThemeExtension.standard,
      ],
    );
  }

  /// Dark theme definition tailored for high-contrast field agronomy and night inspections.
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: AppColors.primaryFixedDim,
      onPrimary: AppColors.onPrimaryFixed,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.primaryFixed,
      secondary: AppColors.secondaryFixedDim,
      onSecondary: AppColors.onSecondaryFixed,
      secondaryContainer: AppColors.secondary,
      onSecondaryContainer: AppColors.secondaryFixed,
      tertiary: AppColors.tertiaryFixedDim,
      onTertiary: AppColors.onTertiaryFixed,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.tertiaryFixed,
      surface: Color(0xFF101419),
      onSurface: Color(0xFFE2E7FF),
      surfaceContainerLowest: Color(0xFF0C0F14),
      surfaceContainerLow: Color(0xFF161A22),
      surfaceContainer: Color(0xFF1C222C),
      surfaceContainerHigh: Color(0xFF242A36),
      surfaceContainerHighest: Color(0xFF2E3542),
      onSurfaceVariant: Color(0xFFB5BEB8),
      outline: AppColors.outline,
      outlineVariant: Color(0xFF424A45),
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF101419),
      textTheme: TextTheme(
        headlineLarge: AppTypography.headlineLarge.copyWith(color: const Color(0xFFE2E7FF)),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: const Color(0xFFE2E7FF)),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: const Color(0xFFE2E7FF)),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: const Color(0xFFE2E7FF)),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: const Color(0xFFE2E7FF)),
        bodySmall: AppTypography.bodySmall.copyWith(color: const Color(0xFFB5BEB8)),
        labelLarge: AppTypography.labelUi.copyWith(color: const Color(0xFFE2E7FF)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF101419),
        foregroundColor: const Color(0xFFE2E7FF),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(
          color: const Color(0xFFE2E7FF),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF161A22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF424A45), width: 1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF161A22),
        indicatorColor: AppColors.secondary,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryFixedDim,
            );
          }
          return AppTypography.bodySmall.copyWith(
            color: const Color(0xFFB5BEB8),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.onSecondaryFixed);
          }
          return const IconThemeData(color: Color(0xFFB5BEB8));
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      extensions: const <ThemeExtension<dynamic>>[
        AgriThemeExtension.standard,
      ],
    );
  }
}
