import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../game_01.dart';
import 'column_component.dart';
import 'camera_shake.dart';

class ObstaclePair extends PositionComponent with HasGameRef<Game01> {
  ObstaclePair({
    required this.gameSize,
    required this.topSprite,
    required this.midSprite,
    required this.gap,
    required this.speed,
    required this.tubeWidthFactor,
  });

  final Vector2 gameSize;
  final Sprite topSprite;
  final Sprite midSprite;
  final double gap;
  final double speed;
  final double tubeWidthFactor;
  bool scored = false;

  // Vertical drift
  late final double _verticalAmplitude;
  late final double _verticalSpeed;
  late final double _verticalPhase;
  double _t = 0;
  late double _baseTopY;
  late double _baseBottomY;
  late double _bottomHeight;

  late ColumnComponent topColumn;
  late ColumnComponent bottomColumn;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 🔥 CLAVE: tamaño del padre
    size = Vector2(gameSize.x + 100, gameSize.y);

    final random = Random();
    const minMargin = 12.0; // minimal margin to maximize column height
    const double extraStretch =
        96.0; // over-extend columns to avoid visible gaps

    // 🎯 AJUSTE: Limitar el rango vertical para que el gap sea alcanzable
    // Definimos una zona "jugable" más centrada (dejamos 25% arriba y 25% abajo)
    final usableHeight = gameSize.y - minMargin * 2;
    final screenCenter = gameSize.y / 2;

    // El gap puede aparecer en el 50% central de la pantalla (25% arriba y 25% abajo del centro)
    final safeZoneHeight = usableHeight * 0.50; // 50% del alto total
    final safeZoneStart = screenCenter - (safeZoneHeight / 2);
    final safeZoneEnd = screenCenter + (safeZoneHeight / 2);

    // Generamos el centro del gap dentro de la zona segura
    final gapCenterY = safeZoneStart + random.nextDouble() * safeZoneHeight;
    final gapTop = gapCenterY - (gap / 2);

    // Aseguramos que el gap no se salga de los límites mínimos
    final clampedGapTop = gapTop.clamp(minMargin, gameSize.y - gap - minMargin);

    final topHeight =
        clampedGapTop + extraStretch; // extends upward, bottom stays at gapTop
    final bottomY = clampedGapTop + gap; // keep gap start intact
    final bottomHeight =
        gameSize.y - bottomY + extraStretch; // extends downward
    _baseTopY = -extraStretch;
    _baseBottomY = bottomY;
    _bottomHeight = bottomHeight;

    topColumn = ColumnComponent(
      capNearGap: topSprite,
      mid: midSprite,
      capFarFromGap: topSprite,
      heightPx: topHeight,
      widthFactor: tubeWidthFactor,
      speed: speed,
    )..position = Vector2(gameSize.x, 0);

    bottomColumn = ColumnComponent(
      capNearGap: topSprite,
      mid: midSprite,
      capFarFromGap: topSprite,
      heightPx: bottomHeight,
      widthFactor: tubeWidthFactor,
      speed: speed,
    )..position = Vector2(gameSize.x, bottomY);

    add(topColumn);
    add(bottomColumn);

    // Vertical drift parameters (small, gentle movement)
    _verticalAmplitude = random.nextDouble() * 16 + 8; // 8..24 px
    _verticalSpeed = random.nextDouble() * 0.6 + 0.6; // 0.6..1.2 rad/s
    _verticalPhase = random.nextDouble() * pi * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isPaused || game.isGameOver) {
      return;
    }

    if (!scored &&
        (topColumn.position.x + topColumn.size.x) < game.player!.position.x) {
      scored = true;
      game.addPoint();
      _spawnPassParticles();

      // Shake leve al pasar obstáculo
      CameraShake.shake(intensity: 0.15, duration: 0.15);
    }

    _t += dt;
    _applyVerticalDrift();

    if (topColumn.position.x + topColumn.size.x < 0) {
      removeFromParent();
    }
  }

  void _applyVerticalDrift() {
    final rawOffset =
        sin(_t * _verticalSpeed + _verticalPhase) * _verticalAmplitude;
    // Allow gentle wiggle up/down; clamp to avoid extreme shifts
    const double clampRange = 24;
    final offset = rawOffset.clamp(-clampRange, clampRange);

    topColumn.position.y = _baseTopY + offset;
    bottomColumn.position.y = _baseBottomY + offset;
  }

  void _spawnPassParticles() {
    final rand = Random();
    final gapCenterY = bottomColumn.position.y - (gap / 2);

    // Partículas desde ambos lados del gap
    for (var side in [
      topColumn.position.y + topColumn.size.y,
      bottomColumn.position.y,
    ]) {
      gameRef.add(
        ParticleSystemComponent(
          position: Vector2(topColumn.position.x + topColumn.size.x / 2, side),
          anchor: Anchor.center,
          particle: Particle.generate(
            count: 8,
            lifespan: 0.5,
            generator: (i) {
              final angle =
                  (side < gapCenterY ? pi / 2 : -pi / 2) +
                  (rand.nextDouble() - 0.5) * pi * 0.5;
              final speed = 80 + rand.nextDouble() * 60;
              final dir = Vector2(cos(angle), sin(angle));

              return AcceleratedParticle(
                speed: dir * speed,
                acceleration: Vector2.zero(),
                child: CircleParticle(
                  radius: 1.5 + rand.nextDouble() * 1.5,
                  paint: Paint()
                    ..color = const Color(0xFF00FFB3).withOpacity(0.8)
                    ..blendMode = BlendMode.plus,
                ),
              );
            },
          ),
        ),
      );
    }

    // Burst central celebratorio
    gameRef.add(
      ParticleSystemComponent(
        position: Vector2(topColumn.position.x + topColumn.size.x, gapCenterY),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: 12,
          lifespan: 0.6,
          generator: (i) {
            final angle = (i / 12) * pi * 2;
            final speed = 100 + rand.nextDouble() * 80;
            final dir = Vector2(cos(angle), sin(angle));

            return AcceleratedParticle(
              speed: dir * speed,
              acceleration: dir * -100,
              child: CircleParticle(
                radius: 2,
                paint: Paint()
                  ..color = const Color(0xFFFFFFFF).withOpacity(0.9)
                  ..blendMode = BlendMode.plus,
              ),
            );
          },
        ),
      ),
    );
  }
}
