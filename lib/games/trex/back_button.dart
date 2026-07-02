import 'dart:ui';

import 'package:flame/components.dart';

class BackButtonComponent extends PositionComponent {
  BackButtonComponent()
    : super(size: Vector2(40, 40), position: Vector2(10, 10));

  @override
  void render(Canvas canvas) {
    // Dark rounded rectangle – matches the game's restart button colour
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFF535353),
    );

    // White chevron arrow pointing left
    final arrowPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.x * 0.55, size.y * 0.28)
      ..lineTo(size.x * 0.32, size.y * 0.50)
      ..lineTo(size.x * 0.55, size.y * 0.72);

    canvas.drawPath(path, arrowPaint);
  }
}
