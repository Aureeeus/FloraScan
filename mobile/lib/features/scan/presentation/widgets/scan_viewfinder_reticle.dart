import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Renders tactical viewfinder corner reticles with botanical leaf silhouette
/// and active augmented reality framing guidance to ensure high-SNR optical inference.
class ScanViewfinderReticle extends StatelessWidget {
  const ScanViewfinderReticle({
    super.key,
    this.isFrameAligned = true,
    this.cameraPreview,
  });

  /// True when the leaf occupies optimal viewfinder area.
  final bool isFrameAligned;

  /// Optional live camera feed widget displayed underneath the AR overlay.
  final Widget? cameraPreview;

  @override
  Widget build(BuildContext context) {
    final activeColor = isFrameAligned ? AppColors.leafBright : AppColors.solarAmber;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white38, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          alignment: Alignment.center,
          children: [
            // Live Camera Feed under AR Overlay (or fallback dark canvas)
            if (cameraPreview != null)
              cameraPreview!
            else
              Container(
                color: const Color(0xFF0F172A),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white.withValues(alpha: 0.2),
                        size: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Align foliage within reticle',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // AR Leaf Silhouette Alignment Guide (60-80% bounding area)
            Center(
              child: CustomPaint(
                size: const Size(200, 200),
                painter: _LeafSilhouettePainter(
                  strokeColor: activeColor.withValues(alpha: 0.5),
                ),
              ),
            ),

            // Top Left Bracket
            Positioned(
              top: 0,
              left: 0,
              child: _CornerBracket(
                alignment: Alignment.topLeft,
                color: activeColor,
              ),
            ),
            // Top Right Bracket
            Positioned(
              top: 0,
              right: 0,
              child: _CornerBracket(
                alignment: Alignment.topRight,
                color: activeColor,
              ),
            ),
            // Bottom Left Bracket
            Positioned(
              bottom: 0,
              left: 0,
              child: _CornerBracket(
                alignment: Alignment.bottomLeft,
                color: activeColor,
              ),
            ),
            // Bottom Right Bracket
            Positioned(
              bottom: 0,
              right: 0,
              child: _CornerBracket(
                alignment: Alignment.bottomRight,
                color: activeColor,
              ),
            ),

            // Tactical Crosshair & Center Focal Dot
            const Center(
              child: SizedBox(
                width: 10,
                height: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.leafBright,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // Bottom In-Viewfinder Framing Pill
            Positioned(
              bottom: 10,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: activeColor.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome, size: 11, color: activeColor),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'ALIGN LEAF IN FRAME',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelUi.copyWith(
                            color: Colors.white,
                            fontSize: 9.5,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
      width: 32,
      height: 32,
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

/// Custom painter rendering an elegant botanical leaf contour guide.
class _LeafSilhouettePainter extends CustomPainter {
  const _LeafSilhouettePainter({required this.strokeColor});

  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Symmetrical Solanaceae ovate leaf contour
    path.moveTo(w * 0.50, h * 0.08); // Leaf apex
    path.cubicTo(w * 0.82, h * 0.28, w * 0.90, h * 0.65, w * 0.50, h * 0.88); // Right margin
    path.cubicTo(w * 0.10, h * 0.65, w * 0.18, h * 0.28, w * 0.50, h * 0.08); // Left margin

    // Central primary midrib vein
    path.moveTo(w * 0.50, h * 0.16);
    path.lineTo(w * 0.50, h * 0.85);

    // Lateral secondary veins
    path.moveTo(w * 0.50, h * 0.38);
    path.quadraticBezierTo(w * 0.65, h * 0.35, w * 0.72, h * 0.42);

    path.moveTo(w * 0.50, h * 0.38);
    path.quadraticBezierTo(w * 0.35, h * 0.35, w * 0.28, h * 0.42);

    path.moveTo(w * 0.50, h * 0.56);
    path.quadraticBezierTo(w * 0.66, h * 0.54, w * 0.74, h * 0.62);

    path.moveTo(w * 0.50, h * 0.56);
    path.quadraticBezierTo(w * 0.34, h * 0.54, w * 0.26, h * 0.62);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LeafSilhouettePainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor;
  }
}
