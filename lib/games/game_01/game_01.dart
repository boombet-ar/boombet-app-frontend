import 'dart:async';

import 'package:boombet_app/games/game_01/components/dark_overlay.dart';
import 'package:boombet_app/games/game_01/components/obstacle_manager.dart';
import 'package:boombet_app/games/game_01/components/parallax_background.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/player.dart';
import 'components/ground.dart';

class Game01 extends FlameGame with HasCollisionDetection, TapCallbacks {
  Player? player;
  Ground? ground;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  bool isGameOver = false;
  bool isPaused = true; // start paused until user taps Play

  static const double groundHeight = 12.0;
  static const double groundOffset = 6.0;

  bool _soundsReady = false;
  final List<String> _sfxFiles = [
    // Nota: FlameAudio usa por defecto el prefijo assets/audio/, por eso quitamos "audio/"
    'sfx/game_01/jump.mp3',
    'sfx/game_01/hit.mp3',
    'sfx/game_01/point.mp3',
  ];

  bool _bgmReady = false;
  final String _bgmFile = 'sfx/game_01/music.mp3';
  bool _bgmStarted = false;

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
    ground = Ground(
      y: size.y - groundHeight + groundOffset,
      width: size.x,
      height: groundHeight,
    );
    add(ground!);

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
      _playPoint();
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

    playHit();
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
    ground = null;
    final toRemove = children.toList();
    for (final c in toRemove) {
      c.removeFromParent();
    }

    // Espera un frame para que Flame procese las eliminaciones
    await Future<void>.delayed(Duration.zero);

    _buildWorld();

    // Arranca usando el mismo flujo que el arranque inicial
    startGame();

    // Reanuda música si no está sonando
    _startBgmLoop();
  }

  // ========================
  // LOAD
  // ========================

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (ground != null) {
      ground!
        ..position.y = canvasSize.y - groundHeight + groundOffset
        ..size = Vector2(canvasSize.x, groundHeight);
    }
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    debugPrint('🎮 [Game01] Loading assets...');

    // Asegura prefijo correcto para audios
    FlameAudio.audioCache.prefix = 'assets/audio/';

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

    _soundsReady = await _tryLoadAudio();
    _bgmReady = await _tryLoadMusic();

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

    _startBgmLoop();
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
    ground = null;
    FlameAudio.bgm.stop();
    super.onRemove();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt('game01_best_score');
    if (stored != null) {
      bestScore.value = stored;
    }
  }

  Future<bool> _tryLoadAudio() async {
    if (_soundsReady) return true;
    try {
      await FlameAudio.audioCache.loadAll(_sfxFiles);
      return _soundsReady = true;
    } catch (e) {
      debugPrint('🔇 [Game01] SFX no cargados: $e');
      return false;
    }
  }

  void _playSafe(String file) {
    if (!_soundsReady) {
      return;
    }
    try {
      FlameAudio.play(file, volume: 0.9);
    } catch (e) {
      debugPrint('🔇 [Game01] error reproduciendo $file: $e');
    }
  }

  void playFlap() => _playSafe('sfx/game_01/jump.mp3');
  void playHit() => _playSafe('sfx/game_01/hit.mp3');
  void _playPoint() => _playSafe('sfx/game_01/point.mp3');

  Future<void> _saveBestScore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('game01_best_score', value);
  }

  Future<bool> _tryLoadMusic() async {
    if (_bgmReady) return true;
    try {
      await FlameAudio.bgm.initialize();
      // Preload the BGM file using the audio cache (Bgm no longer exposes load)
      await FlameAudio.audioCache.load(_bgmFile);
      return _bgmReady = true;
    } catch (e) {
      debugPrint('🔇 [Game01] BGM no cargado: $e');
      return false;
    }
  }

  Future<void> _startBgmLoop() async {
    if (!_bgmReady) return;
    if (_bgmStarted && FlameAudio.bgm.isPlaying) return;
    try {
      await FlameAudio.bgm.play(_bgmFile, volume: 0.45);
      _bgmStarted = true;
    } catch (e) {
      debugPrint('🔇 [Game01] error reproduciendo BGM: $e');
    }
  }

}