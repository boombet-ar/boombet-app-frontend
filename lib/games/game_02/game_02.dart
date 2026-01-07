import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:boombet_app/games/game_02/components/game_over_overlay.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/block.dart';
import 'package:flame/text.dart';

typedef GameOverCallback = void Function(StackResult result);

class StackResult {
  final int score;
  final int best;
  StackResult({required this.score, required this.best});
}

enum StackState { playing, gameOver }

class Game02 extends FlameGame with TapCallbacks {
  Game02({required this.onGameOver});

  final GameOverCallback onGameOver;
  static const overlayGameOver = 'game02GameOver';
  static const _prefsBestKey = 'game02_best_score';
  static const double _gravity = 1200;

  // ====== Tuning ======
  static const double _blockHeight = 34;
  static const double _spawnGap = 12;
  static const double _dropExtra = 90;
  static const double _targetTopY = 180;
  static const double _minOverlapPx = 6;
  static const double _minOverlapRatio = 0.30;
  static const double _perfectRatio = 0.85;

  // dificultad
  static const double _speedStart = 220;
  static const double _speedAddPerBlock = 10;
  static const double _widthStartRatio = 0.62;
  static const double _minWidth = 0; // permite heredar tamaños muy pequeños

  // ====== State ======
  StackState state = StackState.playing;

  final List<BlockComponent> tower = [];
  BlockComponent? moving;

  int score = 0;
  int bestScore = 0;

  int _perfectCombo = 0;
  double _movingSpeed = _speedStart;
  double _movingWidth = 0;
  double _sliceHeight = _blockHeight;
  ui.Image? _towerImage;
  bool _imageReady = false;

  // HUD simple
  late final TextComponent _scoreText;
  late final TextComponent _comboText;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.topLeft;

    _scoreText = TextComponent(
      text: '0',
      position: Vector2(16, 12),
      anchor: Anchor.topLeft,
      priority: 999,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
    );

    _comboText = TextComponent(
      text: '',
      position: Vector2(16, 44),
      anchor: Anchor.topLeft,
      priority: 999,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    );

    add(_scoreText);
    add(_comboText);

    await _loadBestScore();
    try {
      // Ruta relativa a assets/ definida en pubspec (assets/images/...)
      final img = await images.load('games/game_02/boombet_tower.png');
      _towerImage = img;
      _sliceHeight = math.min(_blockHeight, img.height.toDouble());
      _imageReady = img.width > 0 && img.height > 0;
    } catch (e) {
      debugPrint('[Game02] Failed to load tower texture: $e');
      _imageReady = false;
    }

