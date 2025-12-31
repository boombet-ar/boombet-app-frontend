import 'dart:math';
import 'dart:ui';
import 'package:boombet_app/games/game_01/game_01.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import 'ground.dart';
import 'column_component.dart';
import 'camera_shake.dart';
import 'particle_trail.dart';

class Player extends SpriteComponent
    with CollisionCallbacks, HasGameRef<Game01> {
  Player({required this.onDie, required Sprite sprite})
    : super(
        sprite: sprite,
        size: Vector2(40, 40),
        anchor: Anchor.center,
        paint: Paint()..filterQuality = FilterQuality.none,
      );

  final VoidCallback onDie;

  double velocity = 0;

  // Physic tuning: vertical but un poco más controlable
  final double gravity = 1250;
  final double jumpImpulse = -410;
  final double maxFallSpeed = 680;
  final double maxRiseSpeed = -480;
  final double rotationLerp = 13;

  bool isAlive = true;
  late CircleComponent _halo;

  // Animación de sprite
  double _flapTimer = 0;
  static const double _flapDuration = 0.15;
  bool _isFlapping = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleHitbox.relative(
          Vector2(0.7, 0.7),
          parentSize: size,
          position: (size * 0.15),
        )
        ..collisionType = CollisionType.active
        ..debugMode = false
        ..renderShape = false
        ..isSolid = false,
    );

    // Halo sutil
    _halo = CircleComponent(
      radius: 18,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0xFF00FFB3).withOpacity(0.08)
        ..blendMode = BlendMode.srcOver,
    );

    add(_halo);

    // Agregar trail de partículas
    add(ParticleTrail(target: this));
  }

  @override
  void update(double dt) {
    if (!isAlive || gameRef.isPaused) return;

    velocity += gravity * dt;
    velocity = velocity.clamp(maxRiseSpeed, maxFallSpeed);

    position.y += velocity * dt;

    final targetAngle = (velocity / maxFallSpeed).clamp(-1.0, 1.0) * 0.38;
    angle = lerpDouble(angle, targetAngle, (rotationLerp * dt).clamp(0, 1))!;

    // Animación de aleteo
    if (_isFlapping) {
      _flapTimer += dt;
      if (_flapTimer >= _flapDuration) {
        _isFlapping = false;
        _flapTimer = 0;
        scale = Vector2.all(1.0);
      } else {
        // Efecto de squeeze y stretch
        final progress = _flapTimer / _flapDuration;
        final scaleX = 1.0 + sin(progress * pi) * 0.15;
        final scaleY = 1.0 - sin(progress * pi) * 0.15;
        scale = Vector2(scaleX, scaleY);
      }
    }
  }

  void flap() {
    if (!isAlive) return;
    velocity = jumpImpulse;
    gameRef.playFlap();
    _isFlapping = true;
    _flapTimer = 0;
    _burst();
  }

  void die() {
    if (!isAlive) return;
    isAlive = false;
    velocity = 0;
    _halo.removeFromParent();

    // Shake de cámara al morir
    CameraShake.shake(intensity: 0.8, duration: 0.4);

    _deathBurst();
    removeFromParent();
    onDie();
  }

  void _burst() {
    if (!isMounted || isRemoving) return;

    final rand = Random();
    const count = 10;
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: count,
          lifespan: 0.35,
          generator: (i) {
            final angle = (i / count) * pi + rand.nextDouble() * 0.35;
            final speed = 100 + rand.nextDouble() * 80;
            final dir = Vector2(cos(angle), sin(angle));
            return AcceleratedParticle(
              speed: dir * speed,
              acceleration: Vector2.zero(),
              child: CircleParticle(
                radius: 2.5,
                paint: Paint()
                  ..color = const Color(0xFF00FFB3).withOpacity(0.95),
              ),
            );
          },
        ),
      ),
    );
  }

  void _deathBurst() {
    if (!isMounted || isRemoving) return;

    final rand = Random();

    // Explosión principal - más partículas y más dramática
    const mainCount = 35;
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: mainCount,
          lifespan: 1.2,
          generator: (i) {
            final angle = (i / mainCount) * pi * 2 + rand.nextDouble() * 0.3;
            final speed = 150 + rand.nextDouble() * 200;
            final dir = Vector2(cos(angle), sin(angle));
            final size = 2.5 + rand.nextDouble() * 3.5;

            return AcceleratedParticle(
              speed: dir * speed,
              acceleration: dir * -120,
              child: ComputedParticle(
                lifespan: 1.2,
                renderer: (canvas, particle) {
                  final progress = particle.progress;
                  final currentSize = size * (1 - progress * 0.7);
                  final opacity = (1 - progress).clamp(0.0, 1.0);

                  final paint = Paint()
                    ..color = Color.lerp(
                      const Color(0xFF00FFB3),
                      const Color(0xFFFF3366),
                      progress * 0.6,
                    )!.withOpacity(opacity)
                    ..blendMode = BlendMode.plus;

                  canvas.drawCircle(Offset.zero, currentSize, paint);
                },
              ),
            );
          },
        ),
      ),
    );

    // Onda de choque
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        anchor: Anchor.center,
        particle: ComputedParticle(
          lifespan: 0.5,
          renderer: (canvas, particle) {
            final progress = particle.progress;
            final radius = progress * 80;
            final opacity = (1 - progress) * 0.6;

            final paint = Paint()
              ..color = const Color(0xFF00FFB3).withOpacity(opacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3 * (1 - progress);

            canvas.drawCircle(Offset.zero, radius, paint);
          },
        ),
      ),
    );

    // Partículas secundarias más lentas
    const secondaryCount = 20;
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: secondaryCount,
          lifespan: 1.5,
          generator: (i) {
            final angle = rand.nextDouble() * pi * 2;
            final speed = 50 + rand.nextDouble() * 100;
            final dir = Vector2(cos(angle), sin(angle));

            return AcceleratedParticle(
              speed: dir * speed,
              acceleration: Vector2(0, 200), // Gravedad
              child: CircleParticle(
                radius: 1.5 + rand.nextDouble() * 2,
                paint: Paint()
                  ..color = const Color(0xFFFFFFFF).withOpacity(0.8),
              ),
            );
          },
        ),
      ),
    );
  }

  void _createSquashEffect() {
    // Efecto de aplastar al chocar contra el suelo
    if (!isMounted || isRemoving) return;

    final rand = Random();
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: 15,
          lifespan: 0.6,
          generator: (i) {
            final angle = -pi / 2 + (rand.nextDouble() - 0.5) * pi * 0.8;
            final speed = 80 + rand.nextDouble() * 100;
            final dir = Vector2(cos(angle), sin(angle));

            return AcceleratedParticle(
              speed: dir * speed,
              acceleration: Vector2(0, 300),
              child: CircleParticle(
                radius: 2 + rand.nextDouble() * 2,
                paint: Paint()
                  ..color = const Color(0xFFFFFFFF).withOpacity(0.7),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (gameRef.isInvulnerable) {
      return;
    }

    if (other is Ground) {
      // Efecto especial al chocar contra el suelo
      _createSquashEffect();
      CameraShake.shake(intensity: 1.0, duration: 0.5);
      die();
    } else if (other is ColumnComponent) {
      // Shake más leve al chocar con columnas
      CameraShake.shake(intensity: 0.6, duration: 0.3);
      die();
    }
  }
}
