import 'dart:async' as dart_async;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame/parallax.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/block.dart';
import 'components/filtered_parallax_component.dart';

typedef GameOverCallback = void Function(StackResult result);

class StackResult {
  final int score;
  final int best;
  StackResult({required this.score, required this.best});
}

enum StackState { playing, gameOver }

class Game02 extends FlameGame with TapCallbacks {
  Game02({required this.onGameOver});

  @override
  Color backgroundColor() => const Color(0xFF101010); // fondo más claro provisional

  final GameOverCallback onGameOver;
  static const overlayHud = 'hud';
  static const overlayGameOver = 'gameOver';
  static const overlayPause = 'pause';
  static const overlayMenu = 'menu';
  static const overlayCountdown = 'countdown';
  static const _prefsBestKey = 'game02_best_score';
  static const double _gravity = 1200;

  // Force explicit world/camera setup so the scene always renders behind
  // Flutter overlays (menu/pause/countdown), same spirit as Game01.
  final World _world = World();
  CameraComponent? _camera;

  // ====== Tuning ======
  double _blockHeight = 34;
  static const double _spawnGap = 0; // sin separación visual
  static const double _dropExtra = 12; // buffer pequeño para caída
  double _cameraMargin = 180;
  static const double _minOverlapPx = 6;
  static const double _minOverlapRatio = 0.30;
  // Tolerancia en píxeles para considerar “PERFECT” (alineación casi exacta).
  // Más permisivo a propósito + hacemos snap para que quede visualmente perfecto.
  static const double _perfectAlignTolerancePx = 10.0;

  // dificultad
  static const double _speedStart = 320;
  static const double _speedAddPerBlock = 10;
  static const double _widthStartRatio = 0.25;
  static const double _minWidth = 0; // permite heredar tamaños muy pequeños

  // ====== State ======
  StackState state = StackState.playing;

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int?> countdown = ValueNotifier<int?>(null);
  final ValueNotifier<String?> scoreFeedbackText = ValueNotifier<String?>(null);
  final ValueNotifier<int> perfectFeedbackTick = ValueNotifier<int>(0);
  final ValueNotifier<int> perfectStreak = ValueNotifier<int>(0);
  final ValueNotifier<int> perfectCelebrationTick = ValueNotifier<int>(0);

  // UI parity with Game01 (sliders exist even if Game02 has no audio).
  final ValueNotifier<double> musicVolume = ValueNotifier<double>(0.45);
  final ValueNotifier<double> sfxVolume = ValueNotifier<double>(0.7);

  bool isPaused = true; // start paused until user presses Play
  dart_async.Timer? _countdownTimer;
  dart_async.Timer? _scoreFeedbackTimer;

  final List<BlockComponent> tower = [];
  BlockComponent? moving;

  final math.Random _rng = math.Random();

  int score = 0;
  int bestScore = 0;

  int _perfectCombo = 0;
  double _movingSpeed = _speedStart;
  double _movingWidth = 0;
  ui.Image? _towerImage;
  bool _imageReady = false;
  double _imageScale = 1;
  double _blockWidth = 140;
  PositionComponent? _floor;
  double _floorHeight = 90;

  double get _floorTop => size.y - (_floor?.size.y ?? _floorHeight);
  double get _groundY => _floorTop;

  static const double _separatorThickness = 12.0;

  double _cameraY = 0;
  double _cameraTargetY = 0;
  static const double _cameraFollowSpeed = 10.0; // más alto = más rápido
  double _cameraStepY = 0;

  // ===== Background (visual only) =====
  PositionComponent? _bgSky;
  FilteredParallaxComponent? _bgClouds;
  RectangleComponent? _bgDarkOverlay;

  double _bgLastCamY = 0;
  double _bgVelocityY = 0;

  static const double _bgOverlayOpacity = 0.22;
  static const double _bgSaturation = 0.65;
  static const double _bgContrast = 0.92;
  static const double _bgParallaxCameraScale = 0.012;
  static const double _bgParallaxSmoothing = 6.0;
  static const double _bgCloudDelta = 0.55;

  double _bgTime = 0;
  static const double _bgIdleFloatAmplitude = 6.0;
  static const double _bgIdleFloatHz = 0.10;

