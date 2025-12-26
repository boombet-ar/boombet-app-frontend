import 'dart:async';

import 'package:boombet_app/games/game_01/components/dark_overlay.dart';
import 'package:boombet_app/games/game_01/components/obstacle_manager.dart';
import 'package:boombet_app/games/game_01/components/parallax_background.dart';
import 'package:boombet_app/games/game_01/components/camera_shake.dart';
import 'package:boombet_app/games/game_01/components/speed_lines.dart';
import 'package:boombet_app/games/game_01/components/transition_overlay.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/src/cache/images.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/player.dart';
import 'components/ground.dart';

class Game01 extends FlameGame with HasCollisionDetection, TapCallbacks {
  Player? player;
  Ground? ground;
  SpeedLines? speedLines;

  final ValueNotifier<int> score = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScore = ValueNotifier<int>(0);
  final ValueNotifier<double> musicVolume = ValueNotifier<double>(0.45);
  final ValueNotifier<double> sfxVolume = ValueNotifier<double>(0.7);
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

  // AudioPools para sonidos frecuentes (elimina latencia)
  AudioPool? _jumpPool;
  AudioPool? _hitPool;
  AudioPool? _pointPool;

  bool _bgmReady = false;
  final String _bgmFile = 'sfx/game_01/music.mp3';
  bool _bgmStarted = false;

  // Flag para evitar double dispose
  bool _isDisposed = false;

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

    // Speed lines
    speedLines = SpeedLines();
    add(speedLines!);

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

    // Transición suave antes de mostrar overlay
    add(
      TransitionOverlay(
        size: size,
        duration: 0.3,
        fadeIn: false,
        onComplete: () {
          overlays.add('gameOver');
        },
      ),
    );

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

    // Transición suave al iniciar
    add(TransitionOverlay(size: size, duration: 0.4, fadeIn: true));

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
    @override
    void update(double dt) {
      super.update(dt);

      // Actualizar camera shake
      CameraShake.update(dt);
    }

    @override
    void render(Canvas canvas) {
      // Aplicar shake de cámara
      canvas.save();
      canvas.translate(CameraShake.offset.x, CameraShake.offset.y);
      super.render(canvas);
      canvas.restore();
    }

    // ========================

    _buildWorld();

    debugPrint('🎮 [Game01] onLoad completed');

    // Load best score and volume settings from cache
    unawaited(_loadBestScore());
    unawaited(_loadVolumeSettings());

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
    debugPrint('🎮 [Game01] onRemove called');
    _cleanupResources();
    super.onRemove();

    // Reset camera shake
    CameraShake.reset();
  }

  /// Método para liberar todos los recursos cuando se cierra el juego
  void onDispose() {
    debugPrint('🎮 [Game01] onDispose called from page');
    _cleanupResources();
  }

  void _cleanupResources() {
    // Protección contra double dispose
    if (_isDisposed) {
      debugPrint('🎮 [Game01] Already disposed, skipping...');
      return;
    }
    _isDisposed = true;

    debugPrint('🎮 [Game01] Cleaning up resources...');

    // Detener música
    try {
      FlameAudio.bgm.stop();
      _bgmStarted = false;
      _bgmReady = false;
    } catch (e) {
      debugPrint('🎮 [Game01] Error stopping BGM: $e');
    }

    // Liberar AudioPools
    try {
      _jumpPool?.dispose();
      _hitPool?.dispose();
      _pointPool?.dispose();
      _jumpPool = null;
      _hitPool = null;
      _pointPool = null;
      _soundsReady = false;
    } catch (e) {
      debugPrint('🎮 [Game01] Error disposing audio pools: $e');
    }

    // Limpiar imágenes específicas del juego para liberar memoria
    try {
      images.clearCache();
      images.clearCachedImages();
    } catch (e) {
      debugPrint('🎮 [Game01] Error clearing images: $e');
    }

    // Limpiar cache de audio
    try {
      FlameAudio.audioCache.clearAll();
    } catch (e) {
      debugPrint('🎮 [Game01] Error clearing audio cache: $e');
    }

    // Dispose value notifiers
    try {
      score.dispose();
      bestScore.dispose();
      musicVolume.dispose();
      sfxVolume.dispose();
    } catch (e) {
      debugPrint('🎮 [Game01] Error disposing notifiers: $e');
    }

    ground = null;

    debugPrint('🎮 [Game01] Resources cleaned up successfully');
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
      // Crear pools de audio para sonidos frecuentes (elimina latencia)
      _jumpPool = await FlameAudio.createPool(
        'sfx/game_01/jump.mp3',
        minPlayers: 2,
        maxPlayers: 4,
      );
      _hitPool = await FlameAudio.createPool(
        'sfx/game_01/hit.mp3',
        minPlayers: 1,
        maxPlayers: 2,
      );
      _pointPool = await FlameAudio.createPool(
        'sfx/game_01/point.mp3',
        minPlayers: 1,
        maxPlayers: 3,
      );
      return _soundsReady = true;
    } catch (e) {
      debugPrint('🔇 [Game01] SFX no cargados: $e');
      return false;
    }
  }

  void playFlap() {
    if (!_soundsReady || _jumpPool == null || isGameOver) return;
    try {
      unawaited(_jumpPool!.start(volume: sfxVolume.value));
    } catch (e) {
      debugPrint('🔇 [Game01] error reproduciendo jump: $e');
    }
  }

  void playHit() {
    if (!_soundsReady || _hitPool == null) return;
    // Prevenir múltiples reproducciones simultáneas
    if (isGameOver) {
      // Solo reproducir una vez durante game over
      try {
        unawaited(_hitPool!.start(volume: sfxVolume.value));
      } catch (e) {
        debugPrint('🔇 [Game01] error reproduciendo hit: $e');
      }
    }
  }

  void _playPoint() {
    if (!_soundsReady || _pointPool == null || isGameOver) return;
    try {
      unawaited(_pointPool!.start(volume: sfxVolume.value));
    } catch (e) {
      debugPrint('🔇 [Game01] error reproduciendo point: $e');
    }
  }

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
      await FlameAudio.bgm.play(_bgmFile, volume: musicVolume.value);
      _bgmStarted = true;
    } catch (e) {
      debugPrint('🔇 [Game01] error reproduciendo BGM: $e');
    }
  }

  /// Cambiar volumen de la música
  void setMusicVolume(double volume) {
    musicVolume.value = volume.clamp(0.0, 1.0);
    FlameAudio.bgm.audioPlayer.setVolume(musicVolume.value);
    unawaited(_saveMusicVolume(musicVolume.value));
  }

  /// Cambiar volumen de efectos de sonido
  void setSfxVolume(double volume) {
    sfxVolume.value = volume.clamp(0.0, 1.0);
    unawaited(_saveSfxVolume(sfxVolume.value));
  }

  Future<void> _loadVolumeSettings() async {
    final prefs = await SharedPreferences.getInstance();
    musicVolume.value = prefs.getDouble('game01_music_volume') ?? 0.45;
    sfxVolume.value = prefs.getDouble('game01_sfx_volume') ?? 0.7;
  }

  Future<void> _saveMusicVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('game01_music_volume', volume);
  }

  Future<void> _saveSfxVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('game01_sfx_volume', volume);
  }
}

extension on Images {
  void clearCachedImages() {}
}
