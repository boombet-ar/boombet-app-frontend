import 'dart:async' as dart_async;
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/player.dart';
import 'components/platform.dart';
import 'components/hazard_circle.dart';
import 'components/moving_platform.dart';

class Game03 extends FlameGame with PanDetector, KeyboardEvents {
  static const overlayHud = 'hud';
  static const overlayGameOver = 'gameOver';
  static const overlayPause = 'pause';
  static const overlayMenu = 'menu';
  static const overlayCountdown = 'countdown';
  static const _prefsBestKey = 'game03_best_score';

  final ValueNotifier<int> scoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> bestScoreNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int?> countdown = ValueNotifier<int?>(null);
  final ValueNotifier<double> musicVolume = ValueNotifier<double>(0.45);
  final ValueNotifier<double> sfxVolume = ValueNotifier<double>(0.7);

  final math.Random _rng = math.Random();
  final List<PlatformComponent> _platforms = [];
  final List<PlatformComponent> _fragilePlatforms = [];
  final List<MovingPlatformComponent> _movingPlatforms = [];
  final List<PlatformComponent> _boostPlatforms = [];
  final List<HazardCircleComponent> _hazards = [];

  SpriteComponent? _background;
  RectangleComponent? _backgroundOverlay;

  PlayerComponent? _player;
  PlatformComponent? _startPlatform;
  double _inputX = 0;
  double _inputXTarget = 0;
  bool _hasStarted = false;
  bool _isGameOver = false;
  bool isPaused = true;
  bool _panInputEnabled = true;

  static const double _gravity = 1200;
  static const double _jumpVelocity = 820;
  static const double _moveSpeed = 320;
  static const double _platformGapMin = 110;
  static const double _platformGapMax = 170;
  static const double _firstPlatformExtraOffset = 90;
  static const double _platformWidth = 95;
  static const double _platformHeight = 14;
  static const int _basePlatformCount = 10;
  static const int _minPlatformCount = 4;
  static const double _breakPlatformChance = 0.2;
  static const int _fragileMax = 4;
  static const double _movingPlatformChance = 0.18;
  static const int _movingPlatformMax = 3;
  static const double _movingPlatformBaseSpeed = 110;
  static const double _movingPlatformStartScore = 140;
  static const double _boostPlatformChance = 0.14;
  static const int _boostPlatformMax = 3;
  static const double _boostPlatformMultiplier = 1.45;
  static const double _boostPlatformStartScore = 220;
  static const double _hazardStartScore = 250;
  static const double _hazardSpawnInterval = 2.2;
  static const double _hazardRadius = 14;
  static const double _hazardBaseSpeed = 140;
  static const double _densityDecayScore = 2000;
  static const double _slamVelocity = 1500;
  static const double _backgroundDarkness = 0.35;

