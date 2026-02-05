import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class PlatformComponent extends PositionComponent {
  PlatformComponent({
    required Vector2 position,
    required Vector2 size,
    this.isBreakable = true,
    this.breaksOnTouch = false,
    this.boostsOnTouch = false,
    this.boostMultiplier = 1.0,
    this.color,
  }) : super(position: position, size: size, anchor: Anchor.topLeft);

  final bool isBreakable;
  final bool breaksOnTouch;
  final bool boostsOnTouch;
  final double boostMultiplier;
  final Color? color;

  final Paint _paint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.fill;

  final Paint _dividerPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void render(Canvas canvas) {
    final rect = size.toRect();
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    if (breaksOnTouch) {
      _paint.color = const Color(0xFFFF6B6B);
    } else if (boostsOnTouch) {
      _paint.color = const Color(0xFFFFD166);
    } else if (color != null) {
      _paint.color = color!;
    } else {
      _paint.color = const Color(0xFFFFFFFF);
    }
    canvas.drawRRect(rrect, _paint);

    if (breaksOnTouch) {
      final midY = rect.top + rect.height / 2;
      canvas.drawLine(
        Offset(rect.left + 6, midY),
        Offset(rect.right - 6, midY),
        _dividerPaint,
      );
    } else if (boostsOnTouch) {
      final midX = rect.left + rect.width / 2;
      canvas.drawLine(
        Offset(midX, rect.top + 3),
        Offset(midX, rect.bottom - 3),
        _dividerPaint,
      );
    }
  }
}
