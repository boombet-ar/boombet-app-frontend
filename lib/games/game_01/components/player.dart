import 'dart:math';
import 'dart:ui';
import 'package:boombet_app/games/game_01/game_01.dart';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import 'ground.dart';
import 'column_component.dart';

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

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleHitbox.relative(
          Vector2(0.7, 0.7), // 70% del ancho/alto del sprite
          parentSize: size,
          position:
              (size * 0.15), // centra el 70% dejando 15% de margen por lado
        )
        ..collisionType = CollisionType.active
        ..debugMode =
            true // dejamos debug para que veas la caja
        ..renderShape = true
        ..isSolid = false,
    );

    // Halo sutil, más compacto y con transparencia menor
    _halo = CircleComponent(
      radius: 18,
      anchor: Anchor.center,
      paint: Paint()
        ..color = const Color(0xFF00FFB3).withOpacity(0.08)
        ..blendMode = BlendMode.srcOver,
    );

    add(_halo);
  }

  @override
  void update(double dt) {
    if (!isAlive || gameRef.isPaused) return;

    velocity += gravity * dt;
    velocity = velocity.clamp(maxRiseSpeed, maxFallSpeed);

    position.y += velocity * dt;

    final targetAngle = (velocity / maxFallSpeed).clamp(-1.0, 1.0) * 0.38;
    angle = lerpDouble(angle, targetAngle, (rotationLerp * dt).clamp(0, 1))!;
  }

  void flap() {
    if (!isAlive) return;
    velocity = jumpImpulse;
    gameRef.playFlap();
    _burst();
  }

  void die() {
    if (!isAlive) return;
    isAlive = false;
    velocity = 0;
    _halo.removeFromParent();
    _deathBurst();
    removeFromParent();
    gameRef.playHit();
    onDie();
  }

  void _burst() {
    if (!isMounted || isRemoving) return;

    final rand = Random();
    const count = 8;
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: count,
          lifespan: 0.28,
          generator: (i) {
            final angle = (i / count) * pi + rand.nextDouble() * 0.35;
            final speed = 90 + rand.nextDouble() * 70;
            final dir = Vector2(cos(angle), sin(angle));
            return AcceleratedParticle(
              speed: dir * speed,
              acceleration: Vector2.zero(),
              child: CircleParticle(
                radius: 2.4,
                paint: Paint()
                  ..color = const Color(0xFF00FFB3).withOpacity(0.9),
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
    const count = 18;
    gameRef.add(
      ParticleSystemComponent(
        position: position.clone(),
        anchor: Anchor.center,
        particle: Particle.generate(
          count: count,
          lifespan: 0.65,
          generator: (i) {
            final angle = (i / count) * pi * 2 + rand.nextDouble() * 0.2;
            final speed = 110 + rand.nextDouble() * 130;
            final dir = Vector2(cos(angle), sin(angle));
            return AcceleratedParticle(
              speed: dir * speed,
              acceleration: dir * -90,
              child: CircleParticle(
                radius: 3.6,
                paint: Paint()
                  ..color = const Color(0xFF00FFB3).withOpacity(0.92),
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

    // 🔥 ACÁ ESTÁ LA CLAVE
    if (other is Ground || other is ColumnComponent) {
      die();
    }
  }
}
