import '../domain/entities/plant_model.dart';

/// Pure formatting utilities for displaying plant metadata and timestamps.
class PlantFormattingUtils {
  PlantFormattingUtils._();

  /// Formats a past DateTime into a human-readable, context-aware relative timestamp.
  /// Correctly discriminates singular vs plural units ('1 hr ago' vs '2 hrs ago').
  static String formatTimeAgo(DateTime dt, {DateTime? referenceTime}) {
    final now = referenceTime ?? DateTime.now();
    final diff = now.difference(dt);
    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return m == 1 ? '1 min ago' : '$m mins ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return h == 1 ? '1 hr ago' : '$h hrs ago';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return d == 1 ? 'Yesterday' : '$d days ago';
    }
    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return w == 1 ? '1 wk ago' : '$w wks ago';
    }
    final months = (diff.inDays / 30).floor();
    return months == 1 ? '1 mo ago' : '$months mos ago';
  }

  /// Builds clean, non-redundant metadata subtitle row.
  /// Avoids repeating crop name or variety if already included in the plant's name.
  static String buildPlantItemMetadata({
    required PlantModel plant,
    required String area,
    required String crop,
  }) {
    final stage = plant.stage.displayName;
    final parts = <String>[area];

    // Only include crop if not already present in the user-assigned plant name
    if (!plant.name.toLowerCase().contains(crop.toLowerCase())) {
      parts.add(crop);
    }

    // Only include variety if non-empty and distinct from both name and crop
    if (plant.variety.trim().isNotEmpty) {
      final v = plant.variety.trim();
      final lowerName = plant.name.toLowerCase();
      final lowerCrop = crop.toLowerCase();
      final lowerV = v.toLowerCase();
      if (!lowerName.contains(lowerV) && !lowerCrop.contains(lowerV)) {
        parts.add(v);
      }
    }

    // Growth stage provides immediate agronomic value without redundancy
    parts.add(stage);

    return parts.join(' • ');
  }

  /// Builds clean focal plant title without duplicate variety in parentheses.
  static String buildFocalPlantTitle(PlantModel plant) {
    final v = plant.variety.trim();
    if (v.isNotEmpty && !plant.name.toLowerCase().contains(v.toLowerCase())) {
      return '${plant.name} ($v)';
    }
    return plant.name;
  }

  /// Builds clean focal plant subtitle.
  static String buildFocalPlantSubtitle({
    required PlantModel plant,
    required String area,
    required String crop,
  }) {
    if (plant.name.toLowerCase().contains(crop.toLowerCase())) {
      return area;
    }
    return '$crop • $area';
  }
}
