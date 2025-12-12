import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';

import '../../game.dart';
import '../../managers/difficulty_manager.dart';
import '../../managers/game_manager.dart';
import '../player/player_health.dart';
import '../player/player_shooting.dart'; // ← para detectar PlayerBullet

class EnemyBasic extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  EnemyBasic({
    this.health = 1,
    this.damageToPlayer = 1,
    this.scoreValue = 10,
    double speed = 80,
    this.bottomLimitYOffset = 48,
    this.canShoot = false,
    double shootInterval = 2.0,
    this.bulletSpeed = 180,
    this.powerupDropChance = 0.2,
    List<PositionComponent Function()?>? powerupFactories,
    this.spritePath = 'games/boombet_shooter/sprites/enemies/heart.png',
  }) : _speed = speed,
       _shootInterval = shootInterval,
       powerupFactories = powerupFactories ?? [];

  // -------------------------------------------------------
  // STATS
  int health;
  int damageToPlayer;
  int scoreValue;

  // Movement
  double _speed;
  double bottomLimitYOffset;

  // Shooting
  bool canShoot;
  double _shootInterval;
  double bulletSpeed;
  double _shootTimer = 0;

  // Powerups
  List<PositionComponent Function()?> powerupFactories;
  double powerupDropChance;

  // Control
  bool _hasEnteredScreen = false;

  // Asset
  final String spritePath;

  final _rng = Random();
  DifficultyManager? _diff;
  GameManager? _gm;

  // -------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(32);
    anchor = Anchor.center;

    try {
      sprite = await Sprite.load(spritePath);
    } catch (_) {
      sprite = await _solidColorSprite(const Color(0xFFCC3333));
    }

    add(RectangleHitbox()..collisionType = CollisionType.passive);

    _diff = gameRef.firstChild<DifficultyManager>();
    _gm = gameRef.firstChild<GameManager>();

    _shootTimer = _rng.nextDouble() * _shootInterval;
  }

  // -------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    // Movement with difficulty scaling
    final speed = _diff?.getEnemySpeed(_speed) ?? _speed;
    position.y += speed * dt;

    if (!_hasEnteredScreen && _isOnScreen()) {
      _hasEnteredScreen = true;
    }

    if (canShoot && _hasEnteredScreen) {
      _handleShooting(dt);
    }

    if (position.y - size.y / 2 > gameRef.size.y + bottomLimitYOffset) {
      removeFromParent();
    }
  }

  // -------------------------------------------------------
  // SHOOTING
  void _handleShooting(double dt) {
    _shootTimer -= dt;
    if (_shootTimer <= 0) {
      _shoot();

      final interval =
          _diff?.getEnemyShootInterval(_shootInterval) ?? _shootInterval;

      _shootTimer = interval;
    }
  }

  void _shoot() {
    final bullet = _EnemyBasicBullet(speed: bulletSpeed, damage: 1)
      ..position = position + Vector2(0, size.y / 2 + 4);

    gameRef.add(bullet);
  }

  bool _isOnScreen() {
    return position.x >= 0 &&
        position.x <= gameRef.size.x &&
        position.y >= 0 &&
        position.y <= gameRef.size.y;
  }

  // -------------------------------------------------------
  // DAMAGE
  void takeDamage(int amount) {
    if (amount <= 0) return;
    if (!_hasEnteredScreen) return;

    health -= amount;
    if (health <= 0) {
      _die();
    }
  }

  void _die() {
    _gm?.registerEnemyKill(scoreValue, countsForCombo: true);

    // Powerup drop
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

  // -------------------------------------------------------
  // COLLISIONS
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // Player body
    final playerHealth = other.children.whereType<PlayerHealth>();
    if (playerHealth.isNotEmpty) {
      playerHealth.first.takeDamage(damageToPlayer);
      _die();
      return;
    }

    // Player bullet (real detection)
    if (other is PlayerBulletTag) {
      takeDamage(1);
      other.removeFromParent();
    }
  }
}

// ========================================================
// ENEMY BULLET (rectangle, no sprite assertion)
// ========================================================
class _EnemyBasicBullet extends RectangleComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  _EnemyBasicBullet({required this.speed, required this.damage})
    : super(
        size: Vector2(8, 16),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFFF8800),
      ) {
    add(RectangleHitbox()..collisionType = CollisionType.active);
  }

  final double speed;
  final int damage;

  @override
  void update(double dt) {
    super.update(dt);

    position.y += speed * dt;

    if (position.y > gameRef.size.y + 32) {
      removeFromParent();
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    final playerHealth = other.children.whereType<PlayerHealth>();
    if (playerHealth.isNotEmpty) {
      playerHealth.first.takeDamage(damage);
      removeFromParent();
    }
  }
}
