import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HazardCircleComponent extends PositionComponent {
  HazardCircleComponent({
    required Vector2 position,
    required this.radius,
    required this.speed,
    this.direction = 1,
  }) : super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  final double radius;
  final double speed;
  int direction;

  final Paint _paint = Paint()
    ..color = const Color(0xFF00FF7A)
    ..style = PaintingStyle.fill;

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(radius, radius), radius, _paint);
  }
}
