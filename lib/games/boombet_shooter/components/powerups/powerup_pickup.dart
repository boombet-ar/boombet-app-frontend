import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../game.dart';
import '../interfaces/powerup_type.dart';
import '../player/player_powerups.dart';

/// Pickup de powerup: cae hacia abajo y se activa al colisionar con el jugador.
/// Encapsula tipo, duración y comportamiento de caída.
class PowerupPickup extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  PowerupPickup({
    required this.type,
    this.duration = 8.0,
    double fallSpeed = 60,
    Vector2? size,
    this.spritePath,
  }) : _fallSpeed = fallSpeed,
       super(size: size ?? Vector2(24, 24), anchor: Anchor.center);

  final PowerupType type;
  final double duration;
  double _fallSpeed;
  final String? spritePath;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (spritePath != null) {
      try {
        sprite = await Sprite.load(spritePath!);
      } catch (_) {
        sprite = await _solidColorSprite(_getColorForType());
      }
    } else {
      sprite = await _solidColorSprite(_getColorForType());
    }

    add(RectangleHitbox()..collisionType = CollisionType.passive);
  }

  Future<Sprite> _solidColorSprite(Color color) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 8, 8), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    return Sprite(image);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += Vector2(0, _fallSpeed * dt);

    // Limpiar si cae demasiado abajo
    if (position.y - size.y * 0.5 > gameRef.size.y + 32) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Buscar PlayerPowerups en el árbol del jugador
    if (other is SpriteComponent) {
      final pp = other.children.whereType<PlayerPowerups>().firstOrNull;
      if (pp != null) {
        // Activar el powerup pasando los datos
        pp.activatePowerup(PowerupData(type: type, duration: duration));
        removeFromParent();
      }
    }
  }

  /// Retorna el color visual según el tipo de powerup.
  Color _getColorForType() {
    switch (type) {
      case PowerupType.doubleShot:
        return const Color(0xFF00FFFF); // Cyan
      case PowerupType.rapidFire:
        return const Color(0xFFFF00FF); // Magenta
      case PowerupType.scoreMultiplier:
        return const Color(0xFFFFFF00); // Yellow
    }
  }
}
