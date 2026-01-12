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
    this.shadowOpacity = 0.18,
    this.shadowBlurSigma = 2.6,
    this.shadowInflate = 1.2,
    this.shadowOffset = const Offset(0, 1.0),
  }) : super(anchor: Anchor.topLeft);

  final int colorSeed;

  bool isMoving;
  double speed;
  bool isDropping = false;
  double vy = 0;
  double gravity = 0;

  final ui.Image? towerImage;
  final double imageScale;

  /// Sombra/glow negro sutil para separar del fondo.
  /// Mantener valores bajos para que quede "pegada".
  final double shadowOpacity;
  final double shadowBlurSigma;
  final double shadowInflate;
  final Offset shadowOffset;

  final Paint _paint = Paint()..style = PaintingStyle.fill;
  bool _colorInitialized = false;

  Color? _colorFrom;
  Color? _colorTo;
  double _colorElapsed = 0;
  double _colorDuration = 0;

  double opacity = 1.0;

  Paint _shadowPaint() {
    return Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withOpacity(shadowOpacity.clamp(0.0, 1.0))
      ..maskFilter = ui.MaskFilter.blur(
        ui.BlurStyle.normal,
        shadowBlurSigma.clamp(0.0, 20.0),
      );
  }

  @override
  void onLoad() {
    super.onLoad();

    // Color default (si no fue seteado desde afuera)
    if (!_colorInitialized) {
      final hue = (colorSeed * 35) % 360;
      _paint.color = HSVColor.fromAHSV(1, hue.toDouble(), 0.75, 0.95).toColor();
      _colorInitialized = true;
    }
  }

  Color get color => _paint.color;

  void setColor(Color color) {
    _paint.color = color;
    _colorInitialized = true;
    _colorFrom = null;
    _colorTo = null;
    _colorElapsed = 0;
    _colorDuration = 0;
  }

  void animateColorTo(Color target, {double duration = 0.42}) {
    if (!_colorInitialized) {
      setColor(target);
      return;
    }

    if (_paint.color.value == target.value) {
      _colorFrom = null;
      _colorTo = null;
      _colorElapsed = 0;
      _colorDuration = 0;
      return;
    }

    _colorFrom = _paint.color;
    _colorTo = target;
    _colorElapsed = 0;
    _colorDuration = duration <= 0 ? 0.0001 : duration;
  }

  void _updateColor(double dt) {
    final to = _colorTo;
    final from = _colorFrom;
    if (to == null || from == null) return;

    _colorElapsed += dt;
    final t = (_colorElapsed / _colorDuration).clamp(0.0, 1.0);
    final eased = Curves.easeInOut.transform(t);
    _paint.color = Color.lerp(from, to, eased) ?? _paint.color;

    if (t >= 1.0) {
      _paint.color = to;
      _colorFrom = null;
      _colorTo = null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Animación de color es visual: que corra incluso si el gameplay está pausado.
    _updateColor(dt);

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

    // Glow/sombra negra sutil (pegada) para separar del fondo.
    if (shadowOpacity > 0 && shadowBlurSigma > 0) {
      final glowRect = dst.inflate(shadowInflate);
      final glowRRect = RRect.fromRectAndRadius(
        glowRect.shift(shadowOffset),
        const Radius.circular(8),
      );
      canvas.drawRRect(glowRRect, _shadowPaint());
    }

    final img = towerImage;

    // Si no hay imagen, usamos un fallback simple coloreado.
    if (img == null) {
      final baseColorPaint = Paint()
        ..color = _paint.color.withOpacity(opacity.clamp(0, 1));
      canvas.drawRRect(rrect, baseColorPaint);
      return;
    }

    final src = Rect.fromLTWH(
      0,
      0,
      img.width.toDouble(),
      img.height.toDouble(),
    );

    // Pintar la imagen como máscara y tintar sólo el contenido (la parte verde),
    // sin afectar el fondo transparente.
    canvas.saveLayer(dst, Paint());
    canvas.drawImageRect(
      img,
      src,
      Rect.fromLTWH(0, 0, dst.width, dst.height),
      Paint(),
    );
    canvas.drawRect(
      dst,
      Paint()
        ..blendMode = BlendMode.srcIn
        ..color = _paint.color.withOpacity(opacity.clamp(0, 1)),
    );
    canvas.restore();
  }
}
