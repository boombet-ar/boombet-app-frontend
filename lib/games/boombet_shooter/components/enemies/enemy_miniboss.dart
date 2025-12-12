import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game.dart';
import '../../managers/difficulty_manager.dart';
import '../../managers/game_manager.dart';
import '../player/player_health.dart';
import '../player/player_shooting.dart'; // Para PlayerBulletTag

/// Miniboss básico: mucha vida, baja lento, no dispara y puede soltar powerups.
class EnemyMiniBoss extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  EnemyMiniBoss({
    this.health = 50,
    this.damageToPlayer = 3,
    this.scoreValue = 200,
    double speed = 60,
    this.bottomLimitYOffset = 64,
    List<PositionComponent Function()?>? powerupFactories,
    this.powerupDropChance = 1.0,
    this.spritePath = 'games/boombet_shooter/sprites/enemies/chip.png',
  }) : _speed = speed,
       powerupFactories = powerupFactories ?? [];

  // ---------------------------------------------------------------------------
  // STATS
  int health;
  int damageToPlayer;
  int scoreValue;

  // Movimiento
  double _speed;
  double bottomLimitYOffset;

  // Powerups
  List<PositionComponent Function()?> powerupFactories;
  double powerupDropChance;

  final String spritePath;

  DifficultyManager? _diff;
  GameManager? _gm;
  final _rng = Random();

  // ---------------------------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.center;
    size = Vector2.all(64);

    try {
      sprite = await Sprite.load(spritePath);
    } catch (_) {
      sprite = await _solidColorSprite(const Color(0xFF8833CC));
    }

    add(RectangleHitbox()..collisionType = CollisionType.passive);

    _diff = gameRef.firstChild<DifficultyManager>();
    _gm = gameRef.firstChild<GameManager>();
  }

  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    // Movimiento descendente con dificultad
    final speed = _diff?.getEnemySpeed(_speed) ?? _speed;
    position.y += speed * dt;

    // Salida de pantalla
    if (position.y - size.y / 2 > gameRef.size.y + bottomLimitYOffset) {
      removeFromParent();
    }
  }

  // ---------------------------------------------------------------------------
  // DAMAGE
  void takeDamage(int amount) {
    if (amount <= 0) return;
    health -= amount;
    if (health <= 0) _die();
  }

  void _die() {
    // Score + combo
    _gm?.registerEnemyKill(scoreValue, countsForCombo: true);

    // Drop powerup
    if (powerupFactories.isNotEmpty && _rng.nextDouble() < powerupDropChance) {
      final builder = powerupFactories[_rng.nextInt(powerupFactories.length)];
      final p = builder?.call();
      if (p != null) {
        p.position = position.clone();
        gameRef.add(p);
      }
    }

    removeFromParent();
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

  // ---------------------------------------------------------------------------
  // COLLISIONES
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // ▶ Daño al jugador
    if (other.children.whereType<PlayerHealth>().isNotEmpty) {
      final ph = other.children.whereType<PlayerHealth>().first;
      ph.takeDamage(damageToPlayer);
      _die();
      return;
    }

    // ▶ Recibir daño de bala del jugador (con TAG)
    if (other is PlayerBulletTag) {
      takeDamage(1);
      other.removeFromParent();
      return;
    }
  }
}
