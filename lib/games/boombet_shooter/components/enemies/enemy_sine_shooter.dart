import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game.dart';
import '../../managers/difficulty_manager.dart';
import '../../managers/game_manager.dart';
import '../player/player_health.dart';
import '../player/player_shooting.dart'; // ← Por PlayerBulletTag

/// Enemigo que baja en forma de seno y dispara.
class EnemySineShooter extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  EnemySineShooter({
    this.health = 2,
    this.damageToPlayer = 1,
    this.scoreValue = 20,
    double verticalSpeed = 90,
    this.amplitude = 32,
    this.frequency = 2,
    this.bottomLimitYOffset = 48,
    this.canShoot = true,
    double shootInterval = 2,
    this.bulletSpeed = 180,
    this.powerupDropChance = 0.15,
    List<PositionComponent Function()?>? powerupFactories,
    this.spritePath = 'games/boombet_shooter/sprites/enemies/spade.png',
  }) : _verticalSpeed = verticalSpeed,
       _shootInterval = shootInterval,
       powerupFactories = powerupFactories ?? [];

  // ---------------------------------------------------------------------------
  // STATS
  int health;
  int damageToPlayer;
  int scoreValue;

  // Movimiento seno
  double _verticalSpeed;
  double amplitude;
  double frequency;
  double bottomLimitYOffset;
  double _time = 0;
  late double _initialX;

  // Shooting
  bool canShoot;
  double _shootInterval;
  double bulletSpeed;
  double _shootTimer = 0;

  // Powerups
  List<PositionComponent Function()?> powerupFactories;
  double powerupDropChance;

  // Control de pantalla
  bool _hasEnteredScreen = false;

  // Assets
  final String spritePath;

  DifficultyManager? _diff;
  GameManager? _gm;
  final _rng = Random();

  // ---------------------------------------------------------------------------
  @override
  Future<void> onLoad() async {
    await super.onLoad();

    anchor = Anchor.center;
    size = Vector2.all(32);

    try {
      sprite = await Sprite.load(spritePath);
    } catch (_) {
      sprite = await _solidColorSprite(const Color(0xFF44AADD));
    }

    add(RectangleHitbox()..collisionType = CollisionType.passive);

    _diff = gameRef.firstChild<DifficultyManager>();
    _gm = gameRef.firstChild<GameManager>();

    _shootTimer = _rng.nextDouble() * _shootInterval;
    _time = _rng.nextDouble() * 10;

    _initialX = position.x;
  }

  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    _handleMovement(dt);

    if (!_hasEnteredScreen && _isOnScreen()) {
      _hasEnteredScreen = true;
    }

    if (canShoot && _hasEnteredScreen) {
      _handleShooting(dt);
    }

    final limitY = gameRef.size.y + bottomLimitYOffset;
    if (position.y - size.y / 2 > limitY) {
      removeFromParent();
    }
  }

  // ---------------------------------------------------------------------------
  // MOVIMIENTO SENO
  void _handleMovement(double dt) {
    final speed = _diff?.getEnemySpeed(_verticalSpeed) ?? _verticalSpeed;
    position.y += speed * dt;

    position.x = _initialX + sin(_time * frequency) * amplitude;
  }

  // ---------------------------------------------------------------------------
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
    final bullet = _EnemySineBullet(speed: bulletSpeed, damage: 1);

    bullet.position = position + Vector2(0, size.y / 2 + 4);

    gameRef.add(bullet);
  }

  bool _isOnScreen() {
    return position.x >= 0 &&
        position.x <= gameRef.size.x &&
        position.y >= 0 &&
        position.y <= gameRef.size.y;
  }

  // ---------------------------------------------------------------------------
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

    // Drop powerup
    if (powerupFactories.isNotEmpty && _rng.nextDouble() < powerupDropChance) {
      final builder = powerupFactories[_rng.nextInt(powerupFactories.length)];
      final power = builder?.call();
      if (power != null) {
        power.position = position.clone();
        gameRef.add(power);
      }
    }

    removeFromParent();
  }

  // ---------------------------------------------------------------------------
  // COLLISIONES
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

  Future<Sprite> _solidColorSprite(Color color) async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = color;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 32), paint);
    final picture = recorder.endRecording();
    final image = await picture.toImage(32, 32);
    return Sprite(image);
  }
}

// =============================================================================
// BULLET
// =============================================================================
class _EnemySineBullet extends RectangleComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  _EnemySineBullet({required this.speed, this.damage = 1})
    : super(
        size: Vector2(8, 16),
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFCCBB33),
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

    if (other.children.whereType<PlayerHealth>().isNotEmpty) {
      other.children.whereType<PlayerHealth>().first.takeDamage(damage);
      removeFromParent();
    }
  }
}
