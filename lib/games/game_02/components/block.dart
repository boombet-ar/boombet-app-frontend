import 'dart:ui' as ui;

import 'package:boombet_app/games/game_02/game_02.dart';
import 'package:flame/components.dart' hide Matrix4;
import 'package:flutter/material.dart';

class BlockComponent extends PositionComponent with HasGameRef<Game02> {
  BlockComponent({
    required super.position,
    required super.size,
    required this.colorSeed,
    required this.isMoving,
    required this.speed,
    required this.towerImage,
    required this.imageScale,
  }) : super(anchor: Anchor.topLeft);

  final int colorSeed;

  bool isMoving;
  double speed;
  bool isDropping = false;
  double vy = 0;
  double gravity = 0;

  final ui.Image? towerImage;
  final double imageScale;

  final Paint _paint = Paint()..style = PaintingStyle.fill;
  final Paint _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.0;

  double opacity = 1.0;

  // final Paint _glowPaint = Paint()
  //   ..style = PaintingStyle.fill
  //   ..color = const Color(0xCC000000)
  //   ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 8);

  @override
  void onLoad() {
    super.onLoad();

    // Color “vivo” basado en seed (sin assets)
    final hue = (colorSeed * 35) % 360;
    _paint.color = HSVColor.fromAHSV(1, hue.toDouble(), 0.75, 0.95).toColor();

    _stroke.color = Colors.transparent;
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Congelar gameplay mientras hay menú/pausa/countdown, pero seguir renderizando.
    if (gameRef.isPaused || gameRef.countdown.value != null) {
      return;
    }

    if (gameRef.state != StackState.playing) {
      return;
    }

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
    final rrect = RRect.fromRectAndRadius(dst, const Radius.circular(6));
    final glowRect = dst.inflate(2);
    final glowRRect = RRect.fromRectAndRadius(
      glowRect,
      const Radius.circular(8),
    );

    // Glow/sombra negra para separar del fondo
    // canvas.drawRRect(glowRRect, _glowPaint);

    final img = towerImage;

    // Fallback visual si no hay imagen
    if (img == null) {
      final p = Paint()..color = _paint.color.withOpacity(opacity.clamp(0, 1));
      canvas.drawRRect(rrect, p);
      return;
    }

    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );

    final paint = Paint()
      ..colorFilter = ColorFilter.mode(
        Colors.white.withOpacity(opacity.clamp(0, 1)),
        BlendMode.modulate,
      );

    canvas.save();
    // Ajustamos al tamaño del bloque usando drawImageRect (no slicing)
    canvas.drawImageRect(
      img,
      src,
      Rect.fromLTWH(0, 0, dst.width, dst.height),
      paint,
    );

    canvas.restore();
  }
}
