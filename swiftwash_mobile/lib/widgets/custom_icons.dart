import 'package:flutter/material.dart';

class TruckIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(24, 24),
      painter: _TruckPainter(),
    );
  }
}

class _TruckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4aae5a)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..lineTo(size.width * 0.2, size.height * 0.8)
      ..arcToPoint(Offset(size.width * 0.3, size.height * 0.7), radius: Radius.circular(size.width * 0.1))
      ..lineTo(size.width * 0.3, size.height * 0.4)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.7)
      ..arcToPoint(Offset(size.width * 0.8, size.height * 0.8), radius: Radius.circular(size.width * 0.1))
      ..lineTo(size.width * 0.7, size.height * 0.8)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class BasketIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(24, 24),
      painter: _BasketPainter(),
    );
  }
}

class _BasketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2397eb)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.4)
      ..lineTo(size.width * 0.8, size.height * 0.4)
      ..lineTo(size.width * 0.9, size.height * 0.8)
      ..lineTo(size.width * 0.1, size.height * 0.8)
      ..close();

    canvas.drawPath(path, paint);

    final handlePaint = Paint()
      ..color = const Color(0xFF2397eb)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final handlePath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width * 0.7, size.height * 0.4);

    canvas.drawPath(handlePath, handlePaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
