import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';

import 'ground.dart';
import 'column_component.dart';

class Player extends SpriteComponent with CollisionCallbacks {
  Player({required this.onDie, required Sprite sprite})
    : super(
        sprite: sprite,
        size: Vector2(40, 40),
        anchor: Anchor.center,
        paint: Paint()..filterQuality = FilterQuality.none,
      );

  final VoidCallback onDie;

  double velocity = 0;

  final double gravity = 800;
  final double jumpImpulse = -260;
  final double maxFallSpeed = 500;
  final double maxRiseSpeed = -350;

  bool isAlive = true;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(
      RectangleHitbox()
        ..collisionType = CollisionType.active
        ..debugMode = true,
    );
  }

  @override
  void update(double dt) {
    if (!isAlive) return;

    velocity += gravity * dt;
    velocity = velocity.clamp(maxRiseSpeed, maxFallSpeed);

    position.y += velocity * dt;
    angle = (velocity / maxFallSpeed) * 0.6;
  }

  void flap() {
    if (!isAlive) return;
    velocity = jumpImpulse;
  }

  void die() {
    if (!isAlive) return;
    isAlive = false;
    velocity = 0;
    onDie();
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
