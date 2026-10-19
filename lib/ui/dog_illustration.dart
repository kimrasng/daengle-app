import 'package:flutter/material.dart';

import 'shared.dart' show brandColor, tintBackground;

/// Original vector artwork, rendered crisply at any device scale.
class DogIllustration extends StatelessWidget {
  final double size;
  const DogIllustration({super.key, this.size = 132});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _DogPainter()),
    ),
  );
}

class _DogPainter extends CustomPainter {
  const _DogPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 200);
    final paint = Paint()..isAntiAlias = true;
    void oval(Rect rect, Color color) {
      canvas.drawOval(rect, paint..color = color);
    }

    void round(Rect rect, double radius, Color color) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(radius)),
        paint..color = color,
      );
    }

    oval(const Rect.fromLTWH(15, 17, 167, 167), tintBackground);
    oval(const Rect.fromLTWH(34, 169, 132, 13), const Color(0xFFD9E1D3));
    round(const Rect.fromLTWH(63, 123, 76, 49), 24, const Color(0xFFF4DEBD));
    round(const Rect.fromLTWH(58, 150, 31, 26), 13, const Color(0xFFFFEDD4));
    round(const Rect.fromLTWH(113, 150, 31, 26), 13, const Color(0xFFFFEDD4));
    round(const Rect.fromLTWH(62, 123, 78, 17), 8, brandColor);
    oval(const Rect.fromLTWH(91, 134, 17, 17), const Color(0xFFD7C69F));
    // Floppy ears frame a rounded face, with a small white muzzle.
    oval(const Rect.fromLTWH(34, 53, 40, 79), const Color(0xFFC99B70));
    oval(const Rect.fromLTWH(131, 53, 38, 79), const Color(0xFFC99B70));
    round(const Rect.fromLTWH(51, 44, 100, 95), 42, const Color(0xFFFFE8C7));
    oval(const Rect.fromLTWH(65, 88, 20, 13), const Color(0xFFF7C9A7));
    oval(const Rect.fromLTWH(118, 88, 20, 13), const Color(0xFFF7C9A7));
    oval(const Rect.fromLTWH(77, 92, 48, 38), const Color(0xFFFFF8ED));
    oval(const Rect.fromLTWH(77, 77, 7, 9), const Color(0xFF493E37));
    oval(const Rect.fromLTWH(119, 77, 7, 9), const Color(0xFF493E37));
    round(const Rect.fromLTWH(94, 94, 14, 10), 5, const Color(0xFF493E37));
    final smile = Path()
      ..moveTo(91, 111)
      ..quadraticBezierTo(101, 121, 111, 111);
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF493E37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    round(const Rect.fromLTWH(148, 22, 37, 33), 12, Colors.white);
    final heart = Path()
      ..moveTo(166.5, 45)
      ..cubicTo(150, 35, 161, 27, 166.5, 34)
      ..cubicTo(173, 27, 183, 35, 166.5, 45);
    canvas.drawPath(heart, paint..color = brandColor);
    oval(const Rect.fromLTWH(18, 42, 15, 15), const Color(0xFFDFD1AF));
    oval(const Rect.fromLTWH(160, 143, 12, 12), const Color(0xFFACBBA3));
  }

  @override
  bool shouldRepaint(covariant _DogPainter oldDelegate) => false;
}
