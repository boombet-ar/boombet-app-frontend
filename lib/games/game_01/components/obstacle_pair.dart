import 'dart:math';
import 'package:flame/components.dart';
import '../game_01.dart';
import 'column_component.dart';

class ObstaclePair extends PositionComponent with HasGameRef<Game01> {
  ObstaclePair({
    required this.gameSize,
    required this.topSprite,
    required this.midSprite,
    required this.bottomSprite,
  });

  final Vector2 gameSize;
  final Sprite topSprite;
  final Sprite midSprite;
  final Sprite bottomSprite;

  final double gap = 150;
  bool scored = false;

  late ColumnComponent topColumn;
  late ColumnComponent bottomColumn;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // 🔥 CLAVE: tamaño del padre
    size = Vector2(gameSize.x + 100, gameSize.y);

    final random = Random();
    const minMargin = 80.0;

    final usableHeight = gameSize.y - minMargin * 2;
    final gapCenterY = minMargin + random.nextDouble() * (usableHeight - gap);

    final topHeight = gapCenterY - gap / 2;
    final bottomY = gapCenterY + gap / 2;
    final bottomHeight = gameSize.y - bottomY;

    topColumn = ColumnComponent(
      capNearGap: bottomSprite,
      mid: midSprite,
      capFarFromGap: topSprite,
      heightPx: topHeight,
    )..position = Vector2(gameSize.x, 0);

    bottomColumn = ColumnComponent(
      capNearGap: topSprite,
      mid: midSprite,
      capFarFromGap: bottomSprite,
      heightPx: bottomHeight,
    )..position = Vector2(gameSize.x, bottomY);

    add(topColumn);
    add(bottomColumn);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!scored &&
        (topColumn.position.x + topColumn.size.x) < game.player!.position.x) {
      scored = true;
      game.addPoint();
    }

    if (topColumn.position.x + topColumn.size.x < 0) {
      removeFromParent();
    }
  }
}
