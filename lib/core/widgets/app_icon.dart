import 'package:flutter/material.dart';

/// The FloraScan official app icon vector rendered faithfully from Google Stitch.
class FloraScanAppIcon extends StatelessWidget {
  const FloraScanAppIcon({
    super.key,
    this.size = 36,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B4332),
            Color(0xFF081C15),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33012D1D),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.7, size * 0.7),
          painter: _AppIconPainter(),
        ),
      ),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stylized Leaf Path
    final leafPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF74C69D), Color(0xFF40916C)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final leafPath = Path()
      ..moveTo(w * 0.5, w * 0.15)
      ..cubicTo(w * 0.85, h * 0.25, w * 0.95, h * 0.65, w * 0.75, h * 0.85)
      ..cubicTo(w * 0.55, h * 1.05, w * 0.25, h * 0.95, w * 0.15, h * 0.75)
      ..cubicTo(w * 0.05, h * 0.55, w * 0.25, h * 0.25, w * 0.5, h * 0.15)
      ..close();

    canvas.drawPath(leafPath, leafPaint);

    // Stem / Probe Line
    final stemPaint = Paint()
      ..color = const Color(0xFF1B4332)
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final stemPath = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..quadraticBezierTo(w * 0.5, h * 0.65, w * 0.3, h * 0.85);

    canvas.drawPath(stemPath, stemPaint);

    // Glowing tip node
    final glowPaint = Paint()
      ..color = const Color(0xFFD8F3DC)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.18), w * 0.1, glowPaint);

    final innerTip = Paint()
      ..color = const Color(0xFF1B4332)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.18), w * 0.05, innerTip);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
