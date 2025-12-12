import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game.dart';
import '../../managers/difficulty_manager.dart';
import '../../managers/game_manager.dart';
import '../player/player_health.dart';
import '../player/player_shooting.dart'; // ← por PlayerBulletTag

/// Enemigo en zigzag que **NO cuenta para combo**.
class EnemyZigZag extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  EnemyZigZag({
    this.health = 2,
    this.damageToPlayer = 1,
    this.scoreValue = 20,
    double speed = 90,
    this.zigzagAmplitude = 24,
    this.zigzagFrequency = 4,
    this.bottomLimitYOffset = 48,
    List<PositionComponent Function()?>? powerupFactories,
    this.powerupDropChance = 0.10,
    this.spritePath = 'games/boombet_shooter/sprites/enemies/diamond.png',
  }) : _speed = speed,
       powerupFactories = powerupFactories ?? [];

  // ---------------------------------------------------------------------------
  // STATS
  int health;
  int damageToPlayer;
  int scoreValue;

  // Movimiento
  double _speed;
  double zigzagAmplitude;
  double zigzagFrequency;
  double bottomLimitYOffset;

  double _startX = 0;
  bool _hasStartX = false;

  // Powerups
  List<PositionComponent Function()?> powerupFactories;
  double powerupDropChance;

  // Control
  bool _hasEnteredScreen = false;

  final String spritePath;

  final _rng = Random();
  DifficultyManager? _diff;
  GameManager? _gm;

  // ---------------------------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.center;
    size = Vector2.all(32);

    try {
      sprite = await Sprite.load(spritePath);
    } catch (_) {
      sprite = await _solidColorSprite(const Color(0xFF22AA55));
    }

    add(RectangleHitbox()..collisionType = CollisionType.passive);

    _diff = gameRef.firstChild<DifficultyManager>();
    _gm = gameRef.firstChild<GameManager>();

    _startX = position.x;
    _hasStartX = true;
  }

  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    _handleMovement(dt);

    if (!_hasEnteredScreen && _isOnScreen()) {
      _hasEnteredScreen = true;
    }

    final limitY = gameRef.size.y + bottomLimitYOffset;
    if (position.y - size.y / 2 > limitY) {
      removeFromParent();
    }
  }

  // ---------------------------------------------------------------------------
  // MOVIMIENTO ZIGZAG (usa sin como el sine shooter pero no horizontal fijo)
  void _handleMovement(double dt) {
    final speed = _diff?.getEnemySpeed(_speed) ?? _speed;

    final t = gameRef.currentTime();
    final newX = _startX + sin(t * zigzagFrequency) * zigzagAmplitude;
    final newY = position.y + speed * dt;

    position = Vector2(newX, newY);
  }

  bool _isOnScreen() {
    return position.x >= 0 &&
        position.x <= gameRef.size.x &&
        position.y >= 0 &&
        position.y <= gameRef.size.y;
  }

  // ---------------------------------------------------------------------------
  // DAMAGE (NO combo)
  void takeDamage(int amount) {
    if (!_hasEnteredScreen) return;

    health -= amount;
    if (health <= 0) {
      _die();
    }
  }

  void _die() {
    // ❌ NO combo → solo score normal
    _gm?.addScore(scoreValue);

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
  // COLLISIONS
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // ✔ Daño al jugador
    if (other.children.whereType<PlayerHealth>().isNotEmpty) {
      other.children.whereType<PlayerHealth>().first.takeDamage(damageToPlayer);
      _die();
      return;
    }

    // ✔ Bala del jugador usando PlayerBulletTag
    if (other is PlayerBulletTag) {
      takeDamage(1);
      other.removeFromParent();
      return;
    }
  }
}
