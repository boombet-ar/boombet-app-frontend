import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DarkOverlay extends RectangleComponent {
  DarkOverlay(Vector2 gameSize)
    : super(
        size: gameSize,
        position: Vector2.zero(),
        paint: Paint()..color = Colors.black.withOpacity(0.50), // 👈 AJUSTÁ ACÁ
      );
}
