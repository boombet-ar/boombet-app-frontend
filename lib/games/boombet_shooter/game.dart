import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/foundation.dart';

import 'managers/difficulty_manager.dart';
import 'managers/game_manager.dart';

import 'components/player/player.dart';
import 'components/player/player_controller.dart';
import 'components/player/player_shooting.dart';
import 'components/player/player_powerups.dart';
import 'components/player/player_health.dart';

import 'components/spawners/enemy_spawner.dart';
import 'components/enemies/enemy_basic.dart';
import 'components/enemies/enemy_charger.dart';
import 'components/enemies/enemy_sine_shooter.dart';
import 'components/enemies/enemy_zigzag.dart';
import 'components/enemies/enemy_miniboss.dart';

/// Juego principal BoomBet Shooter
class MyGame extends FlameGame
    with HasCollisionDetection, TapCallbacks, DragCallbacks {
  MyGame({Vector2? fixedResolution})
    : _fixedResolution = fixedResolution ?? Vector2(360, 640);

  final Vector2 _fixedResolution;

  double _time = 0;
  double currentTime() => _time;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugPrint('Player onLoad called');

    // Ensure Flame looks under assets/ instead of the default assets/images/ prefix
    images.prefix = 'assets/';

    // Usar viewport por defecto para que ocupe toda la pantalla
    camera.viewfinder.anchor = Anchor.topLeft;

    // ===============================
    // Difficulty Manager
    // ===============================
    add(DifficultyManager());

    // ===============================
    // Game Manager
    // ===============================
    add(GameManager());

    // ===============================
    // Player
    // ===============================
    final player = Player()
      ..position = Vector2(_fixedResolution.x * 0.5, _fixedResolution.y * 0.8);

    await add(player);

    debugPrint('Player sprite loaded');

    // ===============================
    // Enemy Spawner
    // ===============================
    await add(
      EnemySpawner(
        enemyTypes: [
          EnemyEntry(builder: () => EnemyBasic()),
          EnemyEntry(builder: () => EnemyCharger()),
          EnemyEntry(builder: () => EnemySineShooter()),
          EnemyEntry(builder: () => EnemyZigZag()),
          EnemyEntry(
            builder: () => EnemyMiniBoss(),
            isMiniBoss: true,
            allowInFormations: false,
            weight: 0.1,
          ),
        ],
      ),
    );

    debugMode = true;

    add(
      RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF1A1A1A),
        priority: -10,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }
}