  void _spawnLandingParticles({
    required Vector2 worldPos,
    bool isPerfect = false,
  }) {
    // Partículas simples y baratas: “polvo” + opcional chispas verdes.
    final dustColor = (isPerfect ? const Color(0xFF00FF7A) : Colors.white)
        .withOpacity(isPerfect ? 0.78 : 0.38);
    final dust = Particle.generate(
      count: isPerfect ? 130 : 70,
      lifespan: isPerfect ? 0.46 : 0.40,
      generator: (i) {
        final dir = Vector2(
          (_rng.nextDouble() * 2 - 1) * (isPerfect ? 85 : 65),
          -_rng.nextDouble() * (isPerfect ? 210 : 150),
        );
        return AcceleratedParticle(
          acceleration: Vector2(0, isPerfect ? 650 : 520),
          speed: dir,
          position: worldPos,
          child: CircleParticle(
            radius: (isPerfect ? 1.9 : 1.4) + _rng.nextDouble() * 1.8,
            paint: Paint()..color = dustColor,
          ),
        );
      },
    );

    _world.add(
      ParticleSystemComponent(
        particle: dust,
        position: Vector2.zero(),
        priority: 30,
      ),
    );

    if (!isPerfect) return;

    final sparkColor = const Color(0xFF00FF7A).withOpacity(0.98);
    final sparks = Particle.generate(
      count: 80,
      lifespan: 0.55,
      generator: (i) {
        final dir = Vector2(
          (_rng.nextDouble() * 2 - 1) * 160,
          -70 - _rng.nextDouble() * 220,
        );
        return AcceleratedParticle(
          acceleration: Vector2(0, 780),
          speed: dir,
          position: worldPos,
          child: CircleParticle(
            radius: 1.2 + _rng.nextDouble() * 1.8,
            paint: Paint()..color = sparkColor,
          ),
        );
      },
    );

    _world.add(
      ParticleSystemComponent(
        particle: sparks,
        position: Vector2.zero(),
        priority: 31,
      ),
    );
  }

