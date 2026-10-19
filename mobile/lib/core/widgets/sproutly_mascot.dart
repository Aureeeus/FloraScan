import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Cheerful Sproutly Mascot ("Sprouty") widget faithful to Google Stitch.
class SproutlyMascot extends StatelessWidget {
  const SproutlyMascot({
    super.key,
    this.size = 56,
    this.badgeEmoji,
    this.badgeColor,
    this.onTap,
  });

  final double size;
  final String? badgeEmoji;
  final Color? badgeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryFixed,
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.all(size * 0.08),
            child: CustomPaint(
              size: Size(size, size),
              painter: _SproutlyPainter(),
            ),
          ),
          if (badgeEmoji != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: size * 0.38,
                height: size * 0.38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor ?? AppColors.primaryContainer,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    badgeEmoji!,
                    style: TextStyle(fontSize: size * 0.2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SproutlyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Head circle
    final headPaint = Paint()
      ..color = const Color(0xFFC1ECD4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.58), w * 0.34, headPaint);

    // Left leaf
    final leafLeftPaint = Paint()
      ..color = const Color(0xFF116C4A)
      ..style = PaintingStyle.fill;
    final leafLeft = Path()
      ..moveTo(w * 0.5, h * 0.32)
      ..cubicTo(w * 0.5, h * 0.18, w * 0.38, h * 0.12, w * 0.28, h * 0.12)
      ..cubicTo(w * 0.28, h * 0.24, w * 0.38, h * 0.32, w * 0.5, h * 0.32)
      ..close();
    canvas.drawPath(leafLeft, leafLeftPaint);

    // Right leaf
    final leafRightPaint = Paint()
      ..color = const Color(0xFF86D7AD)
      ..style = PaintingStyle.fill;
    final leafRight = Path()
      ..moveTo(w * 0.5, h * 0.30)
      ..cubicTo(w * 0.52, h * 0.16, w * 0.65, h * 0.10, w * 0.76, h * 0.12)
      ..cubicTo(w * 0.76, h * 0.24, w * 0.62, h * 0.30, w * 0.5, h * 0.30)
      ..close();
    canvas.drawPath(leafRight, leafRightPaint);

    // Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFF6BB87)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.34, h * 0.61), w * 0.05, cheekPaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.61), w * 0.05, cheekPaint);

    // Eyes (Happy arcs)
    final eyePaint = Paint()
      ..color = const Color(0xFF012D1D)
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftEye = Path()
      ..moveTo(w * 0.37, h * 0.55)
      ..quadraticBezierTo(w * 0.41, h * 0.49, w * 0.45, h * 0.55);
    canvas.drawPath(leftEye, eyePaint);

    final rightEye = Path()
      ..moveTo(w * 0.55, h * 0.55)
      ..quadraticBezierTo(w * 0.59, h * 0.49, w * 0.63, h * 0.55);
    canvas.drawPath(rightEye, eyePaint);

    // Smiling mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF012D1D)
      ..strokeWidth = w * 0.04
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final mouth = Path()
      ..moveTo(w * 0.43, h * 0.63)
      ..quadraticBezierTo(w * 0.5, h * 0.71, w * 0.57, h * 0.63);
    canvas.drawPath(mouth, mouthPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
