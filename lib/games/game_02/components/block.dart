import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:boombet_app/games/game_02/game_02.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BlockComponent extends PositionComponent with HasGameRef<Game02> {
  BlockComponent({
    required super.position,
    required super.size,
    required this.colorSeed,
    required this.isMoving,
    required this.speed,
    required this.towerImage,
    required this.sliceTop,
    required this.sliceHeight,
  }) : super(anchor: Anchor.topLeft);

  final int colorSeed;

  bool isMoving;
  double speed;
  bool isDropping = false;
  double vy = 0;
  double gravity = 0;

  final ui.Image? towerImage;
  final double sliceTop;
  final double sliceHeight;

  final Paint _paint = Paint()..style = PaintingStyle.fill;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  @override
  void onLoad() {
    super.onLoad();

    // Color “vivo” basado en seed (sin assets)
    final hue = (colorSeed * 35) % 360;
    _paint.color = HSVColor.fromAHSV(1, hue.toDouble(), 0.75, 0.95).toColor();

    _stroke.color = Colors.black.withOpacity(0.15);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDropping) {
      position.y += vy * dt;
      vy += gravity * dt;
      return;
    }

    if (!isMoving) return;

    position.x += speed * dt;

    // rebote en bordes de pantalla
    if (position.x <= 0) {
      position.x = 0;
      speed = speed.abs();
    }

    final maxX = gameRef.size.x - size.x;
    if (position.x >= maxX) {
      position.x = maxX;
      speed = -speed.abs();
    }
  }

  void startDrop(double g) {
    isMoving = false;
    isDropping = true;
    vy = 0;
    gravity = g;
  }

@override
  void render(Canvas canvas) {
    super.render(canvas);

    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    final img = towerImage;

    if (img != null && img.width > 0 && img.height > 0) {
      final double srcWidth = math.min(img.width.toDouble(), size.x);

      final src = Rect.fromLTWH(0, sliceTop, srcWidth, sliceHeight);

      final paint = Paint()
        ..colorFilter = ColorFilter.mode(
          _paint.color.withOpacity(0.85),
          BlendMode.modulate,
        );

      canvas.drawImageRect(img, src, dst, paint);
    } else {
      // fallback sólido
      final rrect = RRect.fromRectAndRadius(dst, const Radius.circular(8));
      canvas.drawRRect(rrect, _paint);
    }

    final rrect = RRect.fromRectAndRadius(dst, const Radius.circular(6));
    canvas.drawRRect(rrect, _stroke);
  }

}
