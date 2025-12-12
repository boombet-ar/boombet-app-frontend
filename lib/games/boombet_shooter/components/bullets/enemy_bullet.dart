import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../game.dart';
import '../player/player_health.dart';

/// Tag para identificar el cuerpo del jugador.
mixin PlayerHitboxTag {}

/// Bala enemiga genérica que baja y daña al jugador.
class EnemyBullet extends RectangleComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  EnemyBullet({double speed = 200, int damage = 1, Vector2? size})
    : speed = speed,
      damage = damage,
      super(
        size: size ?? Vector2(8, 16),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFEE9922),
      );

  final double speed;
  final int damage;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y += speed * dt;

    if (position.y - size.y * 0.5 > gameRef.size.y + 32) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Si choca con el jugador (usando tag)
    if (other is PlayerHitboxTag) {
      // Buscamos el componente PlayerHealth dentro del jugador
      final ph = other.children.whereType<PlayerHealth>().firstOrNull;
      if (ph != null) {
        ph.takeDamage(damage);
      }
      removeFromParent();
    }
  }
}
