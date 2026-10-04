import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Renders tactical viewfinder corner reticles for leaf disease targeting.
class ScanViewfinderReticle extends StatelessWidget {
  const ScanViewfinderReticle({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Top Left Bracket
            Positioned(
              top: 0,
              left: 0,
              child: _CornerBracket(
                alignment: Alignment.topLeft,
                color: AppColors.leafBright,
              ),
            ),
            // Top Right Bracket
            Positioned(
              top: 0,
              right: 0,
              child: _CornerBracket(
                alignment: Alignment.topRight,
                color: AppColors.leafBright,
              ),
            ),
            // Bottom Left Bracket
            Positioned(
              bottom: 0,
              left: 0,
              child: _CornerBracket(
                alignment: Alignment.bottomLeft,
                color: AppColors.leafBright,
              ),
            ),
            // Bottom Right Bracket
            Positioned(
              bottom: 0,
              right: 0,
              child: _CornerBracket(
                alignment: Alignment.bottomRight,
                color: AppColors.leafBright,
              ),
            ),
            // Center focal dot
            const Center(
              child: SizedBox(
                width: 8,
                height: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.leafBright,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({
    required this.alignment,
    required this.color,
  });

  final Alignment alignment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: alignment == Alignment.topLeft || alignment == Alignment.topRight
              ? BorderSide(color: color, width: 3.5)
              : BorderSide.none,
          bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
              ? BorderSide(color: color, width: 3.5)
              : BorderSide.none,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
              ? BorderSide(color: color, width: 3.5)
              : BorderSide.none,
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
              ? BorderSide(color: color, width: 3.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