  double _maxHeight = 0;
  double _elapsedTime = 0;
  double _worldOffset = 0;
  double _maxWorldOffset = 0;
  double _hazardTimer = 0;
  dart_async.Timer? _countdownTimer;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await images.loadAll([
      'games/game_03/background.png',
      'games/game_03/player.png',
    ]);
    await _loadBestScore();
    _reset();
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    bestScoreNotifier.value = prefs.getInt(_prefsBestKey) ?? 0;
  }

  Future<void> _saveBestScore(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsBestKey, value);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final bg = _background;
    if (bg != null) {
      bg.size = size.clone();
    }
    final overlay = _backgroundOverlay;
    if (overlay != null) {
      overlay.size = size.clone();
    }
  }

  void _reset() {
    _isGameOver = false;
    scoreNotifier.value = 0;
    _maxHeight = 0;
    _elapsedTime = 0;
    _worldOffset = 0;
    _maxWorldOffset = 0;
    _hasStarted = false;
    _inputX = 0;
    _inputXTarget = 0;
    _hazardTimer = 0;

    removeAll(children.toList());
    _platforms.clear();
    _fragilePlatforms.clear();
    _movingPlatforms.clear();
    _boostPlatforms.clear();
    _hazards.clear();
    isPaused = true;

    _background = SpriteComponent(
      sprite: Sprite(images.fromCache('games/game_03/background.png')),
      size: size.clone(),
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
      priority: -1000,
    );
    add(_background!);

    _backgroundOverlay = RectangleComponent(
      size: size.clone(),
      position: Vector2.zero(),
      anchor: Anchor.topLeft,
      priority: -999,
      paint: Paint()..color = Colors.black.withOpacity(_backgroundDarkness),
    );
    add(_backgroundOverlay!);

    final playerSprite = Sprite(images.fromCache('games/game_03/player.png'));
    final player = PlayerComponent(
      size: Vector2(42, 42),
      position: Vector2(size.x / 2 - 21, size.y - 140),
      sprite: playerSprite,
      jumpVelocity: _jumpVelocity,
      moveSpeed: _moveSpeed,
    );
    _player = player;
    add(player);

    final startPlatform = _spawnStartPlatform(player);
    _startPlatform = startPlatform;
    _placePlayerOnPlatform(player, startPlatform);
    _spawnInitialPlatforms(startPlatform);
    pauseEngine();
  }

  PlatformComponent _spawnStartPlatform(PlayerComponent player) {
    final x = (player.x + (player.size.x / 2) - (_platformWidth / 2)).clamp(
      0.0,
      size.x - _platformWidth,
    );
    final y = player.y + player.size.y + 6;

    final platform = PlatformComponent(
      size: Vector2(_platformWidth, _platformHeight),
      position: Vector2(x, y),
      isBreakable: false,
      breaksOnTouch: false,
    );
    add(platform);
    _platforms.add(platform);
    return platform;
  }

  void _spawnInitialPlatforms(PlatformComponent startPlatform) {
    double y = startPlatform.y - _randomGap() - _firstPlatformExtraOffset;
    final fixedLeft = startPlatform.x;
    final fixedRight = startPlatform.x + startPlatform.size.x;

    for (int i = 0; i < 8; i++) {
      final width = _platformWidth;
      double x = _randomPlatformX(width);

      if (i == 0) {
        const minGap = 18.0;
        int attempts = 0;
        while (attempts < 8) {
          final left = x;
          final right = x + width;
          final overlaps =
              right > (fixedLeft - minGap) && left < (fixedRight + minGap);
          if (!overlaps) {
            break;
          }
          x = _randomPlatformX(width);
          attempts++;
        }
      }
      final candidateX = _findNonOverlappingX(y) ?? x;
      final platform = _createNormalPlatform(Vector2(candidateX, y));
      if (!_overlapsAnyPlatform(_rectForSpawn(platform.position))) {
        add(platform);
        _platforms.add(platform);
      }
      y -= _randomGap();
    }
  }

  PlatformComponent _createNormalPlatform(Vector2 position) {
    return PlatformComponent(
      size: Vector2(_platformWidth, _platformHeight),
      position: position,
      isBreakable: true,
      breaksOnTouch: false,
    );
  }

  PlatformComponent _createFragilePlatform(Vector2 position) {
    return PlatformComponent(
      size: Vector2(_platformWidth, _platformHeight),
      position: position,
      isBreakable: true,
      breaksOnTouch: true,
    );
  }

  PlatformComponent _createBoostPlatform(Vector2 position) {
    return PlatformComponent(
      size: Vector2(_platformWidth, _platformHeight),
      position: position,
      isBreakable: true,
      breaksOnTouch: false,
      boostsOnTouch: true,
      boostMultiplier: _boostPlatformMultiplier,
    );
  }

  double _currentHighestY() {
    final base = _platforms.isEmpty
        ? size.y - 120
        : _platforms.map((p) => p.y).reduce(math.min);
    var highest = base;
    if (_fragilePlatforms.isNotEmpty) {
      highest = math.min(
        highest,
        _fragilePlatforms.map((p) => p.y).reduce(math.min),
      );
    }
    if (_movingPlatforms.isNotEmpty) {
      highest = math.min(
        highest,
        _movingPlatforms.map((p) => p.y).reduce(math.min),
      );
    }
    if (_boostPlatforms.isNotEmpty) {
      highest = math.min(
        highest,
        _boostPlatforms.map((p) => p.y).reduce(math.min),
      );
    }
    return highest;
  }

  double _densityFactor() {
    final factor = 1.0 - (_maxHeight / _densityDecayScore);
    return factor.clamp(0.35, 1.0);
  }

  int _targetNormalPlatforms() {
    final target = (_basePlatformCount * _densityFactor()).round();
    return target.clamp(_minPlatformCount, _basePlatformCount);
  }

  int _targetFragileMax() {
    final target = (_fragileMax * _densityFactor()).floor();
    return target.clamp(1, _fragileMax);
  }

  int _targetMovingMax() {
    final target = (_movingPlatformMax * _densityFactor()).floor();
    return target.clamp(1, _movingPlatformMax);
  }

  int _targetBoostMax() {
    final target = (_boostPlatformMax * _densityFactor()).floor();
    return target.clamp(1, _boostPlatformMax);
  }

  PlatformComponent _createRandomPlatform(Vector2 position) {
    final breaksOnTouch = _rng.nextDouble() < _breakPlatformChance;
    return PlatformComponent(
      size: Vector2(_platformWidth, _platformHeight),
      position: position,
      isBreakable: true,
      breaksOnTouch: breaksOnTouch,
    );
  }

  double _randomGap() {
    return _platformGapMin +
        _rng.nextDouble() * (_platformGapMax - _platformGapMin);
  }

  double _difficultyMultiplier() {
    final multiplier = 1.0 + (_elapsedTime * 0.012);
    return multiplier.clamp(1.0, 1.9);
  }

  double _gravityMultiplier() {
    final multiplier = 1.0 + (_elapsedTime * 0.006);
    return multiplier.clamp(1.0, 1.35);
  }

  double _randomPlatformX(double width) {
    final maxX = math.max(0, size.x - width);
    return _rng.nextDouble() * maxX;
  }

  Rect _rectForSpawn(Vector2 position) {
    return Rect.fromLTWH(
      position.x,
      position.y,
      _platformWidth,
      _platformHeight,
    );
  }

  bool _overlapsAnyPlatform(Rect rect) {
    const padding = 2.0;
    final expanded = rect.inflate(padding);

    for (final platform in _platforms) {
      if (expanded.overlaps(platform.toRect().inflate(padding))) return true;
    }
    for (final platform in _fragilePlatforms) {
      if (expanded.overlaps(platform.toRect().inflate(padding))) return true;
    }
    for (final platform in _movingPlatforms) {
      if (expanded.overlaps(platform.toRect().inflate(padding))) return true;
    }
    for (final platform in _boostPlatforms) {
      if (expanded.overlaps(platform.toRect().inflate(padding))) return true;
    }
    return false;
  }

  double? _findNonOverlappingX(double y) {
    for (int attempt = 0; attempt < 12; attempt++) {
      final x = _randomPlatformX(_platformWidth);
      final rect = _rectForSpawn(Vector2(x, y));
      if (!_overlapsAnyPlatform(rect)) {
        return x;
      }
    }
    return null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isGameOver || isPaused || countdown.value != null) return;

    _elapsedTime += dt;
    final speedMultiplier = _difficultyMultiplier();
    final gravityMultiplier = _gravityMultiplier();

    final player = _player;
    if (player == null) return;

    if (!_hasStarted) {
      _lockPlayerOnStartPlatform(player);
      return;
    }

    _inputX = _lerp(_inputX, _inputXTarget, 0.18);

    player.velocity.x = _inputX * player.moveSpeed * speedMultiplier;
    player.velocity.y += _gravity * gravityMultiplier * dt;
    player.position += player.velocity * dt;

    if (player.x < -player.size.x) player.x = size.x;
    if (player.x > size.x) player.x = -player.size.x;

    _handlePlatformCollisions(player, dt);
    _updateMovingPlatforms(dt, speedMultiplier);
    _updateHazards(dt, speedMultiplier);
    _syncCameraToPlayer(player);

    if (_checkHazardCollision(player, dt)) {
      _triggerGameOver();
      return;
    }

    final fallDistance = _maxWorldOffset - _worldOffset;
    if (fallDistance > size.y * 0.9) {
      _triggerGameOver();
    }
  }

  void _handlePlatformCollisions(PlayerComponent player, double dt) {
    if (player.velocity.y <= 0) return;

    final playerRect = player.toRect();
    final nextRect = playerRect.shift(
      Offset(player.velocity.x * dt, player.velocity.y * dt),
    );
    final nextBottom = playerRect.bottom + player.velocity.y * dt;
    const horizontalTolerance = 10.0;
    const verticalTolerance = 6.0;

    for (int i = 0; i < _platforms.length; i++) {
      final platform = _platforms[i];
      final platRect = platform.toRect();
      final sweptLeft =
          math.min(playerRect.left, nextRect.left) - horizontalTolerance;
      final sweptRight =
          math.max(playerRect.right, nextRect.right) + horizontalTolerance;
      final isHorizOverlap =
          sweptRight > platRect.left && sweptLeft < platRect.right;
      if (!isHorizOverlap) continue;

      final isCrossingTop =
          playerRect.bottom <= platRect.top + verticalTolerance &&
          nextBottom >= platRect.top - verticalTolerance;
      if (isCrossingTop) {
        player.position.y = platRect.top - player.size.y;
        player.velocity.y = -player.jumpVelocity;
        if (platform.isBreakable) {
          platform.removeFromParent();
          _platforms.removeAt(i);
        }
        break;
      }
    }

    for (int i = 0; i < _movingPlatforms.length; i++) {
      final platform = _movingPlatforms[i];
      final platRect = platform.toRect();
      final sweptLeft =
          math.min(playerRect.left, nextRect.left) - horizontalTolerance;
      final sweptRight =
          math.max(playerRect.right, nextRect.right) + horizontalTolerance;
      final isHorizOverlap =
          sweptRight > platRect.left && sweptLeft < platRect.right;
      if (!isHorizOverlap) continue;

      final isCrossingTop =
          playerRect.bottom <= platRect.top + verticalTolerance &&
          nextBottom >= platRect.top - verticalTolerance;
      if (isCrossingTop) {
        player.position.y = platRect.top - player.size.y;
        player.velocity.y = -player.jumpVelocity;
        if (platform.isBreakable) {
          platform.removeFromParent();
          _movingPlatforms.removeAt(i);
        }
        break;
      }
    }

    for (int i = 0; i < _boostPlatforms.length; i++) {
      final platform = _boostPlatforms[i];
      final platRect = platform.toRect();
      final sweptLeft =
          math.min(playerRect.left, nextRect.left) - horizontalTolerance;
      final sweptRight =
          math.max(playerRect.right, nextRect.right) + horizontalTolerance;
      final isHorizOverlap =
          sweptRight > platRect.left && sweptLeft < platRect.right;
      if (!isHorizOverlap) continue;

      final isCrossingTop =
          playerRect.bottom <= platRect.top + verticalTolerance &&
          nextBottom >= platRect.top - verticalTolerance;
      if (isCrossingTop) {
        player.position.y = platRect.top - player.size.y;
        player.velocity.y = -player.jumpVelocity * platform.boostMultiplier;
        if (platform.isBreakable) {
          platform.removeFromParent();
          _boostPlatforms.removeAt(i);
        }
        break;
      }
    }

    for (int i = 0; i < _fragilePlatforms.length; i++) {
      final platform = _fragilePlatforms[i];
      final platRect = platform.toRect();
      final sweptLeft =
          math.min(playerRect.left, nextRect.left) - horizontalTolerance;
      final sweptRight =
          math.max(playerRect.right, nextRect.right) + horizontalTolerance;
      final isHorizOverlap =
          sweptRight > platRect.left && sweptLeft < platRect.right;
      if (!isHorizOverlap) continue;

      final isCrossingTop =
          playerRect.bottom <= platRect.top + verticalTolerance &&
          nextBottom >= platRect.top - verticalTolerance;
      if (isCrossingTop) {
        player.position.y = platRect.top - player.size.y;
        platform.removeFromParent();
        _fragilePlatforms.removeAt(i);
        player.velocity.y = math.max(player.velocity.y, 0);
        break;
      }
    }
  }

  void _updateHazards(double dt, double speedMultiplier) {
    if (_maxHeight < _hazardStartScore) return;

    _hazardTimer += dt;
    if (_hazardTimer >= _hazardSpawnInterval) {
      _hazardTimer = 0;
      _spawnHazard(speedMultiplier);
    }

    for (int i = _hazards.length - 1; i >= 0; i--) {
      final hazard = _hazards[i];
      hazard.x += hazard.speed * hazard.direction * dt;

      final minX = hazard.radius;
      final maxX = size.x - hazard.radius;
      if (hazard.x <= minX) {
        hazard.x = minX;
        hazard.direction = 1;
      } else if (hazard.x >= maxX) {
        hazard.x = maxX;
        hazard.direction = -1;
      }
    }
  }

  void _updateMovingPlatforms(double dt, double speedMultiplier) {
    for (int i = _movingPlatforms.length - 1; i >= 0; i--) {
      final platform = _movingPlatforms[i];
      platform.x += platform.speed * platform.direction * dt;

      final minX = 0.0;
      final maxX = size.x - platform.size.x;
      if (platform.x <= minX) {
        platform.x = minX;
        platform.direction = 1;
      } else if (platform.x >= maxX) {
        platform.x = maxX;
        platform.direction = -1;
      }
    }
  }

  void _spawnHazard(double speedMultiplier) {
    final y = size.y * (0.12 + _rng.nextDouble() * 0.28);
    final speed = _hazardBaseSpeed * speedMultiplier;
    final hazard = HazardCircleComponent(
      position: Vector2(size.x / 2, y),
      radius: _hazardRadius,
      speed: speed,
      direction: 1,
    );
    add(hazard);
    _hazards.add(hazard);
  }

  bool _checkHazardCollision(PlayerComponent player, double dt) {
    final playerCenter = player.position + (player.size / 2);
    final nextCenter =
        playerCenter + Vector2(player.velocity.x * dt, player.velocity.y * dt);
    final playerRadius = math.min(player.size.x, player.size.y) * 0.35;

    for (final hazard in _hazards) {
      final center = hazard.position;
      final combined = playerRadius + hazard.radius;
      if (playerCenter.distanceTo(center) <= combined ||
          nextCenter.distanceTo(center) <= combined) {
        return true;
      }
    }
    return false;
  }

  void _placePlayerOnPlatform(
    PlayerComponent player,
    PlatformComponent platform,
  ) {
    player.position
      ..x = platform.x + (platform.size.x - player.size.x) / 2
      ..y = platform.y - player.size.y;
    player.velocity.setZero();
  }

  void _lockPlayerOnStartPlatform(PlayerComponent player) {
    final platform = _startPlatform;
    if (platform == null) return;
    _placePlayerOnPlatform(player, platform);
  }

  void _beginRun() {
    if (_hasStarted) return;
    _hasStarted = true;
    final player = _player;
    if (player == null) return;
    player.velocity.y = -player.jumpVelocity;
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  void _syncCameraToPlayer(PlayerComponent player) {
    final targetY = size.y * 0.6;
    final delta = targetY - player.y;
    player.y += delta;

    for (final platform in _platforms) {
      platform.y += delta;
    }

    for (final platform in _fragilePlatforms) {
      platform.y += delta;
    }

    for (final platform in _movingPlatforms) {
      platform.y += delta;
    }

    for (final platform in _boostPlatforms) {
      platform.y += delta;
    }

    for (final hazard in _hazards) {
      hazard.y += delta;
    }

    _worldOffset += delta;
    if (_worldOffset > _maxWorldOffset) {
      _maxWorldOffset = _worldOffset;
    }

    if (delta > 0) {
      _maxHeight += delta;
      scoreNotifier.value = _maxHeight.round();
    }

    _recyclePlatforms();
  }

  void _recyclePlatforms() {
    _platforms.removeWhere((platform) {
      if (platform.y > size.y + 60) {
        platform.removeFromParent();
        return true;
      }
      return false;
    });

    _fragilePlatforms.removeWhere((platform) {
      if (platform.y > size.y + 60) {
        platform.removeFromParent();
        return true;
      }
      return false;
    });

    _movingPlatforms.removeWhere((platform) {
      if (platform.y > size.y + 60) {
        platform.removeFromParent();
        return true;
      }
      return false;
    });

    _boostPlatforms.removeWhere((platform) {
      if (platform.y > size.y + 60) {
        platform.removeFromParent();
        return true;
      }
      return false;
    });

    _hazards.removeWhere((hazard) {
      if (hazard.y > size.y + hazard.radius * 2) {
        hazard.removeFromParent();
        return true;
      }
      return false;
    });

    while (_platforms.length < _targetNormalPlatforms()) {
      final highestY = _platforms.isEmpty
          ? size.y - 120
          : _platforms.map((p) => p.y).reduce(math.min);
      final y = highestY - _randomGap();
      final x = _findNonOverlappingX(y);
      if (x == null) {
        break;
      }
      final platform = _createNormalPlatform(Vector2(x, y));
      if (!_overlapsAnyPlatform(_rectForSpawn(platform.position))) {
        add(platform);
        _platforms.add(platform);
      }
    }

    final densityFactor = _densityFactor();

    if (_fragilePlatforms.length < _targetFragileMax() &&
        _rng.nextDouble() < _breakPlatformChance * densityFactor) {
      final highestY = _currentHighestY();
      final y = highestY - _randomGap();
      final x = _findNonOverlappingX(y);
      if (x != null) {
        final fragile = _createFragilePlatform(Vector2(x, y));
        if (!_overlapsAnyPlatform(_rectForSpawn(fragile.position))) {
          add(fragile);
          _fragilePlatforms.add(fragile);
        }
      }
    }

    if (_maxHeight >= _movingPlatformStartScore &&
        _movingPlatforms.length < _targetMovingMax() &&
        _rng.nextDouble() < _movingPlatformChance * densityFactor) {
      final highestY = _currentHighestY();
      final y = highestY - _randomGap();
      final x = _findNonOverlappingX(y);
      if (x != null) {
        final speed = _movingPlatformBaseSpeed * _difficultyMultiplier();
        final moving = MovingPlatformComponent(
          position: Vector2(x, y),
          size: Vector2(_platformWidth, _platformHeight),
          speed: speed,
          direction: _rng.nextBool() ? 1 : -1,
          isBreakable: true,
        );
        if (!_overlapsAnyPlatform(_rectForSpawn(moving.position))) {
          add(moving);
          _movingPlatforms.add(moving);
        }
      }
    }

    if (_maxHeight >= _boostPlatformStartScore &&
        _boostPlatforms.length < _targetBoostMax() &&
        _rng.nextDouble() < _boostPlatformChance * densityFactor) {
      final highestY = _currentHighestY();
      final y = highestY - _randomGap();
      final x = _findNonOverlappingX(y);
      if (x != null) {
        final boost = _createBoostPlatform(Vector2(x, y));
        if (!_overlapsAnyPlatform(_rectForSpawn(boost.position))) {
          add(boost);
          _boostPlatforms.add(boost);
        }
      }
    }
  }

  void _triggerGameOver() {
    if (_isGameOver) return;
    _isGameOver = true;
    pauseEngine();

    final best = bestScoreNotifier.value;
    if (scoreNotifier.value > best) {
      bestScoreNotifier.value = scoreNotifier.value;
      _saveBestScore(scoreNotifier.value);
    }

    overlays.add(overlayGameOver);
  }

  void restart() {
    overlays.remove(overlayGameOver);
    overlays.remove(overlayPause);
    overlays.remove(overlayMenu);
    overlays.remove(overlayCountdown);
    overlays.remove(overlayHud);
    _reset();
    startWithCountdown();
  }

  void setMusicVolume(double value) {
    musicVolume.value = value.clamp(0.0, 1.0);
  }

  void setSfxVolume(double value) {
    sfxVolume.value = value.clamp(0.0, 1.0);
  }

  void pauseGame() {
    if (_isGameOver || isPaused) return;
    isPaused = true;
    pauseEngine();
    overlays.add(overlayPause);
  }

  void resumeGame() {
    if (_isGameOver || !isPaused) return;
    isPaused = false;
    overlays.remove(overlayPause);
    resumeEngine();
  }

  void startGame() {
    if (_isGameOver || !isPaused) return;
    isPaused = false;
    overlays.remove(overlayMenu);
    overlays.remove(overlayCountdown);
    overlays.remove(overlayPause);
    if (!overlays.isActive(overlayHud)) {
      overlays.add(overlayHud);
    }
    resumeEngine();
  }

  void startWithCountdown() {
    if (_isGameOver || !isPaused) return;

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

  void _applyInputFromPosition(Offset position) {
    final center = size.x / 2;
    final normalized = ((position.dx - center) / center).clamp(-1.0, 1.0);
    _inputXTarget = normalized.toDouble();
  }

  void setInputXTarget(double value) {
    _beginRun();
    _inputXTarget = value.clamp(-1.0, 1.0).toDouble();
  }

  void setPanInputEnabled(bool enabled) {
    _panInputEnabled = enabled;
  }

  void stopInputX() {
    _inputX = 0;
    _inputXTarget = 0;
  }

  void slamDown() {
    if (_isGameOver || isPaused || countdown.value != null) return;
    if (!_hasStarted) return;
    final player = _player;
    if (player == null) return;
    player.velocity.y = math.max(player.velocity.y, _slamVelocity);
  }

  @override
  void onPanStart(DragStartInfo info) {
    if (!_panInputEnabled) return;
    _beginRun();
    _applyInputFromPosition(info.raw.localPosition);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (!_panInputEnabled) return;
    if (!_hasStarted) return;
    _applyInputFromPosition(info.raw.localPosition);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    if (!_panInputEnabled) return;
    stopInputX();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent &&
        (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
            keysPressed.contains(LogicalKeyboardKey.keyS))) {
      slamDown();
    }

    final left =
        keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA);
    final right =
        keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD);

    if (left && !right) {
      setInputXTarget(-1);
    } else if (right && !left) {
      setInputXTarget(1);
    } else if (!keysPressed.contains(LogicalKeyboardKey.arrowLeft) &&
        !keysPressed.contains(LogicalKeyboardKey.arrowRight) &&
        !keysPressed.contains(LogicalKeyboardKey.keyA) &&
        !keysPressed.contains(LogicalKeyboardKey.keyD)) {
      stopInputX();
    }

    return KeyEventResult.handled;
  }
}
