import 'dart:math';
import 'package:flame/components.dart';
import '../game_01.dart';
import 'column_component.dart';

class ObstaclePair extends PositionComponent with HasGameRef<Game01> {
  ObstaclePair({
    required this.gameSize,
    required this.topSprite,
    required this.midSprite,
    required this.gap,
    required this.speed,
    required this.tubeWidthFactor,
  });

  final Vector2 gameSize;
  final Sprite topSprite;
  final Sprite midSprite;
  final double gap;
  final double speed;
  final double tubeWidthFactor;
  bool scored = false;

  // Vertical drift
  late final double _verticalAmplitude;
  late final double _verticalSpeed;
  late final double _verticalPhase;
  double _t = 0;
  late double _baseTopY;
  late double _baseBottomY;
  late double _bottomHeight;

  late ColumnComponent topColumn;
  late ColumnComponent bottomColumn;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 🔥 CLAVE: tamaño del padre
    size = Vector2(gameSize.x + 100, gameSize.y);

    final random = Random();
    const minMargin = 12.0; // minimal margin to maximize column height
    const double extraStretch =
        96.0; // over-extend columns to avoid visible gaps

    final usableHeight = gameSize.y - minMargin * 2;
    final gapTop = minMargin + random.nextDouble() * (usableHeight - gap);
    final gapCenterY = gapTop + gap / 2;

    final topHeight =
        gapTop + extraStretch; // extends upward, bottom stays at gapTop
    final bottomY = gapTop + gap; // keep gap start intact
    final bottomHeight =
        gameSize.y - bottomY + extraStretch; // extends downward
    _baseTopY = -extraStretch;
    _baseBottomY = bottomY;
    _bottomHeight = bottomHeight;

    topColumn = ColumnComponent(
      capNearGap: topSprite,
      mid: midSprite,
      capFarFromGap: topSprite,
      heightPx: topHeight,
      widthFactor: tubeWidthFactor,
      speed: speed,
    )..position = Vector2(gameSize.x, 0);

    bottomColumn = ColumnComponent(
      capNearGap: topSprite,
      mid: midSprite,
      capFarFromGap: topSprite,
      heightPx: bottomHeight,
      widthFactor: tubeWidthFactor,
      speed: speed,
    )..position = Vector2(gameSize.x, bottomY);

    add(topColumn);
    add(bottomColumn);

    // Vertical drift parameters (small, gentle movement)
    _verticalAmplitude = random.nextDouble() * 16 + 8; // 8..24 px
    _verticalSpeed = random.nextDouble() * 0.6 + 0.6; // 0.6..1.2 rad/s
    _verticalPhase = random.nextDouble() * pi * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isPaused || game.isGameOver) {
      return;
    }

    if (!scored &&
        (topColumn.position.x + topColumn.size.x) < game.player!.position.x) {
      scored = true;
      game.addPoint();
    }

    _t += dt;
    _applyVerticalDrift();

    if (topColumn.position.x + topColumn.size.x < 0) {
      removeFromParent();
    }
  }

  void _applyVerticalDrift() {
    final rawOffset =
        sin(_t * _verticalSpeed + _verticalPhase) * _verticalAmplitude;
    // Allow gentle wiggle up/down; clamp to avoid extreme shifts
    const double clampRange = 24;
    final offset = rawOffset.clamp(-clampRange, clampRange);

    topColumn.position.y = _baseTopY + offset;
    bottomColumn.position.y = _baseBottomY + offset;
  }
}
