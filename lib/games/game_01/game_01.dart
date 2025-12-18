import 'package:boombet_app/games/game_01/components/obstacle_manager.dart';
import 'package:boombet_app/games/game_01/components/parallax_background.dart';
import 'package:boombet_app/games/game_01/components/dark_overlay.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'components/player.dart';
import 'components/ground.dart';

class Game01 extends FlameGame with HasCollisionDetection, TapCallbacks {
  Player? player;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  bool isGameOver = false;

  // Sprites
  late Sprite playerSprite;
  late Sprite columnTopSprite;
  late Sprite columnMidSprite;
  late Sprite columnBottomSprite;

  // ========================
  // GAME STATE
  // ========================

  void addPoint() {
    if (!isGameOver) {
      score.value += 1;
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    overlays.add('gameOver');
  }

  // ========================
  // LOAD
  // ========================

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugPrint('🎮 [Game01] Loading assets...');

    // 🔹 CARGA DE ASSETS (UNA SOLA VEZ)
    await images.loadAll([
      // Player
      'games/game_01/sprites/player.png',

      // Columnas (pixel art dividido)
      'games/game_01/obstacles/column_top.png',
      'games/game_01/obstacles/column_mid.png',
      'games/game_01/obstacles/column_bottom.png',

      // Parallax
      'games/game_01/backgrounds/bg_far.png',
      'games/game_01/backgrounds/bg_mid.png',
      'games/game_01/backgrounds/bg_near.png',
    ]);

    debugPrint('🎮 [Game01] Assets loaded');

    // 🔹 SPRITES DESDE CACHE
    playerSprite = Sprite(images.fromCache('games/game_01/sprites/player.png'));

    columnTopSprite = Sprite(
      images.fromCache('games/game_01/obstacles/column_top.png'),
    );

    columnMidSprite = Sprite(
      images.fromCache('games/game_01/obstacles/column_mid.png'),
    );

    columnBottomSprite = Sprite(
      images.fromCache('games/game_01/obstacles/column_bottom.png'),
    );

    // ========================
    // SCENE SETUP (ORDEN IMPORTA)
    // ========================

    // 1️⃣ Fondo parallax
    add(ParallaxBackground());

    // 2️⃣ Oscurecedor global
    add(DarkOverlay(size));

    // 3️⃣ Suelo (invisible pero con colisión)
    const groundHeight = 24.0;
    add(Ground(y: size.y - groundHeight, width: size.x, height: groundHeight));

    // 4️⃣ Player
    player = Player(onDie: gameOver, sprite: playerSprite)
      ..position = Vector2(size.x / 3, size.y / 2);

    add(player!);

    // 5️⃣ Obstáculos (columnas compuestas)
    add(
      ObstacleManager(
        size,
        topSprite: columnTopSprite,
        midSprite: columnMidSprite,
        bottomSprite: columnBottomSprite,
      ),
    );

    debugPrint('🎮 [Game01] onLoad completed');
  }

  // ========================
  // INPUT
  // ========================

  @override
  void onTapDown(TapDownEvent event) {
    if (!isGameOver) {
      player?.flap();
    }
  }

  // ========================
  // CLEANUP
  // ========================

  @override
  void onRemove() {
    score.dispose();
    super.onRemove();
  }
}
