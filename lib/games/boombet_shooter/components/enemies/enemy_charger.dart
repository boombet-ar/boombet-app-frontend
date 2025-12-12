import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../game.dart';
import '../../managers/difficulty_manager.dart';
import '../../managers/game_manager.dart';
import '../player/player.dart';
import '../player/player_health.dart';
import '../player/player_shooting.dart'; // ⭐ Para acceder a PlayerBulletTag

/// Enemigo que persigue al jugador (charger).
class EnemyCharger extends SpriteComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  EnemyCharger({
    this.health = 3,
    this.damageToPlayer = 1,
    this.scoreValue = 25,
    double speed = 110,
    this.bottomLimitYOffset = 48,
    this.powerupDropChance = 0.1,
    List<PositionComponent Function()?>? powerupFactories,
    this.spritePath = 'games/boombet_shooter/sprites/enemies/club.png',
  }) : _speed = speed,
       powerupFactories = powerupFactories ?? [];

  // Stats
  int health;
  int damageToPlayer;
  int scoreValue;

  // Movimiento
  double _speed;
  double bottomLimitYOffset;

  // Powerups
  List<PositionComponent Function()?> powerupFactories;
  double powerupDropChance;

  // Control
  bool _hasEnteredScreen = false;

  // Rutas
  final String spritePath;

  final _rng = Random();
  DifficultyManager? _diff;
  GameManager? _gm;
  Player? _player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(32);
    anchor = Anchor.center;

    try {
      sprite = await Sprite.load(spritePath);
    } catch (_) {
      sprite = await _solidColorSprite(const Color(0xFFAA66CC));
    }

    add(RectangleHitbox()..collisionType = CollisionType.passive);

    _diff = gameRef.firstChild<DifficultyManager>();
    _gm = gameRef.firstChild<GameManager>();
    _player = gameRef.firstChild<Player>();
  }

  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);

    _handleMovement(dt);

    // Entrada en pantalla
    if (!_hasEnteredScreen && _isOnScreen()) {
      _hasEnteredScreen = true;
    }

    // Salida inferior
    if (position.y - size.y / 2 > gameRef.size.y + bottomLimitYOffset) {
      removeFromParent();
    }
  }

  // ---------------------------------------------------------------------------
  // MOVIMIENTO: persigue al jugador
  void _handleMovement(double dt) {
    Vector2 dir;

    if (_player != null) {
      dir = (_player!.position - position).normalized();
    } else {
      dir = Vector2(0, 1);
    }

    final speed = _diff?.getEnemySpeed(_speed) ?? _speed;
    position += dir * speed * dt;
  }

  // ---------------------------------------------------------------------------
  bool _isOnScreen() {
    return position.x >= 0 &&
        position.x <= gameRef.size.x &&
        position.y >= 0 &&
        position.y <= gameRef.size.y;
  }

  // ---------------------------------------------------------------------------
  // DAMAGE
  void takeDamage(int amount) {
    if (amount <= 0 || !_hasEnteredScreen) return;

    health -= amount;
    if (health <= 0) _die();
  }

  void _die() {
    _gm?.registerEnemyKill(scoreValue, countsForCombo: true);

    // Drop de powerup
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

    // Colisión con el jugador
    if (other.children.whereType<PlayerHealth>().isNotEmpty) {
      final ph = other.children.whereType<PlayerHealth>().first;
      ph.takeDamage(damageToPlayer);
      _die();
      return;
    }

    // Colisión con bala del jugador
    if (other is PlayerBulletTag) {
      takeDamage(1);
      other.removeFromParent();
      return;
    }
  }
}
