import 'dart:async';

import 'package:boombet_app/games/game_01/components/dark_overlay.dart';
import 'package:boombet_app/games/game_01/components/obstacle_manager.dart';
import 'package:boombet_app/games/game_01/components/parallax_background.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/player.dart';
import 'components/ground.dart';

class Game01 extends FlameGame with HasCollisionDetection, TapCallbacks {
  Player? player;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  bool isGameOver = false;
  bool isPaused = true; // start paused until user taps Play

  // Sprites
  late Sprite playerSprite;
  late Sprite columnTopSprite;
  late Sprite columnMidSprite;

  // ========================
  // GAME STATE
  // ========================

  void _buildWorld() {
    // Fondo parallax
    add(ParallaxBackground());

    // Oscurecedor global
    add(DarkOverlay(size));

    // Suelo: más bajo y fino para no cortar la pantalla
    const groundHeight = 12.0;
    add(Ground(y: size.y - groundHeight + 6, width: size.x, height: groundHeight));

    // Player
    player = Player(onDie: gameOver, sprite: playerSprite)
      ..position = Vector2(size.x / 3, size.y / 2);
    add(player!);

    // Obstáculos
    add(
      ObstacleManager(
        size,
        topSprite: columnTopSprite,
        midSprite: columnMidSprite,
      ),
    );
  }

  void addPoint() {
    if (!isGameOver) {
      score.value += 1;
    }
  }

  void gameOver() {
    if (isGameOver) return;
    isGameOver = true;
    isPaused = false;
    overlays.add('gameOver');

    if (score.value > bestScore.value) {
      bestScore.value = score.value;
      unawaited(_saveBestScore(score.value));
    }
  }

  void pauseGame() {
    if (isGameOver || isPaused) return;
    isPaused = true;
    overlays.add('pause');
  }

  void resumeGame() {
    if (!isPaused || isGameOver) return;
    isPaused = false;
    overlays.remove('pause');
  }

  void startGame() {
    if (isGameOver || !isPaused) return;
    isPaused = false;
    overlays.remove('menu');
    if (!overlays.isActive('hud')) {
      overlays.add('hud');
    }
  }

  Future<void> restartGame() async {
    isGameOver = false;
    isPaused = true;
    score.value = 0;

    // Reinicia overlays como en un arranque nuevo
    overlays.clear();
    overlays.add('menu');

    // Resetea la escena completa
    player = null;
    final toRemove = children.toList();
    for (final c in toRemove) {
      c.removeFromParent();
    }

    // Espera un frame para que Flame procese las eliminaciones
    await Future<void>.delayed(Duration.zero);

    _buildWorld();

    // Arranca usando el mismo flujo que el arranque inicial
    startGame();
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

    // ========================
    // SCENE SETUP (ORDEN IMPORTA)
    // ========================

    _buildWorld();

    debugPrint('🎮 [Game01] onLoad completed');

    // Load best score from cache
    unawaited(_loadBestScore());

    // Start paused showing menu overlay
    isPaused = true;
    overlays.add('menu');
  }

  // ========================
  // INPUT
  // ========================

  @override
  void onTapDown(TapDownEvent event) {
    if (isPaused || isGameOver) {
      return;
    }

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
    bestScore.dispose();
    super.onRemove();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('game01_best_score');
    if (stored != null) {
      bestScore.value = stored;
    }
  }

  Future<void> _saveBestScore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('game01_best_score', value);
  }
}
