import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Custom ThemeExtension providing domain-specific AgriTech semantic colors.
///
/// Ensures strict type-safety and seamless access to telemetry indicators
/// and plant pathology status colors across the application.
@immutable
class AgriThemeExtension extends ThemeExtension<AgriThemeExtension> {
  const AgriThemeExtension({
    required this.foliageMid,
    required this.bioLeafEmerald,
    required this.leafBright,
    required this.richOchreSoil,
    required this.soilAmberLight,
    required this.moistureCyan,
    required this.ambientTeal,
    required this.solarAmber,
    required this.canopyCoral,
    required this.healthyVigor,
    required this.cautionStress,
    required this.severeOutbreak,
  });

  final Color foliageMid;
  final Color bioLeafEmerald;
  final Color leafBright;
  final Color richOchreSoil;
  final Color soilAmberLight;
  final Color moistureCyan;
  final Color ambientTeal;
  final Color solarAmber;
  final Color canopyCoral;
  final Color healthyVigor;
  final Color cautionStress;
  final Color severeOutbreak;

  /// Default agricultural light theme instance.
  static const AgriThemeExtension standard = AgriThemeExtension(
    foliageMid: AppColors.foliageMid,
    bioLeafEmerald: AppColors.bioLeafEmerald,
    leafBright: AppColors.leafBright,
    richOchreSoil: AppColors.richOchreSoil,
    soilAmberLight: AppColors.soilAmberLight,
    moistureCyan: AppColors.moistureCyan,
    ambientTeal: AppColors.ambientTeal,
    solarAmber: AppColors.solarAmber,
    canopyCoral: AppColors.canopyCoral,
    healthyVigor: AppColors.healthyVigor,
    cautionStress: AppColors.cautionStress,
    severeOutbreak: AppColors.severeOutbreak,
  );

  @override
  AgriThemeExtension copyWith({
    Color? foliageMid,
    Color? bioLeafEmerald,
    Color? leafBright,
    Color? richOchreSoil,
    Color? soilAmberLight,
    Color? moistureCyan,
    Color? ambientTeal,
    Color? solarAmber,
    Color? canopyCoral,
    Color? healthyVigor,
    Color? cautionStress,
    Color? severeOutbreak,
  }) {
    return AgriThemeExtension(
      foliageMid: foliageMid ?? this.foliageMid,
      bioLeafEmerald: bioLeafEmerald ?? this.bioLeafEmerald,
      leafBright: leafBright ?? this.leafBright,
      richOchreSoil: richOchreSoil ?? this.richOchreSoil,
      soilAmberLight: soilAmberLight ?? this.soilAmberLight,
      moistureCyan: moistureCyan ?? this.moistureCyan,
      ambientTeal: ambientTeal ?? this.ambientTeal,
      solarAmber: solarAmber ?? this.solarAmber,
      canopyCoral: canopyCoral ?? this.canopyCoral,
      healthyVigor: healthyVigor ?? this.healthyVigor,
      cautionStress: cautionStress ?? this.cautionStress,
      severeOutbreak: severeOutbreak ?? this.severeOutbreak,
    );
  }

  @override
  AgriThemeExtension lerp(
    covariant ThemeExtension<AgriThemeExtension>? other,
    double t,
  ) {
    if (other is! AgriThemeExtension) return this;

    return AgriThemeExtension(
      foliageMid: Color.lerp(foliageMid, other.foliageMid, t) ?? foliageMid,
      bioLeafEmerald: Color.lerp(bioLeafEmerald, other.bioLeafEmerald, t) ?? bioLeafEmerald,
      leafBright: Color.lerp(leafBright, other.leafBright, t) ?? leafBright,
      richOchreSoil: Color.lerp(richOchreSoil, other.richOchreSoil, t) ?? richOchreSoil,
      soilAmberLight: Color.lerp(soilAmberLight, other.soilAmberLight, t) ?? soilAmberLight,
      moistureCyan: Color.lerp(moistureCyan, other.moistureCyan, t) ?? moistureCyan,
      ambientTeal: Color.lerp(ambientTeal, other.ambientTeal, t) ?? ambientTeal,
      solarAmber: Color.lerp(solarAmber, other.solarAmber, t) ?? solarAmber,
      canopyCoral: Color.lerp(canopyCoral, other.canopyCoral, t) ?? canopyCoral,
      healthyVigor: Color.lerp(healthyVigor, other.healthyVigor, t) ?? healthyVigor,
      cautionStress: Color.lerp(cautionStress, other.cautionStress, t) ?? cautionStress,
      severeOutbreak: Color.lerp(severeOutbreak, other.severeOutbreak, t) ?? severeOutbreak,
    );
  }
}

/// Convenience extension on [BuildContext] for ergonomic retrieval.
extension AgriThemeContext on BuildContext {
  AgriThemeExtension get agriTheme =>
      Theme.of(this).extension<AgriThemeExtension>() ?? AgriThemeExtension.standard;
}