  void _animateLanding(BlockComponent block, {required bool isPerfect}) {
    // Micro “bump” vertical + opcional glow sutil via opacity flicker.
    block.add(
      MoveByEffect(
        Vector2(0, -4),
        EffectController(
          duration: 0.06,
          alternate: true,
          curve: Curves.easeOut,
        ),
      ),
    );

    if (!isPerfect) return;

    // Evitar OpacityEffect (requiere OpacityProvider). Animamos un campo propio.
    block.add(
      _OpacityPulseComponent(
        block,
        low: 0.85,
        downDuration: 0.06,
        upDuration: 0.10,
      ),
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(_world);
    _camera ??= CameraComponent(world: _world)
      ..viewfinder.anchor = Anchor.topLeft
      ..viewfinder.position = Vector2.zero();
    add(_camera!);

    // Precarga de assets (igual enfoque que Game01)
    await images.loadAll([
      'games/game_02/1.png',
      'games/game_02/2.png',
      'games/game_02/3.png',
      'games/game_02/floor.png',
      'games/game_02/boombet_tower.png',
    ]);

    // Fondo: ParallaxComponent + overlay/filtro para empujarlo hacia atrás.
    await _loadBackground();

    await _loadBestScore();
    try {
      final img = images.fromCache('games/game_02/boombet_tower.png');
      _towerImage = img;
      _imageReady = img.width > 0 && img.height > 0;
    } catch (e) {
      debugPrint('[Game02] Failed to load tower texture (cache): $e');
      _imageReady = false;
    }

    if (_towerImage != null && _towerImage!.width > 0) {
      // Escalamos para que el ancho inicial sea una fracción de la pantalla,
      // sin hacer la imagen más grande que su tamaño real.
      final double targetWidth = size.x * _widthStartRatio;
      _imageScale = math.min(1.0, targetWidth / _towerImage!.width);
      _blockWidth = _towerImage!.width * _imageScale;
      _blockHeight = _towerImage!.height * _imageScale;
    }

    // Margen de cámara más agresivo: sigue al bloque apenas sube (~30% pantalla)
    _cameraMargin = size.y * 0.30;

    // Paso de cámara: por cada bloque colocado, subimos casi 1 bloque.
    _cameraStepY = _blockHeight * 0.90;

    await _loadFloor();
    _resetGame();
  }

  // ========================
  // UI / OVERLAYS (Game01 parity)
  // ========================

  void setMusicVolume(double value) {
    musicVolume.value = value.clamp(0.0, 1.0);
  }

  void setSfxVolume(double value) {
    sfxVolume.value = value.clamp(0.0, 1.0);
  }

  void pauseGame() {
    if (state == StackState.gameOver || isPaused) return;
    isPaused = true;
    overlays.add(overlayPause);
  }

  void resumeGame() {
    if (state == StackState.gameOver || !isPaused) return;
    isPaused = false;
    overlays.remove(overlayPause);
  }

  void startGame() {
    if (state == StackState.gameOver || !isPaused) return;
    isPaused = false;
    overlays.remove(overlayMenu);
    overlays.remove(overlayCountdown);
    if (!overlays.isActive(overlayHud)) {
      overlays.add(overlayHud);
    }
  }

  /// Inicia la partida con un conteo regresivo 3-2-1.
  void startWithCountdown() {
    if (state == StackState.gameOver || !isPaused) return;

    _countdownTimer?.cancel();
    countdown.value = 3;

    overlays.remove(overlayMenu);
    overlays.remove(overlayPause);
    overlays.remove(overlayGameOver);
    overlays.add(overlayCountdown);

    _countdownTimer = dart_async.Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      final current = countdown.value ?? 0;
      if (current <= 1) {
        timer.cancel();
        countdown.value = null;
        overlays.remove(overlayCountdown);
        startGame();
        return;
      }
      countdown.value = current - 1;
    });
  }

  Future<void> _loadBackground() async {
    try {
      final imgSky = images.fromCache('games/game_02/1.png');

      _bgSky = SpriteComponent(
        sprite: Sprite(imgSky),
        anchor: Anchor.topLeft,
        priority: -1000,
      );
      _world.add(_bgSky!);

      // Clouds parallax (2 layers). No repeat to avoid visible tiling.
      final cloudsParallax = await Parallax.load(
        [
          ParallaxImageData('games/game_02/2.png'),
          ParallaxImageData('games/game_02/3.png'),
        ],
        baseVelocity: Vector2.zero(),
        velocityMultiplierDelta: Vector2(0, _bgCloudDelta),
      );

      _bgClouds = FilteredParallaxComponent(parallax: cloudsParallax)
        ..anchor = Anchor.topLeft
        ..priority = -999;
      _world.add(_bgClouds!);

      _bgDarkOverlay = RectangleComponent(
        anchor: Anchor.topLeft,
        priority: -998,
        paint: Paint()..color = Colors.black.withOpacity(_bgOverlayOpacity),
      );
      _world.add(_bgDarkOverlay!);

      _applyBackgroundFilters();
      _layoutBackground();
      _syncBackgroundToCamera(1 / 60);
    } catch (e) {
      debugPrint('[Game02] Failed to load background images: $e');
      // Fallback sólido para no dejar gris
      _bgSky = RectangleComponent(
        size: size,
        paint: Paint()..color = const Color(0xFF0C0C0C),
        anchor: Anchor.topLeft,
        priority: -1000,
      );
      _world.add(_bgSky!);
    }
  }

  void _applyBackgroundFilters() {
    final filter = ui.ColorFilter.matrix(
      _buildSaturationContrastMatrix(
        saturation: _bgSaturation,
        contrast: _bgContrast,
      ),
    );

    final sky = _bgSky;
    if (sky is SpriteComponent) {
      sky.paint = Paint()..colorFilter = filter;
    }

    final clouds = _bgClouds;
    if (clouds != null) {
      clouds.colorFilter = filter;
    }
  }

  List<double> _buildSaturationContrastMatrix({
    required double saturation,
    required double contrast,
  }) {
    final s = saturation.clamp(0.0, 2.0);
    final c = contrast.clamp(0.0, 2.0);

    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;

    final sr = (1 - s) * lumR;
    final sg = (1 - s) * lumG;
    final sb = (1 - s) * lumB;

    // Saturation matrix (4x5)
    final m = <double>[
      sr + s,
      sg,
      sb,
      0,
      0,
      sr,
      sg + s,
      sb,
      0,
      0,
      sr,
      sg,
      sb + s,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];

    // Apply contrast after saturation: rgb = c*rgb + t
    final t = (1 - c) * 128.0;
    for (var i = 0; i < 15; i++) {
      // first 3 rows * c
      m[i] *= c;
    }
    m[4] = t;
    m[9] = t;
    m[14] = t;
    return m;
  }

  void _layoutBackground() {
    final sky = _bgSky;
    if (sky is SpriteComponent && sky.sprite != null) {
      final img = sky.sprite!.image;
      final double scale = math.max(size.x / img.width, size.y / img.height);
      sky.size = Vector2(img.width * scale, img.height * scale);
    } else {
      // Fallback: mantenerlo full-screen
      sky?.size = size;
    }

    _bgClouds?.size = size;
    _bgDarkOverlay?.size = size;
  }

  void _syncBackgroundToCamera(double dt) {
    final camera = _camera;
    if (camera == null) return;

    _bgTime += dt;
    final floatY =
        math.sin(_bgTime * (math.pi * 2) * _bgIdleFloatHz) *
        _bgIdleFloatAmplitude;

    final cam = camera.viewfinder.position;

    // Pin the background container to the camera so it stays full-screen.
    final sky = _bgSky;
    if (sky != null) {
      final s = sky.size;
      sky.position = Vector2(
        cam.x + (size.x - s.x) / 2,
        cam.y + (size.y - s.y) / 2,
      );
    }
    _bgClouds?.position = cam + Vector2(0, floatY);
    _bgDarkOverlay?.position = cam;

    // Drive parallax subtly from camera movement, but smooth it so step-scroll
    // doesn't cause harsh jumps.
    if (_bgClouds?.parallax != null && dt > 0) {
      final dy = cam.y - _bgLastCamY;
      final targetVel = dy == 0 ? 0.0 : (-dy / dt) * _bgParallaxCameraScale;
      final t = (dt * _bgParallaxSmoothing).clamp(0.0, 1.0);
      _bgVelocityY = _bgVelocityY + (targetVel - _bgVelocityY) * t;
      _bgClouds!.parallax!.baseVelocity = Vector2(0, _bgVelocityY);
      _bgLastCamY = cam.y;
    }
  }

  Future<void> _loadFloor() async {
    try {
      final floorImg = images.fromCache('games/game_02/floor.png');
      final scale = size.x / floorImg.width;
      _floorHeight = floorImg.height * scale;

      _floor = SpriteComponent(
        sprite: Sprite(floorImg),
        size: Vector2(size.x, _floorHeight),
        position: Vector2(0, size.y - _floorHeight),
        anchor: Anchor.topLeft,
        priority: -10,
      );

      // Piso en el mundo (debe moverse con la cámara)
      _world.add(_floor!);
    } catch (e) {
      debugPrint('[Game02] Failed to load floor texture: $e');
      _floor = RectangleComponent(
        position: Vector2(0, size.y - _floorHeight),
        size: Vector2(size.x, _floorHeight),
        paint: Paint()..color = const Color(0xFF0E0E0E),
        priority: -10,
      );
      // no offset; usaremos solape visual del bloque base
      _world.add(_floor!);
    }
  }

  void _resetGame() {
    // limpiar
    state = StackState.playing;
    isPaused = true;
    countdown.value = null;
    _countdownTimer?.cancel();
    _scoreFeedbackTimer?.cancel();
    scoreFeedbackText.value = null;
    perfectFeedbackTick.value = 0;
    overlays.clear();
    overlays.add(overlayMenu);

    score = 0;
    _perfectCombo = 0;
    perfectStreak.value = 0;
    perfectCelebrationTick.value = 0;
    _movingSpeed = _speedStart;

    // remover componentes existentes
    for (final b in tower) {
      b.removeFromParent();
    }
    tower.clear();
    moving?.removeFromParent();
    moving = null;

    scoreNotifier.value = 0;

    // cámara: reiniciar en base
    _cameraY = 0;
    _cameraTargetY = 0;
    _camera?.viewfinder.position = Vector2.zero();

    // base block
    final baseWidth = _blockWidth;
    _movingWidth = baseWidth;

    const double baseVisualOverlap = 6; // solape para eliminar gap con el piso
    final base = BlockComponent(
      position: Vector2(
        (size.x - baseWidth) / 2,
        _groundY - _blockHeight + baseVisualOverlap,
      ),
      size: Vector2(baseWidth, _blockHeight),
      colorSeed: 0,
      isMoving: false,
      speed: 0,
      towerImage: _imageReady ? _towerImage : null,
      imageScale: _imageScale,
    );

    tower.add(base);
    _world.add(base);

    _spawnNextBlock();
  }

  void restart() => _resetGame();

  void _spawnNextBlock() {
    if (state != StackState.playing) return;

    final prev = tower.last;

    _movingWidth = prev.size.x; // hereda exactamente el ancho del último bloque

    // Spawnea visible, pegado a la parte superior de la vista actual.
    final double cameraTop = _camera?.viewfinder.position.y ?? 0.0;
    final double spawnY = cameraTop + 8;

    final double maxX = math.max(0.0, size.x - _movingWidth);
    final double startX = _rng.nextDouble() * maxX;

    final block = BlockComponent(
      position: Vector2(startX, spawnY),
      size: Vector2(_movingWidth, _blockHeight),
      colorSeed: tower.length,
      isMoving: true,
      speed: _movingSpeed,
      towerImage: _towerImage,
      imageScale: _imageScale,
    );

    moving = block;
    _world.add(block);

    // Asegura que el cameraTop esté aplicado antes de posicionar/pinear.
    _updateCamera(1 / 60);
  }

  void _updateCamera(double dt) {
    // Cámara suavizada: se mueve hacia un target por pasos.
    final camera = _camera;
    if (camera == null) return;

    if (dt > 0) {
      // Exponential smoothing (frame-rate independent)
      final t = 1 - math.exp(-_cameraFollowSpeed * dt);
      _cameraY = _cameraY + (_cameraTargetY - _cameraY) * t;
    } else {
      _cameraY = _cameraTargetY;
    }

    camera.viewfinder.position = Vector2(0, _cameraY);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);

    // Recalcular margen de cámara al cambiar el tamaño.
    _cameraMargin = canvasSize.y * 0.30;
    _cameraStepY = _blockHeight * 0.90;

    _layoutBackground();
    _syncBackgroundToCamera(1 / 60);

    if (_floor != null) {
      _floor!
        ..size = Vector2(canvasSize.x, _floorHeight)
        ..position = Vector2(0, canvasSize.y - _floorHeight);
    }
  }

  // Sin separadores ni slicing: cada bloque es la imagen completa

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (state != StackState.playing || isPaused || countdown.value != null) {
      return;
    }

    final m = moving;
    if (m == null || !m.isMoving) return;

    // soltar: empieza caída vertical con gravedad
    m.startDrop(_gravity);
  }

  @override
  void update(double dt) {
    // Siempre actualizar cámara y background (menú como “wallpaper”).
    _updateCamera(dt);
    _syncBackgroundToCamera(dt);

    // Siempre actualizar componentes (parallax necesita update),
    // pero el gameplay se congela dentro de BlockComponent cuando está pausado.
    super.update(dt);

    // Gameplay logic (colocación / scoring) sólo cuando corresponde.
    if (state != StackState.playing || isPaused || countdown.value != null) {
      return;
    }

    final m = moving;

    if (m != null && m.isMoving && !m.isDropping) {
      final cameraTop = _camera?.viewfinder.position.y ?? 0.0;
      m.position.y = cameraTop + 8;
    }

    if (m != null && m.isDropping) {
      final targetY = tower.last.position.y - _blockHeight;
      if (m.position.y >= targetY) {
        m.position.y = targetY;
        m.isDropping = false;
        _resolvePlacement();
      }
    }
  }

  void _resolvePlacement() {
    final curr = moving!;
    final prev = tower.last;

    final currLeft = curr.position.x;
    final currRight = curr.position.x + curr.size.x;

    final prevLeft = prev.position.x;
    final prevRight = prev.position.x + prev.size.x;

    final double overlap =
        math.min(currRight, prevRight) - math.max(currLeft, prevLeft);

    // Sólo pierde si no hay solape real; permitir “golpe en la punta” con corte mínimo
    if (overlap <= _minOverlapPx) {
      moving = null;
      _triggerGameOverWithBreak(curr);
      return;
    }

    // Dejamos el bloque tal cual cayó (sin recortar ni reducir el ancho).
    _movingWidth = curr.size.x;

    // PERFECT: solo importa que el bloque caiga alineado con el de abajo,
    // sin importar si la torre está a la izquierda/derecha/centro.
    // Usamos centros para tolerar diferencias mínimas y floats.
    final currCenterX = currLeft + curr.size.x / 2;
    final prevCenterX = prevLeft + prev.size.x / 2;
    final double dx = (currCenterX - prevCenterX).abs();
    final bool isPerfect = dx <= _perfectAlignTolerancePx;

    // Snap para que quede perfectamente alineado (full dopamina visual).
    if (isPerfect) {
      final targetX = prevCenterX - curr.size.x / 2;
      curr.position.x = targetX.clamp(0.0, size.x - curr.size.x);
    }

    if (isPerfect) {
      _scoreFeedbackTimer?.cancel();
      scoreFeedbackText.value = 'PERFECT!';
      perfectFeedbackTick.value = perfectFeedbackTick.value + 1;
      _scoreFeedbackTimer = dart_async.Timer(
        const Duration(milliseconds: 1300),
        () => scoreFeedbackText.value = null,
      );
    } else {
      scoreFeedbackText.value = null;
    }

    // FX: partículas + animación en el punto de contacto.
    final landingPos = Vector2(
      curr.position.x + curr.size.x / 2,
      curr.position.y + curr.size.y,
    );
    _spawnLandingParticles(worldPos: landingPos, isPerfect: isPerfect);
    _animateLanding(curr, isPerfect: isPerfect);

    if (isPerfect) {
      _perfectCombo += 1;
      perfectStreak.value = _perfectCombo;
      if (_perfectCombo >= 3) {
        perfectCelebrationTick.value = perfectCelebrationTick.value + 1;
      }
      HapticFeedback.lightImpact();
    } else {
      _perfectCombo = 0;
      perfectStreak.value = 0;
    }

    // score
    int addPoints = 10;
    if (isPerfect) addPoints = 25;

    int multiplier = 1;
    if (_perfectCombo >= 5)
      multiplier = 3;
    else if (_perfectCombo >= 3)
      multiplier = 2;

    score += addPoints * multiplier;
    scoreNotifier.value = score;

    // fijamos la pieza al tower
    tower.add(curr);
    moving = null;

    // A partir de que cae el primer bloque, movemos la cámara por pasos para que
    // se vean solo 1-2 bloques. Al mover la cámara, el bloque en movimiento queda
    // “fijo” arriba gracias al pin en update().
    if (tower.length >= 2) {
      _cameraTargetY -= _cameraStepY;
    }

    // dificultad
    _movingSpeed += _speedAddPerBlock;
    _movingWidth = curr.size.x;

    // spawnear siguiente
    _spawnNextBlock();
  }

  // Separador se agrega al iniciar una nueva “B” (ver _spawnNextBlock)

  void _triggerGameOverWithBreak(BlockComponent fallingBlock) {
    // Congelar gameplay ya mismo (para que no se spawneen más cosas), pero
    // dejamos que el render/update siga para que se vean las animaciones.
    if (state == StackState.gameOver) return;
    state = StackState.gameOver;
    isPaused = false;
    countdown.value = null;
    _countdownTimer?.cancel();

    // Feedback UI fuera
    _scoreFeedbackTimer?.cancel();
    scoreFeedbackText.value = null;
    _perfectCombo = 0;
    perfectStreak.value = 0;

    _playBreakAnimation(fallingBlock);

    // Mostrar game over luego del “romperse”.
    dart_async.Timer(const Duration(milliseconds: 650), _finalizeGameOver);
  }

  void _finalizeGameOver() {
    if (overlays.isActive(overlayGameOver)) return;

    final newBest = math.max(bestScore, score);
    if (newBest != bestScore) {
      bestScore = newBest;
      _persistBestScore();
    }

    onGameOver(StackResult(score: score, best: bestScore));
    overlays.add(overlayGameOver);
  }

  void _playBreakAnimation(BlockComponent block) {
    final origin = block.position.clone();
    final blockSize = block.size.clone();
    final seed = block.colorSeed;

    block.removeFromParent();

    // Partículas de impacto extra (blancas) al romperse.
    _spawnLandingParticles(
      worldPos: Vector2(origin.x + blockSize.x / 2, origin.y + blockSize.y),
      isPerfect: false,
    );

    // Grid de fragmentos (más ancho => más columnas)
    final cols = (blockSize.x / 26).clamp(7, 14).round();
    const rows = 2;
    final fw = blockSize.x / cols;
    final fh = blockSize.y / rows;

    final img = _imageReady ? _towerImage : null;
    final hasImg = img != null;
    final srcW = hasImg ? img!.width.toDouble() / cols : 0.0;
    final srcH = hasImg ? img!.height.toDouble() / rows : 0.0;

    final fallbackColor = HSVColor.fromAHSV(
      1,
      (seed * 35 % 360).toDouble(),
      0.75,
      0.95,
    ).toColor();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final fragPos = Vector2(origin.x + c * fw, origin.y + r * fh);

        final PositionComponent frag;
        if (hasImg) {
          frag = SpriteComponent(
            sprite: Sprite(
              img!,
              srcPosition: Vector2(c * srcW, r * srcH),
              srcSize: Vector2(srcW, srcH),
            ),
            position: fragPos,
            size: Vector2(fw, fh),
            anchor: Anchor.topLeft,
            priority: 20,
          );
        } else {
          frag = RectangleComponent(
            position: fragPos,
            size: Vector2(fw, fh),
            paint: Paint()..color = fallbackColor,
            anchor: Anchor.topLeft,
            priority: 20,
          );
        }

        final duration = 0.75 + _rng.nextDouble() * 0.20;
        final dx = (_rng.nextDouble() * 2 - 1) * 160;
        final up = -80 - _rng.nextDouble() * 170;
        final down = blockSize.y + 240 + _rng.nextDouble() * 240;
        final rot = (_rng.nextDouble() * 2 - 1) * 2.6;

        frag.add(
          SequenceEffect([
            MoveByEffect(
              Vector2(dx * 0.35, up),
              EffectController(duration: 0.16, curve: Curves.easeOutCubic),
            ),
            MoveByEffect(
              Vector2(dx, down),
              EffectController(duration: duration, curve: Curves.easeIn),
            ),
          ]),
        );
        frag.add(
          RotateEffect.by(
            rot,
            EffectController(duration: duration + 0.16, curve: Curves.easeOut),
          ),
        );
        frag.add(
          ScaleEffect.to(
            Vector2.all(0.92),
            EffectController(duration: duration + 0.16, curve: Curves.easeIn),
          ),
        );
        frag.add(
          TimerComponent(
            period: duration + 0.22,
            removeOnFinish: true,
            onTick: frag.removeFromParent,
          ),
        );

        _world.add(frag);
      }
    }
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    bestScore = prefs.getInt(_prefsBestKey) ?? 0;
    bestScoreNotifier.value = bestScore;
  }

  Future<void> _persistBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsBestKey, bestScore);
    bestScoreNotifier.value = bestScore;
  }
}

class _OpacityPulseComponent extends Component {
  _OpacityPulseComponent(
    this.target, {
    required this.low,
    required this.downDuration,
    required this.upDuration,
  });

  final BlockComponent target;
  final double low;
  final double downDuration;
  final double upDuration;

  double _t = 0;
  late final double _startOpacity = target.opacity;

  @override
  void update(double dt) {
    super.update(dt);

    _t += dt;
    final total = downDuration + upDuration;

    if (_t <= downDuration) {
      final a = Curves.easeOut.transform((_t / downDuration).clamp(0.0, 1.0));
      target.opacity = ui.lerpDouble(_startOpacity, low, a) ?? target.opacity;
      return;
    }

    if (_t <= total) {
      final a = Curves.easeOut.transform(
        ((_t - downDuration) / upDuration).clamp(0.0, 1.0),
      );
      target.opacity = ui.lerpDouble(low, _startOpacity, a) ?? target.opacity;
      return;
    }

    target.opacity = _startOpacity;
    removeFromParent();
  }

  @override
  void onRemove() {
    target.opacity = _startOpacity;
    super.onRemove();
  }
}