    await _loadBestScore();
    _resetGame();
  }

  void _resetGame() {
    // limpiar
    state = StackState.playing;
    overlays.remove(overlayGameOver);

    score = 0;
    _perfectCombo = 0;
    _movingSpeed = _speedStart;

    // remover componentes existentes
    for (final b in tower) {
      b.removeFromParent();
    }
    tower.clear();
    moving?.removeFromParent();
    moving = null;

    _scoreText.text = '0';
    _comboText.text = '';

    // base block
    final baseWidth = size.x * _widthStartRatio;
    _movingWidth = baseWidth;

    final base = BlockComponent(
      position: Vector2((size.x - baseWidth) / 2, size.y - _blockHeight - 80),
      size: Vector2(baseWidth, _blockHeight),
      colorSeed: 0,
      isMoving: false,
      speed: 0,
      towerImage: _imageReady ? _towerImage : null,
      sliceTop: _sliceTopForIndex(0),
      sliceHeight: _sliceHeight,
    );

    tower.add(base);
    add(base);

    _spawnNextBlock();
  }

  void restart() => _resetGame();

  void _spawnNextBlock() {
    if (state != StackState.playing) return;

    final prev = tower.last;

    _movingWidth = prev.size.x; // hereda exactamente el ancho del último bloque

    final double spawnY =
        prev.position.y - _blockHeight - _spawnGap - _dropExtra;

    final startLeft = 0.0;
    final startX = startLeft;

    final block = BlockComponent(
      position: Vector2(startX, spawnY),
      size: Vector2(_movingWidth, _blockHeight),
      colorSeed: tower.length,
      isMoving: true,
      speed: _movingSpeed,
      towerImage: _imageReady ? _towerImage : null,
      sliceTop: _sliceTopForIndex(tower.length),
      sliceHeight: _sliceHeight,
    );

    moving = block;
    add(block);

    _rebalanceTower();
  }

  void _rebalanceTower() {
    if (tower.isEmpty) return;

    final topY = tower.last.position.y;
    if (topY >= _targetTopY) return; // aún lejos del borde superior

    final delta =
        _targetTopY - topY; // mover todo hacia abajo para centrar la cima

    if (delta.abs() > 0.01) {
      for (final b in tower) {
        b.position.y += delta;
      }
      if (moving != null) {
        moving!.position.y += delta;
        // mantener separación sobre la cima para que no quede “enganchado” abajo
        final desiredY =
            tower.last.position.y - (_blockHeight + _spawnGap + _dropExtra);
        if (!moving!.isDropping && moving!.position.y > desiredY) {
          moving!.position.y = desiredY;
        }
      }
    }
  }

  double _sliceTopForIndex(int index) {
    if (!_imageReady || _towerImage == null) return 0;
    final double imgH = _towerImage!.height.toDouble();
    final double cycle = (_blockHeight * index) % imgH;
    double sliceTop = imgH - _sliceHeight - cycle;

    while (sliceTop < 0) {
      sliceTop += imgH;
    }
    if (sliceTop + _sliceHeight > imgH) {
      sliceTop = imgH - _sliceHeight;
    }

    return sliceTop;
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    if (state != StackState.playing) return;

    final m = moving;
    if (m == null || !m.isMoving) return;

    // soltar: empieza caída vertical con gravedad
    m.startDrop(_gravity);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (state != StackState.playing) return;

    final m = moving;
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
    final double ratioPrev = overlap / prev.size.x;

    // Sólo pierde si no hay solape real; permitir “golpe en la punta” con corte mínimo
    if (overlap <= _minOverlapPx) {
      _gameOver();
      return;
    }

    // recortes: generamos caída de los sobrantes y dejamos solo el solapado
    final newLeft = math.max(currLeft, prevLeft);
    if (currLeft < prevLeft) {
      _spawnFallingChunk(
        x: currLeft,
        width: prevLeft - currLeft,
        y: curr.position.y,
        height: curr.size.y,
        colorSeed: curr.colorSeed,
      );
    }
    if (currRight > prevRight) {
      _spawnFallingChunk(
        x: prevRight,
        width: currRight - prevRight,
        y: curr.position.y,
        height: curr.size.y,
        colorSeed: curr.colorSeed,
      );
    }

    curr.position.x = newLeft;
    curr.size.x = overlap;
    _movingWidth = curr.size.x;

    final bool isPerfect = ratioPrev >= _perfectRatio;

    if (isPerfect) {
      _perfectCombo += 1;
      HapticFeedback.lightImpact();
    } else {
      _perfectCombo = 0;
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
    _scoreText.text = '$score';

    _comboText.text = _perfectCombo == 0
        ? ''
        : 'PERFECT x$_perfectCombo  (x$multiplier)';

    // fijamos la pieza al tower
    tower.add(curr);
    moving = null;

    _rebalanceTower();

    // dificultad
    _movingSpeed += _speedAddPerBlock;
    _movingWidth = curr.size.x;

    // spawnear siguiente
    _spawnNextBlock();
  }

  void _gameOver() {
    state = StackState.gameOver;

    final newBest = math.max(bestScore, score);
    if (newBest != bestScore) {
      bestScore = newBest;
      _persistBestScore();
    }

    onGameOver(StackResult(score: score, best: bestScore));
    overlays.add(overlayGameOver);
  }

  void _spawnFallingChunk({
    required double x,
    required double width,
    required double y,
    required double height,
    required int colorSeed,
  }) {
    final color = HSVColor.fromAHSV(
      1,
      (colorSeed * 35 % 360).toDouble(),
      0.75,
      0.95,
    ).toColor();

    final chunk = RectangleComponent(
      position: Vector2(x, y),
      size: Vector2(width, height),
      paint: Paint()..color = color,
      anchor: Anchor.topLeft,
      priority: 5,
    );

    final fallDistance = size.y - y + 40;
    chunk.add(
      MoveByEffect(
        Vector2(0, fallDistance),
        EffectController(duration: 0.55, curve: Curves.easeIn),
        onComplete: () => chunk.removeFromParent(),
      ),
    );
    chunk.add(
      OpacityEffect.to(
        0,
        EffectController(duration: 0.55, curve: Curves.easeIn),
      ),
    );

    add(chunk);
  }

  Future<void> _loadBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    bestScore = prefs.getInt(_prefsBestKey) ?? 0;
  }

  Future<void> _persistBestScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsBestKey, bestScore);
  }
}
