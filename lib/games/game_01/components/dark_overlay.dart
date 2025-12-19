import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class DarkOverlay extends RectangleComponent with HasGameRef<FlameGame> {
  DarkOverlay(Vector2 gameSize)
    : super(
        size: gameSize,
        position: Vector2.zero(),
        paint: Paint()..color = Colors.black.withOpacity(0.38),
        anchor: Anchor.topLeft,
      );

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    size = canvasSize;
    position = Vector2.zero();
  }
}
